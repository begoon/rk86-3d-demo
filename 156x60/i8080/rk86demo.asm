monitor_putc equ 0f809h
monitor_puts equ 0f818h
monitor_hexb equ 0f815h
monitor equ 0f86ch

video_start equ 76d0h
video_end equ video_start + 0924h

  org 0h

loop_start:
  call clean_pixels
  lxi h, (30*256)+0
loop:
  mvi a, 0ffh
  call put_pixel

  push h

  lhld time
  lxi d, 30
  dad d
  shld time

  call calc_sin

  xchg
  lxi h, 6
  call div16

  lxi d, 157
  call mul16
  mov a, h

  pop h
  mov h, a
  inr l
  mvi a, 156
  cmp l
  jnz loop

  lxi h, pixels
  call rasterize
; lxi h, frame_buf
; call update_screen

  jmp loop_start

time dw 0

print_sin:
  push b
  push h
  call calc_sin
  mov a, h
  call monitor_hexb
  mov a, l
  call monitor_hexb
  mvi c, ' '
  call monitor_putc
  pop h
  pop b
  ret

main:
  lxi h, banner
  call rasterize
  lxi h, frame_buf
  call update_screen

  lxi h, banner+1
  call rasterize
  lxi h, frame_buf
  call update_screen

  lxi h, banner+1+156
  call rasterize
  lxi h, frame_buf
  call update_screen

  lxi h, banner+156
  call rasterize
  lxi h, frame_buf
  call update_screen

  jmp main

spinner:
  push psw
  push h
  push b
  lxi h, spinner_msg
  call monitor_puts
  lhld spinner_index
  inx h
  mov a, m
  ora a
  jnz spinner_update
  lxi h, spinner_chars
spinner_update:
  shld spinner_index
  mov a, m
  sta spinner_msg + 1
  pop b
  pop h
  pop psw
  ret

spinner_msg:
  db 8, '-', 0
spinner_chars:
  db "-\!/", 0
spinner_index:
  dw spinner_chars

decompress_msg:
  db 1bh, 59h, 20h + (24/2), 20h + ((64-decompress_msg_sz)/2)
decompress_msg_text:
  db "idu na wzlet...", 0
decompress_msg_sz equ $ - decompress_msg_text

update_screen:
  lxi d, video_start
  lxi b, 78*30
update_screen_loop:
  mov a, m
  stax d
  inx h
  inx d
  dcx b
  mov a, c
  ora b
  jnz update_screen_loop
  ret

; hl - banner
rasterize:
    lxi d, video_start ; frame_buf
    mvi c, 78

rasterize_loop:
    mov a, m
    ani 8
    mov b, a
    inx h

    mov a, m
    ani 4
    ora b
    mov b, a
    inx h

    push d
    push h
    lxi d, 78*2 - 2
    dad d

    mov a, m
    ani 2
    ora b
    mov b, a

    inx h
    mov a, m
    ani 1
    ora b

    push d
    push h
    lxi h, rk86_gfx_chars
    mov e, a
    mvi d, 0
    dad d
    mov a, m
    pop h
    pop d

    pop h
    pop d

    stax d
    inx d

    dcr c
    jnz rasterize_no_eol

    push d
    lxi d, 78*2
    dad d
    pop d
    mvi c, 78

rasterize_no_eol:
    mvi a, HIGH(video_end)
    cmp d
    jnz rasterize_loop
    mvi a, LOW(video_end)
    cmp e
    jnz rasterize_loop

    ret

; H - y
; L - x
; A - color (00, FF)
put_pixel:
    push b
    push d
    push psw
    push h          ; Stack: BC DE PSW HL
    lxi d, 78*2
    mov l, h
    mvi h, 0
    call mul16
    xchg            ; DE = y*78*2
    pop h
    push h
    mvi h, 0
    dad d           ; HL = y*78*2 + x
    lxi d, pixels
    dad d           ; HL = pixels + y*78*2 + x
    xchg
    pop h           ; 
    pop psw         ; 
    stax d          ; [DE] = A
    pop d
    pop b
    ret

