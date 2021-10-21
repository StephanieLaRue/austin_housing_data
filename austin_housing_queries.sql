USE austin_housing;

-- Average price of homes sold for each quarter in years 2018-2020
SELECT * FROM 
	(SELECT
		latest_saledate_year AS Year,
		DATEPART(quarter, latest_saledate) AS Quarter,
		AVG(latestPrice) AS AvgHomePrice
		FROM 
			austin_housing 
		WHERE
			latest_saledate_year IS NOT NULL 
			AND latest_saledate_year <> 2021
		GROUP BY 
			latest_saledate_year, DATEPART(quarter,latest_saledate)
	) avg_price
PIVOT (AVG(AvgHomePrice) FOR Year IN ([2018],[2019],[2020])) pivot_years

-- year over year differences 2018-2020
SELECT 
	latest_saledate_year AS Year,
	FORMAT(SUM(CAST(latestPrice AS BIGINT)),'C')  AS Total,
	FORMAT(LAG(SUM(CAST(latestPrice AS BIGINT))) 
			OVER(ORDER BY latest_saledate_year),'C') AS PreviousYear,
	FORMAT(SUM(CAST(latestPrice AS BIGINT)) - LAG(SUM(CAST(latestPrice AS BIGINT))) 
			OVER( ORDER BY latest_saledate_year ),'C') AS YOY_Difference
FROM austin_housing
WHERE 
	latest_saledate_year IS NOT NULL AND 
	YEAR(latest_saledate) BETWEEN '2018' AND '2020'
GROUP BY 
	latest_saledate_year;

-- avg home price year over year
SELECT 
	latest_saledate_year AS Year,
	FORMAT(AVG(CAST(latestPrice AS BIGINT)),'C')  AS Total,
	FORMAT(LAG(AVG(CAST(latestPrice AS BIGINT))) 
			OVER(ORDER BY latest_saledate_year),'C') AS PreviousYear,
	FORMAT(AVG(CAST(latestPrice AS BIGINT)) - LAG(AVG(CAST(latestPrice AS BIGINT))) 
			OVER( ORDER BY latest_saledate_year ),'C') AS YOY_Difference
FROM austin_housing
WHERE 
	latest_saledate_year IS NOT NULL AND 
	YEAR(latest_saledate) BETWEEN '2018' AND '2020'
GROUP BY 
	latest_saledate_year;

-- year over year difference for number of homes sold 
SELECT 
	latest_saledate_year AS Year,
    COUNT(*) AS HomesSold,
    LAG(COUNT(*)) OVER ( ORDER BY latest_saledate_year ) AS PreviousYear,
    COUNT(*) - LAG(COUNT(*)) OVER ( ORDER BY latest_saledate_year ) AS YOY_Difference
FROM   austin_housing
WHERE latest_saledate_year IS NOT NULL AND YEAR(latest_saledate) BETWEEN '2018' AND '2020'
GROUP BY latest_saledate_year;

-- % growth year over year 2018-2020
;WITH cte AS (
    SELECT 
	   latest_saledate_year AS Year,
	   SUM(CAST(latestPrice AS FLOAT)) AS Total,
       LAG(SUM(CAST(latestPrice AS FLOAT))) OVER ( ORDER BY latest_saledate_year ) AS PreviousYear,
       SUM(CAST(latestPrice AS FLOAT)) - LAG(SUM(CAST(latestPrice AS FLOAT))) OVER ( ORDER BY latest_saledate_year ) AS YOY_Difference
	FROM austin_housing 
	WHERE 
		latest_saledate_year IS NOT NULL 
		AND YEAR(latest_saledate) BETWEEN '2018' AND '2020' 
	GROUP BY 
		latest_saledate_year
) SELECT Year,
	FORMAT(Total,'C') Total_Sales, 
	FORMAT(YOY_Difference,'C') YOY_Difference,
	FORMAT(100.0*(YOY_Difference/PreviousYear),'N') AS Percentage_Change
FROM cte;

