-- Run after igdb_import.py has populated the games staging table.
-- Select the database configured by DB_NAME before executing this script.

-- Setting up the normalized schema tables
CREATE TABLE Developer (
    developerID INT PRIMARY KEY AUTO_INCREMENT,
    developerName VARCHAR(255) UNIQUE
);
CREATE TABLE Game (
    gameID INT PRIMARY KEY AUTO_INCREMENT,
    developerID INT,
    gameName VARCHAR(512),
    ratingCount INT,
    rating DOUBLE,
    releaseDate DATE,
    FOREIGN KEY (developerID) REFERENCES Developer(developerID)
);
CREATE TABLE Language (
    languageID INT PRIMARY KEY AUTO_INCREMENT,
    languageName VARCHAR(255) UNIQUE
);
CREATE TABLE GameLanguage (
    languageID INT,
    gameID INT,
    PRIMARY KEY (gameID, languageID),
    FOREIGN KEY (gameID) REFERENCES Game(gameID),
    FOREIGN KEY (languageID) REFERENCES Language(languageID)
);
CREATE TABLE Platform (
    platformID INT PRIMARY KEY AUTO_INCREMENT,
    platformName VARCHAR(255) UNIQUE
);
CREATE TABLE GamePlatform (
	platformID INT,
    gameID INT,
    PRIMARY KEY (gameID, platformID),
    FOREIGN KEY (gameID) REFERENCES Game(gameID),
    FOREIGN KEY (platformID) REFERENCES Platform(platformID)
);
CREATE TABLE Category (
    categoryID INT PRIMARY KEY AUTO_INCREMENT,
    categoryName VARCHAR(255) UNIQUE
);
CREATE TABLE GameCategory (
	categoryID INT,
    gameID INT,
    PRIMARY KEY (gameID, categoryID),
    FOREIGN KEY (gameID) REFERENCES Game(gameID),
    FOREIGN KEY (categoryID) REFERENCES Category(categoryID)
);
CREATE TABLE User (
    userID INT PRIMARY KEY AUTO_INCREMENT,
    userName VARCHAR(255) UNIQUE,
    email VARCHAR(255) UNIQUE,
    birthday DATE
);
CREATE TABLE Wishlist (
    wishlistID INT PRIMARY KEY AUTO_INCREMENT,
    userID INT,
    gameID INT,
    dateAdded DATE DEFAULT (CAST(current_timestamp() AS date)),
    CONSTRAINT unique_user_game UNIQUE (userID, gameID),
    FOREIGN KEY (userID) REFERENCES User(userID),
    FOREIGN KEY (gameID) REFERENCES Game(gameID)
);

-- Log Table for the trigger log_rating_changes
CREATE TABLE GameRatingLog (
    logID INT AUTO_INCREMENT PRIMARY KEY,
    gameID INT,
    oldRating DOUBLE,
    newRating DOUBLE,
    changedAt DATETIME
);
-- Log table for the delete trigger after_wishlist_delete
CREATE TABLE WishlistLog (
    logID INT AUTO_INCREMENT PRIMARY KEY,
    userID INT,
    gameID INT,
    changeType VARCHAR(255),
    changedAt DATETIME
);
-- Filling the user table with users created by AI

SET SESSION cte_max_recursion_depth = 1000000;

INSERT INTO User (userName, email, birthday) VALUES
('alex_m23','alex.m23@email.com','2001-04-12'),
('jordan_k','jordan.k@email.com','1999-08-21'),
('maria_lopez','maria.lopez@email.com','2002-02-10'),
('chris_dev','chris.dev@email.com','1998-11-30'),
('sammy_g','sammy.g@email.com','2003-06-18'),
('nina_p','nina.p@email.com','2000-09-05'),
('david_r','david.r@email.com','1997-01-14'),
('lucas_b','lucas.b@email.com','2004-07-22'),
('emma_w','emma.w@email.com','2001-03-11'),
('olivia_s','olivia.s@email.com','2002-12-01'),

