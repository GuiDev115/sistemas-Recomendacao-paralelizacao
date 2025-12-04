#!/usr/bin/env python3
"""
Script de Análise de Resultados
Calcula speedup, eficiência e métrica de Karp-Flatt
Gera gráficos dos resultados
"""

import os
import sys
import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path

def load_times(filename):
    """Carrega tempos de execução de um arquivo"""
    with open(filename, 'r') as f:
        times = [float(line.strip()) for line in f if line.strip()]
    return times

def calculate_statistics(times):
    """Calcula estatísticas dos tempos"""
    times = np.array(times)
    mean = np.mean(times)
    std = np.std(times, ddof=1)
    
    # Intervalo de confiança 95% (t-student com 9 graus de liberdade)
    t_value = 2.262
    margin = t_value * std / np.sqrt(len(times))
    ci_lower = mean - margin
    ci_upper = mean + margin
    
    return {
        'mean': mean,
        'std': std,
        'ci_lower': ci_lower,
        'ci_upper': ci_upper,
        'margin': margin
    }

def calculate_karp_flatt(speedup, num_processors):
    """
    Calcula a métrica de Karp-Flatt (fração serial experimentalmente estimada)
    e = (1/speedup - 1/p) / (1 - 1/p)
    """
    if speedup == 0 or num_processors == 1:
        return None
    
    numerator = (1.0 / speedup) - (1.0 / num_processors)
    denominator = 1.0 - (1.0 / num_processors)
    
    if denominator == 0:
        return None
    
    return numerator / denominator

def analyze_results(results_dir):
    """Analisa todos os resultados"""
    results_path = Path(results_dir)
    
    # Carregar tempo sequencial
    seq_file = results_path / 'sequential_times.txt'
    if not seq_file.exists():
        print(f"Erro: Arquivo não encontrado: {seq_file}")
        return None
    
    seq_times = load_times(seq_file)
    seq_stats = calculate_statistics(seq_times)
    seq_mean = seq_stats['mean']
    
    print("=" * 60)
    print("ANÁLISE DE RESULTADOS - Sistema de Recomendação")
    print("=" * 60)
    print(f"\nTempo Sequencial:")
    print(f"  Média: {seq_mean:.4f}s")
    print(f"  Desvio Padrão: {seq_stats['std']:.4f}s")
    print(f"  IC 95%: [{seq_stats['ci_lower']:.4f}, {seq_stats['ci_upper']:.4f}]")
    print()
    
    # Analisar cada versão paralela
    versions = ['openmp', 'pthreads', 'mpi']
    thread_counts = [1, 2, 4, 8]
    
    results = {}
    
    for version in versions:
        print(f"\n{'=' * 60}")
        print(f"Versão: {version.upper()}")
        print(f"{'=' * 60}")
        
        results[version] = {
            'threads': [],
            'mean_time': [],
            'speedup': [],
            'efficiency': [],
            'karp_flatt': [],
            'ci_margin': []
        }
        
        for threads in thread_counts:
            suffix = 't' if version != 'mpi' else 'p'
            filename = f"{version}_{threads}{suffix}_times.txt"
            filepath = results_path / filename
            
            if not filepath.exists():
                print(f"  Arquivo não encontrado: {filename}")
                continue
            
            times = load_times(filepath)
            stats = calculate_statistics(times)
            
            mean_time = stats['mean']
            speedup = seq_mean / mean_time
            efficiency = speedup / threads
            karp_flatt = calculate_karp_flatt(speedup, threads)
            
            results[version]['threads'].append(threads)
            results[version]['mean_time'].append(mean_time)
            results[version]['speedup'].append(speedup)
            results[version]['efficiency'].append(efficiency)
            results[version]['karp_flatt'].append(karp_flatt if karp_flatt else 0)
            results[version]['ci_margin'].append(stats['margin'])
            
            print(f"\n{threads} Threads/Processos:")
            print(f"  Tempo Médio: {mean_time:.4f}s (±{stats['margin']:.4f})")
            print(f"  Speedup: {speedup:.4f}x")
            print(f"  Eficiência: {efficiency:.4f} ({efficiency*100:.2f}%)")
            if karp_flatt:
                print(f"  Karp-Flatt (e): {karp_flatt:.6f}")
    
    return results, seq_mean

