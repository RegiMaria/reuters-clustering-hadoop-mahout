#!/bin/bash
# Ponto de entrada do container: sobe SSH + HDFS + YARN e formata o
# namenode na primeira execucao, depois abre um shell interativo.

service ssh start # liga o serviço de SSH dentro do container

if [ ! -d "/root/hdfs/namenode/current" ]; then
  echo ">>> Formatando o HDFS pela primeira vez..."
  $HADOOP_HOME/bin/hdfs namenode -format -force
fi

$HADOOP_HOME/sbin/start-dfs.sh
$HADOOP_HOME/sbin/start-yarn.sh

echo ""
echo "==============================================================="
echo " Ambiente pronto! Hadoop + Mahout 0.9 disponiveis no PATH."
echo " Veja scripts/run_pipeline.sh para rodar o pipeline completo."
echo "==============================================================="
echo ""

exec bash