('noah_t','noah.t@email.com','1999-05-09'),
('liam_h','liam.h@email.com','2000-10-17'),
('ava_m','ava.m@email.com','2003-01-28'),
('isabella_c','isabella.c@email.com','2001-06-30'),
('sophia_l','sophia.l@email.com','1998-09-12'),
('mia_g','mia.g@email.com','2002-04-25'),
('charlotte_d','charlotte.d@email.com','1997-11-03'),
('amelia_v','amelia.v@email.com','2004-08-14'),
('harper_f','harper.f@email.com','2000-02-19'),
('evelyn_j','evelyn.j@email.com','1999-07-07'),

('logan_p','logan.p@email.com','2001-12-22'),
('elijah_k','elijah.k@email.com','2003-03-15'),
('james_w','james.w@email.com','1998-06-01'),
('benjamin_s','benjamin.s@email.com','2002-10-29'),
('lucas_t','lucas.t@email.com','2000-01-05'),
('henry_b','henry.b@email.com','1997-05-18'),
('alexander_c','alex.c@email.com','2004-11-11'),
('jack_d','jack.d@email.com','2001-08-02'),
('daniel_m','daniel.m@email.com','1999-04-09'),
('matthew_r','matthew.r@email.com','2002-07-13'),

('aiden_l','aiden.l@email.com','2003-09-21'),
('owen_g','owen.g@email.com','1998-02-27'),
('samuel_h','samuel.h@email.com','2000-06-06'),
('joseph_v','joseph.v@email.com','1997-12-18'),
('john_f','john.f@email.com','2001-03-29'),
('dylan_j','dylan.j@email.com','2004-05-10'),
('luke_s','luke.s@email.com','1999-11-22'),
('gabriel_p','gabriel.p@email.com','2002-01-17'),
('anthony_k','anthony.k@email.com','2000-07-08'),
('isaac_w','isaac.w@email.com','1998-10-03'),

('grace_m','grace.m@email.com','2001-04-01'),
('chloe_l','chloe.l@email.com','2003-02-14'),
('victoria_r','victoria.r@email.com','1999-09-09'),
('ella_b','ella.b@email.com','2002-06-20'),
('scarlett_t','scarlett.t@email.com','2000-12-12'),
('zoey_d','zoey.d@email.com','1997-03-03'),
('lily_c','lily.c@email.com','2004-08-30'),
('hannah_s','hannah.s@email.com','2001-01-19'),
('aria_f','aria.f@email.com','1998-05-26'),
('layla_j','layla.j@email.com','2003-11-07'),

('wyatt_p','wyatt.p@email.com','2002-02-02'),
('sebastian_k','sebastian.k@email.com','2000-06-16'),
('leo_m','leo.m@email.com','1999-10-25'),
('julian_r','julian.r@email.com','1997-07-07'),
('hudson_w','hudson.w@email.com','2001-09-18'),
('carter_l','carter.l@email.com','2004-04-04'),
('ezra_g','ezra.g@email.com','1998-12-21'),
('jayden_s','jayden.s@email.com','2002-03-13'),
('asher_t','asher.t@email.com','2000-08-08'),
('hunter_b','hunter.b@email.com','1999-01-01'),

('leah_v','leah.v@email.com','2003-05-23'),
('stella_c','stella.c@email.com','2001-11-15'),
('hazel_m','hazel.m@email.com','1998-07-30'),
('ellie_k','ellie.k@email.com','2000-02-11'),
('paisley_r','paisley.r@email.com','2004-09-09'),
('nora_w','nora.w@email.com','2002-10-10'),
('audrey_l','audrey.l@email.com','1999-06-05'),
('brooklyn_s','brooklyn.s@email.com','2001-12-24'),
('bella_j','bella.j@email.com','1997-04-18'),
('savannah_f','savannah.f@email.com','2003-08-08'),

