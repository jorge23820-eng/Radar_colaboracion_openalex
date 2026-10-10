-- Misma consulta sobre la misma tabla, con y sin poda de particiones.
USE openalex_hive;
SELECT MAX(fwci) FROM works_plano;
SELECT 'A_sin_poda' AS prueba, YEAR(fecha) AS anio, COUNT(*) AS n, ROUND(AVG(fwci),2) AS fwci FROM works_ext WHERE YEAR(fecha) BETWEEN 2020 AND 2024 GROUP BY YEAR(fecha);
SELECT 'A_con_poda' AS prueba, anio, COUNT(*) AS n, ROUND(AVG(fwci),2) AS fwci FROM works_ext WHERE anio BETWEEN 2020 AND 2024 GROUP BY anio;
