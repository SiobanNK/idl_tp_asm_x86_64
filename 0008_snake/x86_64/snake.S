# Même programme que snake.c, en assembleur x86-64 (syntaxe AT&T).
# Convention System V AMD64: arguments dans %rdi, %rsi, %rdx, %rcx, %r8, %r9;
# résultat dans %rax; %rbx, %r12 à %r15 sauvés par l'appelé.
# La position (x, y) est gardée dans %r12 et %r13, qui survivent aux appels.

#include "../snake_consts.h"
#include "../gfx_consts.h"

#ifdef __APPLE__
# define C(sym) _##sym
#else
# define C(sym) sym
#endif


    .data
head:    .long 0
tail:    .long 0
len:     .long 1
dx:      .long 1
dy:      .long 0
ax:      .long 3
ay:      .long 3
score:   .long 0
tick_ms: .long TICK0_MS
alive:   .long 1
    .bss
bx:      .skip MAX_LEN*4
by:      .skip MAX_LEN*4
script:  .skip 8
    .section .rodata
body_sprite:
    .byte 2, 1, '[', GFX_GREEN,  ']', GFX_GREEN
head_sprite:
    .byte 2, 1, '(', GFX_GREEN,  ')', GFX_GREEN
apple_sprite:
    .byte 2, 1, '@', GFX_RED,    ' ', GFX_BLACK



    .text
    .globl C(on_body)
C(on_body):  # %rdi = x, %rsi = y
    mov         tail(%rip), %ecx    # ecx = tail
    lea         bx(%rip), %r8   # adresse de base
    lea         by(%rip), %r9   # adresse de base
.Loop_body:
    cmp         %ecx, head(%rip)
    je          .Lret_body   # fin de la boucle

    movslq      %ecx, %rdx          # rdx = i
    mov         (%r8,%rdx,4), %r10d  # %r10d = bx[i]. adresse = %r8 + %rdx × 4
    mov         (%r9,%rdx,4), %r11d  # %r11d = by[i]. adresse = %r9 + %rdx × 4
    cmp         %edi, %r10d  # bx[i] - x
    jne         increment_body
    cmp         %esi, %r11d  # by[i] - y
    jne         increment_body
    mov         $1, %rax
    ret
increment_body:
    add         $1, %ecx
    cmp         $MAX_LEN, %ecx
    jne         .Loop_body
    mov         $0, %ecx
    jmp         .Loop_body
.Lret_body:
    movslq      head(%rip), %rdx
    mov         (%r8,%rdx,4), %r10d
    mov         (%r9,%rdx,4), %r11d
    mov         $1, %rax
    mov         $0, %rcx
    cmp         %edi, %r10d
    cmovne      %rcx, %rax
    cmp         %esi, %r11d
    cmovne      %rcx, %rax
    ret


    .globl C(step)
C(step):
    # sauvegarde des calle-saved
    push        %rbx
    push        %r12
    push        %r13

    lea         bx(%rip), %r8   # adresse de base
    lea         by(%rip), %r9   # adresse de base
    movslq      head(%rip), %rdx
    mov         (%r8,%rdx,4), %r12d     # r12 = bx[head]
    mov         (%r9,%rdx,4), %r13d     # r13 = by[head]

    add         dx(%rip), %r12d  # r12d = nx
    add         dy(%rip), %r13d  # r13d = ny

    cmpl        $0, %r12d   # nx - 0
    jl          .Ldeath_step
    cmp         $W, %r12d   # nx - W
    jge         .Ldeath_step
    cmpl        $0, %r13d   # ny - 0
    jl          .Ldeath_step
    cmp         $H, %r13d   # ny - 0
    jge         .Ldeath_step

    # !eat ?  eat = (nx == ax && ny == ay)
    cmp         %r12d, ax(%rip)
    jne         .Lmove_tail_forward
    cmp         %r13d, ay(%rip)
    jne         .Lmove_tail_forward
    addl        $1, len(%rip)        # else
    # after tail moves forward (or doesn't)
