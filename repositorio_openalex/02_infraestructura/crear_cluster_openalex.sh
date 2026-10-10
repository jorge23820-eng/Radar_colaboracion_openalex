#!/bin/bash
# Script del profe (hive-learning-cluster) con los cambios minimos. Correr en Cloud Shell
# (icono de terminal arriba a la derecha en la consola de GCP).
#
# CAMBIOS respecto al original del profe:
#   (1) se fija TU proyecto
#   (2) BUCKET_NAME es tu bucket
#   (3) se habilitan las APIs (tu proyecto es nuevo)
#   (4) se activa Private Google Access, necesario porque el script del profe usa --no-address
# TODO LO DEMAS (imagen, maquinas, discos, --max-idle, --max-age, Jupyter, Zeppelin, properties) es igual al del profe.

gcloud config set project project-0c406915-8785-4e51-bd1

export PROJECT_ID=$(gcloud config get-value project)
export REGION=us-central1
export ZONE=us-central1-a
export CLUSTER_NAME=hive-learning-cluster
export BUCKET_NAME=big_data_bucket_de_jlgm

# (3) y (4): una sola vez por proyecto
gcloud services enable dataproc.googleapis.com compute.googleapis.com
gcloud compute networks subnets update default --region=$REGION --enable-private-ip-google-access

gcloud dataproc clusters create $CLUSTER_NAME \
    --project=$PROJECT_ID \
    --region=$REGION \
    --zone=$ZONE \
    --image-version=2.1-ubuntu20 \
    --master-machine-type=e2-highmem-2 \
    --master-boot-disk-size 50 \
    --num-workers=3 \
    --worker-machine-type=e2-standard-2 \
    --worker-boot-disk-size 100 \
    --no-address \
    --optional-components JUPYTER,ZEPPELIN \
    --enable-component-gateway \
    --max-idle=3h \
    --max-age=5h \
    --scopes 'https://www.googleapis.com/auth/cloud-platform' \
    --properties="dataproc:jupyter.notebook.gcs.dir=gs://$BUCKET_NAME/notebooks"

# SI FALLA por la version de imagen (el mensaje menciona "2.1" o "image version"):
#   cambia  --image-version=2.1-ubuntu20  por  --image-version=2.2-ubuntu22  y vuelve a correr SOLO el bloque "gcloud dataproc clusters create".
#
# Cuando termines de trabajar, borra el cluster (los datos del bucket NO se borran):
#   gcloud dataproc clusters delete $CLUSTER_NAME --region=$REGION
