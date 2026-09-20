\# \*\*Olist E-Commerce Sales \& Operations Analysis\*\*



\## \*\*Project Overview\*\*



This project analyzes the Brazilian E-Commerce Public Dataset by Olist to understand marketplace performance across sales, products, customers, payments, sellers, and delivery operations.

The analysis combines SQL-based business analysis with an interactive Power BI dashboard to identify trends, customer behavior patterns, product/category performance, and operational issues.

The project follows an end-to-end analytics workflow:

Data → PostgreSQL → SQL Analysis → Data Modeling → Power BI / DAX → Business Insights



\## \*\*Business Objective\*\*



The objective of this project was to analyze the marketplace from multiple business perspectives and answer questions such as:



\* How is marketplace cash collection changing over time?

\* Which product categories contribute the most merchandise value?

\* How do item volume and merchandise value differ across categories?

\* What proportion of customers are repeat customers?

\* How is cash collection distributed across payment methods?

\* How do delivery times and late delivery rates change over time?

\* How does delivery performance vary across customer states?

\* How do seller performance and customer reviews relate to operational performance?



\## \*\*Tools \& Technologies\*\*



\* PostgreSQL — data storage and SQL analysis

\* SQL — business analysis, aggregations, joins, CTEs, subqueries, window functions, rankings, and time-based analysis

\* Power BI — interactive dashboard and reporting

\* DAX — business measures and KPI calculations

\* Power Query — data preparation and transformation

\* Excel — supporting data analysis and validation



\## \*\*Dataset\*\*



The project uses the Brazilian E-Commerce Public Dataset by Olist, containing information about orders, customers, products, sellers, payments, and reviews.

The raw dataset is not included in this repository.

The analysis uses the corresponding data loaded into PostgreSQL and modeled for Power BI.



\### \*\*Main Data Entities\*\*



The analysis works across several related tables:



\* Customers

\* Orders

\* Order Items

\* Products

\* Sellers

\* Payments

\* Reviews

\* Date dimension



The model separates different business grains such as orders, order items, payments, reviews, customers, products, and sellers to support accurate analysis.



\## \*\*SQL Analysis\*\*



The SQL analysis consists of 18 business-focused queries organized into five areas.



\### \*\*1. Business \& Time-Series Analysis\*\*



Analysis of:



\* Cash collection over time

\* Order trends

\* Monthly performance

\* Growth patterns

\* Time-based business performance



\### \*\*2. Product \& Category Analysis\*\*



Analysis of:



\* Category merchandise value

\* Product/category performance

\* Item volumes

\* Category rankings

\* Value contribution



\### \*\*3. Customer Analysis\*\*



Analysis of:



\* Customer purchasing behavior

\* Customer-level spending

\* Repeat customers

\* Customer concentration



\### \*\*4. Seller Analysis\*\*



Analysis of:



\* Seller merchandise value

\* Seller performance

\* Seller rankings

\* Seller-level operational metrics



\### \*\*5. Operations \& Reviews\*\*



Analysis of:



\* Delivery performance

\* Late deliveries

\* Review scores

\* Operational trends

\* Relationships between operational and customer experience metrics



\## \*\*SQL Techniques Used\*\*



The project applies:



\* Multi-table JOIN

\* GROUP BY and aggregations

\* HAVING

\* CASE WHEN

\* Conditional aggregation

\* Common Table Expressions (CTE)

\* Subqueries

\* Window functions

\* Ranking functions

\* Date/time analysis

\* Business KPI calculations



The complete SQL analysis is available in the SQL directory.



\## \*\*Power BI Dashboard\*\*



The final Power BI report contains four analytical pages.



\### \*\*1. Executive Performance\*\*



Focuses on overall marketplace performance.



\*\*Key metrics\*\*



\* Total Cash Collected

\* Total Valid Orders

\* Average Order Value

\* Month-over-Month Cash Growth



\*\*Analysis\*\*



\* Cash collection trends over time

\* Order volume

\* Monthly growth

\* Payment method distribution



\### \*\*2. Product \& Category Analytics\*\*



Focuses on merchandise and category performance.



\*\*Key metrics\*\*



\* Total Merchandise Value

\* Items Sold

\* Active Sellers



\*\*Analysis\*\*



\* Merchandise value by category

\* Category rankings

\* Category contribution to total merchandise value

\* Items sold versus merchandise value

\* Freight burden



\### \*\*3. Customer Analytics\*\*



Focuses on customer behavior and geographic distribution.



\*\*Key metrics\*\*



\* Total Unique Customers

\* Cash per Customer

\* Repeat Customer Rate



\*\*Analysis\*\*



\* Customer cash collection by state

\* Top customers by cash collected

\* Customer order frequency

\* Repeat purchasing behavior



