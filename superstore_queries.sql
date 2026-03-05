-- ============================================================
--  Superstore Sales Analysis — SQL Business Queries
--  Author  : Arvind Shyama Muskan Babu
--  Database: MySQL / SQLite compatible
--  Dataset : Sample Superstore (Kaggle)
-- ============================================================
-- HOW TO USE:
--   1. Import superstore_clean.csv into MySQL (table: superstore)
--   2. Run queries one by one and study the output
--   3. Each query answers a real business question
-- ============================================================


-- ── TABLE SETUP (run once) ───────────────────────────────
CREATE TABLE IF NOT EXISTS superstore (
    row_id         INT,
    order_id       VARCHAR(20),
    order_date     DATE,
    ship_date      DATE,
    ship_mode      VARCHAR(30),
    customer_id    VARCHAR(15),
    customer_name  VARCHAR(50),
    segment        VARCHAR(20),
    city           VARCHAR(50),
    state          VARCHAR(30),
    region         VARCHAR(15),
    product_id     VARCHAR(20),
    category       VARCHAR(25),
    sub_category   VARCHAR(25),
    product_name   VARCHAR(200),
    sales          DECIMAL(10,4),
    quantity       INT,
    discount       DECIMAL(5,4),
    profit         DECIMAL(10,4)
);


-- ============================================================
-- QUERY 1: Overall Business KPIs
-- Business Q: How is our business performing overall?
-- ============================================================
SELECT
    ROUND(SUM(sales), 2)                          AS total_revenue,
    ROUND(SUM(profit), 2)                         AS total_profit,
    ROUND(SUM(profit) / SUM(sales) * 100, 2)      AS profit_margin_pct,
    COUNT(DISTINCT order_id)                       AS total_orders,
    COUNT(DISTINCT customer_id)                    AS unique_customers,
    ROUND(SUM(sales) / COUNT(DISTINCT order_id),2) AS avg_order_value
FROM superstore;


-- ============================================================
-- QUERY 2: Year-over-Year Revenue Growth
-- Business Q: Is our revenue growing year on year?
-- ============================================================
SELECT
    YEAR(order_date)        AS year,
    ROUND(SUM(sales), 2)    AS total_sales,
    ROUND(SUM(profit), 2)   AS total_profit,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(
        (SUM(sales) - LAG(SUM(sales)) OVER (ORDER BY YEAR(order_date)))
        / LAG(SUM(sales)) OVER (ORDER BY YEAR(order_date)) * 100, 1
    )                        AS yoy_growth_pct
FROM superstore
GROUP BY YEAR(order_date)
ORDER BY year;


-- ============================================================
-- QUERY 3: Sales & Profit by Category and Sub-Category
-- Business Q: Which product lines make us the most money?
-- ============================================================
SELECT
    category,
    sub_category,
    ROUND(SUM(sales), 2)                     AS total_sales,
    ROUND(SUM(profit), 2)                    AS total_profit,
    ROUND(SUM(profit)/SUM(sales)*100, 2)     AS margin_pct,
    SUM(quantity)                             AS units_sold,
    RANK() OVER (PARTITION BY category ORDER BY SUM(profit) DESC) AS profit_rank_in_category
FROM superstore
GROUP BY category, sub_category
ORDER BY category, total_profit DESC;


-- ============================================================
-- QUERY 4: Loss-Making Products — Immediate Action Required
-- Business Q: Which products are hurting our profit?
-- ============================================================
SELECT
    sub_category,
    product_name,
    ROUND(SUM(sales), 2)   AS total_sales,
    ROUND(SUM(profit), 2)  AS total_profit,
    ROUND(AVG(discount)*100,1) AS avg_discount_pct,
    COUNT(order_id)         AS times_ordered
FROM superstore
GROUP BY sub_category, product_name
HAVING SUM(profit) < 0
ORDER BY total_profit ASC
LIMIT 20;


-- ============================================================
-- QUERY 5: Regional Sales Performance
-- Business Q: Which region should we invest in more?
-- ============================================================
SELECT
    region,
    ROUND(SUM(sales), 2)                  AS total_sales,
    ROUND(SUM(profit), 2)                 AS total_profit,
    ROUND(SUM(profit)/SUM(sales)*100, 2)  AS margin_pct,
    COUNT(DISTINCT customer_id)            AS customers,
    COUNT(DISTINCT order_id)               AS orders,
    ROUND(SUM(sales)/COUNT(DISTINCT order_id),2) AS avg_order_value
FROM superstore
GROUP BY region
ORDER BY total_profit DESC;


-- ============================================================
-- QUERY 6: Top 10 Customers by Revenue (VIP Customers)
-- Business Q: Who are our most valuable customers?
-- ============================================================
SELECT
    customer_id,
    customer_name,
    segment,
    region,
    ROUND(SUM(sales), 2)    AS lifetime_value,
    ROUND(SUM(profit), 2)   AS profit_contributed,
    COUNT(DISTINCT order_id) AS total_orders,
    MIN(order_date)          AS first_purchase,
    MAX(order_date)          AS last_purchase,
    DATEDIFF(MAX(order_date), MIN(order_date)) AS customer_lifetime_days
