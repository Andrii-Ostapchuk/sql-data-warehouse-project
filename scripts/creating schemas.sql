/*
===============================================================================
DDL Script: Data Warehouse Schema Initialization
===============================================================================
Script Purpose:
    - Establishes the core logical schemas for the Medallion Architecture.
    - Provides structural separation between raw ingestion, transformed staging, 
      and business-ready data presentation layers.
===============================================================================
*/

-- ============================================================================
-- 1. Bronze Schema (Raw / Ingestion Layer)
-- Landing zone for raw, unrefined data directly imported from source systems.
-- Stores source datasets in their original structure without transformations.
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS bronze;

-- ============================================================================
-- 2. Silver Schema (Cleaned / Conformed Layer)
-- Intermediate layer for cleansed, standardized, and validated data.
-- Business rules, data quality checks, data deduplication, and type casting 
-- are applied here.
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS silver;

-- ============================================================================
-- 3. Golden Schema (Curated / Business Presentation Layer)
-- Aggregated, production-ready data layer optimized for BI and reporting.
-- Contains dimensional models (star schemas), aggregated data marts, and 
-- analytical views.
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS golden;

-- ============================================================================
-- 4. Reporting Schema (BI Presentation Views Layer)
-- Specialized abstraction layer containing pre-aggregated views and custom data 
-- structures built specifically to feed Power BI dashboards and executive reports.
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS reporting;