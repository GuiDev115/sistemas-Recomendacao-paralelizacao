# Makefile principal - Sistema de Recomendação Paralelo

# Compiladores e flags
CC = gcc
MPICC = mpicc
CFLAGS = -O3 -Wall
LDFLAGS = -lm

# Diretórios
SRC_DIR = src
BUILD_DIR = build
DATA_DIR = data
RESULTS_DIR = results

# Executáveis
SEQ_TARGET = $(BUILD_DIR)/recommender_seq
OMP_TARGET = $(BUILD_DIR)/recommender_omp
PTH_TARGET = $(BUILD_DIR)/recommender_pthread
MPI_TARGET = $(BUILD_DIR)/recommender_mpi

# Fontes
SEQ_SRC = $(SRC_DIR)/sequential/recommender.c
OMP_SRC = $(SRC_DIR)/openmp/recommender_omp.c
PTH_SRC = $(SRC_DIR)/pthreads/recommender_pthread.c
MPI_SRC = $(SRC_DIR)/mpi/recommender_mpi.c

.PHONY: all clean sequential openmp pthreads mpi dirs test help

# Alvo padrão
all: dirs sequential openmp pthreads mpi

# Criar diretórios necessários
dirs:
	@mkdir -p $(BUILD_DIR) $(DATA_DIR) $(RESULTS_DIR)

# Compilar versão sequencial
sequential: dirs
	@echo "Compilando versão sequencial..."
	$(CC) $(CFLAGS) $(SEQ_SRC) -o $(SEQ_TARGET) $(LDFLAGS)
	@echo "✓ Sequencial compilado: $(SEQ_TARGET)"

# Compilar versão OpenMP
openmp: dirs
	@echo "Compilando versão OpenMP..."
	$(CC) $(CFLAGS) -fopenmp $(OMP_SRC) -o $(OMP_TARGET) $(LDFLAGS)
	@echo "✓ OpenMP compilado: $(OMP_TARGET)"

# Compilar versão Pthreads
pthreads: dirs
	@echo "Compilando versão Pthreads..."
	$(CC) $(CFLAGS) -pthread $(PTH_SRC) -o $(PTH_TARGET) $(LDFLAGS)
	@echo "✓ Pthreads compilado: $(PTH_TARGET)"

# Compilar versão MPI
mpi: dirs
	@echo "Compilando versão MPI..."
	$(MPICC) $(CFLAGS) $(MPI_SRC) -o $(MPI_TARGET) $(LDFLAGS)
	@echo "✓ MPI compilado: $(MPI_TARGET)"

# Gerar dados de teste
data: dirs
	@echo "Gerando dados de teste..."
	@python3 scripts/generate_data.py small
	@python3 scripts/generate_data.py medium
	@python3 scripts/generate_data.py large
	@echo "✓ Dados gerados em $(DATA_DIR)/"

# Executar testes básicos
test: all data
	@echo "Executando testes básicos..."
	@echo "\n=== Sequencial ==="
	$(SEQ_TARGET) $(DATA_DIR)/ratings_small.txt
	@echo "\n=== OpenMP (4 threads) ==="
	$(OMP_TARGET) $(DATA_DIR)/ratings_small.txt 4
	@echo "\n=== Pthreads (4 threads) ==="
	$(PTH_TARGET) $(DATA_DIR)/ratings_small.txt 4
	@echo "\n=== MPI (4 processos) ==="
	mpirun -np 4 $(MPI_TARGET) $(DATA_DIR)/ratings_small.txt

# Executar benchmark completo
benchmark: all data
	@echo "Executando benchmark completo..."
	@chmod +x scripts/run_benchmark.sh
	@./scripts/run_benchmark.sh

# Analisar resultados
analyze:
	@echo "Analisando resultados..."
	@python3 scripts/analyze_results.py

# Compilar relatório LaTeX
report:
	@echo "Compilando relatório..."
	@cd docs && pdflatex relatorio.tex
	@cd docs && pdflatex relatorio.tex
	@echo "✓ Relatório gerado: docs/relatorio.pdf"

# Limpar arquivos compilados
clean:
	@echo "Limpando arquivos compilados..."
	rm -rf $(BUILD_DIR)
	rm -f $(SRC_DIR)/sequential/recommender
	rm -f $(SRC_DIR)/openmp/recommender_omp
	rm -f $(SRC_DIR)/pthreads/recommender_pthread
	rm -f $(SRC_DIR)/mpi/recommender_mpi
	@echo "✓ Limpeza concluída"

# Limpar tudo (incluindo dados e resultados)
cleanall: clean
	@echo "Limpando todos os arquivos gerados..."
	rm -rf $(DATA_DIR)/* $(RESULTS_DIR)/*
	rm -f docs/*.aux docs/*.log docs/*.pdf docs/*.bbl docs/*.blg
	@echo "✓ Limpeza completa concluída"

# Ajuda
help:
	@echo "Sistema de Recomendação Paralelo - Makefile"
	@echo ""
	@echo "Alvos disponíveis:"
	@echo "  make all        - Compila todas as versões"
	@echo "  make sequential - Compila versão sequencial"
	@echo "  make openmp     - Compila versão OpenMP"
	@echo "  make pthreads   - Compila versão Pthreads"
	@echo "  make mpi        - Compila versão MPI"
	@echo "  make data       - Gera dados de teste"
	@echo "  make test       - Executa testes básicos"
	@echo "  make benchmark  - Executa benchmark completo"
	@echo "  make analyze    - Analisa resultados do benchmark"
	@echo "  make report     - Compila relatório LaTeX"
	@echo "  make clean      - Remove arquivos compilados"
	@echo "  make cleanall   - Remove tudo (incluindo dados/resultados)"
	@echo "  make help       - Exibe esta mensagem"
