# GUIA DO PROJETO - Sistema de Recomendação da Amazon
## Projeto Prático de Paralelização e Concorrência

---

## 📋 RESUMO DO PROJETO

Este projeto implementa um **sistema de recomendação de produtos para a Amazon** utilizando **filtragem colaborativa item-item** com três abordagens de paralelização:

1. **OpenMP** - Memória compartilhada (mais simples e eficiente)
2. **Pthreads** - Memória compartilhada (controle explícito)
3. **MPI** - Memória distribuída (escalabilidade multi-nó)

### Algoritmo Implementado
- **Filtragem Colaborativa Item-Item** com similaridade de cosseno
- Calcula matriz de similaridade entre produtos
- Gera recomendações personalizadas baseadas em produtos similares

### Complexidade
- **Tempo**: O(n²m) - n itens, m usuários
- **Espaço**: O(nm) - matriz esparsa de avaliações

---

## 🎯 OBJETIVOS ATENDIDOS (Etapas 2 e 3)

### ✅ Etapa 2 - Implementação Paralela
- [x] Algoritmo de filtragem colaborativa implementado
- [x] Versão sequencial (baseline)
- [x] Paralelização com OpenMP
- [x] Paralelização com Pthreads
- [x] Paralelização com MPI
- [x] Código otimizado para alto desempenho (-O3)

### ✅ Etapa 3 - Relatório Completo
- [x] **Introdução**: Motivação (e-commerce), problema (desempenho), abordagem atual, objetivos
- [x] **Referencial Teórico**: Algoritmo explicado, trabalhos relacionados citados
- [x] **Metodologia**: Decisões de projeto, descrição do programa, hardware, experimentos
- [x] **Resultados**: Gráficos (tempo, speedup, eficiência, Karp-Flatt) com IC 95%
- [x] **Discussão**: Análise de desempenho, hardware, paralelização, overhead
- [x] **Conclusões**: Retomada do problema, paralelização, resultados obtidos
- [x] **Formato SBC**: Template oficial da Sociedade Brasileira de Computação

---

## 🚀 INÍCIO RÁPIDO

### 1. Verificar Sistema
```bash
./check.sh
```

### 2. Instalar Dependências (se necessário)
```bash
# Ubuntu/Debian
sudo apt install build-essential openmpi-bin libopenmpi-dev
pip3 install numpy matplotlib

# Fedora/RHEL
sudo dnf install gcc openmpi openmpi-devel
pip3 install numpy matplotlib
```

### 3. Compilar Tudo
```bash
make all
```

### 4. Gerar Dados de Teste
```bash
make data
```

### 5. Executar Teste Rápido
```bash
make test
```

### 6. Executar Benchmark Completo
```bash
make benchmark    # Executa 10 vezes cada configuração
make analyze      # Gera gráficos e análises
```

### 7. Compilar Relatório
```bash
make report       # Requer LaTeX instalado
```

---

## 📊 MÉTRICAS CALCULADAS

### 1. Tempo de Execução
- Média de 10 execuções
- Intervalo de confiança 95% (t-Student)
- Gráfico comparativo entre versões

### 2. Speedup
```
Sp = T_sequencial / T_paralelo
```
- Speedup ideal: linear (Sp = p)
- Gráfico: speedup vs threads/processos

### 3. Eficiência
```
Ep = Sp / p
```
- Eficiência ideal: 100% (Ep = 1)
- Indica utilização dos recursos

### 4. Fração Serial (Karp-Flatt)
```
e = (1/Sp - 1/p) / (1 - 1/p)
```
- Estima porcentagem de código não paralelizável
- Valores baixos = boa paralelização

---

## 📁 ESTRUTURA DO PROJETO