\### \*\*4. Operations \& Seller Experience\*\*



Focuses on delivery performance and seller-level operations.



\*\*Key metrics\*\*



\* Average Delivery Days

\* Late Delivery Rate

\* Average Review Score



\*\*Analysis\*\*



\* Delivery performance over time

\* Late delivery trends

\* Delivery time by customer state

\* Seller merchandise value

\* Seller late-delivery performance

\* Seller review scores



\## \*\*Key Business Findings\*\*



\### \*\*1. Low Repeat Purchasing\*\*



Only approximately 3% of unique customers placed more than one valid order during the analyzed period.

This indicates that the customer base was overwhelmingly composed of one-time purchasers. The finding highlights customer retention as an area that could be investigated further through cohort, category, geographic, and purchase-frequency analysis.



\### \*\*2. Strong Concentration in Two Payment Methods\*\*



Credit cards accounted for approximately 78% of total cash collected, while Boleto accounted for approximately 18%.

Together, these two payment methods represented more than 96% of recorded cash collection, showing a strong concentration of marketplace cash collection across these payment methods.



\### \*\*3. Merchandise Value Concentrated Among Top Categories\*\*



The top five product categories contributed approximately 40% of total merchandise value.

This indicates that a relatively small group of categories contributed a substantial portion of marketplace merchandise value and provides a useful starting point for deeper category-level analysis.



\### \*\*4. Category Volume and Value Tell Different Stories\*\*



The analysis showed substantial differences between items sold and merchandise value across categories.

For example, bed\_bath\_table generated high item volume, while watches\_gifts generated greater merchandise value with considerably fewer items.

This demonstrates why category performance should be evaluated using both volume and value, rather than item count alone.



\### \*\*5. Growth Slowed During 2018\*\*



Marketplace cash collection grew substantially throughout 2017, while monthly cash collection remained relatively stable around 1.0–1.1M during the first eight months of 2018.

This represents a significant slowdown compared with the earlier growth trajectory and provides a basis for further investigation into customer, category, geographic, and marketplace performance.



\### \*\*6. Significant Deterioration in Delivery Performance\*\*



Late delivery rates increased sharply during February–March 2018, exceeding 18% in March, while monthly order volumes remained relatively stable.

The pattern indicates a significant deterioration in delivery performance during this period and highlights an area where further investigation into fulfillment and logistics factors would be valuable.



\## \*\*Key DAX Measures\*\*



The Power BI model contains reusable measures for core business and operational KPIs, including:



\* Total Cash Collected

\* Total Merchandise Value

\* Total Valid Orders

\* Average Order Value

\* Total Unique Customers

\* Active Sellers

\* Average Review Score

\* Late Delivery Rate

\* Average Delivery Days

\* Freight Burden Ratio

\* Repeat Customer Rate

\* Cash per Customer

\* Month-over-Month Cash Growth

\* Year-over-Year Cash Growth

\* Cumulative Cash Collected

\* Category Ranking

\* Seller Ranking

\* Percentage of Total Merchandise Value



These measures were used throughout the four dashboard pages to provide consistent business definitions and interactive analysis.



\## \*\*Data Modeling\*\*



The Power BI semantic model separates major business entities and their respective grains.

Key entities include:



\* fact\_orders

\* fact\_order\_items

\* fact\_payments

\* fact\_reviews

\* dim\_customers

\* dim\_Products

\* dim\_sellers

\* Dim\_Date



This structure allows analysis across customers, orders, products, sellers, payments, reviews, and time while reducing the risk of incorrect aggregations caused by mixing different fact-table grains.



\## \*\*Project Structure\*\*



```text

olist-ecommerce-sales-analysis/

│

├── README.md

│

├── PowerBI/

│   ├── Olist\_Ecommerce\_Dashboard.pbip

│   ├── Olist\_Ecommerce\_Dashboard.Report/

│   └── Olist\_Ecommerce\_Dashboard.SemanticModel/

│

├── sql/

│   ├── 01\_schema.sql

│   ├── 02\_data\_validation.sql

│   └── 03\_business\_analysis.sql

│

└── Screenshots/

&#x20;   ├── 01\_Executive\_Performance.png

&#x20;   ├── 02\_Product\_Category.png

&#x20;   ├── 03\_Customer\_Analytics.png

&#x20;   └── 04\_Operations\_Seller.png



```



\## \*\*Dashboard Preview\*\*



Executive Performance



Product \& Category Analytics



Customer Analytics



Operations \& Seller Experience



\## \*\*Conclusion\*\*



This project demonstrates an end-to-end approach to business analytics by combining SQL, data modeling, Power BI, DAX, and business analysis.

The analysis moves beyond dashboard creation by using structured SQL queries and reusable analytical measures to investigate marketplace performance, customer behavior, category performance, and operational efficiency.

