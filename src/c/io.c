#include <stdio.h>

void io_writestr_c(const char *s) {
    if (s) {
        fputs(s, stdout);
    }
}

void io_writeln_c(void) {
    fputc('\n', stdout);
    fflush(stdout);
}

void io_writeflt_c(float v) {
    printf("%f", v);
    fflush(stdout);
}

int io_readint_c(void) {
    int v = 0;
    if (scanf("%d", &v) != 1) {
        return 0;
    }
    return v;
}
