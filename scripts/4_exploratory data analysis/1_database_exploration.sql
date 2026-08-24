-- Explore all objects in the database
SELECT *
FROM INFORMATION_SCHEMA.TABLES
ORDER BY table_schema;


-- Explore all columns in the database
SELECT *
FROM INFORMATION_SCHEMA.COLUMNS
WHERE table_schema != 'pg_catalog' AND
table_schema != 'information_schema'
ORDER BY table_schema;