('ryan_t','ryan.t@email.com','2000-03-07'),
('nathan_p','nathan.p@email.com','1998-11-11'),
('aaron_d','aaron.d@email.com','2002-06-28'),
('adam_g','adam.g@email.com','1999-09-19'),
('ian_c','ian.c@email.com','2001-07-14'),
('jason_k','jason.k@email.com','2003-01-06'),
('kevin_r','kevin.r@email.com','2000-05-05'),
('eric_w','eric.w@email.com','1997-08-12'),
('brandon_s','brandon.s@email.com','2002-02-22'),
('justin_l','justin.l@email.com','1999-10-30'),

('tyler_m','tyler.m@email.com','2001-04-04'),
('zachary_b','zachary.b@email.com','2004-07-07'),
('sean_v','sean.v@email.com','1998-12-09'),
('colin_f','colin.f@email.com','2000-01-25'),
('patrick_x','patrick.x@email.com','2003-06-06'),
('victor_j','victor.j@email.com','1999-03-03'),
('andrew_p','andrew.p@email.com','2002-11-20'),
('tristan_k','tristan.k@email.com','2001-08-08'),
('caleb_r','caleb.r@email.com','1997-05-05'),
('miguel_g','miguel.g@email.com','2000-09-09');




-- Inserting all the data from our idgb games data table into our schema

INSERT INTO Developer (developerName)
SELECT DISTINCT 
    TRIM(SUBSTRING_INDEX(developers, ',', 1)) AS developerName
FROM games
WHERE developers IS NOT NULL
ORDER BY developerName;


INSERT INTO Game (gameName, ratingCount, rating, releaseDate, developerID)
SELECT 
    g.name,
    g.total_rating_count,
    ROUND(g.total_rating, 2),
    g.first_release_date,
    d.developerID
FROM games g
JOIN Developer d 
    ON TRIM(SUBSTRING_INDEX(g.developers, ',', 1)) = d.developerName;
    
-- Randomly Filling the wishlists of the users
INSERT IGNORE INTO Wishlist (userID, gameID, dateAdded)
SELECT 
    u.userID,
    g.gameID,
    CURDATE() - INTERVAL FLOOR(RAND()*1000) DAY
FROM User u
JOIN Game g
WHERE RAND() < 0.1;

INSERT INTO Language (languageName)
SELECT lang_name FROM (
    WITH RECURSIVE split_languages AS (
        SELECT 
            TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(language_supports, ',', 1), '(', 1)) AS lang,
            SUBSTRING(language_supports, LOCATE(',', language_supports) + 1) AS rest
        FROM games
        WHERE language_supports IS NOT NULL

        UNION ALL

        SELECT 
            TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(rest, ',', 1), '(', 1)),
            IF(LOCATE(',', rest) > 0, SUBSTRING(rest, LOCATE(',', rest) + 1), '')
        FROM split_languages
        WHERE rest <> ''
    )
    SELECT DISTINCT lang AS lang_name 
    FROM split_languages 
    WHERE lang <> ''
) AS final_list
ORDER BY lang_name ASC;


SET SESSION cte_max_recursion_depth = 1000000;

INSERT INTO GameLanguage (gameID, languageID)
WITH RECURSIVE split_mapping AS (
    SELECT 
        name AS g_name,
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(language_supports, ',', 1), '(', 1)) AS lang_name,
        SUBSTRING(language_supports, LOCATE(',', language_supports) + 1) AS rest
    FROM games
    WHERE language_supports IS NOT NULL AND language_supports <> ''
    
    UNION ALL
    
    SELECT 
        g_name,
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(rest, ',', 1), '(', 1)),
        IF(LOCATE(',', rest) > 0, SUBSTRING(rest, LOCATE(',', rest) + 1), '')
    FROM split_mapping
    WHERE rest <> ''
)
SELECT DISTINCT g.gameID, l.languageID
FROM split_mapping sm
JOIN Game g ON sm.g_name = g.gameName        
JOIN Language l ON sm.lang_name = l.languageName
WHERE sm.lang_name <> '';



