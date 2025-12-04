#!/bin/bash
# Script de Benchmark - Executa experimentos e coleta métricas de desempenho
# Executa cada versão 10 vezes e calcula médias, speedup, eficiência, etc.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
RESULTS_DIR="$PROJECT_ROOT/results"
DATA_DIR="$PROJECT_ROOT/data"

# Criar diretório de resultados
mkdir -p "$RESULTS_DIR"

# Configurações
NUM_RUNS=10
DATA_FILE="$DATA_DIR/ratings_medium.txt"
THREADS_ARRAY=(1 2 4 8)

echo "======================================"
echo "Benchmark - Sistema de Recomendação"
echo "======================================"
echo ""
echo "Configurações:"
echo "  Número de execuções: $NUM_RUNS"
echo "  Arquivo de dados: $DATA_FILE"
echo "  Threads/Processos: ${THREADS_ARRAY[@]}"
echo ""

# Verificar se o arquivo de dados existe
if [ ! -f "$DATA_FILE" ]; then
    echo "Erro: Arquivo de dados não encontrado: $DATA_FILE"
    echo "Execute: cd scripts && python3 generate_data.py medium"
    exit 1
fi

# Função para extrair tempo de execução da saída
extract_time() {
    local result=$(grep "Tempo de execução:" | awk '{print $4}')
    if [ -z "$result" ]; then
        echo "0.0001"  # Valor mínimo para evitar divisão por zero
    else
        echo "$result"
    fi
}

# Função para calcular estatísticas
# Uso: calculate_stats "valor1 valor2 valor3 ..."
calculate_stats() {
    local data="$1"
    python3 -c "
import math
import sys

data_str = '''$data'''
times = [float(x) for x in data_str.strip().split() if x]

if len(times) == 0:
    print('0.0001 0.0000 0.0001 0.0001')
    sys.exit(0)

n = len(times)
mean = sum(times) / n

if n > 1:
    variance = sum((x - mean) ** 2 for x in times) / (n - 1)
    stddev = math.sqrt(variance)
else:
    stddev = 0.0

# Intervalo de confiança 95% (distribuição t)
t_value = 2.262  # Para 9 graus de liberdade (n-1 = 10-1)
margin = t_value * stddev / math.sqrt(n) if n > 0 else 0
ci_lower = mean - margin
ci_upper = mean + margin

print(f'{mean:.4f} {stddev:.4f} {ci_lower:.4f} {ci_upper:.4f}')
"
}

# ====================
# 1. VERSÃO SEQUENCIAL
# ====================
echo ">>> Executando versão SEQUENCIAL"
SEQ_EXEC="$PROJECT_ROOT/build/recommender_seq"

# Tentar executável alternativo se não existir no build/
if [ ! -f "$SEQ_EXEC" ]; then
    SEQ_EXEC="$PROJECT_ROOT/src/sequential/recommender"
fi

if [ ! -f "$SEQ_EXEC" ]; then
    echo "Compilando versão sequencial..."
    cd "$PROJECT_ROOT/src/sequential"
    gcc -O3 -o recommender recommender.c -lm
    cd "$SCRIPT_DIR"
fi

SEQ_TIMES=()
for i in $(seq 1 $NUM_RUNS); do
    echo "  Execução $i/$NUM_RUNS..."
    TIME=$("$SEQ_EXEC" "$DATA_FILE" 2>/dev/null | extract_time)
    SEQ_TIMES+=($TIME)
    echo "    Tempo: ${TIME}s"
done

# Calcular estatísticas
echo "${SEQ_TIMES[@]}" | tr ' ' '\n' > "$RESULTS_DIR/sequential_times.txt"
SEQ_STATS=$(calculate_stats "${SEQ_TIMES[*]}")
SEQ_MEAN=$(echo $SEQ_STATS | awk '{print $1}')
SEQ_STDDEV=$(echo $SEQ_STATS | awk '{print $2}')
SEQ_CI_LOWER=$(echo $SEQ_STATS | awk '{print $3}')
SEQ_CI_UPPER=$(echo $SEQ_STATS | awk '{print $4}')

