USE E_Commerse
GO

SELECT * FROM dbo.cust_dimen

UPDATE dbo.cust_dimen
SET Cust_id = (
	SELECT REPLACE (Cust_id, 'Cust_', '')
)

ALTER TABLE dbo.cust_dimen
ALTER COLUMN Cust_id INT NOT NULL

ALTER TABLE dbo.cust_dimen ADD CONSTRAINT pk_cust_dimen PRIMARY KEY (Cust_id)

SELECT * FROM dbo.orders_dimen


UPDATE dbo.orders_dimen
SET Ord_id = (
	SELECT REPLACE (Ord_id, 'Ord_', '')
)

CREATE TABLE order_dimen2 (
	Order_id INT PRIMARY KEY,
	Order_Priority VARCHAR(15),
	Order_Date DATE Not null
)

INSERT INTO order_dimen2 (Order_id, Order_Priority, Order_Date )  
				SELECT CAST(Ord_id AS INT), Order_Priority, CAST(Order_Date as date) 
				FROM dbo.orders_dimen
				ORDER BY Cast(Ord_id AS INT)
SELECT * FROM order_dimen2

DROP TABLE orders_dimen

sp_rename 'dbo.order_dimen2', 'orders_dimen'

select * from orders_dimen

select * from prod_dimen

UPDATE dbo.prod_dimen
SET column1 = (
	SELECT REPLACE (column1, ',Prod', '')
)

select * from prod_dimen

CREATE TABLE prod_temp (
	Prod_id INT PRIMARY KEY,
	Product_Name VARCHAR(50) NOT NULL,
	Category_Name VARCHAR(50) NOT NULL
)

INSERT INTO prod_temp (Prod_id, Product_Name, Category_Name )
			SELECT CAST(column2 AS int) AS Prod_id, right(column1, LEN(column1)-CHARINDEX( ',', column1)) AS Product_Name, 
					left(column1, CHARINDEX( ',', column1)-1) as Category_Name
			FROM prod_dimen
			ORDER BY CAST(column2 AS int)


select * from prod_temp

DROP TABLE prod_dimen

sp_rename 'dbo.prod_temp', 'prod_dimen'

select * from shipping_dimen

UPDATE dbo.shipping_dimen
SET Ship_id = (
	SELECT REPLACE (Ship_id, 'SHP_', '')
)

CREATE TABLE ship_temp (
	Ship_id INT PRIMARY KEY,
	Order_id INT NOT NULL,
	Ship_Mode VARCHAR(50) NOT NULL,
	Ship_Date DATE NOT NULL
)

select * from shipping_dimen

INSERT INTO ship_temp (Ship_id, Order_id, Ship_Mode, Ship_Date )
	SELECT CAST(Ship_id AS INT), Order_ID, Ship_Mode, CAST(Ship_Date AS DATE) 
	FROM dbo.shipping_dimen
	ORDER BY Cast(Ship_id AS INT)

SELECT * FROM ship_temp

DROP TABLE shipping_dimen

sp_rename 'dbo.ship_temp', 'shipping_dimen'

SELECT * FROM market_fact

UPDATE dbo.market_fact
SET Ship_id = (SELECT REPLACE (Ship_id, 'SHP_', '')), 
	Prod_id = (SELECT REPLACE (Prod_id, 'Prod_', '')), 
	Ord_id = (SELECT REPLACE (Ord_id, 'Ord_', '')), 
	Cust_id = (SELECT REPLACE (Cust_id, 'Cust_', ''))

ALTER TABLE dbo.market_fact ALTER COLUMN Ord_id INT NOT NULL;
ALTER TABLE dbo.market_fact ALTER COLUMN Prod_id INT NOT NULL;
ALTER TABLE dbo.market_fact ALTER COLUMN Ship_id INT NOT NULL;
ALTER TABLE dbo.market_fact ALTER COLUMN Cust_id INT NOT NULL;
ALTER TABLE dbo.market_fact ALTER COLUMN Sales DECIMAL(18,5);
ALTER TABLE dbo.market_fact ALTER COLUMN Discount DECIMAL (18,2);
ALTER TABLE dbo.market_fact ALTER COLUMN Order_Quantity INT;
ALTER TABLE dbo.market_fact ALTER COLUMN Profit  DECIMAL (18,6);
ALTER TABLE dbo.market_fact ALTER COLUMN Shipping_Cost DECIMAL (18,3);
ALTER TABLE dbo.market_fact ALTER COLUMN Product_Base_Margin DECIMAL (18,4);


