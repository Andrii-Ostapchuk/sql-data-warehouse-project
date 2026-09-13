# 📦 Olist E-Commerce Data Warehouse & Power BI Pipeline

In this project I built an end-to-end Medallion pipeline transforming messy, multi-table e-commerce data into curated business objects and Power BI-ready reporting marts.

---

## 1. Background & Overview

**Dataset:** [Olist Brazilian E-Commerce public dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce).<br>
**Time period covered:** Sep 2016 – Sep 2018.<br>
**Tools used:** PostgreSQL (data warehouse), Power BI (dashboards), DbVisualizer / Draw.io (entity–relationship models).

**Business goals this project set out to answer:**
- How healthy is customer acquisition and retention?
- Which sellers are driving growth, and which need support?
- Which customer segments and revenue patterns matter most?

📄 *You can download the complete **Power BI dashboards** here: [Power BI reporting](https://github.com/Andrii-Ostapchuk/sql-data-warehouse-project/tree/main/documents/Power%20BI%20reporting)*

---

## 2. Data Structure Overview

The warehouse follows a **Medallion Architecture** - four schemas, each serving its purpose:

| Layer | Schema | Purpose |
|---|---|---|
| Raw | `bronze` | Ingests raw, untransformed source data (CSV). |
| Cleansed | `silver` | Data cleansing; preserving the original table relationships. |
| Curated | `gold` | **Star Schema** with dimension and fact tables, representing Business-Objects. |
| Presentation | `reporting` | Analytical views built specifically for Power BI. |

**Gold layer (Star Schema):**

| Type | Table | Grain / Contents |
|---|---|---|
| Dimension | `dim_customers` | Unified customer records with latest known location. |
| Dimension | `dim_sellers` | Seller profiles with higher location precision. |
| Dimension | `dim_products` | Product catalog, volume data, English category names. |
| Fact | `fact_sales` | **Order ID + item** granularity. Price, freight, delivery milestones. |
| Fact | `fact_payments` | **Order ID + payment sequential** granularity. Payment splits and installment metrics. |
| Fact | `fact_feedback` | Review scores and comments (chronologically validated). |

**Reporting layer (used directly by Power BI):**

| View | What it answers |
|---|---|
| `customer_360` | RFM segmentation - Champions, Loyal, At Risk, Hibernating, etc. |
| `seller_performance` | MoM revenue momentum vs. lifetime average, by seller health tier |
| `seller_volume_feedback_segmentation` | Order volume × review score quadrant matrix |
| `payment_type_per_state_performance` | Payment method mix by customer state |
| `freight_to_price_30d_rolling_avg` | Daily shipping-cost-to-price ratio, smoothed over 30 days |
| `top_categories_performance` | MoM revenue growth for the top 5 product categories |
| `customer_acquisition_rate` | Daily new customers and cumulative growth |

📄 *Refer to [SQL scripts](https://github.com/Andrii-Ostapchuk/sql-data-warehouse-project/tree/main/scripts) to see the full defining scripts and to [ERD](https://github.com/Andrii-Ostapchuk/sql-data-warehouse-project/tree/main/documents/Table%20Relations) for relationship models.*

---

## 3. Executive Summary

> Olist's marketplace is growing steadily, but revenue is concentrated in a specific customer/logistics profile, and both the customer base and the seller base show a 'long tail' of accounts at risk of disengaging.

**Headline numbers:**

| Metric | Finding |
|---|---|
| Customer growth | Steady, organic - **94.74K** total customers acquired, averaging **9.87%** MoM growth |
| Seasonal peaks | Category revenue accelerates **May–Jul** and **Nov–Jan** |
| Logistics cost | Freight-to-price ratio rises every **summer**, driven by bulky categories |
| Satisfaction driver | Delivery delays hurt review scores **very strongly** - the #1 lever |
| Payment mix | **Credit card** dominates nationally; Boleto is runner-up |
| Seller health | Half of all seller-months sit in lower-performing tiers - the biggest growth lever |
| Customer health | New customers are the largest group, but **At Risk / Lost / Cannot-Lose-Them** together outnumber loyal repeat buyers |
| Revenue geography | **70%** of revenue comes from cross-state sales |
| Top revenue profile | Early-delivered, cross-state orders from **Cannot Lose Them** customers paying in 7+ installments |

---

## 4. Insights Deep Dive

### 📈 Growth & Seasonality

#### <a id="insight-1"></a>Insight 1: Steady, Organic Customer Growth
The business has a stable foundation to scale marketing and retention on - growth isn't a fluke or a one-off spike.
* **Quantified Value:** Total Customers: 94.74K, Average MoM Growth: 9.87%
* **Business Metric:** Customer Acquisition Rate (daily new customers + cumulative growth)

Across the full dataset period, new customer sign-ups climbed consistently without dramatic spikes or crashes which signifies sustainable growth rather than short-lived marketing bursts.

![Customer Acquisition Over Time](../../assets/photos/insight_1.png)
Graph 1: *Customer Acquisition Over Time*

<div style="margin-bottom: 50px;"></div>

#### <a id="insight-2"></a>Insight 2: Two Seasonal Growth Windows
These windows are the best times to plan inventory, seller capacity and marketing spend.
* **Quantified Value:** MoM growth ranges from 35% to 120% across the top 5 categories in each window
* **Business Metric:** Month-over-Month revenue growth, top 5 historical categories

Twice a year, revenue growth for the leading categories accelerates: once mid-year (**May–Jul**) and once around the holidays (**Nov–Jan**) - a repeatable seasonal pattern worth building the calendar around.

![Top Categories MoM Revenue Growth](../../assets/photos/insight_2.png)
Graph 2: *Top Categories MoM Revenue Growth*

<hr style="border: none; height: 2px; background-color: #d0d7de; margin: 70px 0;">

### 🚚 Logistics & Delivery

#### <a id="insight-3"></a>Insight 3: Summer Shipping Costs Spike, and It's Category-Driven
A handful of bulky/heavy categories are scoring higher freight-to-price ratios every summer.
* **Quantified Value:** Freight-to-price ratio **> 0.18** during summer months
* **Business Metric:** Freight-to-Price ratio, 30-day rolling average

Every summer, shipping costs climb relative to item price, and it's disproportionately driven by `bed_bath_table`, `health_beauty`, and `furniture_decor` - categories that are either heavy, bulky, or both.

![Freight to Price Ratio Trend](../../assets/photos/insight_3.png)
Graph 3: *Freight to Price Ratio Trend*

<div style="margin-bottom: 50px;"></div>

#### <a id="insight-4"></a>Insight 4: Delivery Delays Are the Biggest Threat to Satisfaction
On-time delivery is likely the single highest-leverage fix for review scores. Bigger than product or price.
* **Quantified Value:** Average review score, on-time: **4.0**; delayed: **2.5**
* **Business Metric:** Review score vs. delivery delay (actual vs. estimated delivery date)

When an order arrives later than promised, satisfaction doesn't just dip - it drops sharply. Delivery reliability outweighs almost every other factor tested against review scores.

![Review Score vs Delivery Delay](../../assets/photos/insight_4.png)
Graph 4: *Review Score vs Delivery Delay*

<hr style="border: none; height: 2px; background-color: #d0d7de; margin: 70px 0;">

### 💳 Payments

#### <a id="insight-5"></a>Insight 5: Credit Card Wins Nationally - With One Curious Regional Exception
The pattern in state RR (Roraima) is interesting but too small to act on - flagging it for visibility, not for a business decision. The most probable reason being the state is the least populous.
* **Quantified Value:** Credit card is by far the most popular payment method across all states (**> 65%**). Boleto is a solid runner-up (**> 13%**). RR has the highest boleto share (**32%**) but represents only **0.05%** of all orders
* **Business Metric:** Payment type share by customer state

Credit card is the dominant payment method across almost every state. RR stands out with the highest boleto and zero debit-card or voucher usage - but with so few orders, this is a curiosity, not a trend.

![Payment Type Distribution by State](../../assets/photos/insight_5.png)
Graph 5: *Payment Type Distribution by State*

<hr style="border: none; height: 2px; background-color: #d0d7de; margin: 70px 0;">

### 🏪 Sellers

#### <a id="insight-6"></a>Insight 6: More Volume, More "Needs Improvement" - But Fewer "Bad" Reviews
In simple words: the more orders a seller handles, the more "just okay" reviews they collect - but far fewer truly bad ones. More volume brings more average experiences, not more terrible ones, and that's worth understanding before deciding whether - or how - to fix it.
* **Quantified Value:** "Needs Improvement" share rises with volume (23% → 38%), while "Bad" share falls (13% → 1%)
* **Business Metric:** Seller Volume × Review Score quadrant (High/Medium/Low volume × Excellent/Needs Improvement/Bad)

See how Volume and Rating buckets were created:
<details><summary>Volume & Rating classification</summary>
Order Volume: High Volume (>200), Medium Volume (51-200), Low Volume (<=50).<br>
Satisfaction Rating: Excellent (>=4.0), Needs Improvement (3.0-3.99), Bad (<3.0).<br>
</details><br>

As sellers handle more orders, the share of merely "needs improvement" reviews rises - but, surprisingly, the share of outright "bad" reviews falls. **Open question: why?** (See [Caveats](#caveats).)

![Seller Volume vs Review Score Matrix](../../assets/photos/insight_6.png)
Graph 6: *Seller Volume vs Review Score Matrix*

<div style="margin-bottom: 50px;"></div>

#### <a id="insight-7"></a>Insight 7: Seller Performance Shifts Across Monthly Health Tiers
Seller performance varies meaningfully from month to month. Each **seller-month** is classified by comparing that month's sales with the seller's historical average monthly sales and with their previous recorded month's sales.
* **Quantified Value:** Cooling Off seller-months are **2x** less numerous than Growth Leaders seller-months (with slightly higher avg sales); Recovering + Underperforming make up **~50%** of seller-months with **60%+ lower** average sales
* **Business Metric:** Seller Monthly Performance tiers - Avg Sales by tier (Growth Leader, Cooling Off, Recovering, Underperforming)

See how Seller MoM Performance buckets were created:
<details><summary>Performance classification</summary>
Growth Leader: Monthly sales are above the seller's historical average and growing compared with the previous recorded month.<br><br>
Cooling Off: Monthly sales are above the seller's historical average but declining compared with the previous recorded month.<br><br>
Recovering: Monthly sales are below the seller's historical average but growing compared with the previous recorded month.<br><br>
Underperforming: Monthly sales are below the seller's historical average and declining compared with the previous recorded month.<br><br>
Insufficient Data: First recorded active month, where no previous-month comparison is available.<br>
</details><br>

Leader seller-months give the platform a solid revenue base. Cooling Off seller-months already perform nearly as well but are not such numerous - a natural pipeline into the Leader tier. Recovering and Underperforming sellers make up half the base by count but contribute far less revenue each - the single biggest opportunity to lift overall platform sales.

![Seller Performance Health Tiers](../../assets/photos/insight_7.png)
Graph 7: *Seller Performance Health Tiers*

<hr style="border: none; height: 2px; background-color: #d0d7de; margin: 70px 0;">

### 👥 Customers

#### <a id="insight-8"></a>Insight 8: The Customer Base Is Skewed Toward Risk
Retention - not just acquisition - needs to be the priority, because most of the customers are disengaged, not loyal.
* **Quantified Value:** New Customers: 31%, Cannot Lose Them: 18%, Lost: 16%, At Risk: 15%, Low Value/Promising: 8%, Champions: 1.9%, Loyal: 1.2% (rounded)
* **Business Metric:** RFM Segmentation (Recency, Frequency, Monetary)

See how Customer buckets were created:
<details><summary>Customer classification</summary>
Champion: f_score ≥ 3, r_score ≥ 3, m_score ≥ 3 - Recent, frequent buyers with high lifetime spend; the most valuable cohort.<br><br>
Loyal Customer: f_score ≥ 3 - Repeat buyers with 2+ orders who show strong purchasing engagement.<br><br>
Cannot Lose Them: m_score = 5 - Top 20% lifetime spenders who have become dormant.<br><br>
Recent / New Customer: r_score ≥ 4 - Recently active buyers who have not yet reached the top monetary tiers.<br><br>
Promising / Average: r_score = 3, m_score ≥ 3 - Moderately recent customers with above-average historical spend.<br><br>
Lost / Hibernating: r_score ≤ 2, m_score ≤ 2 - Inactive customers in the bottom 40% for both recency and spend.<br><br>
At Risk: r_score ≤ 2, m_score ≥ 3 - Previously higher-spending customers who have become inactive.<br><br>
General / Low Value: ELSE - Remaining customers with moderate/low recency and relatively low lifetime spend.<br>
</details><br>


New customers form the largest group - but the next three largest are **Cannot Lose Them**, **Lost**, and **At Risk**, not repeat loyal buyers. The base is fragile, and losing these segments would hurt more than the new-customer pipeline can offset.

![Customer RFM Cohort Segmentation](../../assets/photos/insight_8.png)
Graph 8: *Customer RFM Cohort Segmentation*

<hr style="border: none; height: 2px; background-color: #d0d7de; margin: 70px 0;">

### 🌎 Revenue & Geography

#### <a id="insight-9"></a>Insight 9: Cross-State Sales Are the Real Revenue Engine
Olist's core value proposition is connecting customers with sellers *outside* their home state - logistics for this needs to stay a strength, not a weakness.
* **Quantified Value:** **70%** of total revenue comes from cross-state orders
* **Business Metric:** Revenue split - cross-state vs. in-state (customer state vs. seller state)

Most purchases aren't local - customers are routinely buying from sellers in a different state, making cross-state logistics a core (not peripheral) part of the business model.

![Cross-State vs In-State Revenue Share](../../assets/photos/insight_9.png)
Graph 9: *Cross-State vs In-State Revenue Share*

<div style="margin-bottom: 50px;"></div>

#### <a id="insight-10"></a>Insight 10: The Highest-Value Order Profile Is Very Specific
This is a small but extremely valuable customer profile worth understanding and replicating - not a coincidence.
* **Quantified Value:** This profile represents **12%** of Total Net Revenue
* **Business Metric:** Total Net Revenue by delivery-speed × cross-state × customer segment × installment count

The single biggest source of net revenue is orders that arrive **6+ days early**, ship **cross-state**, are placed by **Cannot Lose Them** customers, and are paid in **7+ installments** - a specific, high-value combination worth targeting directly, additionally indicating at the importance of preserving **Cannot Lose Them** customers.

![High-Value Order Profile Analysis](../../assets/photos/insight_10.png)
Graph 10: *High-Value Order Profile Analysis*

<hr style="border: none; height: 2px; background-color: #d0d7de; margin: 70px 0;">

## 5. Recommendations

**Sellers**
- Build a "graduation" program to help sellers with a lot of **Cooling Off** months cross into the **Leader** tier - they're already close on average sales [*(→ Insight 7)*](#insight-7).
- Prioritize support (training, promotion tools, logistics help) for sellers with plentiful **Recovering** and **Underperforming** months, since they represent half the seller-month base but a fraction of the revenue [*(→ Insight 7)*](#insight-7).
- Investigate *why* high-volume sellers get more "needs improvement" but fewer "bad" reviews - e.g. via review-text analysis - before designing a fix [*(→ Insight 6)*](#insight-6).

**Customers**
- Launch reactivation campaigns targeted specifically at **Cannot Lose Them** and **At Risk** segments - they represent disproportionate historical value at real risk of full churn [*(→ Insight 8)*](#insight-8).
- Study and replicate the **Cannot Lose Them + cross-state + early delivery + 7+ installments** profile in marketing and offer design, since it's the single highest-revenue combination found [*(→ Insight 10)*](#insight-10).
- Keep new-customer onboarding strong, but treat it as only half the retention story [*(→ Insight 8)*](#insight-8).

**Logistics**
- Treat on-time delivery as the top lever for customer satisfaction - prioritize it above other satisfaction initiatives [*(→ Insight 4)*](#insight-4).
- Review packaging/shipping logistics specifically for `bed_bath_table`, `health_beauty`, and `furniture_decor` ahead of summer, when freight ratios spike [*(→ Insight 3)*](#insight-3).
- Protect and invest in cross-state fulfillment reliability, given it drives 70% of revenue [*(→ Insight 9)*](#insight-9).

**Planning & Operations**
- Align inventory and seller-capacity planning with the two known seasonal growth windows (**May–Jul**, **Nov–Jan**) [*(→ Insight 2)*](#insight-2).
- Treat the RR/boleto pattern as a monitoring note, not an action item, until order volume there grows [*(→ Insight 5)*](#insight-5).

---

## 6. <a id="caveats"></a>Caveats & Assumptions

- **Dataset scope:** Olist's data reflects the Brazilian marketplace only, over Sep 2016 – Sep 2018; findings may not generalize to other markets, countries, or time periods.
- **Currency:** All monetary figures are in Brazilian Real (BRL) unless stated otherwise.
- **Small-sample caveat:** The RR/boleto finding ([*Insight 5*](#insight-5)) is based on just **0.05% of all orders** - interesting, but not statistically robust enough to act on.
- **Freight-to-price threshold:** The `> 0.18` cutoff used to flag "high" freight ratio orders is a judgment call, not an industry standard.
- **RFM scoring:** Recency and Monetary scores are quintile-based (1–5), calculated **relative to this dataset's own population** - they are not universal benchmarks and would shift if applied to a different customer base or time window.
- **Open question:** Why high-volume sellers see more "needs improvement" but fewer "bad" reviews ([*Insight 6*](#insight-6)) is unresolved in this analysis - it would benefit from qualitative follow-up, e.g. review-text sentiment analysis.
- **Delivery delay definition:** "Delayed" is calculated as actual delivery date minus estimated delivery date.