clean_pixels:
    push psw
    push h
    push d
    push b
    lxi b, 78*2*30*2
    lxi h, pixels
    mvi e, 0
clean_pixels_loop:
    mov m, e
    inx h
    dcx b
    mov a, b
    ora c
    jnz clean_pixels_loop
    pop b
    pop d
    pop h
    pop psw
    ret

prepare_banner:
    push psw
    push b
    push h
    lxi b, 78*2*30*2
    lxi h, banner
prepare_banner_loop:
    mov a, m
    ora a
    jz prepare_banner_0
    mvi m, 255
prepare_banner_0:
    inx h
    dcx b
    mov a, c
    ora b
    jnz prepare_banner_loop
    pop h
    pop b
    pop psw
    ret

rk86_gfx_chars:
    db 000h   ; 0000
    db 004h   ; 0001
    db 010h   ; 0010
    db 014h   ; 0011
    db 002h   ; 0100
    db 006h   ; 0101
    db 012h   ; 0110
    db 016h   ; 0111
    db 001h   ; 1000
    db 005h   ; 1001
    db 011h   ; 1010
    db 015h   ; 1011
    db 003h   ; 1100
    db 007h   ; 1101
    db 013h   ; 1110
    db 017h   ; 1111

; Calculate SIN
; =============
;
; function lookup_sin(x) {
;   // The formula:
;   // x = Math.floor(x*(sin_table_scale/256) / TWO_PI) % sin_table_scale;
;
;   // The "optimized" formula:
;   x = Math.floor(x/12) % 128;
;
;   var y = x % sin_table_quater;   // sin_table_quater = 32
;   var r = sin_table_scale*2;      // sin_table_scale = 128
;
;   if (x < sin_table_quater)          r += sin_table[   y];
;   else if (x < sin_table_quater * 2) r += sin_table[sin_table_quater-y];
;   else if (x < sin_table_quater * 3) r -= sin_table[   y];
;   else if (x < sin_table_quater * 4) r -= sin_table[sin_table_quater-y];
;   return r;
; }

; Input: HL - x
; Output: HL - r
; Overwrites: AF, BC, DE
;
calc_sin:
    xchg              ; DE = x
    lxi h, 12
    call div16        ; HL /= 12 (HL = DE / HL)

    mvi h, 0          ; HL = HL % 128 (HL &= 07Fh) (128 = 32*4)
    mov a, l          ;
    ani 07fh          ;
    mov l, a          ; HL: x = Math.floor(x/12) % 128

    mov a, l          ; A = L % 32
    ani 01fh          ; 
    mov c, a          ; C: y = x % sin_table_quarter

    xchg              ; DE = x

    lxi h, 32         ; HL = sin_table_quarter

    call cmp16        ; DE < HL? (x < sin_table_quarter ?)
    jc calc_sin_1
    mvi l, 32*2       ; HL = sin_table_quarter*2
    call cmp16        ; DE < HL? (x < sin_table_quarter*2 ?)
    jc calc_sin_2
    mvi l, 32*3       ; HL = sin_table_quarter*3
    call cmp16        ; DE < HL? (x < sin_table_quarter*3 ?)
    jc calc_sin_3
calc_sin_4:
    mvi a, 32         ; a = sin_table_quarter
    sub c
    mov l, a          ; HL = sin_table_quarter-y
calc_sin_4x:
    mvi h, 0          ; y is always less than 256
    lxi d, sin_table
    dad d             ; HL = sin_table + HL, HL=y or HL=sin_table_quarter-y
    mov a, m          ; A = sin_table[HL]
    xri 0ffh
    inr a
    mov e, a
    mvi d, 0ffh       ; DE = -A

calc_sin_normalize:
    lxi h, 256        ; HL: r = sin_table_scale*2
    dad d
    ret

calc_sin_3:
    mov l, c          ; HL = y
    jmp calc_sin_4x

calc_sin_1:
    mov l, c          ; HL = y
calc_sin_1x:
    mvi h, 0
    lxi d, sin_table  
    dad d             ; HL = sin_table + y
    mov e, m          ; E = [HL] (D=0)
    mvi d, 0
    jmp calc_sin_normalize

