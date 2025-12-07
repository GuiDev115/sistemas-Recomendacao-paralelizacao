# Instruções de Uso

## Setup Inicial

### 1. Instalação de Dependências

#### Ubuntu/Debian
```bash
# Compiladores e bibliotecas
sudo apt update
sudo apt install build-essential
sudo apt install libopenmpi-dev openmpi-bin
sudo apt install python3 python3-pip

# Bibliotecas Python
pip3 install numpy matplotlib scipy

# LaTeX (opcional, para relatório)
sudo apt install texlive-full
```

#### Fedora/CentOS
```bash
sudo dnf install gcc gcc-c++ make
sudo dnf install openmpi openmpi-devel
sudo dnf install python3 python3-pip

pip3 install numpy matplotlib scipy

# LaTeX (opcional)
sudo dnf install texlive-scheme-full
```

### 2. Compilação

```bash
# Compilar todas as versões
make all

# Ou compilar individualmente
make sequential
make openmp
make pthreads
make mpi
```

### 3. Geração de Dados

```bash
# Gerar dados de teste
make data

# Ou manualmente:
cd scripts
python3 generate_data.py small   # 100x100, 1K ratings
python3 generate_data.py medium  # 500x500, 10K ratings
python3 generate_data.py large   # 1000x1000, 50K ratings
python3 generate_data.py xlarge  # 2000x2000, 100K ratings
```

## Execução

### Execução Manual

```bash
# Sequencial
./build/recommender_seq data/ratings_medium.txt

# OpenMP (4 threads)
./build/recommender_omp data/ratings_medium.txt 4

# Pthreads (4 threads)
./build/recommender_pthread data/ratings_medium.txt 4

# MPI (4 processos)
mpirun -np 4 ./build/recommender_mpi data/ratings_medium.txt
```

### Execução com Script Interativo

```bash
chmod +x run.sh
./run.sh
```

O script oferece menu interativo com opções:
1. Benchmark completo (10 execuções)
2. Teste rápido (1 execução)
3. Gerar mais dados
4. Analisar resultados
5. Compilar relatório
6. Limpar arquivos
7. Sair

### Benchmark Completo

```bash
# Executar 10 vezes cada configuração
./scripts/run_benchmark.sh

# Analisar resultados e gerar gráficos
python3 scripts/analyze_results.py
```

## Resultados

Os resultados são salvos em `results/`:
- `sequential_times.txt` - Tempos da versão sequencial
- `openmp_Xt_times.txt` - Tempos OpenMP com X threads
- `pthreads_Xt_times.txt` - Tempos Pthreads com X threads
- `mpi_Xp_times.txt` - Tempos MPI com X processos
- `*.png` - Gráficos gerados
- `results_table.tex` - Tabela LaTeX com resultados

## Personalização

### Modificar Número de Threads Testadas

Edite `scripts/run_benchmark.sh`:
```bash
THREADS_ARRAY=(1 2 4 8 16)  # Adicionar mais valores
```

### Modificar Tamanho dos Datasets

Edite `scripts/generate_data.py`:
```python
configs = {
    'custom': (3000, 3000, 200000, 'ratings_custom.txt'),
}
```

### Ajustar Parâmetros do Algoritmo

Edite os arquivos `.c` em `src/*/`:
```c
#define TOP_K 10        // Top K recomendações
#define MAX_USERS 10000 // Máximo de usuários
#define MAX_ITEMS 10000 // Máximo de itens
```

## Compilação do Relatório

```bash
cd docs
pdflatex relatorio.tex
pdflatex relatorio.tex  # Segunda passagem para referências
```

Ou usando o Makefile:
```bash
make report
```

## Troubleshooting

### Erro: "mpicc not found"
```bash
# Ubuntu/Debian
sudo apt install openmpi-bin libopenmpi-dev

# Fedora/CentOS
sudo dnf install openmpi openmpi-devel
module load mpi/openmpi-x86_64
```

### Erro: "numpy module not found"
```bash
pip3 install --user numpy matplotlib
```

### Erro: OpenMP não funciona
```bash
# Verificar versão do GCC
gcc --version  # Deve ser >= 4.2

# Testar compilação OpenMP
gcc -fopenmp -x c /dev/null -o /dev/null
```

### Resultados inconsistentes
- Execute várias vezes para aquecer cache
- Feche outros programas durante benchmark
- Use `taskset` para fixar em núcleos específicos:
```bash
taskset -c 0-3 ./build/recommender_omp data/ratings_medium.txt 4
```

### Gráficos não são gerados
```bash
pip3 install matplotlib
# Se usar SSH, configure X11 forwarding ou backend:
export MPLBACKEND=Agg
```

## Estrutura de Arquivos

```
ppc/
├── Makefile              # Build automation
├── README.md             # Documentação principal
├── INSTRUCTIONS.md       # Este arquivo
├── run.sh               # Script de execução interativo
├── src/
│   ├── sequential/      # Versão sequencial
│   ├── openmp/          # Versão OpenMP
│   ├── pthreads/        # Versão Pthreads
│   └── mpi/             # Versão MPI
├── scripts/
│   ├── generate_data.py      # Gerador de dados
│   ├── run_benchmark.sh      # Script de benchmark
│   └── analyze_results.py    # Análise e gráficos
├── data/                # Datasets gerados
├── results/             # Resultados dos experimentos
├── docs/
│   ├── relatorio.tex    # Relatório completo
│   └── sbc-template.sty # Template SBC
└── build/               # Executáveis compilados
```

## Métricas Calculadas

### Speedup
$$S_p = \frac{T_1}{T_p}$$

Onde:
- $T_1$ = tempo com 1 processador (sequencial)
- $T_p$ = tempo com p processadores

### Eficiência
$$E_p = \frac{S_p}{p}$$

### Karp-Flatt (Fração Serial)
$$e = \frac{\frac{1}{S_p} - \frac{1}{p}}{1 - \frac{1}{p}}$$

### Intervalo de Confiança (95%)
$$IC = \bar{x} \pm t_{0.025,n-1} \cdot \frac{s}{\sqrt{n}}$$

Para n=10 execuções: $t_{0.025,9} = 2.262$

## Dicas de Otimização

### Para melhor desempenho:

1. **Compilação**: Use `-O3 -march=native`
2. **NUMA**: Configure `numactl` para controlar alocação
3. **Threads**: Experimente com HyperThreading on/off
4. **Dataset**: Maior = melhor amortização de overhead
5. **Scheduling**: Teste diferentes políticas OpenMP

### Exemplo com otimizações máximas:
```bash
# Compilar com otimizações nativas
gcc -O3 -march=native -fopenmp recommender_omp.c -o recommender -lm

# Executar com afinidade de CPU
OMP_PROC_BIND=true OMP_PLACES=cores ./recommender data.txt 4
```

## Referências

- [OpenMP Documentation](https://www.openmp.org/specifications/)
- [MPI Tutorial](https://mpitutorial.com/)
- [POSIX Threads Guide](https://computing.llnl.gov/tutorials/pthreads/)
- [Template SBC](https://www.sbc.org.br/documentos-da-sbc/category/169-templates-para-artigos-e-capitulos-de-livros)

## Suporte

Para dúvidas ou problemas:
1. Verifique esta documentação
2. Consulte o README.md
3. Revise os comentários no código fonte
4. Execute `make help` para ver alvos disponíveis
