CREATE DATABASE cafesalesanalysis_db;

CREATE TABLE cafesales (
    transaction_id TEXT,
    item TEXT,
    quantity FLOAT,
    price_per_unit DECIMAL (10,2),
    total_spent DECIMAL (10,2),
    payment_method TEXT,
    location_type TEXT,
    transaction_date DATE
);

SELECT * 
FROM cafesales
LIMIT 10;

ALTER TABLE cafesales
RENAME COLUMN location TO order_channel

ALTER TABLE cafesales
RENAME COLUMN total_spent TO revenue

--Total revenue earned--
SELECT 
    SUM(revenue) AS total_revenue
FROM cafesales;

--Total orders--
SELECT 
    COUNT(transaction_id) AS total_orders
FROM cafesales;

--AOV calculation--
SELECT
    ROUND((SUM(revenue)::numeric/COUNT(transaction_id)),2) AS avg_order_value 
FROM cafesales;

--Total quantity sold--
SELECT
    item,
    SUM(quantity) AS total_quantity_sold
FROM cafesales;


--Total quantity sold by item--
SELECT
    item,
    SUM(quantity) AS total_quantity_sold
FROM cafesales
GROUP BY item
ORDER BY total_quantity_sold DESC;

--Revenue by order_channel--
SELECT 
    order_channel,
    SUM(revenue) AS total_revenue
FROM cafesales
GROUP BY order_channel
ORDER BY total_revenue;

--Top-selling iteam by quantity--
WITH rev_info AS(
    SELECT 
        item,
        SUM(revenue) AS total_revenue
    FROM cafesales
    GROUP BY item
)
SELECT 
    *,
    RANK () OVER(ORDER BY total_revenue DESC)
FROM rev_info

--Monthly revenue trends--
SELECT 
    DATE_TRUNC('month',transaction_date::date) AS Month,
    SUM(revenue) as total_revenue 
FROM cafesales
GROUP BY date_trunc('month',transaction_date::date)
ORDER BY Month;

--Revenue per item--
WITH rev_by_item AS(
    SELECT 
        item,
        SUM(revenue) AS total_revenue
    FROM cafesales
    GROUP BY item
)
SELECT 
    item,
    total_revenue,
    RANK() OVER (ORDER BY total_revenue DESC) AS rev_rank
FROM rev_by_item;


--Revenue by payment method--
SELECT 
    payment_method,
    SUM(revenue) AS revenue_generated
FROM cafesales
GROUP BY payment_method
ORDER BY revenue_generated DESC;

--Top items per order channel--
WITH rev_by_item AS(
    SELECT
        item, 
        order_channel,
        COUNT(transaction_id) AS quantity_sold
    FROM cafesales
    GROUP BY item,order_channel
    ORDER BY quantity_sold DESC
)
SELECT 
    item,
    order_channel,
    quantity_sold,
    DENSE_RANK() OVER(PARTITION BY order_channel ORDER BY quantity_sold DESC) AS item_rank_orderchannel
FROM rev_by_item

--AOV monthly trends--
SELECT 
    DATE_TRUNC('Month',transaction_date::date) AS Month,
    (SUM(revenue)::numeric/COUNT(transaction_id)) AS aov
FROM cafesales

--table vibe check--
SELECT column_name, data_type 
FROM information_schema.columns
WHERE table_name = 'cafesales';

--Daily revenue trend (last 60 days of dataset)--


WITH sixty_day_info AS(
    SELECT 
        transaction_date::date AS date_,
        SUM(revenue) AS day_rev
    FROM cafesales
    GROUP BY transaction_date
),

last_day AS(
    SELECT
        MAX(transaction_date)::date AS last_working_day
    FROM cafesales
)
SELECT 
    date_,
    day_rev
FROM sixty_day_info,last_day
WHERE date_ >= last_working_day - INTERVAL '60 days'
ORDER BY date_ DESC


--rolling 30 day average calculation--
WITH sixty_day_info AS(
    SELECT 
        transaction_date::date AS date_,
        SUM(revenue) AS rev_of_day
    FROM cafesales
    GROUP BY date_
)
SELECT 
    date_,
    rev_of_day,
    ROUND(AVG(rev_of_day::numeric) OVER (ORDER BY date_ ROWS BETWEEN 29 PRECEDING AND CURRENT ROW),2) AS rolling_avg_30day
FROM sixty_day_info
ORDER BY date_ DESC;


--Revenue by weekday--
SELECT 
    SUM(revenue) AS total_revenue,
    --EXTRACT(DOW FROM transaction_date::date)
    TRIM(TO_CHAR(transaction_date::date,'Day')) AS day_of_week
FROM cafesales
GROUP BY TRIM(TO_CHAR(transaction_date::date,'Day'))
--GROUP BY EXTRACT(DOW FROM transaction_date::date)
ORDER BY total_revenue DESC;

--Average revenue per item--
SELECT 
    item,
    ROUND(SUM(revenue)::numeric/SUM(quantity)::numeric,2) AS avg_rev
FROM cafesales
GROUP BY item
ORDER BY avg_rev



--Weekday vs Weekend Revenue split--
SELECT 
    CASE 
        WHEN EXTRACT(DOW FROM transaction_date::date) IN(0,6) THEN 'weekend'
        ELSE 'weekday'
    END AS day_type,
    SUM(revenue) AS total_revenue
FROM cafesales
GROUP BY day_type;