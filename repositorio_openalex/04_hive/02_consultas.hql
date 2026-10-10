-- Mide la misma consulta sobre texto, Parquet plano y Parquet particionado.
USE openalex_hive;
SELECT MAX(fwci) FROM works_plano;
SELECT 'A_csv' AS prueba, anio, COUNT(*) AS n, ROUND(AVG(fwci),2) AS fwci FROM works_csv WHERE anio BETWEEN 2020 AND 2024 GROUP BY anio;
SELECT 'A_parquet_plano' AS prueba, anio, COUNT(*) AS n, ROUND(AVG(fwci),2) AS fwci FROM works_plano WHERE anio BETWEEN 2020 AND 2024 GROUP BY anio;
SELECT 'A_parquet_particionado' AS prueba, anio, COUNT(*) AS n, ROUND(AVG(fwci),2) AS fwci FROM works_ext WHERE anio BETWEEN 2020 AND 2024 GROUP BY anio;
SELECT 'B_csv' AS prueba, oa_status, COUNT(*) AS n, ROUND(AVG(fwci),2) AS fwci FROM works_csv WHERE fwci IS NOT NULL GROUP BY oa_status;
SELECT 'B_parquet_plano' AS prueba, oa_status, COUNT(*) AS n, ROUND(AVG(fwci),2) AS fwci FROM works_plano WHERE fwci IS NOT NULL GROUP BY oa_status;
SELECT 'B_parquet_particionado' AS prueba, oa_status, COUNT(*) AS n, ROUND(AVG(fwci),2) AS fwci FROM works_ext WHERE fwci IS NOT NULL GROUP BY oa_status;