1:  mov         %r12d, %edi
    mov         %r13d, %esi
    call        C(on_body)      # %r8, %r9, %r10, %r11 et %rdx écrasés
    lea         bx(%rip), %r8   # recharge adresse de base de bx dans r8
    lea         by(%rip), %r9   # recharge adresse de base de by dans r9
    cmpl        $1, %eax        # result of on_body
    je          .Ldeath_step

    # move head forward : head = (head + 1) % MAX_LEN
    mov         head(%rip), %eax    # eax = head
    addl        $1, %eax
    cmp         $MAX_LEN, %eax  # MAX_LEN = 0 mod MAX_LEN
    jne         2f
    mov         $0, %eax        # si eax = MAX_LEN
2:  movl        %eax, head(%rip)

    mov         head(%rip), %rdx
    mov         %r12d, (%r8,%rdx,4) # bx[head] = nx
    mov         %r13d, (%r9,%rdx,4) # by[head] = ny

    # eat ?: eat = (nx == ax && ny == ay)
    cmp         %r12d, ax(%rip)
    jne         .Lret_step
    cmp         %r13d, ay(%rip)
    jne         .Lret_step
    addl        $10, score(%rip)
    cmpl        $TICK_MIN, tick_ms(%rip)
    jle         3f
    subl        $5, tick_ms(%rip)
3:
    # call        C(place_apple)
    jmp         .Lret_step

.Lmove_tail_forward:
    mov         tail(%rip), %eax
    add         $1, %eax
    cmp         $MAX_LEN, %eax
    jne         4f
    mov         $0, %eax
4:  movl        %eax, tail(%rip)
    jmp         1b

.Ldeath_step:
    movl        $0, alive(%rip)
    jmp         .Lret_step

.Lret_step:
    pop         %r13
    pop         %r12
    pop         %rbx
    ret


    .globl C(init)
C(init):    # pas d'argument
    movl    $0, head(%rip)
    movl    $0, tail(%rip)
    movl    $1, len(%rip)
    movl    $1, dx(%rip)
    movl    $0, dy(%rip)
    movl    $3, ax(%rip)
    movl    $3, ay(%rip)
    # sub $8, %rsp      # alignement
    # call    C(place_apple)
    # add $8, %rsp
    movl    $0, score(%rip)
    movl    $TICK0_MS, tick_ms(%rip)
    movl    $1, alive(%rip)
    movl    $(W/2), bx(%rip)
    movl    $(H/2), by(%rip)
    ret



    .globl C(turn)
C(turn):    # rdi : ndx, rsi : ndy
    push    %rdi
    push    %rsi
    neg     %rdi
    neg     %rsi

    cmp     %rdi, %r8
    jne     halfturn

    cmp     %rsi, %r9
    jne     halfturn

    pop     %rsi
    pop     %rdi
    ret

halfturn:
    pop     %rsi
    pop     %rdi
    mov     %rdi, %r8
    mov     %rsi, %r9
    ret


#  --- Affichage et clavier --------------------------------------------

    .globl C(draw)
C(draw):
    push    %rbx
    mov     $GFX_BLACK, %edi
    call    C(gfx_clear)

    mov     $0, %edi             # gfx_rect(0, ORIGIN_Y, 2*W, H, '.', GFX_BLUE)
    mov     $ORIGIN_Y, %esi
    mov     $(2*W), %edx
    mov     $H, %ecx
    mov     $'.', %r8d
    mov     $GFX_BLUE, %r9d
    call    C(gfx_rect)
    # bx, by
    lea         bx(%rip), %r8   # adresse de base de bx
    lea         by(%rip), %r9   # adresse de base de by
    mov         tail(%rip), %ebx    # ebx = i = tail (calle saved)
