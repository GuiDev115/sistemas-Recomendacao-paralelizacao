# Sistema de Recomendação de Produtos - Amazon
## Projeto de Paralelização e Concorrência

### 🎯 Descrição
Implementação paralela de um sistema de recomendação de produtos baseado em filtragem colaborativa para melhorar o desempenho do sistema da Amazon.

### 📚 DOCUMENTAÇÃO PRINCIPAL
- **📖 [GUIA_PROJETO.md](GUIA_PROJETO.md)** ← **COMECE AQUI!** Guia completo do projeto
- **📋 [RESUMO.txt](RESUMO.txt)** - Resumo executivo formatado
- **🔧 [INSTRUCTIONS.md](INSTRUCTIONS.md)** - Instruções técnicas detalhadas
- **📊 [docs/apresentacao.md](docs/apresentacao.md)** - Slides para apresentação
- **📄 [docs/relatorio.tex](docs/relatorio.tex)** - Relatório completo (formato SBC)

### ⚡ INÍCIO RÁPIDO (3 comandos)
```bash
./check.sh           # 1. Verificar sistema
make all && make data # 2. Compilar e gerar dados
make test            # 3. Executar teste
```

### 🎓 Objetivo
Aplicar técnicas de paralelização (OpenMP, Pthreads, MPI) para acelerar o processamento de recomendações em grandes volumes de dados.

### 🏗️ Estrutura do Projeto
```
ppc/
├── 💻 src/                         Código fonte
│   ├── sequential/                 Versão baseline (referência)
│   ├── openmp/                     Paralelização OpenMP
│   ├── pthreads/                   Paralelização Pthreads
│   └── mpi/                        Paralelização MPI
├── 📊 data/                        Datasets (gerados)
├── 🔧 scripts/                     Automação e análise
├── 📈 results/                     Resultados experimentais
├── 📚 docs/                        Documentação e relatório
└── 🚀 Scripts principais
    ├── run.sh                      Menu interativo
    ├── check.sh                    Verificar sistema
    └── Makefile                    Build automation
```

### 🧮 Algoritmo Implementado
**Filtragem Colaborativa Item-Item** com similaridade de cosseno
- ✅ Calcular matriz de similaridade entre produtos (O(n²m))
- ✅ Gerar recomendações baseadas em produtos similares
- ✅ Paralelizar cálculos independentes de similaridade

### 🔨 Compilação Simplificada

#### Usar Makefile (Recomendado)
```bash
make all          # Compila todas as versões
make sequential   # Apenas sequencial
make openmp       # Apenas OpenMP
make pthreads     # Apenas Pthreads
make mpi          # Apenas MPI
```

#### Compilação Manual
```bash
# Sequencial
gcc -O3 -o build/recommender_seq src/sequential/recommender.c -lm

# OpenMP
gcc -O3 -fopenmp -o build/recommender_omp src/openmp/recommender_omp.c -lm

# Pthreads
gcc -O3 -pthread -o build/recommender_pthread src/pthreads/recommender_pthread.c -lm

# MPI
mpicc -O3 -o build/recommender_mpi src/mpi/recommender_mpi.c -lm
```

### 🚀 Execução

#### Usando Scripts Automatizados (Recomendado)
```bash
./run.sh              # Menu interativo completo
make test             # Teste rápido
make benchmark        # Benchmark completo (10 runs)
make analyze          # Gerar gráficos
```

#### Execução Manual
```bash
# Gerar dados primeiro
make data

# Executar versões
./build/recommender_seq data/ratings_medium.txt
./build/recommender_omp data/ratings_medium.txt 4
./build/recommender_pthread data/ratings_medium.txt 4
mpirun -np 4 ./build/recommender_mpi data/ratings_medium.txt
```

### 📊 Experimentos
Os scripts de benchmark executam cada versão **10 vezes** e calculam:
- ⏱️ Tempo médio de execução
- 📊 Intervalo de confiança (95% - t-Student)
- 🚀 Speedup (Sp = T₁ / Tp)
- 💯 Eficiência (Ep = Sp / p)
- 📈 Fração serial (Karp-Flatt)

### 📦 Requisitos
#### Obrigatórios
- GCC ≥ 4.2 com suporte a OpenMP
- POSIX Threads (pthread)
- OpenMPI ou MPICH
- Python 3.x
- pip3: numpy, matplotlib

#### Opcionais
- LaTeX (para compilar relatório)
- Git (para controle de versão)

#### Instalação (Ubuntu/Debian)
```bash
sudo apt update
sudo apt install build-essential openmpi-bin libopenmpi-dev
pip3 install numpy matplotlib
```

### 📈 Resultados Esperados
- **Speedup**: Até ~5.7x com 8 threads (OpenMP)
- **Eficiência**: >80% até 4 threads
- **OpenMP**: Melhor desempenho (menor overhead)
- **Pthreads**: Similar ao OpenMP
- **MPI**: Overhead maior, mas escala multi-nó

### 👨‍💻 Autores
Projeto desenvolvido para a disciplina de **Paralelização e Concorrência**

### 📅 Cronograma
- **Etapa 2**: Implementação paralela ✅
- **Etapa 3**: Relatório completo ✅
- **Apresentação**: 08/12/2025

### 📞 Suporte
1. Leia **[GUIA_PROJETO.md](GUIA_PROJETO.md)** (guia completo)
2. Execute `./check.sh` (verificar sistema)
3. Execute `make help` (ver comandos disponíveis)
4. Consulte **[INSTRUCTIONS.md](INSTRUCTIONS.md)** (detalhes técnicos)
