//
//  ram.c
//  Sean16CPU
//
//  Created by Frida Boleslawska on 26.09.24.
//

#include "ram.h"

uint8_t RAMDISK[S_RAMSIZE_MAX];
uint16_t current_page = 0;
uint32_t current_addr = 0;

typedef struct FreePageNode {
    page_t *page;
    struct FreePageNode *next;
} FreePageNode;

static FreePageNode *free_pages = NULL;

page_t* genpage(void)
{
    if (free_pages != NULL) {
        FreePageNode *node = free_pages;
        page_t *page = node->page;
        free_pages = free_pages->next;
        free(node);
        for (int i = 0; i < 6; i++) {
            for (int j = 0; j < 1024; j++) {
                *(page->memory[i][j]) = 0;
            }
        }
        printf("[ram] reusing page %d\n", page->id);
        return page;
    } else if (current_addr + (1024 * 6) > S_RAMSIZE_MAX) {
        return NULL;
    }

    page_t *page = malloc(sizeof(page_t));
    if (page == NULL) {
        printf("[ram] ram fault\n");
        return NULL;
    }

    page->id = current_page;

    for (int i = 0; i < 6; i++) {
        for (int j = 0; j < 1024; j++) {
            page->memory[i][j] = &RAMDISK[current_addr];
            current_addr++;
        }
    }

    printf("[ram] %'d bytes left (%.2f MB) <- addr %d\n",
        S_RAMSIZE_MAX - current_addr,
        (S_RAMSIZE_MAX - current_addr) / (1024.0 * 1024.0),
        current_addr);

    current_page += 1;
    return page;
}

void freepage(page_t *page)
{
    FreePageNode *node = malloc(sizeof(FreePageNode));
    if (node == NULL) {
        printf("[ram] Unable to free page: Out of memory\n");
        return;
    }
    node->page = page;
    node->next = free_pages;
    free_pages = node;
    printf("[ram] page %d freed\n", page->id);
}
