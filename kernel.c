#include <stdint.h>

#define SPACE_CHAR   0x20

void cls(void)
{
    uint8_t*   COM1 = (uint8_t*)0xB8000;
    for (uint8_t i = 80; i > 0; --i)
        for (uint8_t j = 20; j > 0; --j)
        {
            *COM1 = SPACE_CHAR;
            COM1 += 2;
        }
}

void hlt(void)
{
    uint8_t*   COM1 = (uint8_t*)0xB8000;
    char*   p    = "|/-\\";

    for (uint8_t i = 0;;)
    {
        *COM1 = p[i++ % 4];
        *(COM1 + 1) = 0xc;
    }
}

int _start(void)
{
    cls();
    hlt();

    return 0;
}