calc_sin_2:
    mvi a, 32         ; a = sin_table_quarter
    sub c
    mov l, a          ; HL = sin_table_quarter-y
    jmp calc_sin_1x

; 32+1 (33) values of the pre-calculated SIN() function.
sin_table:
    db 0, 12, 24, 36, 48, 59, 71, 83, 94, 105, 116, 126, 137, 147, 156, 166,
    db 174, 183, 191, 199, 206, 213, 220, 226, 231, 236, 240, 244, 248, 250, 
    db 253, 254, 255

debug_hl:
    push psw
    push b
    mov a, h
    call monitor_hexb
    mov a, l
    call monitor_hexb
    mvi c, ' '
    call monitor_putc
    pop b
    pop psw
    ret

;
; HL = DE * HL [signed]
;
; Grabbed from the Small-C runtime library.
; https://github.com/begoon/smallc-85/blob/master/crun8080lib
;
ccmul:  mov     b,h             ; store multiplier to bc
        mov     c,l
        lxi     h,0             ; result = 0
ccmul1: mov     a,c             ; check the lowerest bit of c
        rrc
        jnc     ccmul2          ; if not 1, skip summation
        dad     d               ; if 1, add the current value from de
ccmul2: xra     a               ; cf = 0
        mov     a,b             ; bc >>= 1
        rar                     ;
        mov     b,a             ;
        mov     a,c             ;
        rar                     ;
        mov     c,a             ; 
        ora     b               ; if bc = 0, return
        rz
        xra     a               ; cf = 0
        mov     a,e             ; de <<= 1
        ral
        mov     e,a
        mov     a,d
        ral
        mov     d,a
        ora     e               ; if de has meaningful bit of the left, return
        rz
        jmp     ccmul1          ; repeat until bc != 0

mul16 equ ccmul

;
; Unsigned divide DE by HL and return quotient in HL, remainder in DE.
; HL = DE / HL, DE = DE % HL
;
; Grabbed from the Small-C runtime library.
; https://github.com/begoon/smallc-85/blob/master/crun8080lib
;
ccudiv: mov     b,h             ; store divisor to bc 
        mov     c,l
        lxi     h,0             ; clear remainder
        xra     a               ; clear carry
        mvi     a,17            ; load loop counter
        push    psw
ccduv1: mov     a,e             ; left shift dividend into carry 
        ral
        mov     e,a
        mov     a,d
        ral
        mov     d,a
        jc      ccduv2          ; we have to keep carry -> calling else branch
        pop     psw             ; decrement loop counter
        dcr     a
        jz      ccduv5
        push    psw
        xra     a               ; clear carry
        jmp     ccduv3
ccduv2: pop     psw             ; decrement loop counter
        dcr     a
        jz      ccduv5
        push    psw
        stc                     ; set carry
ccduv3: mov     a,l             ; left shift carry into remainder 
        ral
        mov     l,a
        mov     a,h
        ral
        mov     h,a
        mov     a,l             ; substract divisor from remainder
        sub     c
        mov     l,a
        mov     a,h
        sbb     b
        mov     h,a
        jnc     ccduv4          ; if result negative, add back divisor, clear carry
        mov     a,l             ; add back divisor
        add     c
        mov     l,a
        mov     a,h
        adc     b
        mov     h,a
        xra     a               ; clear carry
        jmp     ccduv1
ccduv4: stc                     ; set carry
        jmp     ccduv1
ccduv5: xchg
        ret

div16 equ ccudiv

;
; Unsigned compare of DE and HL
;   carry is sign of difference [CF=1 if DE < HL, CF=0 otherwise]
;   zero is zero/non-zero
;
; Grabbed from the Small-C runtime library.
; https://github.com/begoon/smallc-85/blob/master/crun8080lib
;
ccucmp: mov     a,d
        cmp     h
        rnz
        mov     a,e
        cmp     l
        ret

cmp16 equ ccucmp

; Image compression
; -----------------

; - length of compressed data, 2 bytes (LOW, HIGH), little endian.
; - pairs (1-bit value, 7-bit counter)

decompress_banner:
    lxi b, 0288h
    lxi d, banner
    lxi h, banner_compressed
