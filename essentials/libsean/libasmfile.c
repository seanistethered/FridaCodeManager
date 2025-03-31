//
// libasmfile.c
// Sean16Compiler
//

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

#define MAX_INSTRUCTIONS 1000
#define MAX_ARGS 6

uint8_t** readasm(const char *filename)
{
    uint8_t **array = (uint8_t **)malloc(MAX_INSTRUCTIONS * sizeof(uint8_t *));
    if (array == NULL) {
        perror("Error allocating memory for rows");
        return NULL;
    }

    for (int i = 0; i < MAX_INSTRUCTIONS; i++) {
        array[i] = (uint8_t *)malloc(MAX_ARGS * sizeof(uint8_t));
        if (array[i] == NULL) {
            perror("Error allocating memory for columns");
            for (int j = 0; j < i; j++) {
                free(array[j]);
            }
            free(array);
            return NULL;
        }
    }

    FILE *file = fopen(filename, "rb");
    if (file == NULL) {
        perror("Error opening file");
        for (int i = 0; i < MAX_INSTRUCTIONS; i++) {
            free(array[i]);
        }
        free(array);
        return NULL;
    }

    for (int i = 0; i < MAX_INSTRUCTIONS; i++) {
        if (fread(array[i], sizeof(uint8_t), MAX_ARGS, file) != MAX_ARGS) {
            if (feof(file)) {
                printf("Warning: End of file reached before reading all data.\n");
            } else if (ferror(file)) {
                perror("Error reading file");
            }
            break;
        }
    }

    fclose(file);

    return array;
}

void storeasm(const char *filename, uint8_t *values, size_t size)
{
    FILE *file = fopen(filename, "wb");
    if (file == NULL) {
        perror("Error opening file");
        return;
    }

    size_t written = fwrite(values, sizeof(uint8_t), size, file);
    if (written != size) {
        perror("Error writing to file");
    }

    fclose(file);
}
