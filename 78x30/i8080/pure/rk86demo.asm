monitor_putc equ 0f809h
monitor_puts equ 0f818h
monitor_hexb equ 0f815h
monitor equ 0f86ch

video_start equ 76d0h
video_end equ video_start + 0924h

  org 0h

  mvi c, 1fh
  call monitor_putc

  lxi h, decompress_msg
  call monitor_puts

  call decompress_banner

  mvi c, 1fh
  call monitor_putc

  call play

  jmp monitor

play:

;  for (iy = 15; iy < 45; iy++) {
;     var y = 512 + (iy < 30 ? - Math.floor(17*(30-iy)) : 
;                              + Math.floor(17*(iy-30)));
;
;     for (ix = 39; ix < 117; ix++) {
;       var x = 512 + (ix < 78 ? - Math.floor(7*(78-ix)) : 
;                                + Math.floor(7*(ix-78)));
;
;       z_ofs = sin_(sin_(time + 384) + x*2) + sin_(sin_(time) + y*2 + 384);
;
;       var z = Math.floor(z_ofs / 2);
;
;       var zdiv = Math.floor(61440/(384 + z));
;
;       if (x >= 512) {
;         u = (x-512)*zdiv;
;         iu = 39 + Math.floor(u/439);
;       } else {
;         u = (512-x)*zdiv;
;         iu = 39 - Math.floor(u/439);
;       }
;       iu += 2;
;
;       if (y >= 512) {
;         v = (y-512)*zdiv;
;         iv = 15 + Math.floor(v/(256*6));
;       } else {
;         v = (512-y)*zdiv;
;         iv = 15 - Math.floor(v/(256*6));
;       }
;       iv += 1;
;
;       var pixel = 0;
;       if (iu >= 0 && iu < width && iv >= 0 && iv < height) {
;         pixel = banner[iv].charAt(iu);
;       }
;       screen_draw_char(ix-39, iy-15, pixel == ' ' ? 0 : 127);
;     }
;   }
; 
;   time = (time + 8) % (256*256);

    lxi h, 0
    shld time

play_loop:

    lxi h, video_start
    shld xy_addr

