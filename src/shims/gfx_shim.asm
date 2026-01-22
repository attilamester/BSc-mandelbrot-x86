global gfx_init
global gfx_destroy
global gfx_map
global gfx_unmap
global gfx_draw
global gfx_getevent
global gfx_getmouse
global gfx_showcursor

extern gfx_init_c
extern gfx_destroy_c
extern gfx_map_c
extern gfx_unmap_c
extern gfx_draw_c
extern gfx_getevent_c
extern gfx_getmouse_c
extern gfx_showcursor_c

section .text

gfx_init:
    push edx
    push ecx
    push ebx
    push eax
    call gfx_init_c
    add esp, 16
    ret

gfx_destroy:
    call gfx_destroy_c
    ret

gfx_map:
    call gfx_map_c
    ret

gfx_unmap:
    call gfx_unmap_c
    ret

gfx_draw:
    call gfx_draw_c
    ret

gfx_getevent:
    call gfx_getevent_c
    ret

gfx_getmouse:
    sub esp, 8
    lea eax, [esp]
    lea ebx, [esp + 4]
    push ebx
    push eax
    call gfx_getmouse_c
    add esp, 8
    mov eax, [esp]
    mov ebx, [esp + 4]
    add esp, 8
    ret

gfx_showcursor:
    push eax
    call gfx_showcursor_c
    add esp, 4
    ret
