# Clustering de Textos com Hadoop e Apache Mahout - Base Reuters (C50)

Atividade prática da disciplina **Tópicos Avançados em Análise e Desenvolvimento de Sistemas II**, do curso de **Superior de Tecnologia em Análise e Desenvolvimento de Sistemas**, ministrado pela **UNIFRAN / Grupo Cruzeiro do Sul Educacional** (modalidade EAD).

## 📌 Objetivo

Aplicar o algoritmo de clustering **K-means**, via **Apache Mahout** rodando sobre **Apache Hadoop**, a uma base de textos jornalísticos (corpus Reuters, dataset [C50](https://archive.ics.uci.edu/dataset/217/reuter+50+50)), agrupando os documentos por similaridade de conteúdo (vetores TF-IDF) e avaliando se os clusters resultantes correspondem a agrupamentos temáticos coerentes.

O ambiente completo (Hadoop em modo pseudo-distribuído + Mahout 0.9) é empacotado em uma **imagem Docker**, tornando a execução reprodutível em qualquer máquina, sem necessidade de instalação manual. Veja o porquê dessa escolha em [`docs/justificativa-tecnica.md`](docs/justificativa-tecnica.md).

## 🗂️ Estrutura do repositório

```
reuters-clustering-hadoop-mahout/
├── README.md                          # este arquivo
├── docker/
│   ├── Dockerfile                     # define a imagem: Java + Hadoop 2.7.7 + Mahout 0.9
│   ├── entrypoint.sh                  # sobe HDFS/YARN ao iniciar o container
│   └── config/                        # arquivos de configuração do Hadoop (pseudo-distribuído)
│       ├── core-site.xml
│       ├── hdfs-site.xml
│       ├── mapred-site.xml
│       └── yarn-site.xml
├── scripts/
│   └── run_pipeline.sh                # baixa a base e executa o pipeline completo
├── output/
│   └── saida_clusters.txt             # resultado real gerado pelo clusterdump
└── docs/
    ├── justificativa-tecnica.md       # por que o ambiente foi conteinerizado com Docker
    ├── pipeline-detalhado.md          # o que cada comando do pipeline faz, por quê, e quanto tempo leva
    └── Relatorio_Atividade_Pratica_Unidade_IV.docx   # relatório da atividade (análise dos resultados)
```

## ⚙️ Pré-requisitos

- [Docker](https://www.docker.com/products/docker-desktop/) instalado e em execução.

Não é necessário instalar Java, Hadoop ou Mahout na máquina local — tudo roda isolado dentro do container.

## ▶️ Como executar

**1. Clonar o repositório**

```bash
git clone https://github.com/RegiMaria/reuters-clustering-hadoop-mahout 
cd reuters-clustering-hadoop-mahout
```

**2. Construir a imagem Docker**

```bash
docker build -t reuters-hadoop-mahout -f docker/Dockerfile docker/
```
⏱️ Leva entre 3 e 5 minutos (baixa Ubuntu, Java, Hadoop e Mahout - cerca de 600MB no total).

**3. Rodar o container** (monta a pasta `scripts/` e `output/` para dentro dele)

```bash
docker run -it --name mahoutlab \
  -v "$(pwd)/scripts:/root/scripts" \
  -v "$(pwd)/output:/root/output_host" \
  reuters-hadoop-mahout
```

O `entrypoint.sh` sobe o HDFS e o YARN automaticamente e abre um terminal
interativo dentro do container. Ao final, a mensagem "Ambiente pronto!"
confirma que Hadoop e Mahout estão disponíveis.

**4. Rodar o pipeline** (dentro do container)

```bash
bash /root/scripts/run_pipeline.sh
cp /root/saida_clusters.txt /root/output_host/saida_clusters.txt
```
⏱️ Leva entre 10 e 15 minutos no total. A etapa mais demorada é o envio
da base pro HDFS (2.500 arquivos pequenos, ~2-4 min) 
e o `kmeans` (10 iterações, ~4 min). **Não é normal travar - só é lento.**

Para entender o que cada etapa faz, por que essa ordem específica,
e o tempo esperado de cada comando individualmente (útil também se precisar
rodar manualmente, comando por comando), veja [`docs/pipeline-detalhado.md`](docs/pipeline-detalhado.md).

**5. Resultado**

O arquivo `output/saida_clusters.txt` (também disponível agora na sua máquina local após o passo 4)
contém os 10 clusters gerados, com os termos mais representativos de cada um. A análise interpretativa
completa desses resultados está no relatório: [`docs/Relatorio_Atividade_Pratica_Unidade_IV.docx`](docs/Relatorio_Atividade_Pratica_Unidade_IV.docx).

## 🐳 Sobre a imagem Docker

| Componente | Versão |
|---|---|
| Sistema base | Ubuntu 18.04 |
| Java | OpenJDK 8 |
| Hadoop | 2.7.7 (modo pseudo-distribuído: HDFS + YARN em um único nó) |
| Mahout | 0.9 |

A imagem é construída em camadas (uma `RUN` por dependência),
o que favorece o cache do Docker: se você alterar apenas os scripts de pipeline,
não precisa reconstruir a imagem inteira - só as camadas depois da alteração são refeitas.

## 📊 Pipeline executado

```
Textos (.txt)
   │  mahout seqdirectory
   ▼
SequenceFile
   │  mahout seq2sparse   (tokenização, stop words, stemming, TF-IDF)
   ▼
Vetores TF-IDF
   │  mahout kmeans        (k=10, distância Euclidiana, 10 iterações)
   ▼
Clusters
   │  mahout clusterdump
   ▼
saida_clusters.txt
```

Explicação detalhada de cada etapa em [`docs/pipeline-detalhado.md`](docs/pipeline-detalhado.md).

## 🐛 Problema encontrado e corrigido

O `.zip` da base Reuters C50 (UCI) descompacta diretamente em `C50train/` e `C50test/`,
sem uma pasta `C50/` envolvendo os dois. A primeira versão do `run_pipeline.sh` 
assumia essa pasta intermediária, causando o erro `copyFromLocal: '/root/dados/C50/C50train': No such file or directory`
na primeira execução. Corrigido ajustando os caminhos do script. Detalhes em [`docs/pipeline-detalhado.md`](docs/pipeline-detalhado.md#problema-encontrado).

## 👤 Autoria

Desenvolvido por **Regilene Mariano**, RGM **ocultado pela autora**, 
para a disciplina Tópicos Avançados em ADS II - UNIFRAN/Cruzeiro do Sul Virtual.

## 📄 Licença

Uso acadêmico.