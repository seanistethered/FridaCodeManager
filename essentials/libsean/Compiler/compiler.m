//
// compiler.m
// libsean
//
// Created by SeanIsNotAConstant on 22.10.24
//

#import <Foundation/Foundation.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include "../libasmfile.h"
#include "code.h"

#include <CPU/cpu.h>

typedef struct {
    char *modified_str;
    bool had_colon;
    uint8_t offset;
} LABEL;

LABEL labelcheck(const char *input)
{
    LABEL result;
    size_t len = strlen(input);

    result.had_colon = false;
    result.modified_str = (char *)malloc(len + 1);

    if (input[len - 1] == ':') {
        strncpy(result.modified_str, input, len - 1);
        result.modified_str[len - 1] = '\0';
        result.had_colon = true;
    } else {
        strcpy(result.modified_str, input);
    }

    return result;
}

uint8_t rval(const char *input)
{
    int base_value = 0;
    if (input[0] == 'R') {
        base_value = 0;
        input++;
    } else {
        base_value = 65;
    }

    int number = atoi(input);
    return (uint8_t)(number + base_value);
}

uint8_t** sean16compiler(NSString *arguments)
{
    NSArray<NSString *> *components = [arguments componentsSeparatedByString:@" "];
    int argc = (int)[components count];
    char **argv = malloc((argc + 1) * sizeof(char *));

    for (int i = 0; i < argc; i++) {
        NSString *argString = components[i];
        argv[i] = strdup([argString UTF8String]);
    }
    argv[argc] = NULL;

    char *(*raw)[MAX_WORDS] = read_file(argv[1]);

    uint8_t **array = malloc(MAX_LINES * sizeof(uint8_t *));
    for (int i = 0; i < MAX_LINES; i++) {
        array[i] = calloc(MAX_WORDS, sizeof(uint8_t));
    }

    static LABEL symbols[126];
    static uint16_t sym_count = 0;
    static uint16_t roffset = 1;

    printf("[*] getting label addresses\n");
    for (int i = 0; i < MAX_LINES; i++) {
        if (raw[i] == NULL || raw[i][0] == NULL) {
            break;
        }

        symbols[sym_count] = labelcheck(raw[i][0]);
        if(symbols[sym_count].had_colon) {
            symbols[sym_count].offset = roffset;
            printf("%s => %d\n", symbols[sym_count].modified_str, symbols[sym_count].offset);
            sym_count++;
            i++;
        }

        roffset++;
    }

    roffset = 1;
    printf("[*] compile\n");
    for (int i = 0; i < MAX_LINES; i++) {
        if (raw[i] == NULL || raw[i][0] == NULL) {
            break;
        }

        LABEL checklabel = labelcheck(raw[i][0]);
        if(checklabel.had_colon) {
            i++;
        }

        if (strcmp("EXT", raw[i][0]) == 0) {
            array[roffset][0] = EXT;
        } else if (strcmp("STO", raw[i][0]) == 0) {
            array[roffset][0] = STO;
        } else if (strcmp("ADD", raw[i][0]) == 0) {
            array[roffset][0] = ADD;
        } else if (strcmp("SUB", raw[i][0]) == 0) {
            array[roffset][0] = SUB;
        } else if (strcmp("MUL", raw[i][0]) == 0) {
            array[roffset][0] = MUL;
        } else if (strcmp("DIV", raw[i][0]) == 0) {
            array[roffset][0] = DIV;
        } else if (strcmp("DSP", raw[i][0]) == 0) {
            array[roffset][0] = DSP;
        } else if (strcmp("JMP", raw[i][0]) == 0) {
            array[roffset][0] = JMP;
            bool label_found = false;
            for (int h = 0; h < sym_count - 1; h++) {
                if (symbols[h].had_colon && strcmp(raw[i][1], symbols[h].modified_str) == 0) {
                    sprintf(raw[i][1], "%d", symbols[h].offset);
                    label_found = true;
                    break;
                }
            }
            if (!label_found) {
                sprintf(raw[i][1], "%d", roffset + atoi(raw[i][1]));
            }
        } else if (strcmp("IFQ", raw[i][0]) == 0) {
            array[roffset][0] = IFQ;
            bool label_found = false;
            for (int h = 0; h < sym_count - 1; h++) {
                if (symbols[h].had_colon && strcmp(raw[i][4], symbols[h].modified_str) == 0) {
                    sprintf(raw[i][4], "%d", symbols[h].offset);
                    label_found = true;
                    break;
                }
            }
            if (!label_found) {
                sprintf(raw[i][4], "%d", roffset + atoi(raw[i][4]));
            }
        } else if (strcmp("RAN", raw[i][0]) == 0) {
            array[roffset][0] = RAN;
        } else if (strcmp("MUS", raw[i][0]) == 0) {
            array[roffset][0] = MUS;
        } else if (strcmp("SSP", raw[i][0]) == 0) {
            array[roffset][0] = SSP;
        } else if (strcmp("NSP", raw[i][0]) == 0) {
            array[roffset][0] = NSP;
        } else if (strcmp("GPX", raw[i][0]) == 0) {
            array[roffset][0] = GPX;
        } else if (strcmp("GDL", raw[i][0]) == 0) {
            array[roffset][0] = GDL;
        } else if (strcmp("GDC", raw[i][0]) == 0) {
            array[roffset][0] = GDC;
        } else if (strcmp("GCS", raw[i][0]) == 0) {
            array[roffset][0] = GCS;
        } else if (strcmp("GGC", raw[i][0]) == 0) {
            array[roffset][0] = GGC;
        }

        for (int j = 0; j < 5; j++) {
            if (raw[i][j + 1] != NULL) {
                if(strcmp(raw[i][j + 1], ";") != 0) {
                    array[roffset][j + 1] = rval(raw[i][j + 1]);
                } else {
                    break;
                }
            } else {
                array[roffset][j + 1] = 0;
            }
        }

        printf("%02d: 0x%02X 0x%02X 0x%02X 0x%02X 0x%02X 0x%02X\n", roffset, array[roffset][0], array[roffset][1], array[roffset][2], array[roffset][3], array[roffset][4], array[roffset][5]);
        roffset++;
    }

    printf("[*] %db of 6144b used\n", roffset * 6);

    if(strcmp(symbols[sym_count - 1].modified_str, "MAIN") == 0) {
        printf("[*] \"MAIN\" LABEL found at %d\n", symbols[sym_count - 1].offset);
        array[0][0] = JMP;
        array[0][1] = symbols[sym_count - 1].offset + 65;
    } else {
        printf("[!] \"MAIN\" LABEL not found. Make sure that its the last LABEL!\n");
        for (int i = 0; i < argc; i++) {
            free(argv[i]);
        }
        free(argv);

        for (int i = 0; i < sym_count; i++) {
            free(symbols[i].modified_str);
        }

        free_content(raw);

        sym_count = 0;
        roffset = 1;
        return NULL;
    }

    for (int i = 0; i < argc; i++) {
        free(argv[i]);
    }
    free(argv);

    for (int i = 0; i < sym_count; i++) {
        free(symbols[i].modified_str);
    }

    free_content(raw);

    sym_count = 0;
    roffset = 1;

    return array;
}
