global io_writestr
global io_writeln
global io_writeflt
global io_readint

extern io_writestr_c
extern io_writeln_c
extern io_writeflt_c
extern io_readint_c

section .text

io_writestr:
    push eax
    call io_writestr_c
    add esp, 4
    ret

io_writeln:
    call io_writeln_c
    ret

io_writeflt:
    sub esp, 4
    movss [esp], xmm0
    call io_writeflt_c
    add esp, 4
    ret

io_readint:
    call io_readint_c
    ret
