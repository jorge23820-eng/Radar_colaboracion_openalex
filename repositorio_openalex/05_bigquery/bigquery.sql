-- BigQuery: tabla externa sobre el Parquet del bucket + 5 vistas analiticas.
-- Correr en el editor de consultas de BigQuery (conjunto de datos en la ubicacion US).
CREATE SCHEMA IF NOT EXISTS `project-0c406915-8785-4e51-bd1.openalex` OPTIONS (location = 'US');

-- enable_list_inference hace que las listas de Spark (paises, financiadores) se lean como ARRAY normales
CREATE OR REPLACE EXTERNAL TABLE `project-0c406915-8785-4e51-bd1.openalex.works`
WITH PARTITION COLUMNS
OPTIONS (
  format = 'PARQUET',
  uris = ['gs://big_data_bucket_de_jlgm/openalex/parquet/works/anio=*'],
  hive_partition_uri_prefix = 'gs://big_data_bucket_de_jlgm/openalex/parquet/works',
  require_hive_partition_filter = false,
  enable_list_inference = TRUE
);

-- Verificacion: filas, ids unicos y rango de anios
SELECT COUNT(*) AS filas, COUNT(DISTINCT id) AS ids_unicos, MIN(anio) AS anio_min, MAX(anio) AS anio_max
FROM `project-0c406915-8785-4e51-bd1.openalex.works`;

-- Pregunta 1: crecimiento de campos por anio
CREATE OR REPLACE VIEW `project-0c406915-8785-4e51-bd1.openalex.q1_crecimiento_campos` AS
SELECT anio, campo, COUNT(*) AS articulos
FROM `project-0c406915-8785-4e51-bd1.openalex.works`
WHERE campo IS NOT NULL AND anio BETWEEN 2010 AND 2025
GROUP BY anio, campo;

-- Pregunta 2: colaboracion internacional e impacto
CREATE OR REPLACE VIEW `project-0c406915-8785-4e51-bd1.openalex.q2_colaboracion_impacto` AS
SELECT
  CASE WHEN countries_distinct_count <= 1 THEN '1 país'
       WHEN countries_distinct_count = 2 THEN '2 países'
       WHEN countries_distinct_count <= 4 THEN '3-4 países'
       ELSE '5+ países' END AS colaboracion,
  MIN(countries_distinct_count) AS orden,
  COUNT(*) AS articulos,
  ROUND(AVG(fwci), 2) AS fwci_promedio,
  ROUND(100 * COUNTIF(top10) / COUNT(top10), 1) AS pct_top10
FROM `project-0c406915-8785-4e51-bd1.openalex.works`
WHERE fwci IS NOT NULL AND countries_distinct_count >= 1
GROUP BY colaboracion;

-- Pregunta 3: impacto por pais
CREATE OR REPLACE VIEW `project-0c406915-8785-4e51-bd1.openalex.q3_paises_impacto` AS
SELECT pais, COUNT(*) AS articulos, ROUND(AVG(fwci), 2) AS fwci_promedio,
       ROUND(100 * COUNTIF(top10) / COUNT(top10), 1) AS pct_top10
FROM `project-0c406915-8785-4e51-bd1.openalex.works`, UNNEST(paises) AS pais
WHERE fwci IS NOT NULL
GROUP BY pais HAVING COUNT(*) >= 500;

-- Pregunta 4: acceso abierto
CREATE OR REPLACE VIEW `project-0c406915-8785-4e51-bd1.openalex.q4_acceso_abierto` AS
SELECT oa_status, COUNT(*) AS articulos, ROUND(AVG(fwci), 2) AS fwci_promedio,
       ROUND(100 * COUNTIF(top10) / COUNT(top10), 1) AS pct_top10
FROM `project-0c406915-8785-4e51-bd1.openalex.works`
WHERE fwci IS NOT NULL AND oa_status IS NOT NULL
GROUP BY oa_status;

-- Pregunta 5: financiadores
CREATE OR REPLACE VIEW `project-0c406915-8785-4e51-bd1.openalex.q5_financiadores` AS
SELECT financiador, COUNT(*) AS articulos, ROUND(AVG(fwci), 2) AS fwci_promedio,
       ROUND(100 * COUNTIF(top10) / COUNT(top10), 1) AS pct_top10
FROM `project-0c406915-8785-4e51-bd1.openalex.works`, UNNEST(financiadores) AS financiador
WHERE fwci IS NOT NULL
GROUP BY financiador HAVING COUNT(*) >= 20;