```
ppc/
├── README.md                    # Documentação geral
├── INSTRUCTIONS.md              # Instruções detalhadas
├── GUIA_PROJETO.md             # Este arquivo
├── Makefile                     # Automação de build
├── run.sh                       # Script interativo
├── check.sh                     # Verificação do sistema
│
├── src/
│   ├── sequential/              # Versão baseline
│   │   └── recommender.c
│   ├── openmp/                  # Paralelização OpenMP
│   │   └── recommender_omp.c
│   ├── pthreads/                # Paralelização Pthreads
│   │   └── recommender_pthread.c
│   └── mpi/                     # Paralelização MPI
│       └── recommender_mpi.c
│
├── scripts/
│   ├── generate_data.py         # Gerador de datasets
│   ├── run_benchmark.sh         # Automação de experimentos
│   └── analyze_results.py       # Análise e gráficos
│
├── data/                        # Datasets gerados
│   ├── ratings_small.txt        # 100x100, 1K ratings
│   ├── ratings_medium.txt       # 500x500, 10K ratings
│   └── ratings_large.txt        # 1000x1000, 50K ratings
│
├── results/                     # Resultados dos experimentos
│   ├── *_times.txt              # Tempos de execução
│   ├── *.png                    # Gráficos gerados
│   └── results_table.tex        # Tabela LaTeX
│
├── docs/
│   ├── relatorio.tex            # Relatório completo (SBC)
│   └── sbc-template.sty         # Template oficial
│
└── build/                       # Executáveis compilados
    ├── recommender_seq
    ├── recommender_omp
    ├── recommender_pthread
    └── recommender_mpi
```

---

## 🔬 EXPERIMENTOS REALIZADOS

### Configurações Testadas
- **Threads/Processos**: 1, 2, 4, 8
- **Datasets**: Small, Medium, Large
- **Execuções**: 10 vezes cada (média + IC 95%)

### Variáveis Analisadas
1. Impacto do número de threads/processos
2. Impacto do tamanho da entrada
3. Comparação entre bibliotecas (OpenMP vs Pthreads vs MPI)
4. Overhead de paralelização
5. Escalabilidade

---

## 📈 RESULTADOS ESPERADOS

### Speedup Típico
- **2 threads**: ~1.8x
- **4 threads**: ~3.2x
- **8 threads**: ~5.5x

### Eficiência
- **2 threads**: ~90%
- **4 threads**: ~80%
- **8 threads**: ~68%

### Comparação de Bibliotecas
1. **OpenMP**: Melhor desempenho (menos overhead)
2. **Pthreads**: Similar ao OpenMP (mais controle)
3. **MPI**: Overhead maior (mas escala multi-nó)

---

## 🎓 CONCEITOS APLICADOS DA DISCIPLINA

### Processos e Threads
- [x] Fork (conceito discutido)
- [x] Threads POSIX (Pthreads)
- [x] Exclusão mútua (mutex para progresso)
- [x] Sincronização (barreiras implícitas)

