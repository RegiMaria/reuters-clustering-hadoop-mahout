#!/bin/bash
# =====================================================================
# run_pipeline.sh
# Roda dentro do container (imagem construida a partir do docker/Dockerfile).
# Baixa a base Reuters C50, envia para o HDFS e executa o pipeline:
#   seqdirectory -> seq2sparse -> kmeans -> clusterdump
# =====================================================================
set -e

DADOS_DIR=/root/dados
SAIDA=/root/saida_clusters.txt

echo ">>> [1/5] Baixando a base Reuters C50 (UCI)..."
mkdir -p "$DADOS_DIR"
cd "$DADOS_DIR"
if [ ! -d "C50train" ]; then
  wget -q https://archive.ics.uci.edu/ml/machine-learning-databases/00217/C50.zip
  unzip -q C50.zip
fi

echo ">>> [2/5] Enviando a base para o HDFS..."
hadoop fs -mkdir -p /C50
hadoop fs -copyFromLocal -f "$DADOS_DIR/C50train" /C50/C50train

echo ">>> [3/5] Convertendo textos em SequenceFile..."
mahout seqdirectory -i /C50/C50train -o /seqreuters -xm sequential

echo ">>> [4/5] Extracao e selecao de feicoes (TF-IDF)..."
mahout seq2sparse -i /seqreuters -o /train-sparse

echo ">>> [5/5] Executando K-means e extraindo os clusters..."
mahout kmeans -i /train-sparse/tfidf-vectors/ \
  -c /kmeans-train-clusters -o /train-clusters-final \
  -dm org.apache.mahout.common.distance.EuclideanDistanceMeasure \
  -x 10 -k 10 -ow

mahout clusterdump -d /train-sparse/dictionary.file-0 -dt sequencefile \
  -i /train-clusters-final/clusters-10-final -n 10 -b 100 \
  -o "$SAIDA" -p /train-clusters-final/clustered-points

echo ""
echo "==============================================================="
echo " Concluido! Resultado em: $SAIDA"
echo "==============================================================="
cat "$SAIDA"