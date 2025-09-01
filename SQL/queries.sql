-- ===============================================================
-- 1️⃣ Очистка даних
-- Видаляємо дублі та некоректні записи (Quantity <= 0, UnitPrice <= 0, пусті CustomerID)
-- Залишаємо тільки один унікальний рядок на дублікат
CREATE OR REPLACE TABLE `velvety-outcome-464211-n3.8.8_clean` AS
WITH cleaned AS (
  SELECT
    *,
    ROW_NUMBER() OVER (
      PARTITION BY InvoiceNo, StockCode, Quantity, CAST(UnitPrice AS STRING), InvoiceDate, CustomerID
      ORDER BY InvoiceDate
    ) AS row_num
  FROM `velvety-outcome-464211-n3.8.8`
  WHERE Quantity > 0
    AND UnitPrice > 0
    AND CustomerID IS NOT NULL
)
SELECT
  InvoiceNo,
  StockCode,
  Description,
  Quantity,
  InvoiceDate,
  UnitPrice,
  CustomerID,
  Country
FROM cleaned
WHERE row_num = 1;

-- ===============================================================
-- 2️⃣ Топ-10 товарів за виручкою
SELECT Description, SUM(Quantity*UnitPrice) AS Revenue
FROM `velvety-outcome-464211-n3.8.8_clean`
GROUP BY Description
ORDER BY Revenue DESC
LIMIT 10;

-- ===============================================================
-- 3️⃣ Топ-10 товарів за кількістю проданих одиниць
SELECT 
  Description,
  SUM(Quantity) AS TotalSold
FROM `velvety-outcome-464211-n3.8.8_clean`
GROUP BY Description
ORDER BY TotalSold DESC
LIMIT 10;

-- ===============================================================
-- 4️⃣ Товари з мінімальними продажами
SELECT 
  Description,
  SUM(Quantity) AS TotalSold
FROM `velvety-outcome-464211-n3.8.8_clean`
GROUP BY Description
ORDER BY TotalSold 
LIMIT 10;

-- ===============================================================
-- 5️⃣ Топ-10 клієнтів за виручкою
SELECT 
  CustomerID,
  SUM(Quantity * UnitPrice) AS Revenue
FROM `velvety-outcome-464211-n3.8.8_clean`
GROUP BY CustomerID
ORDER BY Revenue DESC
LIMIT 10;

-- ===============================================================
-- 6️⃣ Топ-10 клієнтів за середнім чеком
SELECT 
  CustomerID,
  AVG(Quantity * UnitPrice) AS AvgOrderValue
FROM `velvety-outcome-464211-n3.8.8_clean`
GROUP BY CustomerID
ORDER BY AvgOrderValue DESC
LIMIT 10;

-- ===============================================================
-- 7️⃣ Клієнти, що дають 80% виручки (Pareto)
WITH customer_revenue AS (
  SELECT 
    CustomerID,
    SUM(Quantity * UnitPrice) AS Revenue
  FROM `velvety-outcome-464211-n3.8.8_clean`
  GROUP BY CustomerID
),
ordered AS (
  SELECT 
    CustomerID,
    Revenue,
    SUM(Revenue) OVER (ORDER BY Revenue DESC) AS CumRevenue,
    SUM(Revenue) OVER () AS TotalRevenue
  FROM customer_revenue
)
SELECT 
  CustomerID,
  Revenue,
  CumRevenue,
  TotalRevenue,
  CumRevenue / TotalRevenue AS RevenueShare
FROM ordered
WHERE CumRevenue / TotalRevenue <= 0.8;

-- ===============================================================
-- 8️⃣ Виручка по країнах
SELECT 
  Country,
  SUM(Quantity * UnitPrice) AS Revenue
FROM `velvety-outcome-464211-n3.8.8_clean`
GROUP BY Country
ORDER BY Revenue DESC;

-- ===============================================================
-- 9️⃣ Середній чек по країнах
SELECT 
  Country,
  AVG(Quantity * UnitPrice) AS AvgOrderValue