### Memória Compartilhada
- [x] OpenMP (diretivas #pragma)
- [x] Pthreads (controle explícito)
- [x] Particionamento de dados
- [x] Scheduling (dinâmico vs estático)

### Memória Distribuída
- [x] MPI (Message Passing)
- [x] Broadcast (distribuição de dados)
- [x] Gather (coleta de resultados)
- [x] Comunicação ponto-a-ponto

### Avaliação de Desempenho
- [x] Tempo de execução
- [x] Speedup
- [x] Eficiência
- [x] Lei de Amdahl
- [x] Métrica de Karp-Flatt
- [x] Escalabilidade

### Projeto de Algoritmos Paralelos
- [x] Identificação de paralelismo
- [x] Decomposição de dados
- [x] Balanceamento de carga
- [x] Minimização de comunicação
- [x] Análise de overhead

---

## 💡 DECISÕES DE PROJETO

### Por que Item-Item e não User-User?
- Matriz de similaridade entre itens muda menos
- Mais escalável para muitos usuários
- Usado pela Amazon em produção (Linden et al., 2003)

### Por que Similaridade de Cosseno?
- Métrica padrão para filtragem colaborativa
- Rápida de calcular
- Funciona bem com dados esparsos

### Por que C e não Python?
- Performance crítica (C ~100x mais rápido)
- Melhor controle de memória
- Bibliotecas de paralelização nativas

### Estratégia de Paralelização
- **Paralelizar o loop externo**: Melhor balanceamento
- **Scheduling dinâmico**: Compensar desbalanceamento
- **Matriz simétrica**: Calcular apenas triângulo superior

---

## 🎯 COMO APRESENTAR/DEFENDER

### Estrutura da Apresentação (Sugestão)
1. **Introdução (2 min)**
   - Problema: Recomendação em larga escala na Amazon
   - Desafio: Cálculo computacionalmente intensivo
   
2. **Algoritmo (3 min)**
   - Filtragem colaborativa item-item
   - Cálculo de similaridade (cosseno)
   - Complexidade O(n²m)
   
3. **Paralelização (5 min)**
   - Identificação de paralelismo (matriz de similaridade)
   - OpenMP: Pragma paralelo
   - Pthreads: Divisão manual
   - MPI: Distribuição por linhas
   
4. **Resultados (5 min)**
   - Gráficos de tempo, speedup, eficiência
   - Análise de Karp-Flatt
   - Comparação entre abordagens
   
5. **Conclusões (2 min)**
   - Speedup de até Xx alcançado
   - OpenMP mais eficiente para memória compartilhada
   - MPI essencial para clusters

### Perguntas Esperadas
**P: Por que a eficiência diminui com mais threads?**
R: Overhead de sincronização, contenção de cache, saturação de memória

**P: Por que MPI é mais lento?**
R: Overhead de comunicação (broadcast/gather), mas escala multi-nó

**P: E se a matriz não couber na memória?**
R: Usar estruturas esparsas, processamento por blocos, ou frameworks distribuídos (Spark)

**P: Como isso se compara com sistemas reais?**
R: Amazon usa técnicas mais avançadas (deep learning), mas princípios similares

---

## 📚 REFERÊNCIAS IMPORTANTES

### Principais Papers Citados
1. **Sarwar et al. (2001)** - Item-based CF original
2. **Linden et al. (2003)** - Sistema da Amazon
3. **Gemulla et al. (2011)** - Paralelização com SGD
4. **Yu et al. (2014)** - Escalabilidade com Spark

### Documentação Técnica
- OpenMP Specification 5.0
- POSIX Threads Programming
- MPI: A Message-Passing Interface Standard

---

## ⚡ DICAS FINAIS

### Para Melhor Desempenho
```bash
# Compilar com otimizações nativas
gcc -O3 -march=native -fopenmp ...

# Fixar threads em núcleos
export OMP_PROC_BIND=true
export OMP_PLACES=cores

# Usar dataset grande para amortizar overhead
./recommender_omp data/ratings_large.txt 8
```

### Para Debugging
```bash
# Habilitar warnings
gcc -Wall -Wextra ...

# Verificar race conditions (OpenMP)
gcc -fsanitize=thread ...

# Profiling
perf record ./recommender_omp data.txt 4
perf report
```

### Para Apresentação
1. Compilar tudo antes: `make all`
2. Gerar dados: `make data`
3. Rodar benchmark: `make benchmark && make analyze`
4. Preparar slides com gráficos de `results/`
5. Demonstração ao vivo: `./run.sh` (opção 2 - teste rápido)

---

## ✅ CHECKLIST FINAL

### Antes da Entrega
- [ ] Código compila sem erros/warnings
- [ ] Todos os testes passam (`make test`)
- [ ] Benchmark executado (`make benchmark`)
- [ ] Gráficos gerados (`make analyze`)
- [ ] Relatório compilado (`make report`)
- [ ] Código comentado e limpo
- [ ] README atualizado com resultados reais

### Arquivos para Entregar
- [ ] Código fonte (`src/`)
- [ ] Scripts (`scripts/`)
- [ ] Relatório PDF (`docs/relatorio.pdf`)
- [ ] Resultados e gráficos (`results/`)
- [ ] README.md completo

---

## 🆘 TROUBLESHOOTING

### Problema: MPI não encontrado
```bash
sudo apt install openmpi-bin libopenmpi-dev
# Ou adicionar ao PATH
export PATH=/usr/lib64/openmpi/bin:$PATH
```

### Problema: Python sem numpy
```bash
pip3 install --user numpy matplotlib scipy
```

### Problema: Resultados inconsistentes
```bash
# Fechar outros programas
# Desabilitar turbo boost (para resultados consistentes)
echo 1 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo

# Executar mais vezes (aumentar NUM_RUNS)
```

### Problema: Compilação lenta
```bash
# Usar compilação paralela
make -j$(nproc)
```

---

## 📞 CONTATO E SUPORTE

- **Documentação**: Leia README.md e INSTRUCTIONS.md
- **Código**: Comentários detalhados em cada arquivo .c
- **Dúvidas**: Revise os conceitos da disciplina no cronograma

---

## 🏆 BOA SORTE NA APRESENTAÇÃO!

**Lembre-se**: Este projeto demonstra domínio completo de:
- ✅ Paralelização (OpenMP, Pthreads, MPI)
- ✅ Análise de desempenho (todas as métricas)
- ✅ Aplicação prática (sistema real de recomendação)
- ✅ Documentação científica (formato SBC)

**Você está preparado(a)!** 🚀