FROM superstore
GROUP BY customer_id, customer_name, segment, region
ORDER BY lifetime_value DESC
LIMIT 10;


-- ============================================================
-- QUERY 7: Discount Impact on Profit Margins
-- Business Q: Are we over-discounting and hurting profitability?
-- ============================================================
SELECT
    CASE
        WHEN discount = 0            THEN '0% - No discount'
        WHEN discount <= 0.10        THEN '1-10%'
        WHEN discount <= 0.20        THEN '11-20%'
        WHEN discount <= 0.30        THEN '21-30%'
        WHEN discount <= 0.50        THEN '31-50%'
        ELSE 'Over 50%'
    END                              AS discount_band,
    COUNT(order_id)                   AS num_orders,
    ROUND(SUM(sales), 2)              AS total_sales,
    ROUND(SUM(profit), 2)             AS total_profit,
    ROUND(SUM(profit)/SUM(sales)*100, 2) AS avg_margin_pct
FROM superstore
GROUP BY discount_band
ORDER BY MIN(discount);


-- ============================================================
-- QUERY 8: Monthly Sales Seasonality (Latest Year)
-- Business Q: When is our peak season? Should we stock up earlier?
-- ============================================================
SELECT
    YEAR(order_date)                   AS year,
    MONTH(order_date)                  AS month_num,
    DATE_FORMAT(order_date, '%b')      AS month_name,
    ROUND(SUM(sales), 2)               AS monthly_sales,
    ROUND(SUM(profit), 2)              AS monthly_profit,
    COUNT(DISTINCT order_id)           AS orders,
    ROUND(
        SUM(sales) / SUM(SUM(sales)) OVER (PARTITION BY YEAR(order_date)) * 100, 1
    )                                   AS pct_of_year_revenue
FROM superstore
WHERE YEAR(order_date) = (SELECT MAX(YEAR(order_date)) FROM superstore)
GROUP BY YEAR(order_date), MONTH(order_date), DATE_FORMAT(order_date,'%b')
ORDER BY month_num;


-- ============================================================
-- QUERY 9: Customer Segmentation – RFM Snapshot
-- Business Q: Which customers are most engaged and valuable?
-- (R = Recency, F = Frequency, M = Monetary Value)
-- ============================================================
WITH rfm_base AS (
    SELECT
        customer_id,
        customer_name,
        DATEDIFF((SELECT MAX(order_date) FROM superstore), MAX(order_date)) AS recency_days,
        COUNT(DISTINCT order_id)   AS frequency,
        ROUND(SUM(sales), 2)       AS monetary
    FROM superstore
    GROUP BY customer_id, customer_name
),
rfm_scores AS (
    SELECT *,
        NTILE(4) OVER (ORDER BY recency_days DESC)  AS r_score,  -- lower recency = better
        NTILE(4) OVER (ORDER BY frequency ASC)       AS f_score,
        NTILE(4) OVER (ORDER BY monetary ASC)        AS m_score
    FROM rfm_base
)
SELECT
    customer_id,
    customer_name,
    recency_days,
    frequency,
    monetary,
    r_score, f_score, m_score,
    (r_score + f_score + m_score)   AS total_rfm_score,
    CASE
        WHEN (r_score + f_score + m_score) >= 10 THEN '🏆 Champion'
        WHEN (r_score + f_score + m_score) >= 8  THEN '⭐ Loyal'
        WHEN (r_score + f_score + m_score) >= 6  THEN '🔄 Potential Loyal'
        WHEN r_score <= 1                         THEN '💤 At Risk / Lost'
        ELSE '🆕 Needs Attention'
    END                             AS customer_segment
FROM rfm_scores
ORDER BY total_rfm_score DESC;


-- ============================================================
-- QUERY 10: Shipping Mode Efficiency Analysis
-- Business Q: Which shipping mode balances cost and customer satisfaction?
-- ============================================================
SELECT
    ship_mode,
    COUNT(order_id)                      AS total_orders,
    ROUND(AVG(DATEDIFF(ship_date, order_date)), 1) AS avg_ship_days,
    ROUND(SUM(sales), 2)                  AS total_sales,
    ROUND(SUM(profit), 2)                 AS total_profit,
    ROUND(SUM(profit)/SUM(sales)*100, 2)  AS margin_pct
FROM superstore
GROUP BY ship_mode
ORDER BY avg_ship_days;


-- ============================================================
-- BONUS QUERY: State-Level Heatmap Data
-- Business Q: Which states are most and least profitable?
-- ============================================================
SELECT
    state,
    region,
    ROUND(SUM(sales), 2)                  AS total_sales,
    ROUND(SUM(profit), 2)                 AS total_profit,
    ROUND(SUM(profit)/SUM(sales)*100, 2)  AS margin_pct,
    COUNT(DISTINCT customer_id)            AS customers
FROM superstore
GROUP BY state, region
ORDER BY total_profit DESC;
