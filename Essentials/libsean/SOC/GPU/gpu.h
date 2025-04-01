//
//  gpu.h
//  Sean16CPU
//
//  Created by Frida Boleslawska on 27.09.24.
//

#ifndef gpu_h
#define gpu_h

void clearScreen(void);
void setpixel(int x, int y, uint8_t color);
uint8_t getColorOfPixel(uint8_t x, uint8_t y);
void drawLine(int x0, int y0, int x1, int y1, uint8_t color);
void drawCharacter(uint8_t x, uint8_t y, char ascii, uint8_t color);

#endif /* gpu_h */
