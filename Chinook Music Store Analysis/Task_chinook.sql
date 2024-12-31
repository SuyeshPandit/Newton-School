-- Obj 1. To check for missing values
SELECT COUNT(*) AS Missing_Values
FROM customer
WHERE first_name IS NULL OR last_name IS NULL OR email IS NULL;

-- OBJ 1 To check for duplicates
SELECT first_name, last_name, email, COUNT(*) AS DuplicateCount
FROM customer
GROUP BY first_name, last_name, email
HAVING COUNT(*) > 1;


-- OBJ 2a Top-selling tracks in the USA
SELECT t.name AS TrackName, SUM(il.quantity) AS TotalSold
FROM invoice_line il
JOIN track t ON il.track_id = t.track_id
JOIN invoice i ON il.invoice_id = i.invoice_id
WHERE i.billing_country = 'USA'
GROUP BY t.name
ORDER BY TotalSold DESC
LIMIT 5;

-- OBJ 2b Top artist in the USA
SELECT ar.name AS ArtistName, SUM(il.quantity) AS TotalSold
FROM invoice_line il
JOIN track t ON il.track_id = t.track_id
JOIN album al ON t.album_id = al.album_id
JOIN artist ar ON al.artist_id = ar.artist_id
JOIN invoice i ON il.invoice_id = i.invoice_id
WHERE i.billing_country = 'USA'
GROUP BY ar.name
ORDER BY TotalSold DESC
LIMIT 5;

-- Obj 2c Most famous genres in the USA
SELECT g.name AS GenreName, SUM(il.quantity) AS TotalSold
FROM invoice_line il
JOIN track t ON il.track_id = t.track_id
JOIN genre g ON t.genre_id = g.genre_id
JOIN invoice i ON il.invoice_id = i.invoice_id
WHERE i.billing_country = 'USA'
GROUP BY g.name
ORDER BY TotalSold DESC
LIMIT 5;


-- OBJ 3a Location breakdown
SELECT country, COUNT(*) AS TotalCustomers
FROM customer
GROUP BY country
ORDER BY TotalCustomers DESC;

-- OBJ 3b Age breakdown (assuming birthdate is stored in the employee table for reference)
SELECT TIMESTAMPDIFF(YEAR, e.birthdate, CURDATE()) AS AgeGroup, COUNT(*) AS TotalCustomers
FROM customer c
JOIN employee e ON c.support_rep_id = e.employee_id
GROUP BY AgeGroup
ORDER BY AgeGroup;

-- OBJ 3c Gender breakdown (not directly available; require assumptions or enrich data)
SELECT 'Unknown' AS Gender, COUNT(*) AS TotalCustomers
FROM customer;

--OBJ 4
-- Revenue and invoices by country
SELECT billing_country AS Country, 
       SUM(total) AS TotalRevenue, 
       COUNT(invoice_id) AS TotalInvoices
FROM invoice
GROUP BY billing_country
ORDER BY TotalRevenue DESC;

-- Revenue and invoices by state
SELECT billing_country AS Country, billing_state AS State, 
       SUM(total) AS TotalRevenue, 
       COUNT(invoice_id) AS TotalInvoices
FROM invoice
GROUP BY billing_country, billing_state
ORDER BY TotalRevenue DESC;

-- Revenue and invoices by city
SELECT billing_country AS Country, billing_city AS City, 
       SUM(total) AS TotalRevenue, 
       COUNT(invoice_id) AS TotalInvoices
FROM invoice
GROUP BY billing_country, billing_city
ORDER BY TotalRevenue DESC;


-- OBJ 5.	Find the top 5 customers by total revenue in each country
SELECT  c.country, c.customer_id, SUM(i.total) AS total_revenue
FROM customer c
JOIN invoice i
ON c.customer_id = i.customer_id
GROUP BY c.country, c.customer_id, c.first_name, c.last_name
ORDER BY c.country, total_revenue DESC;


