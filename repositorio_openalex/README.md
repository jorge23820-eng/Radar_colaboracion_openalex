# Radar de colaboración científica con OpenAlex

Proyecto integrador: *Big Data Architecture & Strategy*  
**Autor:** Jorge Luis González Martínez · Universidad Panamericana · Octubre de 2026

**Tablero en Looker Studio:** https://datastudio.google.com/s/kmb4Q7t5t1I

## ¿De qué trata?

Las oficinas de investigación de las universidades suelen decidir sus alianzas por intuición o con reportes hechos a mano. Este proyecto construye, en Google Cloud, un pipeline de datos que procesa **10,467,306 artículos científicos** de OpenAlex y los deja listos para responder preguntas como: *¿nos conviene aliarnos con más países?*

El valor se mide en **impacto científico** (FWCI y porcentaje de artículos en el 10 % más citado), no en dólares, porque OpenAlex casi no trae costos de investigación.

**Hallazgo principal:** los artículos de 5 o más países tienen un FWCI promedio de **6.27**, contra **1.79** de los de un solo país (3.5 veces más). Es una asociación, no una causa.

## Los datos

| Dato | Valor |
|---|---|
| Fuente | OpenAlex, snapshot de septiembre de 2026, licencia CC0 (`s3://openalex`) |
| Muestra | 90 archivos JSONL comprimidos elegidos al azar (semilla 7), 25.51 GiB |
| Artículos tras la limpieza | 10,467,306, sin duplicados |
| Resultado curado | Parquet de 166 MiB, 15 columnas, 131 particiones por año |

## Arquitectura

```
OpenAlex (S3, JSON .gz)
   -> Cloud Storage: zona cruda (openalex/jsonl/)
   -> Dataproc + Spark: limpieza y ETL en 6 lotes (openalex/parquet_lotes/)
   -> Cloud Storage: zona curada, Parquet por año (openalex/parquet/works/)
        |-> Hive en Dataproc: pruebas de formato y de poda de particiones
        |-> BigQuery: tabla externa + 5 vistas -> Looker Studio (tablero)
```

## Estructura del repositorio

| Carpeta | Contenido |
|---|---|
| `01_ingesta/` | Cuaderno que copia los archivos de S3 a Cloud Storage sin descargarlos. |
| `02_infraestructura/` | Script de creación del clúster de Dataproc. |
| `03_etl_spark/` | ETL en PySpark por lotes (`etl_openalex.py`) y revisión del esquema. |
| `04_hive/` | Tablas de Hive, consultas con tiempos y prueba de poda. |
| `05_bigquery/` | Tabla externa y las 5 vistas analíticas. |
| `06_tablero/` | PDF del tablero de Looker Studio. |

## Cómo reproducirlo

1. **Ingesta:** correr el cuaderno de `01_ingesta/` (ajustar proyecto y bucket).
2. **Clúster:** correr `02_infraestructura/crear_cluster_openalex.sh` en Cloud Shell.
3. **ETL:** `gcloud dataproc jobs submit pyspark etl_openalex.py --cluster=hive-learning-cluster --region=us-central1 -- 0 6 1`
4. **Hive:** enviar `01_tablas.hql`, `02_consultas.hql` y `03_poda.hql` con `gcloud dataproc jobs submit hive ... --file=`.
5. **BigQuery:** pegar `05_bigquery/bigquery.sql` en el editor de consultas.
6. **Tablero:** conectar Looker Studio a las vistas `q1` a `q5`.
7. **Limpieza:** `gcloud dataproc clusters delete hive-learning-cluster --region=us-central1` (los datos del bucket no se borran).

## Limpieza de datos

1. Solo registros de tipo `article` (los demás tipos casi no traen FWCI).
2. Años entre 1900 y 2026.
3. Sin artículos retractados.
4. Sin duplicados, usando `id` como llave.

Los artículos sin FWCI (1.7 %) se dejaron vacíos a propósito para no distorsionar los promedios.

## Resultados

**Colaboración internacional** (4,159,827 artículos con país registrado e impacto medido)

| Países en el artículo | Artículos | FWCI promedio | % en el 10 % más citado |
|---|---|---|---|
| 1 país | 3,444,318 | 1.79 | 16.3 |
| 2 países | 539,940 | 2.73 | 25.4 |
| 3 a 4 países | 149,467 | 3.53 | 32.1 |
| 5 o más | 26,102 | 6.27 | 44.1 |

**Otros hallazgos**

- **Países:** los de mayor impacto (con al menos 10 mil artículos) son Hong Kong (4.00), Singapur (3.73), Países Bajos (3.64) y Suiza (3.62). Estados Unidos y China encabezan el volumen, no el impacto.
- **Acceso abierto:** Hybrid (1.92), Gold (1.89) y Bronze (1.88) tienen casi el doble de impacto que el acceso cerrado (0.93). Green (0.75) y Diamond (0.70) quedan por debajo.
- **Financiadores:** solo 10.1 % de los artículos declara uno (1,055,940). Los de mayor volumen son la National Natural Science Foundation of China (146,759), los National Institutes of Health (65,269) y la National Science Foundation (60,596).

**Rendimiento en Hive** (10.47 millones de filas)

| Prueba | Texto | Parquet plano | Parquet particionado |
|---|---|---|---|
| Filtro por años (2020 a 2024) | 15.2 s | 5.7 s | 9.3 s |
| Lectura completa y agrupación | 25.3 s | 6.7 s | 26.9 s |

Parquet fue de 2.7 a 3.8 veces más rápido que texto. La poda de particiones (filtrar por `anio`) fue 12 veces más rápida que leer todos los años: 5.4 s contra 65.4 s, con los mismos resultados.

## Recomendaciones

- Impulsar grupos de investigación con 3 o más países.
- Evaluar publicar en acceso abierto Hybrid o Gold.
- Explorar convenios piloto con Países Bajos, Suiza y Singapur.
- No asignar presupuesto por financiador hasta tener datos más completos.
- Repetir el análisis con el snapshot completo, que reutiliza el mismo pipeline.

## Limitaciones

- Muestra aleatoria de 90 archivos, no el catálogo completo.
- Los resultados son asociaciones, no causas.
- Solo 10.1 % de los artículos trae financiador y 1.7 % no tiene FWCI (sobre todo de 2025 y 2026).
- OpenAlex casi no trae costos (`apc_paid`, solo 0.09 % de los registros), por eso el retorno se mide en impacto.

## Uso de inteligencia artificial

Parte del código (ETL en PySpark, tablas de Hive y consultas de BigQuery) se elaboró con apoyo de Claude, a partir de instrucciones escritas por el autor. El script del clúster y el cuaderno de ingesta se adaptaron de material del curso. Los prompts equivalentes están en el informe.
