global notec
extern debug

default  rel

%macro busy_wait 2
%%busy_wait:
    xchg    [%1], %2      
    test    %2, %2            
    jnz     %%busy_wait  
%endmacro

section .bss
    mutex:          resb 1
    delay:          resb N
    doesWait:       resb N          ; Jeśli czeka 1, jeśli nie 0
    forWhoWaits:    resq N
    stackTop:       resq N

section .text

align 8
; rdi - n
; rsi - wskaźnik do calc
notec:

    push    rbx
    push    rbp
    push    r12
    push    r13
    push    r14
    push    r15

    mov     rbp, rsp                ; Zapamiętaj stos przed noteć w rbp

    mov     r12, rdi                ; W r12 n
    mov     rbx, rsi                ; W rbx wskaźnik do znaku
    dec     rbx                     ; dec przed pierwszym inc

    xor     r14, r14                ; W r14 czy w trybie wpisywania liczby 0 - nie 1 -tak
    xor     r15, r15                ; W r15 wpisywana liczba

string_loop:
    inc     rbx                     ; Wskaźnik do następnego znaku
    movzx   r8, byte [rbx]          ; W r8 następny znak
    jmp     process_char    
process_char_end:
    jmp     string_loop
string_loop_end:

    mov    rax, [rsp]               ; Zapisz wierzchołek stosu do rax

    mov    rsp, rbp                 ; Przywróć stos przed noteć.

    pop    r15
    pop    r14
    pop    r13
    pop    r12
    pop    rbp
    pop    rbx

    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

process_char:
; Sprawdź czy znak to cyfra w hex
    cmp     r8, '0'
    jge     char_is_0_or_more
char_not_0_to_9:
    cmp     r8, 'A'
    jge     char_is_A_or_more
char_not_A_to_F:
    cmp     r8, 'a'
    jge     char_is_a_or_more
char_not_a_to_f:

    cmp     r14, 0
    je      end_input_mode_end      ; Jeśli nie w trybie wpisywania liczby pomiń

    xor     r14, r14                ; Wyjdź z trybu wpisywania liczby
    push    r15                     ; Wpisz liczbę na stos
    xor     r15, r15                ; Wyzeruj bufer na liczbę
end_input_mode_end:

    cmp     r8, 0
    je      string_loop_end

    cmp     r8, '='
    je      process_equals

    cmp     r8, '+'
    je      process_plus

    cmp     r8, '*'
    je      process_asterisk

    cmp     r8, '-'
    je      process_minus

    cmp     r8, '&'
    je      process_and

    cmp     r8, '|'
    je      process_or

    cmp     r8, '^'
    je      process_xor

    cmp     r8, '~'
    je      process_tilde

    cmp     r8, 'Z'
    je      process_Z

    cmp     r8, 'Y'
    je      process_Y

    cmp     r8, 'X'
    je      process_X

    cmp     r8, 'N'
    je      process_N

    cmp     r8, 'n'
    je      process_n

    cmp     r8, 'g'
    je      process_g

    cmp     r8, 'W'
    je      process_W

    jmp     exit1                   ; Jeśli zły znak exit1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

char_is_0_or_more:
    cmp     r8, '9'
    jle     process_0_to_9

    jmp     char_not_0_to_9

char_is_A_or_more:
    cmp     r8, 'F'
    jle     process_A_to_F

    jmp     char_not_A_to_F

char_is_a_or_more:
    cmp     r8, 'f'
    jle     process_a_to_f

    jmp     char_not_a_to_f

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

process_0_to_9:
    mov     r14, 1                  ; Ustab tryb na wpisywanie liczby
    shl     r15, 4                  ; Przesuń liczbę o jedną pozycję w lewo
    sub     r8, '0'                 ; Zapisz w r8 liczbę odpowiadającą znakowi
    add     r15, r8

    jmp     process_char_end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

process_A_to_F:
    mov     r14, 1                  ; Ustab tryb na wpisywanie liczby
    shl     r15, 4                  ; Przesuń liczbę o jedną pozycję w lewo
    sub     r8, 'A'
    add     r8, 10                  ; Zapisz w r8 liczbę odpowiadającą znakowi
    add     r15, r8

    jmp     process_char_end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

process_a_to_f:
    mov     r14, 1                  ; Ustab tryb na wpisywanie liczby
    shl     r15, 4                  ; Przesuń liczbę o jedną pozycję w lewo
    sub     r8, 'a'
    add     r8, 10                  ; Zapisz w r8 liczbę odpowiadającą znakowi
    add     r15, r8

    jmp     process_char_end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

process_equals:
    jmp     process_char_end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

