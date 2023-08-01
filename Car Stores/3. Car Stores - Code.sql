-- Inspecting Data
SELECT * FROM [dbo].[sales_data_sample]

-- Checking Unique Values
SELECT DISTINCT status FROM [dbo].[sales_data_sample] -- Nice one to plot
SELECT DISTINCT year_id FROM [dbo].[sales_data_sample]
SELECT DISTINCT productline FROM [dbo].[sales_data_sample] -- Nice one to plot
SELECT DISTINCT country FROM [dbo].[sales_data_sample] -- Nice one to plot
SELECT DISTINCT dealsize FROM [dbo].[sales_data_sample] -- Nice one to plot
SELECT DISTINCT territory FROM [dbo].[sales_data_sample] -- Nice one to plot

SELECT COUNT(DISTINCT sales)
FROM [dbo].[sales_data_sample]

SELECT DISTINCT month_id 
FROM [dbo].[sales_data_sample]
WHERE year_id = 2005

-- ANALYSIS
--- Grouping sales by productline
SELECT productline, SUM(sales) AS Revenue
FROM [dbo].[sales_data_sample]
GROUP BY productline
ORDER BY 2 DESC

--- Grouping sales by year
SELECT year_id, SUM(sales) AS Revenue
FROM [dbo].[sales_data_sample]
GROUP BY year_id
ORDER BY 2 DESC

--- Grouping sales by dealsize
SELECT dealsize, SUM(sales) AS Revenue
FROM [dbo].[sales_data_sample]
GROUP BY dealsize
ORDER BY 2 DESC

--- Grouping sales by country
SELECT country, SUM(sales) AS Revenue
FROM [dbo].[sales_data_sample]
GROUP BY country
ORDER BY 2 DESC

--- What was the best month for sales in a spesific year? How much was earned that month?
SELECT month_id, SUM(sales) AS Revenue, COUNT(ordernumber) AS Frequency
FROM [dbo].[sales_data_sample]
WHERE year_id = 2003 -- change year to see the rest
GROUP BY month_id
ORDER BY 2 DESC

--- November seems to be the month, what product do they sell in November?
SELECT month_id, productline, SUM(sales) AS Revenue, COUNT(ordernumber) AS Frequency
FROM [dbo].[sales_data_sample]
WHERE year_id = 2004 AND month_id = 11 -- change year to see the rest
GROUP BY month_id, productline
ORDER BY 3 desc

--- Who is our best customer (this could be best answered with RFM)
DROP TABLE IF EXISTS #rfm
;WITH rfm AS
(
	SELECT
		customername,
		SUM(sales) AS MonetaryValue,
		AVG(sales) AS AvgMonetaryValue,
		COUNT(ordernumber) AS Frequency,
		MAX(orderdate) AS last_order_date,
		(SELECT MAX(orderdate) FROM [dbo].[sales_data_sample]) AS max_order_date,
		DATEDIFF(DD, MAX(orderdate), (SELECT MAX(orderdate) FROM [dbo].[sales_data_sample])) AS Recency
	FROM [dbo].[sales_data_sample]
	GROUP BY customername
),
rfm_calc AS
(
	SELECT r.*,
		NTILE(4) OVER (ORDER BY Recency DESC) AS rfm_recency,
		NTILE(4) OVER (ORDER BY Frequency) AS rfm_frequency,
		NTILE(4) OVER (ORDER BY MonetaryValue) AS rfm_monetary
	FROM rfm r
)
SELECT 
	c.*, rfm_recency + rfm_frequency + rfm_monetary AS rfm_cell, 
	CAST(rfm_recency AS VARCHAR) + CAST(rfm_frequency AS VARCHAR) + CAST(rfm_monetary AS VARCHAR) AS rfm_cell_string
into #rfm
FROM rfm_calc c

SELECT customername, rfm_recency, rfm_frequency, rfm_monetary,
	CASE
		WHEN rfm_cell_string IN (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) THEN 'lost_customers'  --lost customers
		WHEN rfm_cell_string IN (133, 134, 143, 244, 334, 343, 344, 144) THEN 'slipping away, cannot lose' -- (Big spenders who haven’t purchased lately) slipping away
		WHEN rfm_cell_string IN (311, 411, 331) THEN 'new customers'
		WHEN rfm_cell_string IN (222, 223, 233, 322) THEN 'potential churners'
		WHEN rfm_cell_string IN (323, 333,321, 422, 332, 432) THEN 'active' --(Customers who buy often & recently, but at low price points)
		WHEN rfm_cell_string IN (433, 434, 443, 444) THEN 'loyal'
	END rfm_segment
FROM #rfm

--- What products are most often sold together?
----SELECT * FROM [dbo].[sales_data_sample] WHERE ordernumber = 10411

SELECT DISTINCT ordernumber, STUFF(

	(SELECT ',' + productcode
	FROM [dbo].[sales_data_sample] p
	WHERE ordernumber IN
		(
			SELECT ordernumber
			FROM (
				SELECT ordernumber, COUNT(*) rn
				FROM [dbo].[sales_data_sample]
				WHERE status = 'Shipped'
				GROUP BY ordernumber
			)m
			WHERE rn = 3
		)
		AND p.ordernumber = s.ordernumber
		FOR XML PATH (''))

		, 1, 1, '') ProductCodes

FROM [dbo].[sales_data_sample] s
ORDER BY 2 DESC

--- What city has the highest number of sales in a spesific country?
SELECT city, SUM(sales) AS Revenue
FROM [dbo].[sales_data_sample]
WHERE country = 'UK'
GROUP BY city
ORDER BY 2 DESC

--- What is the best product in United States?
SELECT country, year_id, productline, SUM(sales) AS Revenue
FROM [dbo].[sales_data_sample]
WHERE country = 'USA'
GROUP BY country, year_id, productline
ORDER BY 4 DESC