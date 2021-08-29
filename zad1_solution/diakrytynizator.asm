global _start

MODULO_NUMBER   equ 0x10FF80
EOF             equ -1

%macro check_next_utf8_byte_format 0
    cmp     rax, EOF
    je      exit1                       ; Jeśli EOF przed zakończeniem znaku exit(1).

    mov     r8, rax
    and     r8, 0xC0
    cmp     r8, 0x80
    jne     exit1                       ; Jeśli zły format exit(1).
%endmacro

section .bss
    utf8_char resb 5

section .text

_start:
    mov     r12, rsp                    ; Zapisz wskaźnik do argc w r12.
    mov     r8, 2
    cmp     [r12], r8
    jl      exit1                       ; Jeśli argc < 2 to exit(1).

; Zapisz współczynniki wielomianu % MODULO_NUMBER na stosie.
    mov     rcx, 2                      ; Zapisz index argv w rxc.
parse_loop:
    mov     rdi, [r12 + rcx * 8]        ; Zapisz argv[rcx] w rdi.
    call    string_to_int
    mov     rdi, rax
    mov     rsi, MODULO_NUMBER
    call    modulo
    push    rax                         ; Zapisz współczynnik wielomianu % MODULO_NUMBER na stosie.
    inc     rcx
    cmp     rcx, [r12]
    jle     parse_loop                  ; Jeśli rcx <= argc to skocz do pętli.

; Wczytaj, modyfikuj i wypisz tekst.
modify_loop:
    call    read_utf8
    cmp     rax, EOF
    je      modify_loop_end

    cmp     rax, 0x80
    jl      print_modified

    mov     rdi, rax                    ; Zapisz wartość unicode w rdi.
    mov     rsi, [r12]
    dec     rsi                         ; Zapisz liczbę współczynników w rsi.
    mov     rdx, r12
    sub     rdx, 8                      ; Zapisz wskaźnik do a0 w rdx
    call    get_polynomial_value

print_modified:
    mov     rdi, rax
    call    print_utf8
    jmp     modify_loop

modify_loop_end:

    mov     rax, 60
    mov     rdi, 0
    syscall

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Zwróć w(rdi - 0x80) + 0x80. w rax.
; liczba współczynników w rsi.
; Wskaźnik do a0 w rdx.
get_polynomial_value:
    sub     rdi, 0x80

    xor     r8, r8                      ; W r8 licz wartość wielomianu.
    mov     r9, 1                       ; W r9 licz rdi^n.
    xor     rcx, rcx                    ; W rcx index współczynników wielomianu.

polynomial_loop:
    mov     rax, r9
    imul    rax, [rdx]
    add     r8, rax                     ; r8 += a_rcx * x^(rcx)

    push    rdi                         ; Zapisz na stosie rdi przed modulo.
    push    rsi                         ; Zapisz na stosie rsi przed modulo.
    push    rdx
    mov     rdi, r8
    mov     rsi, MODULO_NUMBER
    call    modulo                      ; Modulo na wartości wielomianu.
    pop     rdx
    pop     rsi                         ; Weź ze stosu rsi po modulo.
    pop     rdi                         ; Weź ze stosu rdi po modulo.

    mov     r8, rax

    imul    r9, rdi                     ; x^(rcx) -> x^(rcx + 1)

    push    rdi                         ; Zapisz na stosie rdi przed modulo.
    push    rsi                         ; Zapisz na stosie rsi przed modulo.
    push    rdx
    mov     rdi, r9
    mov     rsi, MODULO_NUMBER          ; Modulo na x^n
    call    modulo                      ; Modulo na wartości wielomianu.
    pop     rdx
    pop     rsi                         ; Weź ze stosu rsi po modulo.
    pop     rdi                         ; Weź ze stosu rdi po modulo.

    mov     r9, rax

    sub     rdx, 8                      ; Zapisz wskaźnik do a_(rcx+1) w rdx
    inc     rcx
    cmp     rcx, rsi
    jl      polynomial_loop

    add     r8, 0x80
    mov     rax, r8
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Wypisz znak utf8 odpowiadający wartości unicode zapisanej w rdi.
print_utf8:
    cmp     rdi, 0x10FFFF
    jg      exit1                       ; Jeśli zły format exit(1).

    cmp     rdi, 0x80
    jge     more_than_one_byte
    mov     [utf8_char], dil
    mov     [utf8_char + 1], byte 0

    jmp     print_utf8_end