FROM `velvety-outcome-464211-n3.8.8_clean`
GROUP BY Country
ORDER BY AvgOrderValue DESC;

-- ===============================================================
-- 10️⃣ Загальні продажі по країнах
SELECT 
  Country,
  SUM(Quantity) AS TotalSold
FROM `velvety-outcome-464211-n3.8.8_clean`
GROUP BY Country
ORDER BY TotalSold DESC;

-- ===============================================================
-- 11️⃣ Виручка по місяцях
SELECT 
  EXTRACT(MONTH FROM InvoiceDate) AS Month,
  SUM(Quantity * UnitPrice) AS Revenue
FROM `velvety-outcome-464211-n3.8.8_clean`
GROUP BY Month
ORDER BY Revenue DESC;

-- ===============================================================
-- 12️⃣ Виручка по днях тижня
SELECT 
  FORMAT_DATE('%A', DATE(InvoiceDate)) AS DayOfWeek,
  SUM(Quantity * UnitPrice) AS Revenue
FROM `velvety-outcome-464211-n3.8.8_clean`
GROUP BY DayOfWeek
ORDER BY Revenue DESC;

-- ===============================================================
-- 13️⃣ Виручка по датах
SELECT 
  DATE(InvoiceDate) AS Date,
  SUM(Quantity * UnitPrice) AS Revenue
FROM `velvety-outcome-464211-n3.8.8_clean`
GROUP BY Date
ORDER BY Date;

-- ===============================================================
-- 14️⃣ Нові клієнти по місяцях
WITH first_purchase AS (
  SELECT 
    CustomerID,
    MIN(DATE(InvoiceDate)) AS FirstPurchaseDate
  FROM `velvety-outcome-464211-n3.8.8_clean`
  GROUP BY CustomerID
)
SELECT 
  EXTRACT(YEAR FROM FirstPurchaseDate) AS Year,
  EXTRACT(MONTH FROM FirstPurchaseDate) AS Month,
  COUNT(DISTINCT CustomerID) AS NewCustomers
FROM first_purchase
GROUP BY Year, Month
ORDER BY Year, Month;

-- ===============================================================
-- 15️⃣ Когортний аналіз
WITH first_purchase AS (
  SELECT 
    CustomerID,
    MIN(DATE(InvoiceDate)) AS CohortDate
  FROM `velvety-outcome-464211-n3.8.8_clean`
  GROUP BY CustomerID
),
purchases AS (
  SELECT 
    CustomerID,
    DATE(InvoiceDate) AS PurchaseDate
  FROM `velvety-outcome-464211-n3.8.8_clean`
),
joined AS (
  SELECT 
    p.CustomerID,
    f.CohortDate,
    DATE_TRUNC(p.PurchaseDate, MONTH) AS PurchaseMonth
  FROM purchases p
  JOIN first_purchase f USING(CustomerID)
)
SELECT 
  FORMAT_DATE('%Y-%m', CohortDate) AS Cohort,
  FORMAT_DATE('%Y-%m', PurchaseMonth) AS PurchaseMonth,
  COUNT(DISTINCT CustomerID) AS ActiveCustomers
FROM joined
GROUP BY Cohort, PurchaseMonth
ORDER BY Cohort, PurchaseMonth;

-- ===============================================================
-- 16️⃣ Середній час до повторної покупки
WITH purchases AS (
  SELECT 
    CustomerID,
    DATE(InvoiceDate) AS PurchaseDate,
    ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY InvoiceDate) AS order_num
  FROM `velvety-outcome-464211-n3.8.8_clean`
),
diffs AS (
  SELECT 
    p1.CustomerID,
    DATE_DIFF(p2.PurchaseDate, p1.PurchaseDate, DAY) AS DaysBetween
  FROM purchases p1
  JOIN purchases p2
    ON p1.CustomerID = p2.CustomerID 
   AND p2.order_num = p1.order_num + 1
)
SELECT 
  AVG(DaysBetween) AS AvgDaysToRepurchase
FROM diffs;
