
DESCRIBE Walmart;

SELECT *
FROM 
	Walmart
LIMIT 3;


-- number of stores 

SELECT
	COUNT(DISTINCT(Store)) AS num_stores
FROM 
	Walmart;

-- 45 stores


/* since date column is varcahr datatype, string rules will apply for max/min decisions and it 
produces wrong result. we need to change its datatype to date datatype */

ALTER TABLE Walmart 
	ADD (new_Date DATE);

UPDATE Walmart
	SET new_Date=str_to_date(Date,'%d-%m-%Y');

ALTER TABLE Walmart
	DROP COLUMN Date;

ALTER TABLE Walmart
	RENAME COLUMN new_Date TO Date;


-- duration of analysis

SELECT 
	MIN(Date) AS first_week,
	MAX(Date) AS last_week,
	COUNT(DISTINCT(Date)) AS weeks_number
FROM 
	Walmart;

-- 143 unique weeks from 2010-02-05 to 2012-10-26


-- total weekly sale in all stores

SELECT
	SUM(Weekly_Sales) AS total_sales
FROM
	Walmart;

-- total weekly_Sale = 6737218987.11001


-- Weekly_Sales in 45 weeks

SELECT 
	Date,
	Weekly_Sales 
FROM 
	Walmart;


-- top 3 stores with highest amount of sales during 3 years

SELECT
	Store, 
	SUM(Weekly_Sales) AS sales_per_store
FROM 
	Walmart
GROUP BY Store 
ORDER BY sales_per_store DESC
LIMIT 3;

-- top 3 in 3 years : stores #20 (301397792.46000004),#4 (299543953.38), #14 (288999911.34000003)


-- last 3 stores with lowest amount of sales during 3 years

SELECT Store, 
	SUM(Weekly_Sales) AS sales_per_store
FROM 
	Walmart
GROUP BY Store 
ORDER BY sales_per_store
LIMIT 3;


-- last in 3 years: store #33 (37160221.960000016), #44 (43293087.83999999), #5 (45475688.9)


-- extract month and year from Date column for next analysis

ALTER TABLE Walmart
	ADD (Sales_Month INT);

ALTER TABLE Walmart
	ADD (Sales_Year INT);

UPDATE Walmart 
	SET Sales_Month=MONTH(Date);

UPDATE Walmart
	SET Sales_Year=Year(Date);


-- top store in each year based on their total sales


SELECT 
	Sales_Year, 
	Store
FROM 
    (SELECT 
    	Sales_Year,
    	Store, 
    	SUM(Weekly_Sales),
    	RANK () OVER (PARTITION BY Sales_Year ORDER BY SUM(Weekly_Sales) DESC) AS `rank`  
    FROM
    	Walmart
    GROUP BY Sales_Year, Store) temp
WHERE `rank` = 1;

-- 2010 : 14, 2011 : 4, 2012 : 4


-- last store in each year based on their total sales

SELECT 
	Sales_Year, 
	Store
FROM 
    (SELECT
    	Sales_Year,
    	Store, 
    	SUM(Weekly_Sales),
    	RANK() OVER (PARTITION BY Sales_Year ORDER BY SUM(Weekly_Sales)) AS `rank`  
    FROM 
    	Walmart
    GROUP BY Sales_Year, Store) temp
WHERE `rank` = 1;

-- 2010, 2011, 2012 : 33


-- month with highest and lowest sales 

SELECT 
	Sales_Month, 
	SUM(Weekly_Sales)
FROM 
	Walmart
GROUP BY Sales_Month
ORDER BY SUM(Weekly_Sales) DESC;

-- highest: 7 (650000977.2499998) lowest: 1 (332598438.48999983)


-- year with highest and lowest sales 

SELECT 
	Sales_Year, 
	SUM(Weekly_Sales)
FROM 
	Walmart
GROUP BY Sales_Year
ORDER BY SUM(Weekly_Sales) DESC;

-- highest: 2011 (2448200007.3499975) lowest: 2012 (2000132859.3500023)


-- top 5 stores with Weekly_Sales varying a lot

SELECT
	Store, 
	SUM(Weekly_Sales),
	STDDEV(Weekly_Sales) AS std
FROM 
	Walmart
GROUP BY Store
ORDER BY std DESC
LIMIT 5;

-- stores: 14, 10, 20, 4, 13


-- Holiday Analysis:

-- relation between the sales and the holiday weeks for all the years

SELECT
	Sales_Year,
	Holiday_Flag, 
	SUM(Weekly_Sales)
FROM 
	Walmart
GROUP BY Sales_Year, Holiday_Flag
ORDER BY Sales_Year;

-- holidays have a negative impact on annually sales.


-- sum of Weekly_Sales in each store in holiday and non-holiday dates

SELECT
	Store,
	Holiday_Flag, 
	SUM(Weekly_Sales)
FROM 
	Walmart
GROUP BY Store, Holiday_Flag
ORDER BY Store;


-- total weekly sales in holiday and non-holiday dates

SELECT
	Holiday_Flag, 
	SUM(Weekly_Sales)