;   for (iy = 15; iy < 45; iy++) {
    mvi a, 15
    sta iy

iy_loop:
;   var y = 512 + (iy < 30 ? - Math.floor(17*(30-iy)) : 
;                            + Math.floor(17*(iy-30)));
    mvi c, 30
    lda iy
    cmp c            ; iy < 30?
    jp iy_greater_30 ; If iy >= 30, go to the case 2.

    mov b, a         ; B = iy
    mov a, c         ; A = 30
    sub b            ; A = 30-iy

    mov l, a         ; HL = 30-iy
    mvi h, 0

    ; lxi d, 17
    ; call mul16     ; HL = 17*(30-iy)
    mov d, h
    mov e, l
    dad h            ; HL = HL*2
    dad h            ; HL = HL*4
    dad h            ; HL = HL*8
    dad h            ; HL = HL*16
    dad d            ; HL = 17*(30-iy)

    mov a, l
    cma
    mov l, a
    mov a, h
    cma
    mov h, a
    inx h            ; HL = -17*(30-iy)

iy_loop_norm:
    lxi d, 512
    dad d            ; HL = 512 - 17*(30-iy) or 512 + (iy-30)*17 (case 2)

    shld y

    jmp ix_loop_prolog

iy_greater_30:

    sub c            ; A = iy-30

    mov l, a
    mvi h, 0         ; HL = iy-30

    ; lxi d, 17
    ; call mul16     ; HL = 17*(iy-30)
    mov d, h
    mov e, l
    dad h            ; HL = HL*2
    dad h            ; HL = HL*4
    dad h            ; HL = HL*8
    dad h            ; HL = HL*16
    dad d            ; HL = 17*(iy-30)

    jmp iy_loop_norm

ix_loop_prolog:

;   for (ix = 39; ix < 117; ix++) {
    mvi a, 39
    sta ix

ix_loop:

    mvi c, 78
    lda ix
    cmp c            ; ix < 78?
    jp ix_greater_78 ; If ix >= 78, go to the case 2.

    mov b, a         ; B = ix
    mov a, c         ; A = 78
    sub b            ; A = 78-ix

    mov l, a         ; HL = 78-ix
    mvi h, 0

    ; lxi d, 7
    ; call mul16     ; HL = 7*(78-ix)
    ; We multiply by 7 "quickly".
    mov e, l
    mov d, h
    dad h            ; HL = HL*2
    dad h            ; HL = HL*4
    dad d            ; HL = HL*5
    dad d            ; HL = HL*6
    dad d            ; HL = HL*7

    mov a, l
    cma
    mov l, a
    mov a, h
    cma
    mov h, a
    inx h            ; HL = -7*(78-ix)

ix_loop_norm:
    lxi d, 512
    dad d            ; HL = 512 - 7*(78-ix) or 512 + 7*(78-ix) (case 2)

    shld x
    jmp calc_z

ix_greater_78:
    sub c            ; A = ix-78

    mov l, a
    mvi h, 0         ; HL= ix-78

    ; lxi d, 7
    ; call mul16     ; HL = 7*(ix-78)
    mov e, l
    mov d, h
    dad h            ; HL = HL*2
    dad h            ; HL = HL*4
    dad d            ; HL = HL*5
    dad d            ; HL = HL*6
    dad d            ; HL = HL*7

    jmp ix_loop_norm

calc_z:

    lhld time
    lxi d, 384
    dad d            ; HL = time + 384
    call calc_sin    ; HL = sin(time + 384)
    xchg
    lhld x
    dad h            ; HL = x*2
    dad d            ; HL = sin(time + 384) + x*2
    call calc_sin    ; HL = sin(sin(time + 384) + x*2)

    push h

    lhld time
    call calc_sin    ; HL = sin(time)

    xchg
    lhld y
    dad h            ; HL = y*2
    dad d            ; HL = sin(time) + y*2
    lxi d, 384
    dad d            ; HL = sin(time) + y*2 + 384
    call calc_sin    ; HL = sin(sin(time) + y*2 + 384)

    pop d
    dad d            ; HL = sin(sin(time + 384) + x*2) 
                     ;    + sin(sin(time) + y*2 + 384)
    xra a            ; CF = 0
    mov a, h
    rar
    mov h, a
    mov a, l
    rar
    mov l, a         ; HL >>= 1 (HL /= 2) (z)

    lxi d, 384
    dad d            ; HL = z + 384
    lxi d, 61440
    call div16       ; HL = 61440/(z + 384)

    shld zdiv

calc_iu:

    lhld  x          ; HL = x
    xchg             ; DE = x
    lxi h, 512       ; 
    call cmp16       ; DE < HL? x < 512?
    xchg             ; HL = x
    jc x_less_512    ; If no, go to the case 2

    lxi d, -512
    dad d            ; HL = x - 512
    xchg
    lhld zdiv
    call mul16       ; HL = zdiv * (x - 512) (u)
    xchg             ; DE = u
    lxi h, 439
    call div16       ; HL = u/439

iu_norm:
    lxi d, 39
    dad d            ; HL = 30 + u/439 or 39 - u/439 (iu)
    inx h
    inx h            ; HL = iu + 2
    shld iu

    jmp calc_iv

x_less_512:
    mov a, l
    cma
    mov l, a
    mov a, h
    cma
    mov h, a
    inx h           ; HL = -x

    lxi d, 512
    dad d           ; HL = 512 - x
    xchg
    lhld zdiv
    call mul16      ; HL = zdiv * (512 - x) (u)
    xchg            ; DE = u
    lxi h, 439
    call div16      ; HL = u/439

    mov a, l
    cma
    mov l, a
    mov a, h
    cma
    mov h, a
    inx h           ; HL = -u/439
    jmp iu_norm

calc_iv:

    lhld  y          ; HL = y
    xchg             ; DE = y
    lxi h, 512       ; 
    call cmp16       ; DE < HL? y < 512?
    xchg             ; HL = y
    jc y_less_512    ; If no, go to the case 2

    lxi d, -512
    dad d            ; HL = y - 512
    xchg
    lhld zdiv
    call mul16       ; HL = zdiv * (y - 512) (v)
    xchg             ; DE = v

    lxi h, 256*6
    call div16       ; HL = v/(256*6)

iv_norm:
    lxi d, 15
    dad d            ; HL = 15 + v/(256*6) or 15 - v/(256*6) (iv)
    inx h            ; HL = iv + 1
    shld iv

    jmp draw_point

y_less_512:
    mov a, l
    cma
    mov l, a
    mov a, h
    cma
    mov h, a
    inx h            ; HL = -y

    lxi d, 512
    dad d            ; HL = 512 - x
    xchg
    lhld zdiv
    call mul16       ; HL = zdiv * (512 - x) (v)
    xchg             ; DE = v
    lxi h, (256*6)
    call div16       ; HL = v/(256*6)

    mov a, l
    cma
    mov l, a
    mov a, h
    cma
    mov h, a
    inx h            ; HL = -v/(256*6)
    jmp iv_norm

draw_point:
    mvi c, 0         ; The point by default.

    lhld iu          ; HL = iu
    xchg
    lxi h, 78
    call cmp16       ; DE < HL? iu < 78?
    jnc skip_point   ; If not, skip the point.

    lhld iv          ; HL = iv
    xchg
    lxi h, 30
    call cmp16       ; DE < HL? iv < 30?
    jnc skip_point   ; If not, skip the point.

    ; The "slow" way of displaying a character.
    ; lhld iv
    ; lxi d, 78
    ; call mul16     ; HL = iv*78
    ; xchg
    ; lhld iu
    ; dad d          ; HL = iv*78 + iu
    ; lxi d, banner
    ; dad d          ; HL = iv*78 + iu + banner
    ; mov c, m       ; C = banner[iv*78 + iu]

    lda iv
    mov h, a
    lda iu
    mov l, a
    call banner_char
    mov c, a

skip_point:

    ; lda ix
    ; sui 39
    ; mov l, a        ; L = ix-39

    ; lda iy
    ; sui 15
    ; mov h, a        ; H = iy-15

    ; mov a, c
    ; call put_char

    lhld xy_addr
    mov m, c
    inx h
    shld xy_addr

;   for (ix = 39; ix < 117; ix++) {
;   }

    lxi h, ix
    inr m
    mov a, m
    cpi 117
    jm ix_loop

;   for (iy = 15; iy < 45; iy++) {
;   }

    lxi h, iy
    inr m
    mov a, m
    cpi 45
    jm iy_loop

    lhld time
    lxi d, 8
    dad d
    shld time

    jmp play_loop

    ret

ix   db 0
iy   db 0

x    dw 0
y    dw 0
zdiv dw 0
iu   dw 0
iv   dw 0

xy_addr dw 0

time dw 0

put_char:
  push h
  push d
  push b
  push psw
  mov c, l            ; C = x

  xra a               ; CF = 0
  mov a, h            ; A = y
  ral                 ; A = y*2
  mvi h, 0            ;
  mov l, a            ; HL = y * 2
  lxi d, put_char_line00
  dad d               ; HL = put_char_line00 + y*2
  mov e, m
  inx h
  mov d, m            ; DE = [put_char_line00 + y*2]

  mov l, c
  mvi h, 0            ; HL = x

  dad d               ; HL = [put_char_line00 + y*2] + x

  pop psw
  mov m, a
  pop b
  pop d
  pop h
  ret

put_char_line00 dw video_start
put_char_line01 dw video_start + (78*01)
put_char_line02 dw video_start + (78*02)
put_char_line03 dw video_start + (78*03)
put_char_line04 dw video_start + (78*04)
put_char_line05 dw video_start + (78*05)
put_char_line06 dw video_start + (78*06)
put_char_line07 dw video_start + (78*07)
put_char_line08 dw video_start + (78*08)
put_char_line09 dw video_start + (78*09)
put_char_line10 dw video_start + (78*10)
put_char_line11 dw video_start + (78*11)
put_char_line12 dw video_start + (78*12)
put_char_line13 dw video_start + (78*13)
put_char_line14 dw video_start + (78*14)
put_char_line15 dw video_start + (78*15)
put_char_line16 dw video_start + (78*16)
put_char_line17 dw video_start + (78*17)
put_char_line18 dw video_start + (78*18)
put_char_line19 dw video_start + (78*19)
put_char_line20 dw video_start + (78*20)
put_char_line21 dw video_start + (78*21)
put_char_line22 dw video_start + (78*22)
put_char_line23 dw video_start + (78*23)
put_char_line24 dw video_start + (78*24)
put_char_line25 dw video_start + (78*25)
put_char_line26 dw video_start + (78*26)
put_char_line27 dw video_start + (78*27)
put_char_line28 dw video_start + (78*28)
put_char_line29 dw video_start + (78*29)

banner_char:
  push h
  push d
  push b
  mov c, l            ; C = x

  xra a               ; CF = 0
  mov a, h            ; A = y
  ral                 ; A = y*2
  mvi h, 0            ;
  mov l, a            ; HL = y * 2
  lxi d, banner_line00
  dad d               ; HL = banner_line00 + y*2
  mov e, m
  inx h
  mov d, m            ; DE = [banner_line00 + y*2]

  mov l, c
  mvi h, 0            ; HL = x

  dad d               ; HL = [banner_line00 + y*2] + x

  mov a, m
  pop b
  pop d
  pop h
  ret

banner_line00: 
    dw banner
    dw banner + (78*01)
    dw banner + (78*02)
    dw banner + (78*03)
    dw banner + (78*04)
    dw banner + (78*05)
    dw banner + (78*06)
    dw banner + (78*07)
    dw banner + (78*08)
    dw banner + (78*09)
    dw banner + (78*10)
    dw banner + (78*11)
    dw banner + (78*12)
    dw banner + (78*13)
    dw banner + (78*14)
    dw banner + (78*15)
    dw banner + (78*16)
    dw banner + (78*17)
    dw banner + (78*18)
    dw banner + (78*19)
    dw banner + (78*20)
    dw banner + (78*21)
    dw banner + (78*22)
    dw banner + (78*23)
    dw banner + (78*24)
    dw banner + (78*25)
    dw banner + (78*26)
    dw banner + (78*27)
    dw banner + (78*28)
    dw banner + (78*29)

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
  db "idu na wzlet...",
decompress_msg_sz equ $ - decompress_msg_text
  db ' ', 0

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

clear_screen:
    push psw
    push h
    push d
    push b
    lxi b, 78*30
    lxi h, video_start
    mvi e, 0
clear_screen_loop:
    mov m, e
    inx h
    dcx b
    mov a, b
    ora c
    jnz clear_screen_loop
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
;
calc_sin:
    push psw
    push b
    push d

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
    cma
    inr a
    mov e, a
    mvi d, 0ffh       ; DE = -sin_table[HL]

calc_sin_normalize:
    lxi h, 256        ; HL += sin_table_scale*2 (r)
    dad d

    pop d
    pop b
    pop psw
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

mul16:
        push psw
        push b
        push d
        call ccmul
        pop d
        pop b
        pop psw
        ret

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

div16:
        push psw
        push b
        push d
        call ccudiv
        pop d
        pop b
        pop psw
        ret

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

decompress_banner:
    lxi d, banner
    lxi h, compressed_banner
decompress_banner_loop:
    call spinner
    xra a                        ; CF=0
    mov a, m                     ; A = current byte
    rar                          ; D0 = 1?
    mov c, a                     ; C = D7-D1, counter
    mvi a, 07fh
    jc decompress_banner_repeat  ; Yes, fill with 0ffh.
    xra a                        ; No, fill with 0
decompress_banner_repeat:        ; Save A to [DE] C times.
    stax d
    inx d
    dcr c
    jp decompress_banner_repeat

    inx h
    mvi a, HIGH(compressed_banner_end)
    cmp h
    jnz decompress_banner_loop
    mvi a, LOW(compressed_banner_end)
    cmp l
    jnz decompress_banner_loop
    ret

compressed_banner:
  db 0feh, 0feh, 074h, 01dh, 006h, 005h, 010h, 005h
  db 006h, 01dh, 006h, 01dh, 00ah, 01dh, 006h, 005h
  db 00eh, 007h, 006h, 01dh, 006h, 01dh, 00ah, 005h
  db 010h, 005h, 006h, 005h, 00ch, 007h, 008h, 005h
  db 010h, 005h, 006h, 005h, 022h, 005h, 010h, 005h
  db 006h, 005h, 00ah, 007h, 00ah, 005h, 010h, 005h
  db 006h, 005h, 022h, 005h, 010h, 005h, 006h, 005h
  db 008h, 007h, 00ch, 005h, 010h, 005h, 006h, 005h
  db 022h, 005h, 010h, 005h, 006h, 005h, 006h, 007h
  db 00eh, 005h, 010h, 005h, 006h, 005h, 022h, 005h
  db 010h, 005h, 006h, 005h, 004h, 007h, 010h, 005h
  db 010h, 005h, 006h, 005h, 022h, 005h, 010h, 005h
  db 006h, 005h, 002h, 007h, 012h, 005h, 010h, 005h
  db 006h, 005h, 022h, 005h, 010h, 005h, 006h, 005h
  db 000h, 007h, 014h, 005h, 010h, 005h, 006h, 005h
  db 022h, 01dh, 006h, 00dh, 016h, 01dh, 006h, 01dh
  db 00ah, 01dh, 006h, 00dh, 016h, 01dh, 006h, 01dh
  db 00ah, 005h, 01eh, 005h, 000h, 007h, 014h, 005h
  db 010h, 005h, 006h, 005h, 010h, 005h, 00ah, 005h
  db 01eh, 005h, 002h, 007h, 012h, 005h, 010h, 005h
  db 006h, 005h, 010h, 005h, 00ah, 005h, 01eh, 005h
  db 004h, 007h, 010h, 005h, 010h, 005h, 006h, 005h
  db 010h, 005h, 00ah, 005h, 01eh, 005h, 006h, 007h
  db 00eh, 005h, 010h, 005h, 006h, 005h, 010h, 005h
  db 00ah, 005h, 01eh, 005h, 008h, 007h, 00ch, 005h
  db 010h, 005h, 006h, 005h, 010h, 005h, 00ah, 005h
  db 01eh, 005h, 00ah, 007h, 00ah, 005h, 010h, 005h
  db 006h, 005h, 010h, 005h, 00ah, 005h, 01eh, 005h
  db 00ch, 007h, 008h, 005h, 010h, 005h, 006h, 005h
  db 010h, 005h, 00ah, 005h, 01eh, 005h, 00eh, 007h
  db 006h, 005h, 010h, 005h, 006h, 005h, 010h, 005h
  db 00ah, 005h, 01eh, 005h, 010h, 005h, 006h, 005h
  db 010h, 005h, 006h, 005h, 010h, 005h, 00ah, 005h
  db 01eh, 005h, 010h, 005h, 006h, 01dh, 006h, 01dh
  db 00ah, 005h, 01eh, 005h, 010h, 005h, 006h, 01dh
  db 006h, 01dh, 0feh, 0feh, 074h

compressed_banner_end equ $
compressed_banner_sz equ compressed_banner_end - compressed_banner

banner ds 78*30
