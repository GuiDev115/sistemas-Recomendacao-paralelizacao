# Entendimento Completo do Projeto
## Sistema de Recomendação Paralelo - Amazon

---

## 📋 O QUE O PROJETO FAZ?

Este projeto implementa um **sistema de recomendação de produtos** similar ao usado pela Amazon, mas com foco em **paralelização** para melhorar o desempenho.

### Funcionamento Básico

1. **Entrada**: Avaliações de usuários sobre produtos (ex: usuário 1 deu nota 5 para produto 10)
2. **Processamento**: Calcula quais produtos são similares entre si
3. **Saída**: Recomenda produtos para usuários baseado em suas compras anteriores

### Exemplo Prático

```
Usuário comprou: Celular Samsung
Sistema calcula: "Celular Samsung" é similar a "Capa Samsung", "Fone Bluetooth"
Sistema recomenda: "Capa Samsung" e "Fone Bluetooth" para o usuário
```

---

## 🎯 PROBLEMA QUE RESOLVE

### Desafio Real da Amazon
- Milhões de produtos no catálogo
- Bilhões de interações usuário-produto
- Necessidade de calcular similaridade entre **TODOS** os pares de produtos
- Para 10.000 produtos = 50 milhões de comparações!

### Solução: Paralelização
Em vez de fazer as comparações uma por vez (sequencial), o projeto divide o trabalho entre múltiplos processadores, executando cálculos simultaneamente.

---

## 🔬 ALGORITMO IMPLEMENTADO

### Filtragem Colaborativa Item-Item

#### Passo 1: Calcular Similaridade de Cosseno
Para cada par de produtos (i, j), calcula quão similares eles são baseado nas avaliações dos usuários:

```
Similaridade(Produto_A, Produto_B) = 
    soma(avaliações_A × avaliações_B) / 
    (norma_A × norma_B)
```

**Exemplo:**
- Produto A: [5, 4, -, 5] (4 usuários avaliaram)
- Produto B: [5, 5, -, 4]
- Similaridade ≈ 0.98 (muito similares!)

#### Passo 2: Construir Matriz de Similaridade
Cria uma tabela com similaridade entre todos os produtos:

```
         Prod1  Prod2  Prod3
Prod1    1.00   0.85   0.23
Prod2    0.85   1.00   0.67
Prod3    0.23   0.67   1.00
```

#### Passo 3: Gerar Recomendações
Para um usuário, pega os produtos que ele já avaliou e recomenda produtos similares que ele ainda não comprou.

---

## 💻 IMPLEMENTAÇÕES

### 4 Versões do Código

#### 1️⃣ **Sequencial** (`src/sequential/recommender.c`)
- Executa tudo em **1 processador**
- Baseline (referência) para comparação
- Código mais simples

#### 2️⃣ **OpenMP** (`src/openmp/recommender_omp.c`)
- Usa **diretivas #pragma** para paralelizar
- Memória compartilhada
- **Mais simples** de implementar
- Melhor desempenho geral

```c
#pragma omp parallel for schedule(dynamic, 10)
for (int i = 0; i < num_items; i++) {
    // Cada thread processa alguns itens
}
```

#### 3️⃣ **Pthreads** (`src/pthreads/recommender_pthread.c`)
- Usa **threads POSIX** (controle manual)
- Memória compartilhada
- Mais controle, mas mais complexo

```c
pthread_create(&threads[i], NULL, worker_function, &data[i]);
pthread_join(threads[i], NULL);
```

#### 4️⃣ **MPI** (`src/mpi/recommender_mpi.c`)
- Usa **passagem de mensagens**
- Memória distribuída
- Escala para **múltiplos computadores** (cluster)

```c
MPI_Bcast(data, size, MPI_FLOAT, 0, MPI_COMM_WORLD);  // Distribui dados
MPI_Gather(results, size, MPI_FLOAT, 0, ...);         // Coleta resultados
```

---

## 📊 DADOS SINTÉTICOS

### Gerador de Dados (`scripts/generate_data.py`)

Cria avaliações fictícias de usuários sobre produtos:

```
Formato: user_id item_id rating
Exemplo:
0 42 5.0    # Usuário 0 deu nota 5 para item 42
1 10 4.5    # Usuário 1 deu nota 4.5 para item 10
```

### Tamanhos Disponíveis
- **Small**: 100 usuários × 100 produtos = 1.000 avaliações
- **Medium**: 500 × 500 = 10.000 avaliações
- **Large**: 1.000 × 1.000 = 50.000 avaliações
- **XLarge**: 2.000 × 2.000 = 100.000 avaliações

---

## 🧪 O QUE FAZ `make test`?

### Comando: `make test`