def plot_results(results, seq_mean, output_dir):
    """Gera gráficos dos resultados"""
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)
    
    versions = ['openmp', 'pthreads', 'mpi']
    colors = {'openmp': 'blue', 'pthreads': 'green', 'mpi': 'red'}
    labels = {'openmp': 'OpenMP', 'pthreads': 'Pthreads', 'mpi': 'MPI'}
    
    # Configurar estilo
    plt.rcParams['figure.figsize'] = (10, 6)
    plt.rcParams['font.size'] = 10
    
    # 1. Gráfico de Tempo de Execução
    plt.figure()
    for version in versions:
        if version in results and results[version]['threads']:
            plt.plot(results[version]['threads'], 
                    results[version]['mean_time'],
                    'o-', color=colors[version], label=labels[version], linewidth=2)
            
            # Barras de erro (intervalo de confiança)
            plt.errorbar(results[version]['threads'], 
                        results[version]['mean_time'],
                        yerr=results[version]['ci_margin'],
                        fmt='none', color=colors[version], alpha=0.3, capsize=5)
    
    plt.axhline(y=seq_mean, color='black', linestyle='--', label='Sequencial', linewidth=1.5)
    plt.xlabel('Número de Threads/Processos')
    plt.ylabel('Tempo de Execução (segundos)')
    plt.title('Tempo de Execução vs Número de Threads/Processos')
    plt.legend()
    plt.grid(True, alpha=0.3)
    plt.xticks(results[versions[0]]['threads'])
    plt.savefig(output_path / 'execution_time.png', dpi=300, bbox_inches='tight')
    print(f"\nGráfico salvo: {output_path / 'execution_time.png'}")
    
    # 2. Gráfico de Speedup
    plt.figure()
    for version in versions:
        if version in results and results[version]['threads']:
            plt.plot(results[version]['threads'], 
                    results[version]['speedup'],
                    'o-', color=colors[version], label=labels[version], linewidth=2)
    
    # Speedup ideal (linear)
    max_threads = max(results[versions[0]]['threads'])
    plt.plot([1, max_threads], [1, max_threads], 'k--', 
            label='Speedup Ideal', linewidth=1.5)
    
    plt.xlabel('Número de Threads/Processos')
    plt.ylabel('Speedup')
    plt.title('Speedup vs Número de Threads/Processos')
    plt.legend()
    plt.grid(True, alpha=0.3)
    plt.xticks(results[versions[0]]['threads'])
    plt.savefig(output_path / 'speedup.png', dpi=300, bbox_inches='tight')
    print(f"Gráfico salvo: {output_path / 'speedup.png'}")
    
    # 3. Gráfico de Eficiência
    plt.figure()
    for version in versions:
        if version in results and results[version]['threads']:
            plt.plot(results[version]['threads'], 
                    results[version]['efficiency'],
                    'o-', color=colors[version], label=labels[version], linewidth=2)
    
    plt.axhline(y=1.0, color='black', linestyle='--', 
               label='Eficiência Ideal', linewidth=1.5)
    
    plt.xlabel('Número de Threads/Processos')
    plt.ylabel('Eficiência')
    plt.title('Eficiência vs Número de Threads/Processos')
    plt.legend()
    plt.grid(True, alpha=0.3)
    plt.xticks(results[versions[0]]['threads'])
    plt.ylim([0, 1.1])
    plt.savefig(output_path / 'efficiency.png', dpi=300, bbox_inches='tight')
    print(f"Gráfico salvo: {output_path / 'efficiency.png'}")
    
    # 4. Gráfico de Karp-Flatt
    plt.figure()
    for version in versions:
        if version in results and results[version]['threads']:
            # Remover valores para 1 thread (não aplicável)
            threads_filtered = [t for t in results[version]['threads'] if t > 1]
            kf_filtered = [kf for t, kf in zip(results[version]['threads'], 
                                                results[version]['karp_flatt']) if t > 1]
            
            if threads_filtered:
                plt.plot(threads_filtered, kf_filtered,
                        'o-', color=colors[version], label=labels[version], linewidth=2)
    
    plt.xlabel('Número de Threads/Processos')
    plt.ylabel('Fração Serial (e)')
    plt.title('Métrica de Karp-Flatt - Fração Serial')
    plt.legend()
    plt.grid(True, alpha=0.3)
    plt.savefig(output_path / 'karp_flatt.png', dpi=300, bbox_inches='tight')
    print(f"Gráfico salvo: {output_path / 'karp_flatt.png'}")
    
    plt.close('all')

