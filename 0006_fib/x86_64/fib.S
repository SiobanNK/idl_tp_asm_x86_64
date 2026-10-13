# int64_t gcd(int64_t x, int64_t y)
# x86-64, syntaxe AT&T, convention System V: x -> %rdi, y -> %rsi,
# résultat dans %rax.

#ifdef __APPLE__
# define C(sym) _##sym
#else
# define C(sym) sym
#endif

    .text
    .globl C(fib_rec)
C(fib_rec):
    # pour call: rsp doit être aligné sur rsp (l'adresse mem doit être un multiple de 16 octets)
    # quand on empile, ça doit être par 64
    # on ne peut pas empiler juste un registre
    # empiler deux par deux: si rien à empiler, prendre un registre non utilisé
    # symétie push/pop
    cmp     $2, %rdi    # n - 2
    jge     recursion   # n >= 2  -> recursion
    mov     %rdi, %rax
end:
    ret
recursion:
    push    %rdi        # save n
    sub     $1, %rdi    # n - 1
    call    C(fib_rec)  # rax = f(n-1)
    push    %rax        # save the result
    sub     $1, %rdi    # n - 1 -1
    call    C(fib_rec)  # rax = f(n-2)
    pop     %rsi        # rsi = f(n-1)
    add     %rsi, %rax  # rax = f(n-1) + f(n-2)
    pop     %rdi
    jmp     end


    .globl C(fib_iter)
C(fib_iter):    # n: rdi ; a: rax ; b: rsi ; c: rdx
    mov     $0, %rax   # a=0
    mov     $1, %rsi    # b=1
for:
    cmp     $1, %rdi    # n - 1
    jge     update      # update if n >= 1
    ret

update:
    mov     %rsi, %rdx  # c = b
    add     %rax, %rsi  # b += a
    mov     %rdx, %rax  # a = c
    sub     $1, %rdi    # n = n - 1
    jmp     for


    .text
    .globl C(fib_binet)
C(fib_binet):   # n: rdi, phi: rsi
    push        %rbx                # registre callee saved
    mov         %rdi, %rbx          # rbx = n
    sub         $16, %rsp

    # compute sqrt(5)
    mov         $5, %eax
    cvtsi2sd    %eax, %xmm0         # conversion en double -> dans xmm0
    call        sqrt                # %xmm0 = sqrt(5)
    # Add 1
    mov         $1, %eax
    cvtsi2sd    %eax, %xmm1         # conversion en double -> dans xmm0
    addsd       %xmm1, %xmm0        # xmm0 = 1 + sqrt(5)
    # Divide by 2
    mov         $2, %eax
    cvtsi2sd    %eax, %xmm1         # conversion en double -> dans xmm0
    divsd       %xmm1, %xmm0         # %xmm0 = (1+sqrt(5))/2 = phi

    # Power n
    pop         %rdi
    cvtsi2sd    %rdi, %xmm1         # xmm1 = n (double)
    push        %rdi                # save n
    call        pow                 # %xmm0 = phi ** n

    # save phi ** n
    sub         $8, %rsp
    movsd       %xmm0, (%rsp)

    # compute sqrt(5) : in xmm0
    mov         $5, %eax
    cvtsi2sd    %eax, %xmm0         # conversion en double -> dans xmm0
    call        sqrt                # %xmm0 = sqrt(5)
    # retrieve phi ** n
    movsd       (%rsp), %xmm1
    add         $8, %rsp
    # divide by sqrt(5)
    divsd       %xmm1, %xmm0        # xmm1 = phi**n / sqrt(5)
    cvtsd2si    %xmm1, %rax            # arrondi au plus proche -> rax

    pop         %rdi
    ret
