# Revisa el esquema y el numero de filas del Parquet final (zona curada).
# Se corre como job de Dataproc:
#   gcloud dataproc jobs submit pyspark ver_esquema.py --cluster=hive-learning-cluster --region=us-central1
from pyspark.sql import SparkSession
spark = SparkSession.builder.getOrCreate()
df = spark.read.parquet("gs://big_data_bucket_de_jlgm/openalex/parquet/works")
df.printSchema()
print("FILAS", df.count())
