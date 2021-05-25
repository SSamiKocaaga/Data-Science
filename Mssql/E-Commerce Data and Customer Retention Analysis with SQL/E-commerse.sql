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
		FROM market_fact AS a  
		JOIN cust_dimen AS b 
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

SELECT TOP 3 Customer_Name, SUM(Order_Quantity) AS Quantity 
FROM combined_table 
GROUP BY Customer_Name 
ORDER BY SUM(Order_Quantity) DESC

--ANSWER 3

ALTER TABLE dbo.combined_table ADD DaysTakenForDelivery INT

UPDATE dbo.combined_table
SET DaysTakenForDelivery = DATEDIFF(d, Order_Date, Ship_Date)

--ANSWER 4

SELECT Customer_Name, DaysTakenForDelivery AS MaxDaysTakenForDelivery
FROM combined_table
WHERE DaysTakenForDelivery = (
			SELECT MAX(DaysTakenForDelivery)  
			FROM combined_table
			)

--ANSWER 5

SELECT Prod_id, Product_Name, SUM(Sales) 
OVER(PARTITION BY Prod_id) AS Product_Total_Sales 
FROM combined_table 
ORDER BY Prod_id

--ANSWER 6

SELECT Prod_id, Product_Name, SUM(Profit) 
OVER(PARTITION BY Prod_id) AS Each_Products_Total_Profit 
FROM combined_table 
ORDER BY Prod_id

--ANSWER 7

SELECT COUNT(DISTINCT Customer_Name) Total_Customers_Visits_in_January  
FROM combined_table 
WHERE MONTH(Order_Date) = 1 AND YEAR(Order_Date) = 2011

SELECT Customer_Name
FROM combined_table
WHERE YEAR(Order_Date) = 2021 and Customer_Name IN (
		SELECT DISTINCT Customer_Name Total_Customers_Visits_in_January  
		FROM combined_table 
		WHERE MONTH(Order_Date) = 1 AND YEAR(Order_Date) = 2011)
HAVING (COUNT(DISTINCT MONTH(Order_Date))=12)


/*SELECT Customer_Name, COUNT(DISTINCT MONTH(Order_Date)) OVER(Partition By Customer_Name order by Order_Date DESC ROWS BETWEEN  UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) 

FROM combined_table
Order BY Customer_Name, Order_Date*/

SELECT Customer_Name, Seperate_Month_Visit 
FROM (
	SELECT Customer_Name, Order_Date, DENSE_RANK() OVER(PARTITION BY (Customer_Name) ORDER BY  MONTH(Order_Date)) AS Seperate_Month_Visit
	FROM combined_table 
	WHERE YEAR(Order_Date) = 2011) Temp
	--ORDER BY Customer_Name, Order_Date
	WHERE Seperate_Month_Visit = 12


--ANSWER 8
SELECT Cust_id, Customer_Name,First_Order, t1.Order_Date AS Thirth_Order, DATEDIFF(d,First_Order,t1.Order_Date) DifferenceDay 
FROM (
		SELECT Customer_Name, Order_Date, Cust_id, ROW_NUMBER() OVER(PARTITION BY Cust_id ORDER BY Order_Date) RN,
				FIRST_VALUE(Order_Date) OVER(PARTITION BY Cust_id ORDER BY Order_Date) First_Order
		FROM combined_table) AS t1
WHERE RN = 3

---Answer 9
WITH cte AS (
	SELECT Cust_id, Customer_Name, Prod_id, Order_Quantity, SUM(Order_Quantity) OVER(PARTITION by Prod_id) AS each_prod_quantity_sum 
	FROM combined_table 
	WHERE Prod_id in (11,14))
SELECT *, CAST(Order_Quantity AS DECIMAL)/each_prod_quantity_sum AS Quantity_Ratio 
FROM cte
ORDER BY Cust_id

--Second Part
--1.2,3,4,5
--Create view Montly_Visit as (
		SELECT *, LEAD(Order_Date,1) OVER(PARTITION BY Cust_id ORDER BY Order_Date) AS Next_Visit,
				DATEDIFF(d,LEAD(Order_Date,1) OVER(PARTITION by Cust_id ORDER BY Order_Date),Order_Date) Next_Visit_This_Month,
				CASE COALESCE(DATEDIFF(d,LEAD(Order_Date,1) OVER(PARTITION BY Cust_id ORDER BY Order_Date),Order_Date),-1)
					WHEN -1 THEN 'Churned'
					WHEN 0 THEN 'Retained'
					WHEN 1 THEN 'Retained'
					ELSE 'Irregular'
					END Retention_Month
		FROM combined_table
		WHERE DATEPART(m, Order_Date) = DATEPART(m, DATEADD(m, -1, '2009-02-01'))
		AND DATEPART(yyyy, Order_Date) = DATEPART(yyyy, DATEADD(m, -1, '2009-02-01'))