--Used for finding  Non number values.
SELECT Ord_id, Ship_id,Product_Base_Margin 
FROM market_fact 
WHERE ISNUMERIC( Product_Base_Margin) = 0

UPDATE dbo.market_fact
SET Product_Base_Margin = (
	SELECT REPLACE (Product_Base_Margin, 'NA', '0')
)

SELECT * 
FROM market_fact AS a 
JOIN shipping_dimen AS e
ON a.Ship_id = e.Ship_id -- and a.Ord_id = e.Order_id
ORDER BY e.Ship_id

SELECT * 
FROM market_fact AS a  
JOIN cust_dimen AS b 
ON a.Cust_id = b.Cust_id
JOIN orders_dimen AS c
ON a.Ord_id = c.Order_id
JOIN prod_dimen AS d
ON a.Prod_id = d.Prod_id
JOIN shipping_dimen AS e
ON a.Ship_id = e.Ship_id


--ANSWER 1

SELECT * INTO combined_table 
	FROM (
		SELECT a.Ord_id, a.Prod_id, a.Ship_id, a.Cust_id, a.Sales, a.Discount, a.Order_Quantity, a. Profit, a.Shipping_Cost,
				a.Product_Base_Margin, b.Customer_Name, b.Customer_Segment, b.Province, b.Region,
				c.Order_Priority, c.Order_Date, d.Product_Name, d.Category_Name, e.Ship_Mode, e.Ship_Date
		FROM market_fact AS a JOIN cust_dimen AS b 
		ON a.Cust_id = b.Cust_id
		JOIN orders_dimen AS c
		ON a.Ord_id = c.Order_id
		JOIN prod_dimen AS d
		ON a.Prod_id = d.Prod_id
		JOIN shipping_dimen AS e
		ON a.Ship_id = e.Ship_id
		) combined

SELECT * FROM combined_table ORDER BY Order_Date

--ANSWER 2

SELECT TOP 3 Cust_id, Customer_Name, COUNT(Ord_id) AS Cust_Orders 
FROM combined_table 
GROUP BY Cust_id, Customer_Name 
ORDER BY COUNT(Ord_id) DESC

--ANSWER 3

ALTER TABLE dbo.combined_table ADD DaysTakenForDelivery INT

UPDATE dbo.combined_table
SET DaysTakenForDelivery = DATEDIFF(d, Order_Date, Ship_Date)

--ANSWER 4

SELECT Cust_id, Customer_Name, Order_Date, Ship_Date, DaysTakenForDelivery AS MaxDaysTakenForDelivery
FROM combined_table
WHERE DaysTakenForDelivery = (
			SELECT MAX(DaysTakenForDelivery)  
			FROM combined_table
			)


--ANSWER 5

SELECT Prod_id, Product_Name, SUM(Sales) 
OVER(PARTITION BY Prod_id) AS Product_Total_Sales 
FROM combined_table 
--ORDER BY Prod_id

--ANSWER 6

SELECT DISTINCT Prod_id, Product_Name, SUM(Profit) 
OVER(PARTITION BY Prod_id) AS Each_Products_Total_Profit 
FROM combined_table 
ORDER BY 3 DESC

--ANSWER 7

SELECT COUNT(DISTINCT Cust_id) Total_Customers_Visits_in_January  
FROM combined_table 
WHERE MONTH(Order_Date) = 1 AND YEAR(Order_Date) = 2011

SELECT	DISTINCT MONTH(Order_Date) [month], 
		Count(DISTINCT Cust_id) count_customerS
FROM combined_table A
WHERE EXISTS (
		SELECT Cust_id
		FROM combined_table B 
		WHERE A.Cust_id = B.Cust_id 
		And MONTH(Order_Date) = 1 
		AND YEAR(Order_Date) = 2011
		)
AND  YEAR(Order_Date) = 2011
GROUP BY MONTH(Order_Date)

--Below query shows; Customers who visit a store in 2011, january also visits any store/stores n times  again 2011 another month

SELECT DISTINCT Cust_id, Customer_Name, Seperate_Month_Visit 
FROM (
	SELECT Cust_id, Customer_Name, Order_Date, DENSE_RANK() OVER(PARTITION BY (Cust_id) ORDER BY  MONTH(Order_Date)) AS Seperate_Month_Visit
	FROM combined_table 
	WHERE YEAR(Order_Date) = 2011) Temp
	--ORDER BY Customer_Name, Order_Date
	WHERE Seperate_Month_Visit = 5 --n