-- OBJ 6.	Identify the top-selling track for each customer
WITH CustomerTrackRevenue AS (
    SELECT c.customer_id, t.name AS track_name, SUM(il.quantity * il.unit_price) AS total_revenue
    FROM customer c
    JOIN invoice i ON c.customer_id = i.customer_id
    JOIN invoice_line il ON i.invoice_id = il.invoice_id
    JOIN track t ON il.track_id = t.track_id
    GROUP BY c.customer_id, t.name
),
TopTracks AS (
    SELECT customer_id, track_name, total_revenue,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY total_revenue DESC) AS rnk
    FROM CustomerTrackRevenue
)
SELECT customer_id, track_name AS top_selling_track, total_revenue
FROM TopTracks
WHERE rnk = 1
ORDER BY customer_id;


-- OBJ 7.Are there any patterns or trends in customer purchasing behavior 
SELECT c.customer_id, COUNT(i.invoice_id) AS purchase_frequency,
    AVG(i.total) AS average_order_value,
    SUM(i.total) AS total_spent
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY c.customer_id
ORDER BY total_spent DESC;


-- OBJ 8
-- Total customers
SELECT COUNT(*) AS TotalCustomers FROM customer;

-- Customers who made a purchase in the last 3 months
SELECT COUNT(DISTINCT customer_id) AS ActiveCustomers
FROM invoice
WHERE invoice_date >= DATE_SUB(CURDATE(), INTERVAL 3 MONTH);

-- Churn rate calculation
SELECT 
    (1 - (ActiveCustomers.TotalActive / TotalCustomers.Total)) * 100 AS ChurnRate
FROM 
    (SELECT COUNT(*) AS Total FROM customer) AS TotalCustomers,
    (SELECT COUNT(DISTINCT customer_id) AS TotalActive 
     FROM invoice 
     WHERE invoice_date >= DATE_SUB(CURDATE(), INTERVAL 3 MONTH)) AS ActiveCustomers;


-- OBJ 9
-- Percentage of total sales by genre in the USA
SELECT g.name AS Genre, 
       SUM(il.quantity * il.unit_price) AS GenreSales, 
       ROUND(SUM(il.quantity * il.unit_price) * 100 / 
             (SELECT SUM(il.quantity * il.unit_price)
              FROM invoice_line il
              JOIN invoice i ON il.invoice_id = i.invoice_id
              WHERE i.billing_country = 'USA'), 2) AS PercentageOfTotalSales
FROM invoice_line il
JOIN track t ON il.track_id = t.track_id
JOIN genre g ON t.genre_id = g.genre_id
JOIN invoice i ON il.invoice_id = i.invoice_id
WHERE i.billing_country = 'USA'
GROUP BY g.name
ORDER BY GenreSales DESC;

-- across countries
SELECT c.country, SUM(i.total) AS total_sales,
    ROUND(SUM(i.total) * 100.0 / (SELECT SUM(total) FROM invoice), 2) AS sales_percentage
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY c.country
ORDER BY total_sales DESC;




-- Best-selling genres and artists in the USA
SELECT g.name AS Genre, ar.name AS Artist, 
       SUM(il.quantity * il.unit_price) AS TotalSales
FROM invoice_line il
JOIN track t ON il.track_id = t.track_id
JOIN album al ON t.album_id = al.album_id
JOIN artist ar ON al.artist_id = ar.artist_id
JOIN genre g ON t.genre_id = g.genre_id
JOIN invoice i ON il.invoice_id = i.invoice_id
WHERE i.billing_country = 'USA'
GROUP BY g.name, ar.name
ORDER BY TotalSales DESC
LIMIT 10;


-- OBJ 10. customers who have purchased tracks from at least 3 different genres.
SELECT c.customer_id AS CustomerID, 
       CONCAT(c.first_name, ' ', c.last_name) AS CustomerName, 
       COUNT(DISTINCT g.genre_id) AS UniqueGenres
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
JOIN invoice_line il ON i.invoice_id = il.invoice_id
JOIN track t ON il.track_id = t.track_id
JOIN genre g ON t.genre_id = g.genre_id
GROUP BY c.customer_id
HAVING UniqueGenres >= 3
ORDER BY UniqueGenres DESC;


