-- Crea la base y 3 tablas con los mismos datos para comparar formatos.
-- Correr: gcloud dataproc jobs submit hive --cluster=hive-learning-cluster --region=us-central1 --file=01_tablas.hql
CREATE DATABASE IF NOT EXISTS openalex_hive;
USE openalex_hive;

-- 1) Tabla EXTERNA sobre el Parquet particionado del bucket (Data Lake)
DROP TABLE IF EXISTS works_ext;
CREATE EXTERNAL TABLE works_ext (
  id STRING, fecha DATE, language STRING, cited_by_count BIGINT, fwci DOUBLE,
  top10 BOOLEAN, oa_status STRING, campo STRING, dominio STRING,
  authors_count BIGINT, countries_distinct_count BIGINT,
  institutions_distinct_count BIGINT,
  financiadores ARRAY<STRING>, paises ARRAY<STRING>)
PARTITIONED BY (anio INT)
STORED AS PARQUET
LOCATION 'gs://big_data_bucket_de_jlgm/openalex/parquet/works';
MSCK REPAIR TABLE works_ext;

-- 2) Copia Parquet SIN particionar
DROP TABLE IF EXISTS works_plano;
CREATE TABLE works_plano STORED AS PARQUET AS
SELECT id, fecha, language, cited_by_count, fwci, top10, oa_status, campo, dominio,
       authors_count, countries_distinct_count, institutions_distinct_count,
       financiadores, paises, anio
FROM works_ext;

-- 3) Copia en TEXTO (TEXTFILE), el formato "malo" para comparar
DROP TABLE IF EXISTS works_csv;
CREATE TABLE works_csv
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t' COLLECTION ITEMS TERMINATED BY ','
STORED AS TEXTFILE AS
SELECT id, fecha, language, cited_by_count, fwci, top10, oa_status, campo, dominio,
       authors_count, countries_distinct_count, institutions_distinct_count,
       financiadores, paises, anio
FROM works_ext;

SELECT 'filas_ext' AS tabla, COUNT(*) AS n FROM works_ext;
SELECT 'filas_plano' AS tabla, COUNT(*) AS n FROM works_plano;
SELECT 'filas_csv' AS tabla, COUNT(*) AS n FROM works_csv;
