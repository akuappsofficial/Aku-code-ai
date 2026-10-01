#include <stdint.h>

#define VGA ((volatile uint16_t*)0xB8000)
#define W 80
#define H 25

static int row = 0;
static int col = 0;
static uint8_t color = 0x0F;

static void putc(char c) {
    if (c == '\n') {
        col = 0;
        if (++row >= H) row = 0;
        return;
    }
    if (c == '\b') {
        if (col > 0) {
            --col;
            VGA[row * W + col] = ((uint16_t)color << 8) | ' ';
        }
        return;
    }
    VGA[row * W + col] = ((uint16_t)color << 8) | (uint8_t)c;
    if (++col >= W) {
        col = 0;
        if (++row >= H) row = 0;
    }
}

static void print(const char* s) {
    while (*s) putc(*s++);
}

static void clear(void) {
    for (int i = 0; i < W * H; ++i)
        VGA[i] = ((uint16_t)color << 8) | ' ';
    row = 0;
    col = 0;
}

static uint8_t inb(uint16_t port) {
    uint8_t value;
    __asm__ volatile ("inb %1, %0" : "=a"(value) : "Nd"(port));
    return value;
}

static char scancode(uint8_t s) {
    switch (s) {
        case 0x1C: return '\n';
        case 0x39: return ' ';
        case 0x0E: return '\b';
        case 0x10: return 'q'; case 0x11: return 'w';
        case 0x12: return 'e'; case 0x13: return 'r';
        case 0x14: return 't'; case 0x15: return 'y';
        case 0x16: return 'u'; case 0x17: return 'i';
        case 0x18: return 'o'; case 0x19: return 'p';
        case 0x1E: return 'a'; case 0x1F: return 's';
        case 0x20: return 'd'; case 0x21: return 'f';
        case 0x22: return 'g'; case 0x23: return 'h';
        case 0x24: return 'j'; case 0x25: return 'k';
        case 0x26: return 'l'; case 0x2C: return 'z';
        case 0x2D: return 'x'; case 0x2E: return 'c';
        case 0x2F: return 'v'; case 0x30: return 'b';
        case 0x31: return 'n'; case 0x32: return 'm';
        case 0x02: return '1'; case 0x03: return '2';
        case 0x04: return '3'; case 0x05: return '4';
        case 0x06: return '5'; case 0x07: return '6';
        case 0x08: return '7'; case 0x09: return '8';
        case 0x0A: return '9'; case 0x0B: return '0';
        case 0x35: return '/'; case 0x34: return '.';
        case 0x33: return ',';
        default: return 0;
    }
}

static int starts(const char* a, const char* b) {
    while (*b) {
        if (*a++ != *b++) return 0;
    }
    return *a == 0;
}

static char input[128];
static int input_len = 0;

static void shell(void) {
    print("aku@os:~$ ");
    for (;;) {
        if (!(inb(0x64) & 1)) continue;

        uint8_t s = inb(0x60);
        if (s & 0x80) continue;

        char c = scancode(s);
        if (!c) continue;

        if (c == '\n') {
            putc('\n');
            input[input_len] = 0;

            if (starts(input, "help")) {
                print("Commands: help, clear, about\n");
            } else if (starts(input, "clear")) {
                clear();
            } else if (starts(input, "about")) {
                print("AKU OS v0.1 - tiny experimental OS\n");
                print("Booted from a Multiboot ISO.\n");
            } else {
                print("Unknown command. Type help.\n");
            }

            input_len = 0;
            print("aku@os:~$ ");
        } else if (c == '\b') {
            if (input_len > 0) {
                --input_len;
                putc('\b');
            }
        } else if (input_len < 127) {
            input[input_len++] = c;
            putc(c);
        }
    }
}

void kmain(void) {
    clear();
    print("========================================\n");
    print("             AKU OS v0.1                \n");
    print("========================================\n");
    print("Booted successfully.\n");
    print("Ventoy-compatible ISO test build.\n");
    print("Type help for commands.\n\n");
    shell();
}
