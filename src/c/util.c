#include <stdint.h>
#include <time.h>

void sleep_c(uint32_t ms) {
    struct timespec ts;
    ts.tv_sec = ms / 1000u;
    ts.tv_nsec = (long)(ms % 1000u) * 1000000L;
    nanosleep(&ts, NULL);
}