Executa um **teste rápido** (1 execução) de cada versão com o dataset **small**:

```bash
make test
```

### Fluxo de Execução:

```
1. make all     → Compila todas as 4 versões
2. make data    → Gera dados de teste (se não existir)
3. Executa:
   ├─ Sequencial       data/ratings_small.txt
   ├─ OpenMP (4)       data/ratings_small.txt 4
   ├─ Pthreads (4)     data/ratings_small.txt 4
   └─ MPI (4)          data/ratings_small.txt 4
```

### Saída Esperada:

```
=== Sequencial ===
Carregados: 100 usuários, 100 itens, 1000 avaliações
Tempo de execução: 0.0011 segundos
Top 10 recomendações para usuário 0: ...

=== OpenMP (4 threads) ===
Tempo de execução: 0.0006 segundos  ← ~2x mais rápido!
Top 10 recomendações para usuário 0: ...

=== Pthreads (4 threads) ===
Tempo de execução: 0.0007 segundos
...

=== MPI (4 processos) ===
Tempo de execução: 0.0008 segundos
...
```

### Objetivo do Teste:
- ✅ Verificar que **todos** os programas compilam
- ✅ Verificar que **todos** executam corretamente
- ✅ Comparar **tempos de execução** rapidamente
- ✅ Ver que a **paralelização acelera** o processamento

---

## 🔬 O QUE FAZ `make benchmark`?

### Comando: `make benchmark`

Executa experimentos **completos** para análise científica:

```bash
make benchmark  # Demora ~30 minutos
```

### Fluxo de Execução:

```
1. Para cada versão (Sequencial, OpenMP, Pthreads, MPI):
   ├─ Para cada número de threads (1, 2, 4, 8):
   │  └─ Executa 10 vezes
   │     ├─ Execução 1
   │     ├─ Execução 2
   │     └─ ...
   │     └─ Execução 10
   └─ Calcula estatísticas:
      ├─ Média
      ├─ Desvio padrão
      ├─ Intervalo de confiança 95%
      ├─ Speedup
      ├─ Eficiência
      └─ Karp-Flatt (fração serial)
```

### Saída:
- Arquivos em `results/` com tempos de execução
- Usado depois por `make analyze` para gerar gráficos

---

## 📈 O QUE FAZ `make analyze`?

### Comando: `make analyze`

Analisa os resultados do benchmark e **gera gráficos**:

```bash
make analyze
```

### Gráficos Gerados (em `results/`):

1. **execution_time.png**
   - Tempo vs Número de Threads
   - Mostra como o tempo diminui com mais threads

2. **speedup.png**
   - Speedup vs Número de Threads
   - Mostra quantas vezes mais rápido ficou
   - Linha "ideal" para comparação

3. **efficiency.png**
   - Eficiência vs Número de Threads
   - Mostra se os recursos estão sendo bem aproveitados

4. **karp_flatt.png**
   - Fração Serial vs Threads
   - Estima quanto código não pode ser paralelizado

5. **results_table.tex**
   - Tabela LaTeX formatada para o relatório

---

## 🎓 MÉTRICAS CALCULADAS

### 1. Tempo de Execução
- **Definição**: Quanto tempo o programa leva para executar
- **Cálculo**: Média de 10 execuções
- **Exemplo**: 2.5 segundos

### 2. Speedup (Sp)
- **Definição**: Quantas vezes mais rápido ficou
- **Fórmula**: `Sp = Tempo_Sequencial / Tempo_Paralelo`
- **Ideal**: Linear (Sp = p), ex: 4 threads = 4x mais rápido
- **Exemplo**: Se sequencial = 4s e paralelo = 1s → Speedup = 4x

### 3. Eficiência (Ep)
- **Definição**: Quão bem os recursos estão sendo usados
- **Fórmula**: `Ep = Speedup / Número_de_Threads`
- **Ideal**: 100% (Ep = 1.0)
- **Exemplo**: Speedup 3.2x com 4 threads → Eficiência = 80%

### 4. Karp-Flatt (e)
- **Definição**: Estimativa da fração de código que não pode ser paralelizada
- **Fórmula**: `e = (1/Sp - 1/p) / (1 - 1/p)`
- **Ideal**: Próximo de 0 (código altamente paralelizável)
- **Exemplo**: e = 0.05 significa 5% do código é sequencial

### 5. Intervalo de Confiança (95%)
- **Definição**: Margem de erro estatística
- **Uso**: Tempo médio ± margem
- **Exemplo**: 2.5s ± 0.1s (entre 2.4s e 2.6s)

---

## 🔄 FLUXO COMPLETO DO PROJETO

