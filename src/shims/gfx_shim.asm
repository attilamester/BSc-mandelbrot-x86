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
    push ebp
    mov ebp, esp
    and esp, -16
    push edx
    push ecx
    push ebx
    push eax
    call gfx_init_c
    mov esp, ebp
    pop ebp
    ret

gfx_destroy:
    push ebp
    mov ebp, esp
    and esp, -16
    call gfx_destroy_c
    mov esp, ebp
    pop ebp
    ret

gfx_map:
    push ebp
    mov ebp, esp
    and esp, -16
    call gfx_map_c
    mov esp, ebp
    pop ebp
    ret

gfx_unmap:
    push ebp
    mov ebp, esp
    and esp, -16
    call gfx_unmap_c
    mov esp, ebp
    pop ebp
    ret

gfx_draw:
    push ebp
    mov ebp, esp
    and esp, -16
    call gfx_draw_c
    mov esp, ebp
    pop ebp
    ret

gfx_getevent:
    push ebp
    mov ebp, esp
    and esp, -16
    call gfx_getevent_c
    mov esp, ebp
    pop ebp
    ret

gfx_getmouse:
    push ebp
    mov ebp, esp
    and esp, -16
    sub esp, 8
    lea eax, [esp]
    lea ebx, [esp + 4]
    push ebx
    push eax
    call gfx_getmouse_c
    add esp, 8
    mov eax, [esp]
    mov ebx, [esp + 4]
    mov esp, ebp
    pop ebp
    ret

gfx_showcursor:
    push ebp
    mov ebp, esp
    and esp, -16
    push eax
    call gfx_showcursor_c
    mov esp, ebp
    pop ebp
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