more_than_one_byte:
    cmp     rdi, 0x800
    jge     more_than_two_byte

    mov     r8, rdi
    shr     r8, 6
    or      r8, 0xc0
    mov     [utf8_char], r8b

    mov     r8, rdi
    and     r8, 0x3f
    or      r8, 0x80
    mov     [utf8_char + 1], r8b

    mov     [utf8_char + 2], byte 0

    jmp     print_utf8_end

more_than_two_byte:
    cmp     rdi, 0x10000
    jge     more_than_three_byte

    mov     r8, rdi
    shr     r8, 12
    or      r8, 0xe0
    mov     [utf8_char], r8b

    mov     r8, rdi
    shr     r8, 6
    and     r8, 0x3f
    or      r8, 0x80
    mov     [utf8_char + 1], r8b

    mov     r8, rdi
    and     r8, 0x3f
    or      r8, 0x80
    mov     [utf8_char + 2], r8b

    mov     [utf8_char + 3], byte 0

    jmp     print_utf8_end

more_than_three_byte:

    mov     r8, rdi
    shr     r8, 18
    or      r8, 0xf0
    mov     [utf8_char], r8b

    mov     r8, rdi
    shr     r8, 12
    and     r8, 0x3f
    or      r8, 0x80
    mov     [utf8_char + 1], r8b

    mov     r8, rdi
    shr     r8, 6
    and     r8, 0x3f
    or      r8, 0x80
    mov     [utf8_char + 2], r8b

    mov     r8, rdi
    and     r8, 0x3f
    or      r8, 0x80
    mov     [utf8_char + 3], r8b

    mov     [utf8_char + 4], byte 0

    jmp     print_utf8_end

print_utf8_end:
    mov     rdi, utf8_char
    call    print_string
    ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Wypisz napis o adresie w rdi.
print_string:
    push    rdi
    mov     r8, 0                       ; W r8 licz długość napisu.

    mov     r9b, [rdi]                  ; W r9b trzymaj kolejne bajty napisu.
    cmp     r9b, 0
    je      print_string_call           ; Jeśli koniec napisu to długość napisu policzona.

string_length_loop:
    inc     rdi
    inc     r8
    mov     r9b, [rdi]
    cmp     r9b, 0
    jne     string_length_loop          ; Jeśli koniec napisu to długość napisu policzona.

print_string_call:
    mov     rax, 1
    mov     rdi, 1
    pop     rsi
    mov     rdx, r8
    syscall                             ; Wypisz napis o adresie w rdi.

    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Czytaj znak utf8.
; Zwróć jego wartość unicode w rax.
; Jeśli EOF zwróć EOF.
; Jeśli niepoprawny znak exit(1).
read_utf8:
    push    r12                         ; Wstaw na stos r12. Będzie w nim zapisywana wartość unicode.
    call    getc

    cmp     rax, EOF
    je      read_utf8_end               ; Jeśli EOF zwróć EOF.

; Sprawdź ilu bitowy jest znak utf8.
    mov     r8, rax
    and     r8, 0x80
    cmp     r8, 0x0                     ; Sprawdź czy znak jedno-bajtowy.
    jne     not_one_byte

    jmp     read_utf8_end

not_one_byte:
    mov     r8, rax
    and     r8, 0xE0
    cmp     r8, 0xC0                    ; Sprawdź czy znak dwu-bajtowy.
    jne     not_two_byte

    mov     r8, rax
    and     r8, 0x1F
    shl     r8, 6
    mov     r12, r8                     ; Zapisz górne 5 bitów wartości unicode.

    call    getc
    check_next_utf8_byte_format

    mov     r8, rax
    and     r8, 0x3F
    add     r12, r8                     ; Zapisz dolne 6 bitów wartości unicode.


    cmp     r12, 0x80
    jl      exit1                       ; Jeśli zły format exit(1).

    mov     rax, r12                    ; Zapisz wynik do rax.
    jmp     read_utf8_end

