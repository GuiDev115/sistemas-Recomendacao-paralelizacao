#!/usr/bin/env python3
"""
Gerador de Dados Sintéticos para Sistema de Recomendação
Simula avaliações de produtos da Amazon (user_id, item_id, rating)
"""

import random
import sys

def generate_ratings(num_users, num_items, num_ratings, output_file, sparsity=0.95):
    """
    Gera avaliações sintéticas
    
    Args:
        num_users: Número de usuários
        num_items: Número de itens/produtos
        num_ratings: Número total de avaliações
        output_file: Arquivo de saída
        sparsity: Porcentagem de esparsidade (matriz realista)
    """
    print(f"Gerando dados sintéticos:")
    print(f"  Usuários: {num_users}")
    print(f"  Itens: {num_items}")
    print(f"  Avaliações: {num_ratings}")
    print(f"  Esparsidade: {sparsity*100:.1f}%")
    
    # Conjunto para evitar duplicatas
    ratings_set = set()
    
    # Gerar avaliações únicas
    attempts = 0
    max_attempts = num_ratings * 10
    
    while len(ratings_set) < num_ratings and attempts < max_attempts:
        user_id = random.randint(0, num_users - 1)
        item_id = random.randint(0, num_items - 1)
        
        # Verificar se já existe
        if (user_id, item_id) not in ratings_set:
            # Gerar rating seguindo distribuição realista
            # Mais ratings altos (usuários tendem a avaliar bem)
            rating = random.choices(
                [1.0, 2.0, 3.0, 4.0, 5.0],
                weights=[5, 10, 20, 30, 35]  # Tendência para ratings altos
            )[0]
            
            ratings_set.add((user_id, item_id, rating))
        
        attempts += 1
    
    # Escrever no arquivo
    with open(output_file, 'w') as f:
        for user_id, item_id, rating in sorted(ratings_set):
            f.write(f"{user_id} {item_id} {rating:.1f}\n")
    
    print(f"Arquivo gerado: {output_file}")
    print(f"Total de avaliações únicas: {len(ratings_set)}")
    
    # Estatísticas
    actual_sparsity = 1.0 - (len(ratings_set) / (num_users * num_items))
    print(f"Esparsidade real: {actual_sparsity*100:.2f}%")

def main():
    if len(sys.argv) < 2:
        print("Uso: python3 generate_data.py <tamanho>")
        print("Tamanhos disponíveis:")
        print("  small  - 100 usuários, 100 itens, 1000 avaliações")
        print("  medium - 500 usuários, 500 itens, 10000 avaliações")
        print("  large  - 1000 usuários, 1000 itens, 50000 avaliações")
        print("  xlarge - 2000 usuários, 2000 itens, 100000 avaliações")
        sys.exit(1)
    
    size = sys.argv[1].lower()
    
    # Configurações por tamanho
    import os
    script_dir = os.path.dirname(os.path.abspath(__file__))
    data_dir = os.path.join(os.path.dirname(script_dir), 'data')
    
    configs = {
        'small': (100, 100, 1000, os.path.join(data_dir, 'ratings_small.txt')),
        'medium': (500, 500, 10000, os.path.join(data_dir, 'ratings_medium.txt')),
        'large': (1000, 1000, 50000, os.path.join(data_dir, 'ratings_large.txt')),
        'xlarge': (2000, 2000, 100000, os.path.join(data_dir, 'ratings_xlarge.txt')),
    }
    
    if size not in configs:
        print(f"Tamanho '{size}' não reconhecido!")
        sys.exit(1)
    
    num_users, num_items, num_ratings, output_file = configs[size]
    generate_ratings(num_users, num_items, num_ratings, output_file)

if __name__ == '__main__':
    main()