### Fase 1: Preparação
```
1. Verificar sistema        ./check.sh
2. Compilar programas       make all
3. Gerar dados              make data
```

### Fase 2: Testes Rápidos
```
4. Teste básico             make test
   └─ Verifica funcionamento básico
```

### Fase 3: Experimentos Completos
```
5. Benchmark completo       make benchmark
   ├─ 10 execuções × 4 threads × 4 versões
   └─ Salva tempos em results/
   
6. Análise estatística      make analyze
   ├─ Calcula métricas
   ├─ Gera gráficos
   └─ Cria tabela LaTeX
```

### Fase 4: Documentação
```
7. Compilar relatório       make report
   └─ Gera docs/relatorio.pdf
```

### Fase 5: Apresentação
```
8. Preparar slides          docs/apresentacao.md
9. Praticar apresentação    15-20 minutos
```

---

## 📁 ESTRUTURA DE ARQUIVOS EXPLICADA

```
ppc/
│
├── src/                              # Código fonte
│   ├── sequential/recommender.c      # Versão baseline (1 core)
│   ├── openmp/recommender_omp.c      # Versão OpenMP (N cores)
│   ├── pthreads/recommender_pthread.c # Versão Pthreads (N cores)
│   └── mpi/recommender_mpi.c         # Versão MPI (N nodes)
│
├── scripts/
│   ├── generate_data.py              # Gera avaliações sintéticas
│   ├── run_benchmark.sh              # Executa 10x cada versão
│   └── analyze_results.py            # Calcula métricas + gráficos
│
├── data/                             # Dados de entrada
│   ├── ratings_small.txt             # 100×100 (teste rápido)
│   ├── ratings_medium.txt            # 500×500 (benchmark)
│   └── ratings_large.txt             # 1000×1000 (análise)
│
├── results/                          # Resultados dos experimentos
│   ├── sequential_times.txt          # 10 tempos da versão seq
│   ├── openmp_4t_times.txt           # 10 tempos OpenMP 4 threads
│   ├── execution_time.png            # Gráfico tempo vs threads
│   ├── speedup.png                   # Gráfico speedup
│   ├── efficiency.png                # Gráfico eficiência
│   └── results_table.tex             # Tabela para relatório
│
├── build/                            # Executáveis compilados
│   ├── recommender_seq               # Binário sequencial
│   ├── recommender_omp               # Binário OpenMP
│   ├── recommender_pthread           # Binário Pthreads
│   └── recommender_mpi               # Binário MPI
│
├── docs/
│   ├── relatorio.tex                 # Relatório científico (SBC)
│   ├── apresentacao.md               # Slides para apresentação
│   └── sbc-template.sty              # Template SBC oficial
│
├── Makefile                          # Automação de build/testes
├── run.sh                            # Menu interativo
├── check.sh                          # Verifica dependências
│
└── Documentação:
    ├── README.md                     # Visão geral
    ├── GUIA_PROJETO.md              # Guia completo
    ├── INSTRUCTIONS.md              # Instruções técnicas
    ├── RESUMO.txt                   # Resumo executivo
    └── ENTENDIMENTO_PROJETO.md      # Este arquivo
```

---

## 🎯 COMANDOS PRINCIPAIS EXPLICADOS

### Compilação
```bash
make all          # Compila: sequencial + OpenMP + Pthreads + MPI
make sequential   # Compila apenas versão sequencial
make openmp       # Compila apenas versão OpenMP
make clean        # Remove executáveis
```

### Dados
```bash
make data         # Gera small, medium, large
python3 scripts/generate_data.py xlarge  # Gera dataset extra grande
```

### Testes
```bash
make test         # Teste rápido (1 execução, dataset small)
make benchmark    # Benchmark completo (10 exec × 4 configs)
make analyze      # Analisa resultados + gera gráficos
```

### Execução Manual
```bash
# Sequencial
./build/recommender_seq data/ratings_medium.txt

# OpenMP com 8 threads
./build/recommender_omp data/ratings_medium.txt 8

# Pthreads com 4 threads
./build/recommender_pthread data/ratings_medium.txt 4

# MPI com 4 processos
mpirun -np 4 ./build/recommender_mpi data/ratings_medium.txt
```

### Documentação
```bash
make report       # Compila relatório LaTeX → PDF
./run.sh          # Menu interativo completo
```

---

## 🔬 POR QUE PARALELIZAR?

### Exemplo Prático de Ganho

**Cenário**: Calcular similaridade para 1000 produtos

#### Sequencial (1 core):
```
Comparações: 1000 × 999 / 2 = 499.500
Tempo por comparação: 0.01ms
Tempo total: 499.500 × 0.01ms = 4.995 segundos ≈ 5 segundos
```

