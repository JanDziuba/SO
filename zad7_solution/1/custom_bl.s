org 0x0600

STACKADDR   equ 0x7c00

; Inicjuj rejestry segmentowe i stos.
_start:
    mov ax, cs
    mov ds, ax
    mov es, ax
    cli
    mov ss, ax
    mov sp, STACKADDR
    sti
; Przesuń sie do 0x0600
    mov si, 0x7c00
    mov di, 0x0600
    mov	cx, 512/2
    cld
    rep movsw
	jmp 0:migrate
migrate:

; Ładuj message.txt
    xor ax, ax
    mov es, ax
    mov bx, 0x7c00  ; ładuj do 0x7c00
    mov cx, 2       ; ładuj z drugiego sektora
    mov al, 1       ; ładuj jeden sektor
    mov ah, 02      ; function 02: Read Sectors
    mov dx, 0x80    ; HDD
    int 0x13

    mov ax, 0x7c00
    call print

; Czekaj na naciśnięcie klawisza Escape
getkey:
    xor ah,ah          
    int 16h            ; Czekaj na klawisz
    cmp ah, 01h        ; Scan code 1 = Escape
    jne getkey         ; Jeśli nie Escape wczytaj kolejny klawisz

; Ładuj oryginalny bootloader
    xor ax, ax
    mov es, ax
    mov bx, 0x7c00  ; ładuj do 0x7c00
    mov cx, 3       ; ładuj z trzeciego sektora
    mov al, 1       ; ładuj jeden sektor
    mov ah, 02      ; function 02: Read Sectors
    mov dx, 0x80    ; HDD
    int 0x13

; Przywróć oryginalny stan dysku

; Przywróć oryginalny mbr
    xor ax, ax
    mov es, ax
    mov bx, 0x7c00  ; ładuj z 0x7c00
    mov cx, 1       ; ładuj do pierwszego sektora
    mov al, 1       ; ładuj jeden sektor
    mov ah, 03      ; function 03: Write Sectors
    mov dx, 0x80    ; HDD
    int 0x13

; Wyzeruj drugi i trzeci sektor
    xor ax, ax
    mov es, ax
    mov bx, 0x7e00  ; ładuj z 0x7e00. Są tam zera
    mov cx, 2       ; ładuj do drugiego sektora
    mov al, 2       ; ładuj dwa sektory
    mov ah, 03      ; function 03: Write Sectors
    mov dx, 0x80    ; HDD
    int 0x13

; Przejdź do oryginalnego mbr
    jmp 0:0x7c00

; Wypisuj bajty spod adresu w ax, aż do napotkania 0x0.
print:
    xor bx, bx
    mov si, ax
    mov ah, 0x0e
print_loop:
    mov al, byte [si]
    test al, al
    jz print_done
    int 0x10
    inc si

    cmp al, 0xa
    jne print_loop

; Dodaj carriage return
    mov al, 0xd
    int 0x10

    jmp print_loop
print_done:
; Dodaj newline
    mov al, 0xa
    int 0x10

    mov al, 0xd
    int 0x10

    ret

times 510 - ($ - $$) db 0
dw 0xaa55