---- total home sales for all months from 2018 to 2020
WITH cte AS (
    SELECT 
	   latest_saledate_year AS Year,
       MONTH(latest_saledate) AS MonthSold,
	   SUM(latestPrice) AS Total,
       LAG(SUM(latestPrice)) OVER( partition by latest_saledate_year ORDER BY MONTH(latest_saledate)) AS PreviousYear,
       SUM(latestPrice) - LAG(SUM(latestPrice)) OVER(partition by latest_saledate_year ORDER BY latest_saledate_year) AS YOY_Difference
	FROM austin_housing 
	WHERE 
		latest_saledate_year IS NOT NULL AND latest_saledate_year <> '2021'
	GROUP BY 
		latest_saledate_year, MONTH(latest_saledate)
)
SELECT 
	Year, 
	DATENAME(month, DATEADD(MONTH, MonthSold, -1)) Month,
	FORMAT(Total,'C') Total_Sales, 
    FORMAT(PreviousYear,'C') AS Previous_Month,
	FORMAT(YOY_Difference,'C') MoM_Difference,
	FORMAT(100*(CAST(YOY_Difference AS FLOAT)/CAST(PreviousYear AS FLOAT)),'N')  
    AS Percentage_Change
FROM cte
ORDER BY Year;

-- avg sale price per month
SELECT 
	latest_saledate_year AS Year,
    MONTH(latest_saledate) AS MonthSold,
	AVG(latestPrice) AS Average
FROM austin_housing 
WHERE 
	latest_saledate_year IS NOT NULL AND latest_saledate_year <> '2021'
GROUP BY 
	latest_saledate_year, MONTH(latest_saledate)
ORDER BY Year, MonthSold;


-- jan only
-- total home sales for all months from 2018 to 2021
WITH cte AS (
    SELECT 
	   latest_saledate_year AS Year,
       MONTH(latest_saledate) AS MonthSold,
	   SUM(latestPrice) AS Total,
       LAG(SUM(latestPrice)) OVER(ORDER BY latest_saledate_year) AS PreviousYear,
       SUM(latestPrice) - LAG(SUM(latestPrice)) OVER(ORDER BY latest_saledate_year) AS YOY_Difference
	FROM austin_housing 
	WHERE 
		latest_saledate_year IS NOT NULL AND MONTH(latest_saledate) = 1
	GROUP BY 
		latest_saledate_year, MONTH(latest_saledate)
)
SELECT 
	Year, 
	DATENAME(month, DATEADD(MONTH, MonthSold, -1)) Month,
	FORMAT(Total,'C') Total_Sales_Jan, 
    FORMAT(PreviousYear,'C') AS Previous_Jan,
	FORMAT(YOY_Difference,'C') YOY_Difference_Jan,
	FORMAT(100*(CAST(YOY_Difference AS FLOAT)/CAST(PreviousYear AS FLOAT)),'N')  
    AS Percentage_Change_Jan
FROM cte
ORDER BY Year;

---- AVG home price by month and year
SELECT * FROM 
	(SELECT 
		latest_saledate_year AS Year,
		MONTH(latest_saledate) AS MonthSold,
		AVG(latestPrice) AS AvgHomePrice
	FROM
		austin_housing 
	WHERE
		latest_saledate_year IS NOT NULL 
		AND latest_saledate_year <> 2021
	GROUP BY 
		latest_saledate_year, MONTH(latest_saledate)
	) avg_price 
PIVOT(AVG(AvgHomePrice) FOR Year IN ([2018],[2019],[2020])) byyear;

-- total sold and avg cost of home in jan
SELECT 
	latest_saledate_year AS Year,
	DATENAME(month,latest_saledate) AS Month,
    AVG(latestPrice) AS AvgHomePrice,
    COUNT(*) AS Total_Sold
FROM
    austin_housing
WHERE
    latest_saledate_year IS NOT NULL 
    AND MONTH(latest_saledate) = 01
GROUP BY latest_saledate_year, DATENAME(month,latest_saledate);

-- number of houses sold year over year for jan
WITH cte AS (
    SELECT DISTINCT
	   latest_saledate_year AS Year,
       DATENAME(month,latest_saledate) AS Month,
       COUNT(*) AS Total_Sold,
       LAG(COUNT(*)) OVER (ORDER BY latest_saledate_year) AS PreviousYear,
       COUNT(*) - LAG(COUNT(*)) OVER (ORDER BY latest_saledate_year) AS YOY_Difference
	FROM austin_housing 
	WHERE 
		latest_saledate_year IS NOT NULL AND MONTH(latest_saledate) = 01
	GROUP BY 
		latest_saledate_year, DATENAME(month,latest_saledate))
SELECT Year, Month,  
    Total_Sold,
    YOY_Difference YOY_Difference,
	FORMAT(100*(CAST(YOY_Difference AS FLOAT)/CAST(PreviousYear AS FLOAT)),'N') 
		AS Percentage_Change
FROM cte;

