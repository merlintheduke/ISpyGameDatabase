-- Top 10 Most Wishlisted Games
SELECT 
    g.gameName,
    COUNT(w.wishlistID) AS timesWishlisted
FROM Game g
JOIN Wishlist w ON g.gameID = w.gameID
GROUP BY g.gameID, g.gameName
ORDER BY timesWishlisted DESC
LIMIT 10;

-- Developer's Average Game Rating
SELECT 
    d.developerName,
    ROUND(AVG(g.rating), 2) AS avgRating
FROM Developer d
JOIN Game g ON d.developerID = g.developerID
GROUP BY d.developerID, d.developerName
ORDER BY avgRating DESC;

-- What is the range of release dates
SELECT 
    MIN(releaseDate) AS oldestGame,
    MAX(releaseDate) AS newestGame
FROM Game;

-- Total number of games per platform
SELECT 
    p.platformName,
    COUNT(gp.gameID) AS totalGames
FROM Platform p
JOIN GamePlatform gp ON p.platformID = gp.platformID
GROUP BY p.platformID, p.platformName
ORDER BY totalGames DESC;

-- Unique languages in database
SELECT DISTINCT languageName
FROM Language
ORDER BY languageName;

-- games with above average ratings
SELECT 
    gameName,
    rating
FROM Game
WHERE rating > (
    SELECT AVG(rating) FROM Game
)
ORDER BY rating DESC;

-- Number of Wishlist Items per User
SELECT 
    u.userName,
    COUNT(w.wishlistID) AS totalWishlistItems
FROM User u
LEFT JOIN Wishlist w ON u.userID = w.userID
GROUP BY u.userID, u.userName
ORDER BY totalWishlistItems DESC;

-- game summary with developer, rating, release date
SELECT 
    CONCAT(
        g.gameName, 
        ' by ', 
        d.developerName, 
        ' | Rating: ', 
        ROUND(g.rating, 2),
        ' | Released: ', 
        YEAR(g.releaseDate)
    ) AS gameSummary
FROM Game g
JOIN Developer d ON g.developerID = d.developerID
ORDER BY g.rating DESC;