def generate_latex_table(results, seq_mean, output_dir):
    """Gera tabela LaTeX com os resultados"""
    output_path = Path(output_dir)
    
    with open(output_path / 'results_table.tex', 'w') as f:
        f.write("\\begin{table}[htbp]\n")
        f.write("\\centering\n")
        f.write("\\caption{Resultados de desempenho das implementações paralelas}\n")
        f.write("\\label{tab:results}\n")
        f.write("\\begin{tabular}{|l|c|c|c|c|c|}\n")
        f.write("\\hline\n")
        f.write("\\textbf{Versão} & \\textbf{Threads/Procs} & \\textbf{Tempo (s)} & ")
        f.write("\\textbf{Speedup} & \\textbf{Eficiência} & \\textbf{Karp-Flatt} \\\\\n")
        f.write("\\hline\n")
        f.write(f"Sequencial & 1 & {seq_mean:.4f} & 1.0000 & 1.0000 & - \\\\\n")
        f.write("\\hline\n")
        
        for version in ['openmp', 'pthreads', 'mpi']:
            version_label = {'openmp': 'OpenMP', 'pthreads': 'Pthreads', 'mpi': 'MPI'}[version]
            
            if version in results:
                for i, threads in enumerate(results[version]['threads']):
                    mean_time = results[version]['mean_time'][i]
                    speedup = results[version]['speedup'][i]
                    efficiency = results[version]['efficiency'][i]
                    karp_flatt = results[version]['karp_flatt'][i]
                    
                    kf_str = f"{karp_flatt:.6f}" if threads > 1 and karp_flatt > 0 else "-"
                    
                    f.write(f"{version_label} & {threads} & {mean_time:.4f} & ")
                    f.write(f"{speedup:.4f} & {efficiency:.4f} & {kf_str} \\\\\n")
            
            f.write("\\hline\n")
        
        f.write("\\end{tabular}\n")
        f.write("\\end{table}\n")
    
    print(f"\nTabela LaTeX salva: {output_path / 'results_table.tex'}")

def main():
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    results_dir = project_root / 'results'
    
    if not results_dir.exists():
        print(f"Erro: Diretório de resultados não encontrado: {results_dir}")
        print("Execute primeiro: ./scripts/run_benchmark.sh")
        sys.exit(1)
    
    # Analisar resultados
    results, seq_mean = analyze_results(results_dir)
    
    if results:
        # Gerar gráficos
        print(f"\n{'=' * 60}")
        print("GERANDO GRÁFICOS")
        print(f"{'=' * 60}")
        plot_results(results, seq_mean, results_dir)
        
        # Gerar tabela LaTeX
        print(f"\n{'=' * 60}")
        print("GERANDO TABELA LATEX")
        print(f"{'=' * 60}")
        generate_latex_table(results, seq_mean, results_dir)
        
        print(f"\n{'=' * 60}")
        print("ANÁLISE CONCLUÍDA")
        print(f"{'=' * 60}")
        print(f"Arquivos gerados em: {results_dir}")

if __name__ == '__main__':
    main()