echo "  Média: ${SEQ_MEAN}s"
echo "  Desvio padrão: ${SEQ_STDDEV}s"
echo "  IC 95%: [${SEQ_CI_LOWER}, ${SEQ_CI_UPPER}]"
echo ""

# ====================
# 2. VERSÃO OPENMP
# ====================
echo ">>> Executando versão OPENMP"
OMP_EXEC="$PROJECT_ROOT/build/recommender_omp"

# Tentar executável alternativo se não existir no build/
if [ ! -f "$OMP_EXEC" ]; then
    OMP_EXEC="$PROJECT_ROOT/src/openmp/recommender_omp"
fi

if [ ! -f "$OMP_EXEC" ]; then
    echo "Compilando versão OpenMP..."
    cd "$PROJECT_ROOT/src/openmp"
    gcc -O3 -fopenmp -o recommender_omp recommender_omp.c -lm
    cd "$SCRIPT_DIR"
fi

for THREADS in "${THREADS_ARRAY[@]}"; do
    echo "  Threads: $THREADS"
    OMP_TIMES=()
    
    for i in $(seq 1 $NUM_RUNS); do
        echo "    Execução $i/$NUM_RUNS..."
        TIME=$("$OMP_EXEC" "$DATA_FILE" "$THREADS" 2>/dev/null | extract_time)
        OMP_TIMES+=($TIME)
        echo "      Tempo: ${TIME}s"
    done
    
    echo "${OMP_TIMES[@]}" | tr ' ' '\n' > "$RESULTS_DIR/openmp_${THREADS}t_times.txt"
    OMP_STATS=$(calculate_stats "${OMP_TIMES[*]}")
    OMP_MEAN=$(echo $OMP_STATS | awk '{print $1}')
    OMP_STDDEV=$(echo $OMP_STATS | awk '{print $2}')
    
    # Calcular speedup e eficiência (com validação)
    if [ -n "$SEQ_MEAN" ] && [ -n "$OMP_MEAN" ] && [ "$OMP_MEAN" != "0" ] && [ "$OMP_MEAN" != "0.0000" ]; then
        SPEEDUP=$(python3 -c "seq=$SEQ_MEAN; omp=$OMP_MEAN; print(f'{seq/omp:.4f}' if omp > 0 else 'N/A')")
        EFFICIENCY=$(python3 -c "seq=$SEQ_MEAN; omp=$OMP_MEAN; t=$THREADS; print(f'{(seq/omp)/t:.4f}' if omp > 0 else 'N/A')")
    else
        SPEEDUP="N/A"
        EFFICIENCY="N/A"
    fi
    
    echo "    Média: ${OMP_MEAN:-N/A}s"
    echo "    Speedup: ${SPEEDUP}x"
    echo "    Eficiência: ${EFFICIENCY}"
    echo ""
done

# ====================
# 3. VERSÃO PTHREADS
# ====================
echo ">>> Executando versão PTHREADS"
PTH_EXEC="$PROJECT_ROOT/build/recommender_pthread"

# Tentar executável alternativo se não existir no build/
if [ ! -f "$PTH_EXEC" ]; then
    PTH_EXEC="$PROJECT_ROOT/src/pthreads/recommender_pthread"
fi

if [ ! -f "$PTH_EXEC" ]; then
    echo "Compilando versão Pthreads..."
    cd "$PROJECT_ROOT/src/pthreads"
    gcc -O3 -pthread -o recommender_pthread recommender_pthread.c -lm
    cd "$SCRIPT_DIR"
fi

