# int64_t gcd(int64_t x, int64_t y)
# x86-64, syntaxe AT&T, convention System V: x -> %rdi, y -> %rsi,
# résultat dans %rax.

#ifdef __APPLE__
# define C(sym) _##sym
#else
# define C(sym) sym
#endif

    .text
    .globl C(gcd)
C(gcd):
    # set a, b to their posittive value
    cmp     $0, %rdi     # a - 0
    jge     abs_b
    neg     %rdi
abs_b:
    cmp     $0, %rsi
    jge     while_test
    neg     %rsi

while_test:
    cmp     %rdi, %rsi      # b - a
    jne     Loop          # jump if a != b
    mov     %rdi, %rax
    ret

Loop:
    cmp     %rdi, %rsi      # b - a
    jb      a_greater_than_b    # jump if below -> a>b
    sub     %rdi, %rsi   # b -= a (sub S,D)
    jmp      while_test

a_greater_than_b:
    sub     %rsi, %rdi   # a -= b (sub S,D)
    jmp     while_test