decompress_banner_loop:
    call spinner
    mov a, m                     ; A = current byte
    push b

    ral                          ; D7 = 1?
    mvi b, 0ffh
    jc decompress_banner_1       ; Yes, fill with 0ffh
    inr b                        ; No, fill with 0
decompress_banner_1:
    mov a, m                     ; A = current byte
    ani 07fh                     ; Mask D7
    mov c, a                     ; C = D6-D0, counter
    mov a, b                     ; A = 0 or 0ffh
decompress_banner_repeat:        ; Save A to [DE] C times
    stax d
    inx d
    dcr c
    jp decompress_banner_repeat

    pop b

    inx h
    dcx b
    mov a, c
    ora b
    jnz decompress_banner_loop
    ret

banner_compressed:
    db 07fh, 07fh, 07fh, 07fh, 07fh, 07fh, 07fh, 041h
    db 08ah, 0ch, 089h, 010h, 088h, 0dh, 083h, 05h
    db 083h, 0ah, 089h, 02eh, 08bh, 0ah, 08bh, 0eh
    db 08ah, 0ch, 083h, 05h, 083h, 09h, 08bh, 02dh
    db 08ch, 08h, 08dh, 0ch, 08ch, 0bh, 083h, 05h
    db 083h, 08h, 08dh, 02ch, 083h, 04h, 084h, 07h
    db 084h, 03h, 084h, 0ch, 084h, 02h, 084h, 0bh
    db 083h, 05h, 083h, 08h, 084h, 03h, 084h, 02ch
    db 083h, 05h, 083h, 07h, 083h, 05h, 083h, 0ch
    db 083h, 04h, 083h, 0bh, 083h, 05h, 083h, 08h
    db 083h, 05h, 083h, 02ch, 083h, 05h, 083h, 07h
    db 083h, 05h, 083h, 0ch, 083h, 04h, 083h, 0bh
    db 083h, 05h, 083h, 08h, 083h, 05h, 083h, 02ch
    db 083h, 05h, 083h, 07h, 083h, 05h, 083h, 0ch
    db 083h, 04h, 083h, 0bh, 083h, 05h, 083h, 08h
    db 083h, 05h, 083h, 02ch, 083h, 05h, 083h, 07h
    db 083h, 05h, 083h, 0ch, 083h, 04h, 083h, 0bh
    db 083h, 05h, 083h, 08h, 083h, 05h, 083h, 02ch
    db 083h, 04h, 084h, 07h, 083h, 05h, 083h, 0ch
    db 083h, 04h, 083h, 0bh, 083h, 05h, 083h, 08h
    db 083h, 05h, 083h, 02ch, 08dh, 07h, 08dh, 0ch
    db 083h, 04h, 083h, 0bh, 083h, 05h, 083h, 08h
    db 083h, 05h, 083h, 02ch, 08ch, 08h, 08dh, 0ch
    db 083h, 04h, 083h, 0bh, 083h, 05h, 083h, 08h
    db 083h, 05h, 083h, 02ch, 08bh, 09h, 08dh, 0ch
    db 083h, 04h, 083h, 0bh, 083h, 05h, 083h, 08h
    db 083h, 05h, 083h, 02ch, 08ah, 0ah, 08dh, 0ch
    db 083h, 04h, 083h, 0bh, 083h, 03h, 085h, 08h
    db 083h, 05h, 083h, 02ch, 083h, 011h, 083h, 05h
    db 083h, 0ch, 083h, 04h, 083h, 0bh, 083h, 03h
    db 085h, 08h, 083h, 05h, 083h, 02ch, 083h, 011h
    db 083h, 05h, 083h, 0ch, 083h, 04h, 083h, 0bh
    db 083h, 02h, 086h, 08h, 083h, 05h, 083h, 02ch
    db 083h, 011h, 083h, 05h, 083h, 0ch, 083h, 04h
    db 083h, 0bh, 083h, 01h, 087h, 08h, 083h, 05h
    db 083h, 02ch, 083h, 011h, 083h, 05h, 083h, 0ch
    db 083h, 04h, 083h, 0bh, 083h, 00h, 088h, 08h
    db 083h, 05h, 083h, 02ch, 083h, 011h, 083h, 05h
    db 083h, 0ch, 083h, 04h, 083h, 0bh, 088h, 00h
    db 083h, 08h, 083h, 05h, 083h, 02ch, 083h, 011h
    db 083h, 05h, 083h, 0ch, 083h, 04h, 083h, 0bh
    db 087h, 01h, 083h, 08h, 084h, 03h, 084h, 02ch
    db 083h, 011h, 083h, 05h, 083h, 08h, 094h, 07h
    db 087h, 01h, 083h, 08h, 08dh, 02ch, 083h, 011h
    db 083h, 05h, 083h, 08h, 094h, 07h, 086h, 02h
    db 083h, 09h, 08bh, 02dh, 083h, 011h, 083h, 05h
    db 083h, 08h, 094h, 07h, 083h, 05h, 083h, 0ah
    db 089h, 07fh, 07fh, 07fh, 07fh, 07fh, 07fh, 04dh
    db 089h, 05h, 088h, 0ah, 08bh, 03h, 082h, 05h
    db 083h, 059h, 08bh, 03h, 08ah, 09h, 08ch, 02h
    db 082h, 04h, 084h, 058h, 08dh, 01h, 08ch, 08h
    db 08dh, 01h, 082h, 03h, 084h, 059h, 083h, 05h
    db 083h, 01h, 083h, 05h, 082h, 08h, 083h, 04h
    db 084h, 01h, 082h, 02h, 084h, 05ah, 083h, 05h
    db 083h, 01h, 083h, 05h, 082h, 08h, 083h, 05h
    db 083h, 01h, 082h, 01h, 084h, 05bh, 083h, 05h
    db 083h, 01h, 083h, 011h, 083h, 05h, 083h, 01h
    db 082h, 00h, 084h, 05ch, 083h, 05h, 083h, 01h
    db 083h, 011h, 083h, 05h, 083h, 01h, 087h, 05dh
    db 083h, 05h, 083h, 01h, 083h, 011h, 083h, 05h
    db 083h, 01h, 087h, 05dh, 083h, 05h, 083h, 01h
    db 083h, 011h, 083h, 04h, 084h, 01h, 086h, 05eh
    db 08dh, 01h, 08ah, 0ah, 08dh, 01h, 089h, 05bh
    db 08dh, 01h, 08bh, 09h, 08dh, 01h, 08bh, 059h
    db 08dh, 01h, 08ch, 08h, 08ch, 02h, 08ch, 058h
    db 08dh, 01h, 08ch, 08h, 08bh, 03h, 08ch, 058h
    db 083h, 05h, 083h, 01h, 083h, 04h, 083h, 08h
    db 083h, 0bh, 082h, 05h, 083h, 058h, 083h, 05h
    db 083h, 01h, 083h, 04h, 083h, 08h, 083h, 0bh
    db 082h, 06h, 082h, 058h, 083h, 05h, 083h, 01h
    db 083h, 04h, 083h, 08h, 083h, 0bh, 082h, 06h
    db 082h, 058h, 083h, 05h, 083h, 01h, 083h, 04h
    db 083h, 08h, 083h, 0bh, 082h, 06h, 082h, 058h
    db 083h, 05h, 083h, 01h, 083h, 04h, 083h, 08h
    db 083h, 0bh, 082h, 06h, 082h, 058h, 083h, 05h
    db 083h, 01h, 083h, 04h, 083h, 08h, 083h, 0bh
    db 082h, 06h, 082h, 058h, 08dh, 01h, 08ch, 08h
    db 083h, 0bh, 082h, 06h, 082h, 059h, 08bh, 03h
    db 08ah, 09h, 083h, 0bh, 082h, 06h, 082h, 05ah
    db 089h, 05h, 088h, 0ah, 083h, 0bh, 082h, 06h
    db 082h, 07fh, 07fh, 07fh, 07fh, 07fh, 07fh, 039h

banner ds 78*2*30*2
pixels ds 78*2*30*2

frame_buf ds 78*2*30*2
frame_buf_end equ $
