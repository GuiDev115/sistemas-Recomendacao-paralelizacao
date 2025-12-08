/**
 * Sistema de Recomendação de Produtos - Versão OpenMP
 * Algoritmo: Filtragem Colaborativa Item-Item com Similaridade de Cosseno
 * 
 * Paralelização usando OpenMP para memória compartilhada.
 */

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <omp.h>

#define MAX_USERS 10000
#define MAX_ITEMS 10000
#define MAX_RATINGS 1000000
#define TOP_K 10

typedef struct {
    int user_id;
    int item_id;
    float rating;
} Rating;

typedef struct {
    int item_id;
    float similarity;
} ItemSimilarity;

float ratings_matrix[MAX_USERS][MAX_ITEMS];
int num_users = 0;
int num_items = 0;
int num_ratings = 0;

float similarity_matrix[MAX_ITEMS][MAX_ITEMS];

int load_ratings(const char *filename) {
    FILE *file = fopen(filename, "r");
    if (!file) {
        fprintf(stderr, "Erro ao abrir arquivo: %s\n", filename);
        return -1;
    }

    memset(ratings_matrix, 0, sizeof(ratings_matrix));

    int user, item;
    float rating;
    num_users = 0;
    num_items = 0;
    num_ratings = 0;

    while (fscanf(file, "%d %d %f", &user, &item, &rating) == 3) {
        if (user >= MAX_USERS || item >= MAX_ITEMS) {
            continue;
        }
        
        ratings_matrix[user][item] = rating;
        if (user >= num_users) num_users = user + 1;
        if (item >= num_items) num_items = item + 1;
        num_ratings++;
    }

    fclose(file);
    printf("Carregados: %d usuários, %d itens, %d avaliações\n", 
           num_users, num_items, num_ratings);
    return 0;
}

/**
 * Calcula a similaridade de cosseno entre dois itens
 */
float cosine_similarity(int item1, int item2) {
    float dot_product = 0.0;
    float norm1 = 0.0;
    float norm2 = 0.0;

    for (int user = 0; user < num_users; user++) {
        float r1 = ratings_matrix[user][item1];
        float r2 = ratings_matrix[user][item2];
        
        if (r1 > 0 && r2 > 0) {
            dot_product += r1 * r2;
            norm1 += r1 * r1;
            norm2 += r2 * r2;
        }
    }

    if (norm1 == 0.0 || norm2 == 0.0) {
        return 0.0;
    }

    return dot_product / (sqrt(norm1) * sqrt(norm2));
}

/**
 * Calcula a matriz de similaridade usando OpenMP
 * Paralelização do loop externo com schedule dinâmico
 */
void compute_similarity_matrix(int num_threads) {
    printf("Calculando matriz de similaridade com %d threads (OpenMP)...\n", num_threads);
    
    omp_set_num_threads(num_threads);
    
    #pragma omp parallel for schedule(dynamic, 10) shared(similarity_matrix)
    for (int i = 0; i < num_items; i++) {
        for (int j = i; j < num_items; j++) {
            if (i == j) {
                similarity_matrix[i][j] = 1.0;
            } else {
                float sim = cosine_similarity(i, j);
                similarity_matrix[i][j] = sim;
                similarity_matrix[j][i] = sim;
            }
        }
        
        #pragma omp critical
        {
            if ((i + 1) % 100 == 0) {
                printf("Processado: %d/%d itens (thread %d)\n", 
                       i + 1, num_items, omp_get_thread_num());
            }
        }
    }
}


int compare_similarity(const void *a, const void *b) {
    ItemSimilarity *ia = (ItemSimilarity *)a;
    ItemSimilarity *ib = (ItemSimilarity *)b;
    
    if (ib->similarity > ia->similarity) return 1;
    if (ib->similarity < ia->similarity) return -1;
    return 0;
}

/**
 * Gera recomendações para um usuário (paralelizado)
 */
void recommend_for_user(int user_id, int top_n, int num_threads) {
    float predictions[MAX_ITEMS];
    memset(predictions, 0, sizeof(predictions));

    omp_set_num_threads(num_threads);

    // Paralelizar cálculo de predições
    #pragma omp parallel for schedule(dynamic) shared(predictions)
    for (int target_item = 0; target_item < num_items; target_item++) {
        if (ratings_matrix[user_id][target_item] > 0) {
            continue;
        }

        float weighted_sum = 0.0;
        float similarity_sum = 0.0;

        for (int rated_item = 0; rated_item < num_items; rated_item++) {
            float user_rating = ratings_matrix[user_id][rated_item];
            
            if (user_rating > 0) {
                float sim = similarity_matrix[target_item][rated_item];
                weighted_sum += sim * user_rating;
                similarity_sum += fabs(sim);
            }
        }

        if (similarity_sum > 0) {
            predictions[target_item] = weighted_sum / similarity_sum;
        }
    }

    // Encontrar top N
    ItemSimilarity recommendations[MAX_ITEMS];
    int count = 0;
    
    for (int i = 0; i < num_items; i++) {
        if (predictions[i] > 0) {
            recommendations[count].item_id = i;
            recommendations[count].similarity = predictions[i];
            count++;
        }
    }

    qsort(recommendations, count, sizeof(ItemSimilarity), compare_similarity);

    printf("\nTop %d recomendações para usuário %d:\n", top_n, user_id);
    for (int i = 0; i < top_n && i < count; i++) {
        printf("  Item %d: score %.4f\n", 
               recommendations[i].item_id, 
               recommendations[i].similarity);
    }
}

int main(int argc, char *argv[]) {
    if (argc < 3) {
        fprintf(stderr, "Uso: %s <arquivo_avaliacoes> <num_threads>\n", argv[0]);
        return 1;
    }

    int num_threads = atoi(argv[2]);
    if (num_threads <= 0) {
        fprintf(stderr, "Número de threads inválido\n");
        return 1;
    }

    printf("=== Sistema de Recomendação (OpenMP) ===\n");
    printf("Threads: %d\n\n", num_threads);

    if (load_ratings(argv[1]) != 0) {
        return 1;
    }

    // Medir tempo de execução
    double start = omp_get_wtime();

    // Calcular matriz de similaridade
    compute_similarity_matrix(num_threads);

    double end = omp_get_wtime();
    double elapsed = end - start;

    printf("\n=== Resultados ===\n");
    printf("Tempo de execução: %.4f segundos\n", elapsed);
    printf("Número de threads: %d\n", num_threads);
    printf("Número de comparações: %d\n", (num_items * (num_items - 1)) / 2);

    printf("\n=== Exemplos de Recomendações ===\n");
    recommend_for_user(0, TOP_K, num_threads);
    recommend_for_user(1, TOP_K, num_threads);

    return 0;
}
