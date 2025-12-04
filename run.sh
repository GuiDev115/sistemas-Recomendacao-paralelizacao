#!/bin/bash
# Script completo de execução - Setup, compilação, geração de dados e testes

set -e  # Sair em caso de erro

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "================================================"
echo "Sistema de Recomendação Paralelo - Amazon"
echo "Projeto de Paralelização e Concorrência"
echo "================================================"
echo ""

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Função para imprimir com cor
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_info() {
    echo -e "${YELLOW}[i]${NC} $1"
}

# 1. Verificar dependências
echo "=== Verificando Dependências ==="
echo ""

check_command() {
    if command -v $1 &> /dev/null; then
        print_status "$1 encontrado: $(command -v $1)"
        return 0
    else
        print_error "$1 não encontrado!"
        return 1
    fi
}

MISSING_DEPS=0

check_command gcc || MISSING_DEPS=1
check_command mpicc || MISSING_DEPS=1
check_command python3 || MISSING_DEPS=1

# Verificar suporte a OpenMP
if gcc -fopenmp -x c /dev/null -o /dev/null 2>/dev/null; then
    print_status "Suporte a OpenMP verificado"
else
    print_error "GCC sem suporte a OpenMP!"
    MISSING_DEPS=1
fi

# Verificar bibliotecas Python
python3 -c "import numpy, matplotlib" 2>/dev/null
if [ $? -eq 0 ]; then
    print_status "Bibliotecas Python (numpy, matplotlib) encontradas"
else
    print_error "Bibliotecas Python faltando!"
    print_info "Instale com: pip3 install numpy matplotlib"
    MISSING_DEPS=1
fi

echo ""

if [ $MISSING_DEPS -eq 1 ]; then
    print_error "Dependências faltando! Instale-as antes de continuar."
    exit 1
fi

# 2. Compilar programas
echo "=== Compilando Programas ==="
echo ""

make clean > /dev/null 2>&1
make all

if [ $? -eq 0 ]; then
    print_status "Todos os programas compilados com sucesso!"
else
    print_error "Erro na compilação!"
    exit 1
fi

echo ""

# 3. Gerar dados de teste
echo "=== Gerando Dados de Teste ==="
echo ""

chmod +x scripts/generate_data.py

cd scripts
python3 generate_data.py small
python3 generate_data.py medium
cd ..

print_status "Dados gerados com sucesso!"
echo ""

# 4. Executar testes básicos
echo "=== Executando Testes Básicos ==="
echo ""

print_info "Testando versão sequencial..."
build/recommender_seq data/ratings_small.txt > /dev/null 2>&1
if [ $? -eq 0 ]; then
    print_status "Sequencial: OK"
else
    print_error "Sequencial: FALHOU"
fi

print_info "Testando versão OpenMP..."
build/recommender_omp data/ratings_small.txt 2 > /dev/null 2>&1
if [ $? -eq 0 ]; then
    print_status "OpenMP: OK"
else
    print_error "OpenMP: FALHOU"
fi

print_info "Testando versão Pthreads..."
build/recommender_pthread data/ratings_small.txt 2 > /dev/null 2>&1
if [ $? -eq 0 ]; then
    print_status "Pthreads: OK"
else
    print_error "Pthreads: FALHOU"
fi

print_info "Testando versão MPI..."
mpirun -np 2 build/recommender_mpi data/ratings_small.txt > /dev/null 2>&1
if [ $? -eq 0 ]; then
    print_status "MPI: OK"
else
    print_error "MPI: FALHOU"
fi

echo ""

# 5. Menu interativo
while true; do
    echo "================================================"
    echo "O que você deseja fazer?"
    echo "================================================"
    echo "1) Executar benchmark completo (10 execuções de cada)"
    echo "2) Executar teste rápido (1 execução de cada)"
    echo "3) Gerar mais dados (large/xlarge)"
    echo "4) Analisar resultados existentes"
    echo "5) Compilar relatório LaTeX"
    echo "6) Limpar arquivos"
    echo "7) Sair"
    echo ""
    read -p "Escolha uma opção [1-7]: " choice

    case $choice in
        1)
            echo ""
            print_info "Executando benchmark completo..."
            print_info "Isso pode levar vários minutos..."
            chmod +x scripts/run_benchmark.sh
            ./scripts/run_benchmark.sh
            
            print_info "Analisando resultados..."
            python3 scripts/analyze_results.py
            
            print_status "Benchmark concluído! Veja os resultados em results/"
            ;;
        2)
            echo ""
            print_info "Executando teste rápido com dataset medium..."
            
            echo ">>> Sequencial"
            build/recommender_seq data/ratings_medium.txt
            
            echo ""
            echo ">>> OpenMP (4 threads)"
            build/recommender_omp data/ratings_medium.txt 4
            
            echo ""
            echo ">>> Pthreads (4 threads)"
            build/recommender_pthread data/ratings_medium.txt 4
            
            echo ""
            echo ">>> MPI (4 processos)"
            mpirun -np 4 build/recommender_mpi data/ratings_medium.txt
            
            print_status "Teste rápido concluído!"
            ;;
        3)
            echo ""
            print_info "Gerando datasets adicionais..."
            cd scripts
            python3 generate_data.py large
            python3 generate_data.py xlarge
            cd ..
            print_status "Dados gerados!"
            ;;
        4)
            echo ""
            if [ ! -d "results" ] || [ -z "$(ls -A results)" ]; then
                print_error "Nenhum resultado encontrado! Execute o benchmark primeiro."
            else
                print_info "Analisando resultados..."
                python3 scripts/analyze_results.py
                print_status "Análise concluída!"
            fi
            ;;
        5)
            echo ""
            print_info "Compilando relatório LaTeX..."
            if command -v pdflatex &> /dev/null; then
                cd docs
                pdflatex relatorio.tex > /dev/null 2>&1
                pdflatex relatorio.tex > /dev/null 2>&1
                cd ..
                print_status "Relatório gerado: docs/relatorio.pdf"
            else
                print_error "pdflatex não encontrado! Instale TeXLive ou MiKTeX."
            fi
            ;;
        6)
            echo ""
            read -p "Limpar tudo (dados e resultados)? [s/N]: " confirm
            if [[ $confirm == [sS] ]]; then
                make cleanall
                print_status "Limpeza completa!"
            else
                make clean
                print_status "Arquivos compilados removidos!"
            fi
            ;;
        7)
            echo ""
            print_info "Encerrando..."
            exit 0
            ;;
        *)
            print_error "Opção inválida!"
            ;;
    esac
    
    echo ""
    read -p "Pressione ENTER para continuar..."
    clear
done