not_two_byte:
    mov     r8, rax
    and     r8, 0xF0
    cmp     r8, 0xE0                    ; Sprawdź czy znak trzy-bajtowy.
    jne     not_three_byte

    mov     r8, rax
    and     r8, 0xF
    shl     r8, 12
    mov     r12, r8                     ; Zapisz górne 4 bity wartości unicode.

    call    getc
    check_next_utf8_byte_format

    mov     r8, rax
    and     r8, 0x3F
    shl     r8, 6
    add     r12, r8                     ; Zapisz kolejne 6 bitów wartości unicode.

    call    getc
    check_next_utf8_byte_format

    mov     r8, rax
    and     r8, 0x3F
    add     r12, r8                     ; Zapisz kolejne 6 bitów wartości unicode.

    cmp     r12, 0x800
    jl      exit1                       ; Jeśli zły format exit(1).

    mov     rax, r12                    ; Zapisz wynik do rax.
    jmp     read_utf8_end

not_three_byte:
    mov     r8, rax
    and     r8, 0xF8
    cmp     r8, 0xF0                    ; Sprawdź czy znak cztero-bajtowy.
    jne     exit1                       ; Jeśli nie cztero-bajtowy to zły format.

    mov     r8, rax
    and     r8, 0x7
    shl     r8, 18
    mov     r12, r8                     ; Zapisz górne 3 bity wartości unicode.

    call    getc
    check_next_utf8_byte_format

    mov     r8, rax
    and     r8, 0x3F
    shl     r8, 12
    add     r12, r8                     ; Zapisz kolejne 6 bitów wartości unicode.

    call    getc
    check_next_utf8_byte_format

    mov     r8, rax
    and     r8, 0x3F
    shl     r8, 6
    add     r12, r8                     ; Zapisz kolejne 6 bitów wartości unicode.

    call    getc
    check_next_utf8_byte_format

    mov     r8, rax
    and     r8, 0x3F
    add     r12, r8                     ; Zapisz kolejne 6 bitów wartości unicode.

    cmp     r12, 0x10000
    jl      exit1                       ; Jeśli zły format exit(1).

    cmp     r12, 0x10FFFF
    jg      exit1                       ; Jeśli zły format exit(1).

    mov     rax, r12                    ; Zapisz wynik do rax.
    jmp     read_utf8_end

read_utf8_end:
    pop     r12
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Wczytaj znak z stdin
; Zwróć wczytany znak, lub EOF w rax.
getc:
    mov     rax, 0
    mov     rdi, 0
    push    rax                         ; Zarezerwuj miejsce na stosie.
    mov     rsi, rsp
    mov     rdx, 1
    syscall                             ; Odczytaj 1 znak z stdin i zapisz go na stosie.
    cmp     rax, 0                      ; Sprawdź czy EOF.
    je      eof
    pop     rax
    ret
eof:
    pop     rax
    mov     rax, EOF
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Zwróć rdi % rsi w rax
modulo:
    mov     rax, rdi
    xor     rdx, rdx
    div     rsi
    mov     rax, rdx
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Weź napis ze wskaźnikiem w rdi.
; Zwróć odpowiadającą mu nieujemną liczbę całkowitą w rax.
; Jeśli napis nie jest nieujemną liczbę całkowitą exit(1).
string_to_int:
    xor     rax, rax                    ; Zainicjiuj int na 0.
    movzx   rsi, byte [rdi]             ; Zapisz znak w rsi.

string_to_int_loop:
    cmp     rsi, 48
    jl      exit1                       ; Jeśli znak < '0' to exit(1).

    cmp     rsi, 57
    jg      exit1                       ; Jeśli znak > '9' to exit(1).

    sub     rsi, 48                     ; Zmień znak na cyfrę.
    mov     r8, 10
    mul     r8                          ; Pomnóż liczbę razy 10 przed dodaniem cyfry.
    add     rax, rsi                    ; Dodaj cyfrę do liczby.

    inc     rdi                         ; Zapisz adres następnego znaku.

    movzx   rsi, byte [rdi]             ; Zapisz znak w rsi.
    cmp     rsi, 0
    jne     string_to_int_loop          ; Jeśli znak != '\0' to skocz do pętli.
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; exit(1);
exit1:
      mov   rax, 60
      mov   rdi, 1
      syscall