-- 1. After_Wishlist_Insert Trigger Automatically logs newly inserted wishlists
DELIMITER $$

CREATE TRIGGER after_wishlist_insert
AFTER INSERT ON wishlist
FOR EACH ROW
BEGIN
    INSERT INTO wishlistlog (userID, gameID, changeType, changedAt)
    VALUES (NEW.userID, NEW.gameID, "INSERT", NOW());
END $$

DELIMITER ;
-- 2. AFTER UPDATE trigger: log rating changes
DELIMITER $$

CREATE TRIGGER log_rating_changes
AFTER UPDATE ON Game
FOR EACH ROW
BEGIN
    IF OLD.rating <> NEW.rating THEN
        INSERT INTO GameRatingLog (gameID, oldRating, newRating, changedAt)
        VALUES (OLD.gameID, OLD.rating, NEW.rating, NOW());
    END IF;
END $$

DELIMITER ;
SELECT * FROM GameRatingLog;
-- 3. Delete Trigger: Log deletions from Wishlist
DELIMITER $$

CREATE TRIGGER after_wishlist_delete
AFTER DELETE ON wishlist
FOR EACH ROW
BEGIN
    INSERT INTO wishlistlog (userID, gameID, changeType, changedAt)
    VALUES (OLD.userID, OLD.gameID, "DELETE",NOW());
END $$

DELIMITER ;

DELIMITER $$

CREATE PROCEDURE AddToWishlistAndShow (
    IN p_userID INT,
    IN p_gameID INT
)
BEGIN
    
    IF NOT EXISTS (
        SELECT 1 
        FROM Wishlist 
        WHERE userID = p_userID AND gameID = p_gameID
    ) THEN
        INSERT INTO Wishlist (userID, gameID, dateAdded)
        VALUES (p_userID, p_gameID, CURDATE());
    END IF;

    SELECT 
        g.gameName,
        g.rating,
        w.dateAdded
    FROM Wishlist w
    JOIN Game g ON w.gameID = g.gameID
    WHERE w.userID = p_userID
    ORDER BY g.rating DESC;
END $$

DELIMITER ;


CALL AddToWishlistAndShow(1, 13);

-- Total wishlist count for a user
DELIMITER $$

-- GetUserWishListCount function, gets the total wishlist count for a user
DELIMITER $$

CREATE FUNCTION GetUserWishlistCount (p_userID INT)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE total INT;

    SELECT COUNT(*)
    INTO total
    FROM Wishlist
    WHERE userID = p_userID;

    RETURN total;
END $$

DELIMITER ;


-- Tests all the functions

-- Tests the after_wishlist_insert trigger, Inserting and then checking the wishlistlog
INSERT INTO Wishlist (userID, gameID)
VALUES (3, 101);
-- Check result
SELECT * FROM wishlistlog;
CALL AddToWishlistAndShow(1, 9);
-- Tests the log_rating_changes trigger where you Update a gameratinglog rating
UPDATE Game
SET rating = rating - 1
WHERE gameID = 101;
-- Check log table
SELECT * FROM GameRatingLog WHERE gameID = 101;

-- Tests the 3rd trigger,by Deleting a wishlist entry to see if it logs it
DELETE FROM Wishlist
WHERE userID = 3 AND gameID = 101;
-- Check log
SELECT * FROM WishlistLog WHERE userID = 3 AND gameID = 101;

-- Tests the AddToWishlist procedure Should insert only if NOT already there
CALL AddToWishlistAndShow(1, 5);

-- Test GetUserWishlistCount function Should return total wishlist items
SELECT GetUserWishlistCount(2) AS wishlist_count;
-- DROP TRIGGER after_wishlist_delete;