-- OBJ 11. Rank genres based on their sales performance in the USA
SELECT g.name AS Genre, 
       SUM(il.quantity * il.unit_price) AS TotalSales,
       RANK() OVER (ORDER BY SUM(il.quantity * il.unit_price) DESC) AS Rank
FROM invoice_line il
JOIN track t ON il.track_id = t.track_id
JOIN genre g ON t.genre_id = g.genre_id
JOIN invoice i ON il.invoice_id = i.invoice_id
WHERE i.billing_country = 'USA'
GROUP BY g.name
ORDER BY TotalSales DESC;


-- OBJ 12. Identify customers who have not made a purchase in the last 3 months
SELECT c.customer_id AS CustomerID, 
       CONCAT(c.first_name, ' ', c.last_name) AS CustomerName, 
       MAX(i.invoice_date) AS LastPurchaseDate
FROM customer c
LEFT JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY c.customer_id
HAVING MAX(i.invoice_date) < DATE_SUB(CURDATE(), INTERVAL 3 MONTH) 
   OR MAX(i.invoice_date) IS NULL
ORDER BY LastPurchaseDate DESC;


-- SUB 1. Recommend three albums for prioritization in the USA based on genre sales analysis.
SELECT g.name AS Genre, a.title AS Album, SUM(il.quantity * il.unit_price) AS TotalSales
FROM invoice_line il
JOIN track t ON il.track_id = t.track_id
JOIN genre g ON t.genre_id = g.genre_id
JOIN album a ON t.album_id = a.album_id
JOIN invoice i ON il.invoice_id = i.invoice_id
JOIN customer c ON i.customer_id = c.customer_id
WHERE c.country = 'USA'
GROUP BY g.name, a.title
ORDER BY TotalSales DESC
LIMIT 3;


-- SUB 2. Determine the top-selling genres outside the USA and identify commonalities or differences.
SELECT g.name AS Genre, SUM(il.quantity * il.unit_price) AS TotalSales
FROM invoice_line il
JOIN track t ON il.track_id = t.track_id
JOIN genre g ON t.genre_id = g.genre_id
JOIN invoice i ON il.invoice_id = i.invoice_id
JOIN customer c ON i.customer_id = c.customer_id
WHERE c.country != 'USA'
GROUP BY g.name
ORDER BY TotalSales DESC;


-- SUB 3. Customer Purchasing Behavior Analysis
SELECT CustomerType,COUNT(*) AS CustomerCount,AVG(PurchaseFrequency) AS AvgPurchaseFrequency,AVG(AvgBasketSize) AS AvgBasketSize,
SUM(TotalSpending) AS TotalSpending
FROM (
    SELECT i.customer_id,
        CASE 
            WHEN MIN(i.invoice_date) < DATE_SUB(NOW(), INTERVAL 1 YEAR) THEN 'Long-Term'
            ELSE 'New'
        END AS CustomerType, COUNT(i.invoice_id) AS PurchaseFrequency, AVG(il.quantity) AS AvgBasketSize, SUM(il.quantity * il.unit_price) AS TotalSpending
    FROM invoice i
    JOIN invoice_line il ON i.invoice_id = il.invoice_id
    GROUP BY i.customer_id
) AS Subquery
GROUP BY CustomerType;


-- Sub 4.Product Affinity Analysis
WITH GenrePairs AS (
    SELECT il1.invoice_id, g1.name AS genre1, g2.name AS genre2
    FROM invoice_line il1
    JOIN track t1 ON il1.track_id = t1.track_id
    JOIN genre g1 ON t1.genre_id = g1.genre_id
    JOIN invoice_line il2 ON il1.invoice_id = il2.invoice_id AND il1.track_id <> il2.track_id
    JOIN track t2 ON il2.track_id = t2.track_id
    JOIN genre g2 ON t2.genre_id = g2.genre_id
)
SELECT genre1, genre2, COUNT(*) AS co_occurrence_count
FROM GenrePairs
GROUP BY genre1, genre2
ORDER BY co_occurrence_count DESC
LIMIT 10;