--ANSWER 8

SELECT DISTINCT Cust_id, Customer_Name, First_Order, t1.Order_Date AS Thirth_Order, DATEDIFF(d,First_Order,t1.Order_Date) DifferenceDay 
FROM (
		SELECT Customer_Name, Order_Date, Cust_id, DENSE_RANK() OVER(PARTITION BY Cust_id ORDER BY Order_Date) RN,
				FIRST_VALUE(Order_Date) OVER(PARTITION BY Cust_id ORDER BY Order_Date) First_Order
		FROM combined_table) AS t1
WHERE RN = 3

---Answer 9

WITH cte1 AS (
	SELECT Cust_id, Customer_Name, COUNT(Prod_id) OVER(PARTITION BY Cust_id) Prod11Count
	FROM combined_table 
	WHERE Prod_id = 11
), cte2 AS(
	SELECT Cust_id, Customer_Name, COUNT(Prod_id) OVER(PARTITION BY Cust_id) Prod14Count
	FROM combined_table 
	WHERE Prod_id = 14
), cte3 AS(
	SELECT Cust_id, Customer_Name, COUNT(Prod_id) OVER(PARTITION BY Cust_id) ProdCount
	FROM combined_table 
)SELECT DISTINCT cte1.Cust_id,cte1.Customer_Name, Prod11Count, Prod14Count, ProdCount,
		CAST(1.0*Prod11Count/ProdCount AS numeric(3,2)) AS P11_Quantity_Ratio,
		CAST(1.0*Prod14Count/ProdCount AS numeric(3,2)) AS P14_Quantity_Ratio
FROM cte1, cte2,cte3 
WHERE cte1.Cust_id = cte2.Cust_id AND cte1.Cust_id=cte3.Cust_id


SELECT Cust_id,Customer_Name, Order_Quantity, CAST(Order_Quantity AS DECIMAL)/each_prod_quantity_sum AS Quantity_Ratio 
FROM cte
ORDER BY Cust_id

--Second Part

--1. Create a view where each user’s visits are logged by month, 
--	allowing for the possibility that these will have occurred over multiple years since whenever business started operations.

CREATE VIEW CUSTOMER_LOGS AS
SELECT	Cust_id,
		YEAR (Order_Date) [Year],
		MONTH(Order_Date) [Month],
		COUNT (*) total_visit,
		DENSE_RANK() OVER (ORDER BY YEAR (Order_Date), MONTH(Order_Date)) AS DENSE_MONTH
FROM	combined_table
GROUP BY	
		Cust_id, MONTH(Order_Date), YEAR (Order_Date)

--2. Identify the time lapse between each visit. So, for each person and for each month, we see when the next visit is.

CREATE VIEW NEXT_VISIT_VW AS
SELECT	*,
		LEAD (DENSE_MONTH) OVER (PARTITION BY cust_id ORDER BY DENSE_MONTH) NEXT_VISIT_MONTH
FROM	CUSTOMER_LOGS


--3. Calculate the time gaps between visits.

CREATE VIEW TIME_GAPS_VW AS 
SELECT	*, NEXT_VISIT_MONTH - DENSE_MONTH AS TIME_GAPS
FROM	NEXT_VISIT_VW

--4. Categorise the customer with time gap 1 as retained, >1 as irregular and NULL as churned.

SELECT cust_id, AVG_TIME_GAP,
		CASE 
			WHEN AVG_TIME_GAP = 1 THEN 'retained'
			WHEN AVG_TIME_GAP >1 THEN 'irregular'
			WHEN AVG_TIME_GAP IS NULL THEN 'churned'
		ELSE 'UNKNOWN DATA' END CUST_CLASS
FROM
		(
		SELECT	cust_id, AVG (TIME_GAPS) AVG_TIME_GAP
		FROM	TIME_GAPS_VW
		GROUP BY 
				cust_id
		) A

--5. Calculate the retention month wise.
SELECT  DISTINCT
		NEXT_VISIT_MONTH as retention_month,
		COUNT (cust_id) OVER (PARTITION BY NEXT_VISIT_MONTH ) RETENTION_SUM_MONTHLY
FROM 
TIME_GAPS_VW
WHERE
TIME_GAPS = 1
ORDER BY
		1 






