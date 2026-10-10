import sys
from pyspark.sql import SparkSession, functions as F
from pyspark.sql.functions import col
from pyspark.sql.types import *

B = "gs://big_data_bucket_de_jlgm"
LISTA, MARCAS = f"{B}/openalex/etl/lista_archivos.txt", f"{B}/openalex/etl/marcas"
TMP, DEST = f"{B}/openalex/parquet_lotes", f"{B}/openalex/parquet/works"
N_LOTES = 6
ini, fin, consolidar = int(sys.argv[1]), int(sys.argv[2]), int(sys.argv[3])

spark = SparkSession.builder.appName("ETL_OpenAlex_works").getOrCreate()
spark.conf.set("spark.sql.shuffle.partitions", "12")

esquema_etl = StructType([
    StructField("id", StringType()), StructField("type", StringType()),
    StructField("language", StringType()), StructField("publication_year", LongType()),
    StructField("publication_date", StringType()), StructField("cited_by_count", LongType()),
    StructField("fwci", DoubleType()), StructField("is_retracted", BooleanType()),
    StructField("authors_count", LongType()), StructField("countries_distinct_count", LongType()),
    StructField("institutions_distinct_count", LongType()),
    StructField("citation_normalized_percentile", StructType([StructField("is_in_top_10_percent", BooleanType())])),
    StructField("open_access", StructType([StructField("oa_status", StringType())])),
    StructField("primary_topic", StructType([
        StructField("field", StructType([StructField("display_name", StringType())])),
        StructField("domain", StructType([StructField("display_name", StringType())]))])),
    StructField("funders", ArrayType(StructType([StructField("id", StringType()), StructField("display_name", StringType())]))),
    StructField("authorships", ArrayType(StructType([StructField("countries", ArrayType(StringType()))])))])

def existe(ruta):
    try:
        spark.read.text(ruta).limit(1).collect(); return True
    except Exception:
        return False

# archivos de mayor a menor tamaño, repartidos en lotes de tamaño parecido
filas = [l.split() for l in spark.sparkContext.textFile(LISTA).collect()]
archivos = sorted([(int(t), p) for t, p in filas], reverse=True)

for k in range(ini, fin):
    marca = f"{MARCAS}/lote_{k:02d}"
    if existe(marca):
        print(f"Lote {k}: ya procesado, se omite"); continue
    rutas = [p for _, p in archivos[k::N_LOTES]]
    print(f"Lote {k}: {len(rutas)} archivos", flush=True)
    raw = spark.read.schema(esquema_etl).json(rutas)
    works = (raw
        .filter(col("type") == "article")
        .filter(col("publication_year").between(1900, 2026))
        .filter(col("is_retracted").isNull() | (col("is_retracted") == False))
        .dropDuplicates(["id"])
        .select("id", col("publication_year").cast("int").alias("anio"),
            F.to_date("publication_date").alias("fecha"), "language", "cited_by_count", "fwci",
            col("citation_normalized_percentile.is_in_top_10_percent").alias("top10"),
            col("open_access.oa_status").alias("oa_status"),
            col("primary_topic.field.display_name").alias("campo"),
            col("primary_topic.domain.display_name").alias("dominio"),
            "authors_count", "countries_distinct_count", "institutions_distinct_count",
            col("funders.display_name").alias("financiadores"),
            F.array_distinct(F.flatten(col("authorships.countries"))).alias("paises")))
    works.repartition("anio").write.mode("overwrite").partitionBy("anio").parquet(f"{TMP}/lote_{k:02d}")
    spark.createDataFrame([(f"lote {k} listo",)], ["estado"]).write.mode("overwrite").text(marca)
    print(f"Lote {k}: LISTO", flush=True)

if consolidar:
    hechos = [f"{TMP}/lote_{k:02d}" for k in range(N_LOTES) if existe(f"{MARCAS}/lote_{k:02d}")]
    print("Consolidando lotes:", len(hechos), flush=True)
    from functools import reduce
    todo = reduce(lambda a, b: a.unionByName(b), [spark.read.parquet(h) for h in hechos]).dropDuplicates(["id"])
    todo.repartition("anio").write.mode("overwrite").partitionBy("anio").parquet(DEST)
    print("CONSOLIDADO en", DEST, flush=True)
spark.stop()
