#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_LINES 1000
#define MAX_WORDS 6
#define MAX_WORD_LENGTH 50
#define MAX_LINE_LENGTH 256

char *(*read_file(char *filename))[MAX_WORDS];
void free_content(char *content[MAX_LINES][MAX_WORDS]);
