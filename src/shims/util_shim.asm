global sleep

extern sleep_c

section .text

sleep:
    push eax
    call sleep_c
    add esp, 4
    ret
