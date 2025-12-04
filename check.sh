#!/bin/bash
# Script de verificação - Testa se tudo está funcionando corretamente

echo "=========================================="
echo "Verificação do Projeto"
echo "=========================================="
echo ""

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0

check() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $1"
    else
        echo -e "${RED}✗${NC} $1"
        ((ERRORS++))
    fi
}

echo "1. Verificando estrutura de diretórios..."
[ -d "src/sequential" ] && echo -e "${GREEN}✓${NC} src/sequential/" || { echo -e "${RED}✗${NC} src/sequential/"; ((ERRORS++)); }
[ -d "src/openmp" ] && echo -e "${GREEN}✓${NC} src/openmp/" || { echo -e "${RED}✗${NC} src/openmp/"; ((ERRORS++)); }
[ -d "src/pthreads" ] && echo -e "${GREEN}✓${NC} src/pthreads/" || { echo -e "${RED}✗${NC} src/pthreads/"; ((ERRORS++)); }
[ -d "src/mpi" ] && echo -e "${GREEN}✓${NC} src/mpi/" || { echo -e "${RED}✗${NC} src/mpi/"; ((ERRORS++)); }
[ -d "scripts" ] && echo -e "${GREEN}✓${NC} scripts/" || { echo -e "${RED}✗${NC} scripts/"; ((ERRORS++)); }
[ -d "docs" ] && echo -e "${GREEN}✓${NC} docs/" || { echo -e "${RED}✗${NC} docs/"; ((ERRORS++)); }
echo ""

echo "2. Verificando arquivos fonte..."
[ -f "src/sequential/recommender.c" ]; check "recommender.c (sequencial)"
[ -f "src/openmp/recommender_omp.c" ]; check "recommender_omp.c"
[ -f "src/pthreads/recommender_pthread.c" ]; check "recommender_pthread.c"
[ -f "src/mpi/recommender_mpi.c" ]; check "recommender_mpi.c"
echo ""

echo "3. Verificando scripts..."
[ -f "scripts/generate_data.py" ]; check "generate_data.py"
[ -f "scripts/run_benchmark.sh" ]; check "run_benchmark.sh"
[ -f "scripts/analyze_results.py" ]; check "analyze_results.py"
[ -x "scripts/generate_data.py" ]; check "generate_data.py (executável)"
[ -x "scripts/run_benchmark.sh" ]; check "run_benchmark.sh (executável)"
[ -x "scripts/analyze_results.py" ]; check "analyze_results.py (executável)"
echo ""

echo "4. Verificando documentação..."
[ -f "README.md" ]; check "README.md"
[ -f "INSTRUCTIONS.md" ]; check "INSTRUCTIONS.md"
[ -f "Makefile" ]; check "Makefile"
[ -f "docs/relatorio.tex" ]; check "relatorio.tex"
[ -f "docs/sbc-template.sty" ]; check "sbc-template.sty"
echo ""

echo "5. Verificando ferramentas do sistema..."
command -v gcc > /dev/null 2>&1; check "gcc"
command -v mpicc > /dev/null 2>&1; check "mpicc"
command -v python3 > /dev/null 2>&1; check "python3"
command -v make > /dev/null 2>&1; check "make"
echo ""

echo "6. Verificando suporte OpenMP..."
echo "int main(){return 0;}" | gcc -fopenmp -x c - -o /tmp/test_omp 2>/dev/null; check "Suporte OpenMP no GCC"
rm -f /tmp/test_omp 2>/dev/null
echo ""

echo "7. Verificando bibliotecas Python..."
python3 -c "import numpy" 2>/dev/null; check "numpy"
python3 -c "import matplotlib" 2>/dev/null; check "matplotlib"
echo ""

echo "=========================================="
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✓ Tudo OK! Pronto para usar.${NC}"
    echo ""
    echo "Próximos passos:"
    echo "  1. Compilar: make all"
    echo "  2. Gerar dados: make data"
    echo "  3. Testar: make test"
    echo "  4. Benchmark: make benchmark"
    echo "  5. Analisar: make analyze"
    echo ""
    echo "Ou use o script interativo: ./run.sh"
else
    echo -e "${RED}✗ Encontrados $ERRORS erros!${NC}"
    echo ""
    echo "Instale dependências faltantes:"
    echo "  sudo apt install build-essential openmpi-bin libopenmpi-dev"
    echo "  pip3 install numpy matplotlib"
fi
echo "=========================================="
