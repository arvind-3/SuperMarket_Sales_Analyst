#Superstore Sales Analytics — End-to-End Business Intelligence Project
In today's data-driven world, businesses generate enormous amounts of transactional data every single day — but raw data alone means nothing. The real value lies in what you do with it. This project is my attempt to demonstrate exactly that: taking a messy, real-world retail dataset and turning it into clear, actionable business insights that a manager or CEO could actually use to make decisions.

What I Built


I worked with the Sample Superstore dataset from Kaggle — over 10,000 sales transactions spanning 4 years, covering customers across all regions of the United States. My goal was simple: find where the business is making money, where it is losing money, and what should be done about it.
The project covers the full data analyst workflow. I started with data cleaning in Python using Pandas — handling date formats, removing duplicates, engineering new columns like profit margin percentage and shipping delay days. This is the unglamorous part of analytics that most beginners skip, but it is the foundation of every trustworthy analysis.

SQL Analysis


Next, I wrote 10 business-framed SQL queries in MySQL covering topics like year-over-year revenue growth using LAG window functions, regional performance comparisons, discount impact analysis, and monthly seasonality trends. The most advanced query builds an RFM customer segmentation model — scoring every customer on Recency, Frequency, and Monetary value using NTILE — to classify them as Champions, Loyal, Potential, or At-Risk customers. This is a technique used by real e-commerce companies to drive retention strategy.

Key Findings



The analysis uncovered some genuinely surprising results. Three sub-categories — Tables, Bookcases, and Supplies — are actively losing money despite decent sales volumes. The culprit is heavy discounting: orders with more than 30% discount have a negative average profit margin. This means the business is essentially paying customers to buy certain products. Capping discounts at 20% could recover significant margin.
