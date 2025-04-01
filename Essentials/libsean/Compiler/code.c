#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_LINES 1000
#define MAX_WORDS 6
#define MAX_WORD_LENGTH 50
#define MAX_LINE_LENGTH 256

char *(*read_file(char *filename))[MAX_WORDS] {
    static char *content[MAX_LINES][MAX_WORDS];
    FILE *file = fopen(filename, "r");
    
    if (file == NULL) {
        printf("Error: Could not open file.\n");
        return NULL;
    }

    char line[MAX_LINE_LENGTH];
    int line_number = 0;

    while (fgets(line, sizeof(line), file) != NULL && line_number < MAX_LINES) {
        char *word;
        int word_number = 0;

        word = strtok(line, " \t\n");
        while (word != NULL && word_number < MAX_WORDS) {
            content[line_number][word_number] = malloc(strlen(word) + 1);
            strcpy(content[line_number][word_number], word);
            
            word_number++;
            word = strtok(NULL, " \t\n");
        }

        for (int i = word_number; i < MAX_WORDS; i++) {
            content[line_number][i] = NULL;
        }

        line_number++;
    }

    fclose(file);
    return content;
}

void free_content(char *content[MAX_LINES][MAX_WORDS]) {
    for (int i = 0; i < MAX_LINES; i++) {
        for (int j = 0; j < MAX_WORDS; j++) {
            if (content[i][j] != NULL) {
                free(content[i][j]);
                content[i][j] = NULL;
            }
        }
    }
}