.Loop_draw:
    cmp         %ebx, head(%rip)        # i == head ?
    je          .Lend_for_draw   # fin de la boucle
    movslq      %ebx, %rbx
    mov         (%r8,%rbx,4), %edi     # edi = bx[i]
    add         %edi, %edi
    mov         (%r9,%rbx,4), %esi     # esi = by[i]
    add         $ORIGIN_Y, %esi
    lea         body_sprite(%rip), %rdx
    call        C(gfx_blit)             # rcx, r8, r9 lost
    lea         bx(%rip), %r8   # adresse de base de bx
    lea         by(%rip), %r9   # adresse de base de by
    # increment_body:
    add         $1, %ebx
    cmp         $MAX_LEN, %ebx
    jne         .Loop_draw
    mov         $0, %ebx
    jmp         .Loop_draw

.Lend_for_draw:
    # gfx_blit(2 * bx[head], ORIGIN_Y + by[head], head_sprite);
    mov         (%r8,%rbx,4), %edi     # edi = bx[i], rbx = i = head
    add         %edi, %edi
    mov         (%r9,%rbx,4), %esi     # esi = by[i]
    add         $ORIGIN_Y, %esi
    lea         head_sprite(%rip), %rdx
    call        C(gfx_blit)

    # gfx_blit(2 * ax, ORIGIN_Y + ay, apple_sprite);
    mov         ax(%rip), %edi
    add         %edi, %edi
    mov         ay(%rip), %esi
    add         $ORIGIN_Y, %esi
    lea         apple_sprite(%rip), %rdx
    call        C(gfx_blit)

    xor         %edi, %edi              # gfx_text(0, 0, aide, GFX_WHITE)
    xor         %esi, %esi
    lea         %rdi, %rdx
    mov         $GFX_WHITE, %ecx
    call        C(gfx_text)

    call        C(gfx_present)

    pop         %rbx
    ret


    .globl C(last_key)
C(last_key):
    push    %rbx
    mov     $GFX_KEY_NONE, %rax
.while:
    call    C(gfx_key)
    cmp     $GFX_KEY_NONE, %rax
    je      .Lret_last_key
.Lret_last_key:
    pop     %rbx
    ret



    .globl C(main)
C(main):    # rdi : argc
    push    %rbx       # 1 push: la pile reste alignée sur 16
    ; if (gfx_open(2 * W, H + ORIGIN_Y) < 0) return 1;
    mov     $W, %edi
    add     %edi, %edi
    mov     $H, %esi
    add     $ORIGIN_Y, %esi
    call    C(gfx_open)
    test    %eax, %eax
    js      .Lfail  # fail si < 0

    call    C(init)

.Lloop:
    call C(last_key)              # k dans %eax to do
# if (k == 'q') break;
    cmp     $'q', %eax
    je      .Lquit
# if (k == GFX_KEY_LEFT)  turn(-1, 0)
    cmp     $GFX_KEY_LEFT, %ebx
    jz      1f
    mov     $(-1), %rdi
    mov     $1, %rsi
    call    C(turn)
1:  cmp     $GFX_KEY_RIGHT, %ebx
    jne     2f
    mov     $1, %rdi
    mov     $0, %rsi
    call    C(turn)
2:  cmp     $GFX_KEY_UP, %ebx
    jne     3f
    mov     $0, %rdi
    mov     $(-1), %rsi
    call    C(turn)
3:  cmp     $GFX_KEY_DOWN, %ebx
    jne     4f
    mov     $0, %rdi
    mov     $(-1), %rsi
    call    C(turn)
4:  cmpl    $0, alive(%rip)   # alive ?
    jz      5f      # jump if not alive (0)
    call    C(step)     # if alive : step()

5:  cmpl    $0, alive(%rip) # alive ?
    jne     lost_msg
    mov     $"", %rdi
    jmp     call_draw
lost_msg:
    mov     $"Perdu. q pour quitter", %rdi
call_draw:
    call    C(draw)

    cmpl    $0, alive(%rip)    # alive ?
    jz      .Lquit      # quit if dead
    mov     $30, %edi       # sleep
    call    C(gfx_sleep)
    jmp     .Lloop

.Lquit:
    call    C(gfx_close)
    xor     %eax, %eax
    jmp     .Lret
.Lfail:
    mov     $1, %eax
.Lret:
    pop     %rbx
    ret



#ifdef __APPLE__
    .section __TEXT,__cstring
#else
    .section .rodata
#endif
