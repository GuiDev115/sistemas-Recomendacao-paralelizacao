/**
 * Sistema de Recomendação de Produtos - Versão MPI
 * Algoritmo: Filtragem Colaborativa Item-Item com Similaridade de Cosseno
 * 
 * Paralelização usando MPI para memória distribuída.
 */

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <mpi.h>

#define MAX_USERS 10000
#define MAX_ITEMS 10000
#define MAX_RATINGS 1000000
#define TOP_K 10

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
 * Calcula a matriz de similaridade usando MPI
 * Cada processo calcula um subconjunto de linhas da matriz
 */
void compute_similarity_matrix_mpi(int rank, int size) {
    // Determinar quais itens este processo irá processar
    int items_per_process = num_items / size;
    int remainder = num_items % size;
    
    int start_item = rank * items_per_process + (rank < remainder ? rank : remainder);
    int end_item = start_item + items_per_process + (rank < remainder ? 1 : 0);
    
    if (rank == 0) {
        printf("Calculando matriz de similaridade com %d processos MPI...\n", size);
    }
    
    printf("Processo %d: itens %d até %d\n", rank, start_item, end_item - 1);
    
    // Calcular similaridades para a faixa deste processo
    for (int i = start_item; i < end_item && i < num_items; i++) {
        similarity_matrix[i][i] = 1.0;
        
        // Triângulo superior (j > i): calcula e armazena
        for (int j = i + 1; j < num_items; j++) {
            float sim = cosine_similarity(i, j);
            similarity_matrix[i][j] = sim;
            // NÃO preenche [j][i] aqui para evitar race condition!
        }
        
        if ((i + 1) % 100 == 0) {
            printf("Processo %d: Processado %d/%d itens\n", rank, i + 1, end_item);
        }
    }
    
    // Sincronizar todos os processos
    MPI_Barrier(MPI_COMM_WORLD);
    
    // Coletar resultados parciais no processo 0
    if (rank == 0) {
        // Processo 0 já tem sua parte calculada
        for (int src = 1; src < size; src++) {
            int src_start = src * items_per_process + (src < remainder ? src : remainder);
            int src_end = src_start + items_per_process + (src < remainder ? 1 : 0);
            
            // Receber cada linha calculada pelo processo src
            for (int i = src_start; i < src_end && i < num_items; i++) {
                MPI_Recv(similarity_matrix[i], num_items, MPI_FLOAT, src, i, 
                        MPI_COMM_WORLD, MPI_STATUS_IGNORE);
            }
        }
        
        // Reconstruir simetria da matriz: [j][i] = [i][j]
        for (int i = 0; i < num_items; i++) {
            for (int j = i + 1; j < num_items; j++) {
                similarity_matrix[j][i] = similarity_matrix[i][j];
            }
        }
    } else {
        // Enviar resultados para o processo 0
        for (int i = start_item; i < end_item && i < num_items; i++) {
            MPI_Send(similarity_matrix[i], num_items, MPI_FLOAT, 0, i, MPI_COMM_WORLD);
        }
    }
}

/**
 * Compara itens por similaridade (para qsort)
 */
int compare_similarity(const void *a, const void *b) {
    ItemSimilarity *ia = (ItemSimilarity *)a;
    ItemSimilarity *ib = (ItemSimilarity *)b;
    
    if (ib->similarity > ia->similarity) return 1;
    if (ib->similarity < ia->similarity) return -1;
    return 0;
}

void recommend_for_user(int user_id, int top_n) {
    float predictions[MAX_ITEMS];
    memset(predictions, 0, sizeof(predictions));

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
    int rank, size;
    double start_time, end_time;

    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    if (argc < 2) {
        if (rank == 0) {
            fprintf(stderr, "Uso: mpirun -np <num_processos> %s <arquivo_avaliacoes>\n", argv[0]);
        }
        MPI_Finalize();
        return 1;
    }

    if (rank == 0) {
        printf("=== Sistema de Recomendação (MPI) ===\n");
        printf("Processos: %d\n\n", size);
    }

    // Processo 0 carrega os dados
    if (rank == 0) {
        if (load_ratings(argv[1]) != 0) {
            MPI_Abort(MPI_COMM_WORLD, 1);
            return 1;
        }
    }

    // Broadcast dos metadados para todos os processos
    MPI_Bcast(&num_users, 1, MPI_INT, 0, MPI_COMM_WORLD);
    MPI_Bcast(&num_items, 1, MPI_INT, 0, MPI_COMM_WORLD);
    MPI_Bcast(&num_ratings, 1, MPI_INT, 0, MPI_COMM_WORLD);
    
    // Broadcast da matriz de avaliações
    MPI_Bcast(ratings_matrix, MAX_USERS * MAX_ITEMS, MPI_FLOAT, 0, MPI_COMM_WORLD);

    // Medir tempo de execução
    MPI_Barrier(MPI_COMM_WORLD);
    start_time = MPI_Wtime();

    // Calcular matriz de similaridade
    compute_similarity_matrix_mpi(rank, size);

    MPI_Barrier(MPI_COMM_WORLD);
    end_time = MPI_Wtime();

    // Apenas processo 0 imprime resultados
    if (rank == 0) {
        double elapsed = end_time - start_time;
        
        printf("\n=== Resultados ===\n");
        printf("Tempo de execução: %.4f segundos\n", elapsed);
        printf("Número de processos: %d\n", size);
        printf("Número de comparações: %d\n", (num_items * (num_items - 1)) / 2);

        printf("\n=== Exemplos de Recomendações ===\n");
        recommend_for_user(0, TOP_K);
        recommend_for_user(1, TOP_K);
    }

    MPI_Finalize();
    return 0;
}
