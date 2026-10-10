# Radar de colaboración científica con OpenAlex

Proyecto integrador capstone: *Big Data Architecture & Strategy* (Análisis de Grandes Volúmenes de Datos).

Pipeline en Google Cloud que convierte **25.51 GiB** de publicaciones de OpenAlex (snapshot de septiembre de 2026, licencia CC0)
en **10,467,306 artículos limpios** y un tablero para decidir con quién colaborar. Usa solo las herramientas del curso:
Cloud Storage, Dataproc (Spark y Hive), BigQuery y Looker Studio.

## Las 4 preguntas del CDO

| Pregunta | Respuesta |
|---|---|
| ¿Qué? | Plataforma de datos de publicaciones científicas (lago en Cloud Storage, ETL en Spark, tablas en Hive, consulta en BigQuery). |
| ¿Para qué? | Decidir alianzas y temas con evidencia de impacto. |
| ¿Cómo? | Pipeline distribuido en Dataproc, Parquet particionado por año, tablas externas en BigQuery. |
| ¿A quién beneficia? | A la oficina de investigación de una universidad. El retorno se mide en impacto (FWCI y % en el 10% más citado), no en dólares. |

## Arquitectura

```
OpenAlex (S3, JSON .gz)
   -> Cloud Storage: zona cruda (openalex/jsonl/)
   -> Dataproc + Spark: limpieza y ETL por lotes (openalex/parquet_lotes/)
   -> Cloud Storage: zona curada, Parquet particionado por año (openalex/parquet/works/)
        |-> Hive en Dataproc: tablas externas y pruebas de rendimiento
        |-> BigQuery: tabla externa + 5 vistas -> Looker Studio (tablero)
```

## Estructura del repositorio

| Carpeta | Contenido |
|---|---|
| `01_ingesta/` | Cuaderno que copia los archivos de S3 a Cloud Storage sin descargarlos. |
| `02_infraestructura/` | Script de creación del cluster Dataproc. |
| `03_etl_spark/` | ETL en PySpark por lotes (`etl_openalex.py`) y revisión del esquema. |
| `04_hive/` | Tablas de Hive y consultas con tiempos (texto, Parquet, Parquet particionado). |
| `05_bigquery/` | Tabla externa y las 5 vistas analíticas. |
| `06_tablero/` | PDF del tablero de Looker Studio. |

## Cómo reproducirlo

1. **Ingesta:** correr el cuaderno de `01_ingesta/` (ajustar proyecto y bucket).
2. **Cluster:** correr `02_infraestructura/crear_cluster_openalex.sh` en Cloud Shell.
3. **ETL:** `gcloud dataproc jobs submit pyspark etl_openalex.py ...` (6 lotes y una consolidación final).
4. **Hive:** `gcloud dataproc jobs submit hive --cluster=hive-learning-cluster --region=us-central1 --file=01_tablas.hql` y luego `02_consultas.hql` y `03_poda.hql`.
5. **BigQuery:** pegar `05_bigquery/bigquery.sql` en el editor de consultas.
6. **Tablero:** conectar Looker Studio a las vistas `q1` a `q5`.
7. **Limpieza:** `gcloud dataproc clusters delete hive-learning-cluster --region=us-central1` (los datos del bucket no se borran).

## Resultados principales

| Países en el artículo | Artículos | FWCI promedio | % en el 10% más citado |
|---|---|---|---|
| 1 país | 3,444,318 | 1.79 | 16.3 |
| 2 países | 539,940 | 2.73 | 25.4 |
| 3 a 4 países | 149,467 | 3.53 | 32.1 |
| 5 o más | 26,102 | 6.27 | 44.1 |

Rendimiento en Hive (10.47 millones de filas): Parquet fue de 2.7 a 3.8 veces más rápido que texto, y la poda de particiones (filtrar por `anio`) fue 12 veces más rápida que leer todos los años (5.4 s contra 65.4 s, mismos resultados).

## Limitaciones

- Muestra aleatoria de 90 archivos, no el catálogo completo.
- Los archivos se agrupan por fecha de actualización, no por año de publicación.
- Los resultados son asociaciones, no causas.
- OpenAlex casi no trae costos (`apc_paid`), por eso el retorno se mide en impacto.