#### Paralelo (4 cores):
```
Cada core processa: 499.500 / 4 ≈ 125.000 comparações
Tempo por core: 125.000 × 0.01ms = 1.25 segundos
Speedup teórico: 5s / 1.25s = 4x
Speedup real: ~3.2x (80% eficiência devido a overhead)
```

### Overhead Paralelo
Fatores que reduzem eficiência:
- **Sincronização**: Threads precisam esperar umas pelas outras
- **Comunicação**: Transferência de dados entre processos (MPI)
- **Criação de threads**: Tempo para criar/destruir threads
- **Cache**: Contenção quando múltiplos cores acessam mesma memória

---

## 📊 RESULTADOS ESPERADOS

### Speedup Típico (Dataset Medium)

| Threads | Sequencial | OpenMP  | Pthreads | MPI     |
|---------|-----------|---------|----------|---------|
| 1       | 1.00x     | 1.00x   | 1.00x    | 1.00x   |
| 2       | 1.00x     | 1.85x   | 1.82x    | 1.71x   |
| 4       | 1.00x     | 3.41x   | 3.28x    | 2.93x   |
| 8       | 1.00x     | 5.67x   | 5.42x    | 4.81x   |

### Por Que OpenMP é Mais Rápido?
1. **Menos overhead**: Compilador otimiza automaticamente
2. **Scheduling dinâmico**: Balanceamento de carga automático
3. **Memória compartilhada**: Sem cópia de dados
4. **Cache eficiente**: Melhor localidade de dados

### Por Que MPI é Mais Lento (em 1 nó)?
1. **Overhead de comunicação**: Broadcast e Gather
2. **Cópia de dados**: Serialização/desserialização
3. **Latência**: Mesmo em memória compartilhada
4. **Vantagem**: Escala para múltiplos computadores!

---

## 🎓 CONCEITOS DA DISCIPLINA APLICADOS

### ✅ Processos e Threads
- Fork (conceitual)
- POSIX Threads (implementado)
- Mutex para exclusão mútua
- Sincronização com barreiras

### ✅ Memória Compartilhada
- OpenMP: diretivas #pragma
- Pthreads: controle explícito
- Particionamento de dados
- Scheduling (estático vs dinâmico)

### ✅ Memória Distribuída
- MPI: message passing
- Broadcast (distribuir dados)
- Gather (coletar resultados)
- Balanceamento de carga

### ✅ Avaliação de Desempenho
- Tempo de execução
- Speedup
- Eficiência
- Lei de Amdahl
- Métrica de Karp-Flatt
- Escalabilidade

---

## 🚀 COMO USAR O PROJETO

### Para Desenvolvimento/Teste
```bash
./check.sh          # 1. Verificar dependências
make all            # 2. Compilar tudo
make data           # 3. Gerar dados
make test           # 4. Teste rápido
```

### Para Experimentos Completos
```bash
make benchmark      # 1. Executar 10x cada
make analyze        # 2. Gerar gráficos
```

### Para Apresentação
```bash
make report         # 1. Compilar relatório
./run.sh            # 2. Menu interativo (demo ao vivo)
```

---

## 🎯 OBJETIVO FINAL

Demonstrar que:
1. ✅ **Paralelização acelera** processamento de sistemas de recomendação
2. ✅ **OpenMP é eficiente** para memória compartilhada
3. ✅ **MPI escala** para computação distribuída
4. ✅ **Métrica de desempenho** comprovam ganhos
5. ✅ **Aplicação real** (sistema da Amazon) beneficia-se de paralelização

---

## 📚 REFERÊNCIAS PRINCIPAIS

1. **Sarwar et al. (2001)** - Filtragem colaborativa item-item
2. **Linden et al. (2003)** - Sistema de recomendação da Amazon
3. **OpenMP 5.0** - Especificação da API
4. **MPI 3.1** - Padrão de passagem de mensagens

---

## ✅ CHECKLIST DE COMPREENSÃO

Você entendeu o projeto se consegue responder:

- [ ] O que é filtragem colaborativa item-item?
- [ ] Por que calcular similaridade de cosseno?
- [ ] Como OpenMP paraleliza o código?
- [ ] Qual a diferença entre OpenMP e Pthreads?
- [ ] Por que MPI é mais lento em 1 nó mas escala melhor?
- [ ] O que é speedup e eficiência?
- [ ] Como interpretar a métrica de Karp-Flatt?
- [ ] O que `make test` faz exatamente?
- [ ] Como os gráficos são gerados?
- [ ] Qual o fluxo completo do projeto?

---

**Pronto! Agora você tem uma visão completa do projeto!** 🎓✨
