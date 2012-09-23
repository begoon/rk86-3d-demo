monitor_putc equ 0f809h
monitor_puts equ 0f818h
monitor_hexb equ 0f815h
monitor equ 0f86ch

video_area equ 76d0h
video_area_end equ video_area + (78*30)

  org 0h

  mvi c, 1fh
  call monitor_putc

init_frame_start:
  lxi h, initial_frame
  lxi d, video_area
initial_frame_loop:
  mov a, m
  cpi 'X'
  jnz initial_frame_blank
  mvi a, 7fh
initial_frame_blank:
  stax d
  inx h
  inx d
  mov a, d
  cpi HIGH(video_area_end)
  jnz initial_frame_loop
  mov a, e
  cpi LOW(video_area_end)
  jnz initial_frame_loop

next_frame:
  lxi d, 2000
frame_delay_loop:
  dcx d
  mov a, d
  ora e
  jnz frame_delay_loop

  mov a, m
  inx h
  cpi 255
  jz init_frame_start
  cpi 0
  jz next_frame

  mov c, a
frame_loop:
  mov e, m
  inx h
  mov d, m
  inx h
  ldax d
  cpi ' '
  mvi a, 7fh
  jz frame_loop_1
  mvi a, ' '
frame_loop_1:
  stax d
  dcr c
  jnz frame_loop
  jmp next_frame

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

  include "frames.asm"