process_plus:
    pop     rax
    pop     rcx
    add     rax, rcx
    push    rax                     ; Zdejmij dwie wartości ze stosu, oblicz ich sumę i wstaw wynik na stos.
    jmp     process_char_end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

process_asterisk:
    pop     rax
    pop     rcx
    mul     rcx
    push    rax                     ; Zdejmij dwie wartości ze stosu, oblicz ich iloczyn i wstaw wynik na stos.
    jmp     process_char_end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

process_minus:
    pop     rax
    neg     rax
    push    rax                     ; Zaneguj arytmetycznie wartość na wierzchołku stosu.
    jmp     process_char_end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

process_and:
    pop     rax
    pop     rcx
    and     rax, rcx
    push    rax                     ; Zdejmij dwie wartości ze stosu, wykonaj na nich operację AND i wstaw wynik na stos.
    jmp     process_char_end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

process_or:
    pop     rax
    pop     rcx
    or      rax, rcx
    push    rax                     ; Zdejmij dwie wartości ze stosu, wykonaj na nich operację OR i wstaw wynik na stos.
    jmp     process_char_end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

process_xor:
    pop     rax
    pop     rcx
    xor     rax, rcx
    push    rax                     ; Zdejmij dwie wartości ze stosu, wykonaj na nich operację XOR i wstaw wynik na stos.
    jmp     process_char_end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

process_tilde:
    pop     rax
    not     rax
    push    rax                     ; Zaneguj bitowo wartość na wierzchołku stosu.
    jmp     process_char_end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

process_Z:
    pop     rax                     ; Usuń wartość z wierzchołka stosu.
    jmp     process_char_end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

process_Y:
    pop rax
    push rax
    push rax                        ; Wstaw na stos wartość z wierzchołka stosu
    jmp     process_char_end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

process_X:
    pop rax
    pop rcx
    push rax
    push rcx                        ; Zamień miejscami dwie wartości na wierzchu stosu.
    jmp     process_char_end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

process_N:
    push N                          ; Wstaw na stos liczbę Noteci.
    jmp     process_char_end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

process_n:
    push r12                        ; Wstaw na stos numer instancji tego Notecia.
    jmp     process_char_end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

process_g:
    mov     r13, rsp                ; Zapamiętaj rsp w r13
    mov     rdi, r12
    mov     rsi, rsp
    and     rsp, -16                ; Allign 16
    call    debug
    mov     rsp, r13                ; Przywróć stary rsp
    imul    rax, 8
    add     rsp, rax                ; przesuń
    jmp     process_char_end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

process_W:
    pop     rax                     ; Zapisz m do rax
    lea     rdx, [stackTop]
    pop     qword [rdx + 8 * r12]   ; Zapisz wierzch stosu do tablicy

    lea     rdx, [delay]
    mov     byte [rdx + r12], 1     ; Ustaw delay dla siebie

    mov     cl, 1

    busy_wait mutex, cl             ; Zdobądź mutex

    lea     rdx, [doesWait]
    cmp     byte [rdx + rax], 1     ; Sprawdź czy m czeka
    jne     m_not_waits

    lea     rdx, [forWhoWaits]
    cmp     [rdx + 8 * rax], r12    ; Sprawdź czy m czeka na ciebie
    jne     m_not_waits

m_waits:
    mov     [mutex], cl             ; Zwolnij mutex  
    
    lea     rdx, [stackTop]
    mov     r8, [rdx + 8 * rax]
    push    r8                      ; Zapisz wierzch stosu m na swoim stosie

    lea     rdx, [delay]
    mov     [rdx + rax], cl         ; Obudź m

    mov     cl, 1
    lea     rdx, [delay]

    busy_wait rdx + r12, cl         ; Czekaj aż m skończy

    jmp     process_char_end    

m_not_waits:

    lea     rdx, [doesWait]
    mov     byte [rdx + r12], 1     ; Zapisz że czekasz

    lea     rdx, [forWhoWaits]
    mov     [rdx + 8 * r12], rax    ; Zapisz że czekasz na m

    mov     [mutex], cl             ; Zwolnij mutex    

    mov     cl, 1
    lea     rdx, [delay]

    busy_wait rdx + r12, cl         ; Czekaj na m     

    lea     rdx, [stackTop]
    mov     r8, [rdx + 8 * rax]
    push    r8                      ; Zapisz wierzch stosu m na swoim stosie

    lea     rdx, [doesWait]
    mov     byte [rdx + r12], 0     ; Zapisz że nie czekasz

    lea     rdx, [delay]
    mov     [rdx + rax], cl         ; Obudź m

    jmp     process_char_end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

exit1:
    mov     rax, 60
    mov     rdi, 1
    syscall