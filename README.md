# Olist E-Commerce Data Warehouse & BI Pipeline

This repository contains an end-to-end data engineering and analytics pipeline built for the Olist E-Commerce dataset. The project implements a scalable Medallion Data Architecture (Bronze, Silver, Gold, Reporting) in PostgreSQL, culminating in a production-ready Power BI semantic model for executive reporting.

## 🏗️ Data Architecture (Medallion Approach)

The PostgreSQL data warehouse is structured into four distinct logical schemas to separate raw ingestion, transformation, dimensional modeling, and BI presentation.

| Layer | Schema | Purpose | Key Operations |
| --- | --- | --- | --- |
| **Raw** | `bronze` | Ingestion & Staging | Stores raw, untransformed source data directly from CSV/API sources. |
| **Cleansed** | `silver` | Conformed & Validated | Unaccent extensions, null handling, deduplication (geo), chronological integrity checks, and zero-value anomaly handling. |
| **Curated** | `gold` | Dimensional Modeling | Business-ready Star Schema. Resolves multi-account transient IDs to unified master records and calculates base metrics. |
| **Presentation** | `reporting` | BI Abstraction | Denormalized, pre-aggregated analytical views designed specifically for Power BI ingestion to minimize DAX overhead. |

## 🗄️ Database Schema (Gold Layer)

The curated layer implements a Star Schema optimized for high-performance analytical querying:

* **Dimension Tables:**
* `dim_customers`: Unified customer grains with most recent spatial/address coordinates.
* `dim_sellers`: Standardized seller profiles with enriched geographic data.
* `dim_products`: Catalog metrics including volumetric calculations and English-translated categories.


* **Fact Tables:**
* `fact_sales`: Line-item transactional grain tracking price, freight, and chronological delivery milestones.
* `fact_payments`: Financial settlement splits and installment metrics.
* `fact_feedback`: Customer satisfaction scores and qualitative reviews filtered by chronological validity.



## 📈 Advanced Analytics (Reporting Layer)

A dedicated `reporting` schema houses complex business logic and time-series aggregations:

* **Customer 360 & RFM (`customer_360`):** A custom Recency, Frequency, Monetary cohort segmentation model (Champions, Loyal, At Risk, Hibernating) tracking Lifetime Value (LTV), logistics friction, and installment dependency.
* **Seller Performance Matrix (`seller_performance`):** Benchmarks MoM revenue momentum against lifetime averages, sorting sellers into operational health tiers (Growth Leader, Cooling Off, Recovering, Underperforming).
* **Seller Volume vs. Rating (`seller_volume_feedback_segmentation`):** A 2-axis quadrant matrix crossing fulfillment capacity with customer satisfaction metrics.
* **Logistics Tracking (`freight_to_price_30d_rolling_avg`):** Tracks the daily ratio of shipping costs to product prices, smoothed via a 30-day rolling average window.
* **Category Momentum (`top_categories_performance`):** Month-over-month (MoM) revenue growth trajectories for the top 5 historical product categories using a dense calendar spine.
* **Acquisition Velocity (`customer_acquisition_rate`):** Daily new customer counts and cumulative marketplace growth tracking.

## 📊 Power BI Implementation

The visualization layer integrates the `reporting` views to deliver actionable insights while maintaining strict data governance.

* **Data Modeling:** Direct 1-to-Many ($1 \rightarrow *$) relationships between standalone dimension tables and fact/reporting views.
* **Resolving Circular Dependencies:** Avoided DAX VertiPaq loop errors by migrating structural sorting logic upstream. Sort indexes (e.g., `Growth Leader` = 1, `Cooling Off` = 2) are materialized natively in SQL/Power Query before reaching the semantic model.
* **Visual Engineering:** Implementation of dual-axis charts (e.g., contrasting raw seller headcount via columns against average revenue per seller via line graphs) to expose high-value "whale" segments at risk of churn.