-- SUB 5. Regional Market Analysis
SELECT c.country AS Region, AVG(i.total) AS AvgSpendingPerInvoice,COUNT(DISTINCT i.customer_id) AS NumberOfCustomers,
    AVG(il.quantity) AS AvgTracksPerCustomer
FROM invoice i
JOIN customer c ON i.customer_id = c.customer_id
JOIN invoice_line il ON i.invoice_id = il.invoice_id
GROUP BY c.country
ORDER BY AvgSpendingPerInvoice DESC;


-- Sub 6.Customer Risk Profiling
SELECT c.customer_id, c.city, c.country,
    COUNT(i.invoice_id) AS total_purchases,
    SUM(i.total) AS total_spent,
    MAX(i.invoice_date) AS last_purchase_date,
    DATEDIFF(CURRENT_DATE(), MAX(i.invoice_date)) AS days_since_last_purchase,
    CASE
        WHEN DATEDIFF(CURRENT_DATE(), MAX(i.invoice_date)) > 90 THEN 'High Risk'
        WHEN DATEDIFF(CURRENT_DATE(), MAX(i.invoice_date)) BETWEEN 30 AND 90 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS risk_level
FROM customer c
LEFT JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY c.customer_id, c.city, c.country
ORDER BY risk_level DESC, total_spent DESC;



-- SUB 7. Customer Lifetime Value Modeling
SELECT c.customer_id, SUM(il.quantity * il.unit_price) AS LifetimeValue
FROM invoice i
JOIN customer c ON i.customer_id = c.customer_id
JOIN invoice_line il ON i.invoice_id = il.invoice_id
GROUP BY c.customer_id
ORDER BY LifetimeValue DESC;


-- Sub 8. If data on promotional campaigns (discounts, events, email marketing) is available
CREATE TABLE promotion (
    promotion_id INT PRIMARY KEY, campaign_name VARCHAR(255), start_date DATE, end_date DATE
);
-- Campaign Sales Impact
SELECT
    p.campaign_name,
    COUNT(DISTINCT i.customer_id) AS new_customers,
    SUM(i.total) AS total_sales,
    AVG(i.total) AS avg_order_value,
    COUNT(i.invoice_id) AS total_orders
FROM invoice i
JOIN promotion p ON i.invoice_date BETWEEN p.start_date AND p.end_date
GROUP BY p.campaign_name;



-- SUB 10. Add "ReleaseYear" Column to Albums Table
ALTER TABLE album ADD ReleaseYear INTEGER;


-- SUB 11. Geographical Purchasing Behavior
SELECT c.country, 
    COUNT(DISTINCT c.customer_id) AS CustomerCount,
    AVG(i.total) AS AvgSpending,
    AVG(il.quantity) AS AvgTracksPerCustomer
FROM invoice i
JOIN customer c ON i.customer_id = c.customer_id
JOIN invoice_line il ON i.invoice_id = il.invoice_id
GROUP BY c.country
ORDER BY AvgSpending DESC;
ORDER BY AvgSpending DESC;


------------------------------------- For graphs ----------------------------------------------
-- Top tracks of artist with total sold
SELECT t.name AS TrackName, ar.name AS ArtistName, 
       SUM(il.quantity) AS TotalSold
FROM invoice_line il
JOIN track t ON il.track_id = t.track_id
JOIN album al ON t.album_id = al.album_id
JOIN artist ar ON al.artist_id = ar.artist_id
JOIN invoice i ON il.invoice_id = i.invoice_id
WHERE i.billing_country = 'USA'
GROUP BY t.name, ar.name
ORDER BY TotalSold DESC;
