# Guia Detalhado do Pipeline

Este documento explica, comando a comando, o que o `scripts/run_pipeline.sh` 
faz internamente: o que cada etapa produz, por que essa ordem é obrigatória, 
e quanto tempo esperar em cada uma. Útil tanto para entender o processo quanto
para rodar manualmente, comando por comando, caso precise depurar algo.

## Visão geral: por que essa sequência

Cada comando **depende do resultado do anterior** - é uma esteira de produção, não etapas independentes:

```
texto cru (.txt)  →  formato interno  →  vetores numéricos  →  grupos  →  grupos legíveis
   (arquivos)        (SequenceFile)        (TF-IDF)          (clusters)   (saida_clusters.txt)
```

Não é possível pular etapas: o Mahout não processa `.txt` soltos diretamente, e o K-means não entende texto - só números.

## Etapa 1 - Enviar a base para o HDFS

```bash
hadoop fs -mkdir -p /C50
hadoop fs -copyFromLocal -f /root/dados/C50train /C50/C50train
```

**O que faz:** copia a pasta `C50train` (2.500 arquivos `.txt`,
um por notícia, organizados em 50 subpastas por autor) do disco 
comum do container para dentro do **HDFS** - o sistema de arquivos
distribuído do Hadoop, gerenciado por um componente chamado *namenode* 
(o "catálogo" que sabe onde cada pedaço de arquivo está guardado).

**Por que é necessário:** o Mahout só processa dados que estão no HDFS,
não no disco comum. Sem esse passo, os comandos seguintes não encontrariam
nada para processar.

**Tempo esperado:** 2 a 5 minutos. É a etapa mais lenta em proporção ao volume de dados,
porque envolve 2.500 arquivos pequenos - cada arquivo passa por uma negociação individual
com o namenode (registrar metadado, alocar bloco). **Não travou se parecer parado**
- confirme o progresso rodando, em outro terminal, `hadoop fs -du -s /C50/C50train`
repetidas vezes; se o número crescer, está funcionando.

## Etapa 2 - Converter texto em SequenceFile

```bash
mahout seqdirectory -i /C50/C50train -o /seqreuters -xm sequential
```

**O que faz:** lê todos os `.txt` de `/C50/C50train` (no HDFS) e converte
para o formato **SequenceFile** - um formato binário interno chave-valor 
que o Hadoop processa de forma mais eficiente que arquivos de texto soltos.

- `-i` = pasta de entrada
- `-o` = pasta de saída
- `-xm sequential` = roda sem distribuir entre múltiplos nós (não faz diferença aqui, já que o ambiente tem só um nó)

**Tempo esperado:** rápido, ~15-20 segundos.

## Etapa 3 - Extração e seleção de feições (TF-IDF)

```bash
mahout seq2sparse -i /seqreuters -o /train-sparse
```

**O que faz:** é aqui que ocorre o processamento de linguagem natural propriamente dito, internamente em várias sub-etapas (cada uma um job MapReduce):
1. **Tokenização** - separa cada texto em palavras individuais;
2. **Remoção de stop words** - descarta palavras sem carga semântica (artigos, preposições);
3. **Stemming** - reduz palavras a sua raiz (ex.: "companies" → "compani");
4. **Cálculo de TF-IDF** - atribui um peso numérico a cada termo, indicando sua importância relativa em cada documento e no conjunto total.

O resultado são vetores numéricos (`/train-sparse/tfidf-vectors/`) que representam cada texto, mais um dicionário de termos (`/train-sparse/dictionary.file-0`) usado depois para traduzir os IDs de volta em palavras legíveis.

**Por que é necessário:** o K-means (próxima etapa) não entende texto - só números. Este comando é a "tradução" de palavras para pesos numéricos.

**Tempo esperado:** a etapa mais pesada de todo o pipeline, entre 3 e 5 minutos - envolve vários jobs MapReduce encadeados (tokenização, criação de dicionário, cálculo de frequência, cálculo de IDF, poda de termos raros).

## Etapa 4 - Execução do K-means

```bash
mahout kmeans -i /train-sparse/tfidf-vectors/ \
  -c /kmeans-train-clusters -o /train-clusters-final \
  -dm org.apache.mahout.common.distance.EuclideanDistanceMeasure \
  -x 10 -k 10 -ow
```

**O que faz:** roda o algoritmo de clustering sobre os vetores TF-IDF.

- `-i` = vetores de entrada
- `-c` = onde salvar os centros iniciais dos clusters
- `-o` = onde salvar o resultado final
- `-dm EuclideanDistanceMeasure` = mede "quão parecidos" dois textos são pela distância Euclidiana entre seus vetores
- `-x 10` = no máximo 10 iterações até convergir
- `-k 10` = agrupa em 10 clusters
- `-ow` = sobrescreve resultado anterior, se existir

**Tempo esperado:** entre 3 e 4 minutos. Cada uma das 10 iterações pedidas em `-x 10`
é um job MapReduce completo (recalcula a distância de cada documento até os centros atuais,
reagrupa, recalcula os centros) - por isso o tempo se multiplica pelo número de iterações.

## Etapa 5 - Extração e leitura dos clusters

```bash
mahout clusterdump -d /train-sparse/dictionary.file-0 -dt sequencefile \
  -i /train-clusters-final/clusters-10-final -n 10 -b 100 \
  -o ~/saida_clusters.txt -p /train-clusters-final/clustered-points
```

**O que faz:** o resultado bruto do K-means usa IDs numéricos internos,
ilegíveis para humanos. Este comando traduz de volta usando o dicionário
gerado na Etapa 3.

- `-d` = dicionário de termos
- `-n 10` = mostra os 10 termos mais relevantes de cada cluster
- `-b 100` = até 100 caracteres de cada documento associado
- `-o` = arquivo de saída final

**Tempo esperado:** rápido, menos de 5 segundos - 
é só leitura e formatação, não é mais um job iterativo.

## Tempo total esperado

| Etapa | Tempo aproximado |
|---|---|
| Envio para o HDFS | 2-5 min |
| `seqdirectory` | ~20s |
| `seq2sparse` | 3-5 min |
| `kmeans` | 3-4 min |
| `clusterdump` | < 5s |
| **Total** | **~10-15 min** |

(Além disso, o `docker build` inicial leva mais 3-5 minutos, feito só uma vez.)

## Problema encontrado

Ao rodar pela primeira vez, o `run_pipeline.sh` original falhou na etapa de envio ao HDFS com o erro:

```
copyFromLocal: `/root/dados/C50/C50train': No such file or directory
```

**Causa:** o `.zip` da base Reuters C50, ao ser descompactado, 
cria as pastas `C50train/` e `C50test/` diretamente na raiz - **sem** uma pasta `C50/` 
envolvendo as duas, como o script original assumia.

**Correção:** ajustados os caminhos no `run_pipeline.sh` de `$DADOS_DIR/C50/C50train`
para `$DADOS_DIR/C50train`, e a checagem de "já baixado antes" de `[ ! -d "C50" ]` para `[ ! -d "C50train" ]`.

Esse tipo de ajuste é normal ao integrar um dataset externo a um pipeline automatizado
- a estrutura interna de um `.zip` de terceiros nem sempre é a esperada,
e só se descobre rodando de verdade.

## Rodando manualmente (comando por comando)

Se `run_pipeline.sh` falhar no meio do caminho e você não quiser reiniciar do zero,
os comandos podem ser rodados manualmente, um de cada vez, direto no terminal do container
- são exatamente os mesmos comandos das etapas 1 a 5 acima, na mesma ordem.