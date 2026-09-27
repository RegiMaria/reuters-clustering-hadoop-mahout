# Justificativa Técnica: Por que Conteinerizar o ambiente com Docker

## O problema encontrado

A atividade prática solicitou a execução de uma sequência de comandos
do **Apache Mahout** (`seqdirectory`, `seq2sparse`, `kmeans`, `clusterdump`)
sobre o **Apache Hadoop**, para realizar clustering de textos na base Reuters (C50).

Ao investigar como reproduzir esse ambiente, identifiquei que esses comandos pertencem
à **API clássica do Mahout (Map/Reduce)**, disponível até a versão **0.9** do projeto.
A partir da versão 0.10, o Mahout abandonou o processamento distribuído baseado em MapReduce
do Hadoop em favor de outros backends (como o Apache Spark),
e **removeu os algoritmos clássicos de clustering, classificação e recomendação**
da linha de comando (`mahout kmeans`, `mahout seq2sparse` etc. não existem mais nas versões atuais).

Ou seja: **instalar a versão mais recente do Hadoop e do Mahout, hoje, não reproduziria
os comandos exatos pedidos na atividade.** Seria necessário um ambiente com versões 
específicas e mais antigas (Hadoop ~2.x e Mahout 0.9), que não são as versões disponíveis
nos gerenciadores de pacotes atuais nem compatíveis, de forma trivial, com versões modernas
de Java e sistemas operacionais.

## As alternativas que considerei

| Alternativa | Problema |
|---|---|
| Instalar Hadoop 2.x + Mahout 0.9 diretamente no meu sistema operacional | Alto risco de conflito com versões de Java, variáveis de ambiente e outras ferramentas já instaladas na máquina; difícil de desfazer; não reprodutível em outra máquina. |
| Usar uma máquina virtual completa (VM) | Funciona, mas é pesada (gigabytes de imagem, minutos para inicializar), difícil de compartilhar/versionar, e não é prática comum de mercado para isolar ambientes de aplicação. |
| Usar um serviço de nuvem gerenciado (ex: EMR, Dataproc) | Foge do escopo pedagógico da atividade (rodar localmente com comandos do enunciado), tem custo, e depende de configuração de conta na nuvem. |
| **Conteinerizar com Docker** | Isola completamente as versões específicas exigidas (Java 8, Hadoop 2.7.7, Mahout 0.9) do restante do sistema, sem afetar nada fora do container; é leve; e - ponto central - é **totalmente reprodutível**: qualquer pessoa, em qualquer sistema operacional (Windows, macOS ou Linux), consegue reconstruir exatamente o mesmo ambiente rodando dois comandos (`docker build` e `docker run`). |

## Por que essa escolha é tecnicamente correta (e não apenas conveniente)

1. **Reprodutibilidade científica/acadêmica**: o `Dockerfile` funciona como documentação executável. Qualquer pessoa (incluindo o professor) pode reconstruir o ambiente exato usado, sem depender de "na minha máquina funcionava".
2. **Isolamento de dependências conflitantes**: Hadoop 2.7.7 e Mahout 0.9 exigem Java 8 especificamente. Minha máquina (ou a máquina de qualquer avaliador) pode ter uma versão diferente de Java instalada para outros projetos — o container evita esse conflito completamente.
3. **Versionamento junto com o código**: os arquivos de configuração do Hadoop (`core-site.xml`, `hdfs-site.xml` etc.) ficam versionados no próprio repositório Git, junto com o `Dockerfile` que os utiliza — o ambiente é parte do histórico do projeto, não um passo manual "à parte".
4. **Coerência com o eixo de estudo do semestre**: a disciplina trata justamente de ferramentas e infraestrutura de Big Data; usar Docker para isolar essa infraestrutura é uma prática amplamente adotada no mercado (inclusive pela própria comunidade Hadoop/Mahout, que distribui imagens Docker oficiais e de terceiros para facilitar testes).

## Conclusão

A conteinerização com Docker não foi uma escolha por comodidade,
mas a solução que resolve um problema real de **incompatibilidade de versões
entre o Mahout atual e os comandos exigidos pela atividade**,
ao mesmo tempo em que produz um ambiente **reprodutível, isolado e versionado**
— características desejáveis em qualquer entrega de engenharia de dados no mundo real.