FROM 
	Walmart
GROUP BY Holiday_Flag;

-- in general the sales in non-holidays is higher that holidays.


-- CPI Analysis:

-- relationship between sales and the Consumer Price Index (CPI) as a macroeconomic variable 

SELECT 
	Date,
	SUM(Weekly_Sales), 
	AVG(CPI) 
FROM 
	Walmart
GROUP BY Date
ORDER BY SUM(Weekly_Sales) DESC;

/* CPI does not seem to affect the weekly sales of stores.
 But, we can go through detail and check the exact correlation between them*/


SELECT 
	@a := AVG(CPI) AS avg1, 
    @b := AVG(Weekly_Sales) AS avg2, 
    @div := (stddev_samp(CPI) * stddev_samp(Weekly_Sales)) AS divv,
    SUM((CPI - @a) * (Weekly_Sales - @b)) / ((COUNT(CPI) - 1) * @div) AS cor
FROM 
	Walmart;

-- the negative correlation = -0.07263416204017634 confirms previous results.


-- average of CPI in top 3 stores

SELECT 
	Store,
	AVG(CPI),
	SUM(Weekly_Sales)
FROM
	Walmart
GROUP BY Store
ORDER BY SUM(Weekly_Sales) DESC
LIMIT 3;

-- stores: 20, 4, 14 with AVG(CPI)= 209, 128, 186


-- Temperature Analysis:

-- correlation between temperature and Weekly_Sales

SELECT 
	@a := AVG(Temperature) AS avg1, 
    @b := AVG(Weekly_Sales) AS avg2, 
    @div := (stddev_samp(Temperature) * stddev_samp(Weekly_Sales)) AS divv,
    SUM((Temperature - @a) * (Weekly_Sales - @b)) / ((count(Temperature) - 1) * @div) AS cor
FROM 
	Walmart;

-- temperature does not influence the weekly sales of stores.



-- temperature and weekly sales

ALTER TABLE Walmart
	ADD (temp VARCHAR(20));

UPDATE Walmart 
	SET temp = CASE
		WHEN Temperature <= 20.0 THEN '<20'
		WHEN 20.0 < Temperature AND Temperature <= 40.0 THEN '20-40'
		WHEN 40.0 < Temperature AND Temperature <= 60.0 THEN '40-60'
		WHEN 60.0 < Temperature AND Temperature <= 80.0 THEN '60-80'
		ELSE '>80'
	END;


SELECT 
	temp,
	SUM(Weekly_Sales)
FROM
	Walmart
GROUP BY temp
ORDER BY SUM(Weekly_Sales) DESC;


-- most sales happened in temperature 60-80 and the least sales happened in temperature<20


-- temperature and top-3 stores

SELECT 
	Store,
	temp,
	SUM(Weekly_Sales)
FROM
	Walmart
GROUP BY Store, temp
ORDER BY SUM(Weekly_Sales) DESC
LIMIT 3;

-- stores 20, 14, 4 at temperature = 60-80


-- Unemployment Analysis:

-- relationship between sales and the Unemployment as a macroeconomic variable 

SELECT 
	@a := AVG(Unemployment) AS avg1, 
    @b := AVG(Weekly_Sales) AS avg2, 
    @div := (stddev_samp(Unemployment) * stddev_samp(Weekly_Sales)) AS divv,
    SUM((Unemployment - @a) * (Weekly_Sales - @b)) / ((count(Unemployment) - 1) * @div) AS cor
FROM 
	Walmart;

-- the Unemployment does not influence weekly sales of stores.


-- unemployment rate and sales 

SELECT
	Sales_Year,
	Sales_Month,
	AVG(Unemployment),
	SUM(Weekly_Sales)
FROM
	Walmart
GROUP BY Sales_Year, Sales_Month
ORDER BY SUM(Weekly_Sales) DESC
LIMIT 3;

-- top : 12/2010 with AVG(Unemployment) = 8.47


-- min, max, avg of unemployment

SELECT 
	MIN(Unemployment),
	MAX(Unemployment),
	AVG(Unemployment) 
FROM
	Walmart;

-- min = 3.879 , max = 14.313, avg = 7.999
/*the top sales in 12/2010 happened with average unemployment rate more than average of 
total average unemployment*/


-- Fuel_Price Analysis:

-- fuel price and sales relation in each month of year

SELECT
	Sales_Year,
	Sales_Month,
	AVG(Fuel_Price),
	SUM(Weekly_Sales)
FROM
	Walmart
GROUP BY Sales_Year, Sales_Month
ORDER BY SUM(Weekly_Sales) DESC
LIMIT 3;

-- top : 12/2010 with AVG(Fuel_Price) = 2.988 


-- min, max, avg of fuel price

SELECT 
	MIN(Fuel_Price),
	MAX(Fuel_Price),
	AVG(Fuel_Price) 
FROM
	Walmart;

-- min = 2.472 , max = 4.468, avg = 3.358
-- the top sales in 12/2010 happened with average fuel price less than average of total fuel prices