INSERT INTO Platform (platformName)
SELECT plat_name FROM (
    WITH RECURSIVE split_plats AS (
        SELECT 
            TRIM(SUBSTRING_INDEX(platforms, ',', 1)) AS plat,
            SUBSTRING(platforms, LOCATE(',', platforms) + 1) AS rest
        FROM games
        WHERE platforms IS NOT NULL AND platforms <> ''
        UNION ALL
        SELECT 
            TRIM(SUBSTRING_INDEX(rest, ',', 1)),
            IF(LOCATE(',', rest) > 0, SUBSTRING(rest, LOCATE(',', rest) + 1), '')
        FROM split_plats
        WHERE rest <> ''
    )
    SELECT DISTINCT plat AS plat_name FROM split_plats WHERE plat <> ''
) AS final_list
ORDER BY plat_name ASC;


SET SESSION cte_max_recursion_depth = 1000000;

INSERT IGNORE INTO GamePlatform (platformID, gameID)
WITH RECURSIVE platform_mapping AS (
    SELECT 
        name AS g_name,
        TRIM(SUBSTRING_INDEX(platforms, ',', 1)) AS single_plat,
        SUBSTRING(platforms, LOCATE(',', platforms) + 1) AS rest
    FROM games
    WHERE platforms IS NOT NULL AND platforms <> ''
    UNION ALL
    SELECT 
        g_name,
        TRIM(SUBSTRING_INDEX(rest, ',', 1)),
        IF(LOCATE(',', rest) > 0, SUBSTRING(rest, LOCATE(',', rest) + 1), '')
    FROM platform_mapping
    WHERE rest <> ''
)
SELECT p.platformID, g.gameID
FROM platform_mapping pm
JOIN Game g ON pm.g_name = g.gameName        
JOIN Platform p ON pm.single_plat = p.platformName;


INSERT INTO Category (categoryName)
SELECT cat_name FROM (
    WITH RECURSIVE split_cats AS (
        SELECT 
            TRIM(SUBSTRING_INDEX(genres, ',', 1)) AS cat,
            SUBSTRING(genres, LOCATE(',', genres) + 1) AS rest
        FROM games
        WHERE genres IS NOT NULL AND genres <> ''
        UNION ALL
        SELECT 
            TRIM(SUBSTRING_INDEX(rest, ',', 1)),
            IF(LOCATE(',', rest) > 0, SUBSTRING(rest, LOCATE(',', rest) + 1), '')
        FROM split_cats
        WHERE rest <> ''
    )
    SELECT DISTINCT cat AS cat_name FROM split_cats WHERE cat <> ''
) AS final_list
ORDER BY cat_name ASC;


SET SESSION cte_max_recursion_depth = 1000000;

INSERT IGNORE INTO GameCategory (categoryID, gameID)
WITH RECURSIVE category_mapping AS (
    SELECT 
        name AS g_name,
        TRIM(SUBSTRING_INDEX(genres, ',', 1)) AS single_cat,
        SUBSTRING(genres, LOCATE(',', genres) + 1) AS rest
    FROM games
    WHERE genres IS NOT NULL AND genres <> ''
    UNION ALL
    SELECT 
        g_name, 
        TRIM(SUBSTRING_INDEX(rest, ',', 1)),
        IF(LOCATE(',', rest) > 0, SUBSTRING(rest, LOCATE(',', rest) + 1), '')
    FROM category_mapping
    WHERE rest <> ''
)
SELECT c.categoryID, g.gameID
FROM category_mapping cm
JOIN Game g ON cm.g_name = g.gameName        
JOIN Category c ON cm.single_cat = c.categoryName;