for THREADS in "${THREADS_ARRAY[@]}"; do
    echo "  Threads: $THREADS"
    PTH_TIMES=()
    
    for i in $(seq 1 $NUM_RUNS); do
        echo "    Execução $i/$NUM_RUNS..."
        TIME=$("$PTH_EXEC" "$DATA_FILE" "$THREADS" 2>/dev/null | extract_time)
        PTH_TIMES+=($TIME)
        echo "      Tempo: ${TIME}s"
    done
    
    echo "${PTH_TIMES[@]}" | tr ' ' '\n' > "$RESULTS_DIR/pthreads_${THREADS}t_times.txt"
    PTH_STATS=$(calculate_stats "${PTH_TIMES[*]}")
    PTH_MEAN=$(echo $PTH_STATS | awk '{print $1}')
    PTH_STDDEV=$(echo $PTH_STATS | awk '{print $2}')
    
    # Calcular speedup e eficiência (com validação)
    if [ -n "$SEQ_MEAN" ] && [ -n "$PTH_MEAN" ] && [ "$PTH_MEAN" != "0" ] && [ "$PTH_MEAN" != "0.0000" ]; then
        SPEEDUP=$(python3 -c "seq=$SEQ_MEAN; pth=$PTH_MEAN; print(f'{seq/pth:.4f}' if pth > 0 else 'N/A')")
        EFFICIENCY=$(python3 -c "seq=$SEQ_MEAN; pth=$PTH_MEAN; t=$THREADS; print(f'{(seq/pth)/t:.4f}' if pth > 0 else 'N/A')")
    else
        SPEEDUP="N/A"
        EFFICIENCY="N/A"
    fi
    
    echo "    Média: ${PTH_MEAN:-N/A}s"
    echo "    Speedup: ${SPEEDUP}x"
    echo "    Eficiência: ${EFFICIENCY}"
    echo ""
done

# ====================
# 4. VERSÃO MPI
# ====================
echo ">>> Executando versão MPI"
MPI_EXEC="$PROJECT_ROOT/build/recommender_mpi"

# Tentar executável alternativo se não existir no build/
if [ ! -f "$MPI_EXEC" ]; then
    MPI_EXEC="$PROJECT_ROOT/src/mpi/recommender_mpi"
fi

if [ ! -f "$MPI_EXEC" ]; then
    echo "Compilando versão MPI..."
    cd "$PROJECT_ROOT/src/mpi"
    mpicc -O3 -o recommender_mpi recommender_mpi.c -lm
    cd "$SCRIPT_DIR"
fi

for PROCS in "${THREADS_ARRAY[@]}"; do
    echo "  Processos: $PROCS"
    MPI_TIMES=()
    
    for i in $(seq 1 $NUM_RUNS); do
        echo "    Execução $i/$NUM_RUNS..."
        TIME=$(mpirun -np "$PROCS" "$MPI_EXEC" "$DATA_FILE" 2>/dev/null | extract_time)
        MPI_TIMES+=($TIME)
        echo "      Tempo: ${TIME}s"
    done
    
    echo "${MPI_TIMES[@]}" | tr ' ' '\n' > "$RESULTS_DIR/mpi_${PROCS}p_times.txt"
    MPI_STATS=$(calculate_stats "${MPI_TIMES[*]}")
    MPI_MEAN=$(echo $MPI_STATS | awk '{print $1}')
    MPI_STDDEV=$(echo $MPI_STATS | awk '{print $2}')
    
    # Calcular speedup e eficiência (com validação)
    if [ -n "$SEQ_MEAN" ] && [ -n "$MPI_MEAN" ] && [ "$MPI_MEAN" != "0" ] && [ "$MPI_MEAN" != "0.0000" ]; then
        SPEEDUP=$(python3 -c "seq=$SEQ_MEAN; mpi=$MPI_MEAN; print(f'{seq/mpi:.4f}' if mpi > 0 else 'N/A')")
        EFFICIENCY=$(python3 -c "seq=$SEQ_MEAN; mpi=$MPI_MEAN; p=$PROCS; print(f'{(seq/mpi)/p:.4f}' if mpi > 0 else 'N/A')")
    else
        SPEEDUP="N/A"
        EFFICIENCY="N/A"
    fi
    
    echo "    Média: ${MPI_MEAN:-N/A}s"
    echo "    Speedup: ${SPEEDUP}x"
    echo "    Eficiência: ${EFFICIENCY}"
    echo ""
done

echo "======================================"
echo "Benchmark concluído!"
echo "Resultados salvos em: $RESULTS_DIR"
echo "======================================"
