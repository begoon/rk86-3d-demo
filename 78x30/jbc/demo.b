height = 30
width = 78

DIM S(30), M(30)
FOR I = 0 TO height-1
S(I) = SPACE(width)
M(I) = SPACE(width)
NEXT I

GOSUB build_gfx

time = 0

loop:

GOSUB refresh

FOR iy = 0 TO height-1
  y = 2.0 * iy / height - 1.0
  FOR ix = 0 TO width-1
    x = 2.0 * (ix - width/2) / width

    z = 0.08 * (SIN((COS(time)+x)*360) + COS((SIN(time)+y)*360))
    zdiv = 2 / (1 + z)

    u = x * zdiv
    v = y * zdiv

    iu = width/2 + INT(0.6 * u * width/2)
    iv = height/2 + INT(0.6 * v * height/2)

    ch = " "
    IF (iu >= 0) AND (iu < width) AND (iv >= 0) AND (iv < height) THEN
      ch = M(iv)[iu + 1, 1]
    END
    S(iy)[ix + 1, 1] = ch
  NEXT
NEXT

IF SYSTEM(14) > 0 THEN STOP

time = time + 1

GOTO loop

STOP

refresh:
CRT @(-2)
FOR I = 0 TO height-1
CRT S(I):
CRT
NEXT I
RETURN

build_gfx:

M(00) = "                                                                              "
M(01) = "                                                                              "
M(02) = "                                                                              "
M(03) = "                                                                              "
M(04) = "   XXXXXXXXXXXXXXX    XXX         XXX    XXXXXXXXXXXXXXX    XXXXXXXXXXXXXXX   "
M(05) = "   XXXXXXXXXXXXXXX    XXX        XXXX    XXXXXXXXXXXXXXX    XXXXXXXXXXXXXXX   "
M(06) = "   XXX         XXX    XXX       XXXX     XXX         XXX    XXX               "
M(07) = "   XXX         XXX    XXX      XXXX      XXX         XXX    XXX               "
M(08) = "   XXX         XXX    XXX     XXXX       XXX         XXX    XXX               "
M(09) = "   XXX         XXX    XXX    XXXX        XXX         XXX    XXX               "
M(10) = "   XXX         XXX    XXX   XXXX         XXX         XXX    XXX               "
M(11) = "   XXX         XXX    XXX  XXXX          XXX         XXX    XXX               "
M(12) = "   XXX         XXX    XXX XXXX           XXX         XXX    XXX               "
M(13) = "   XXXXXXXXXXXXXXX    XXXXXXX            XXXXXXXXXXXXXXX    XXXXXXXXXXXXXXX   "
M(14) = "   XXXXXXXXXXXXXXX    XXXXXXX            XXXXXXXXXXXXXXX    XXXXXXXXXXXXXXX   "
M(15) = "   XXX                XXX XXXX           XXX         XXX    XXX         XXX   "
M(16) = "   XXX                XXX  XXXX          XXX         XXX    XXX         XXX   "
M(17) = "   XXX                XXX   XXXX         XXX         XXX    XXX         XXX   "
M(18) = "   XXX                XXX    XXXX        XXX         XXX    XXX         XXX   "
M(19) = "   XXX                XXX     XXXX       XXX         XXX    XXX         XXX   "
M(20) = "   XXX                XXX      XXXX      XXX         XXX    XXX         XXX   "
M(21) = "   XXX                XXX       XXXX     XXX         XXX    XXX         XXX   "
M(22) = "   XXX                XXX        XXXX    XXX         XXX    XXX         XXX   "
M(23) = "   XXX                XXX         XXX    XXX         XXX    XXX         XXX   "
M(24) = "   XXX                XXX         XXX    XXXXXXXXXXXXXXX    XXXXXXXXXXXXXXX   "
M(25) = "   XXX                XXX         XXX    XXXXXXXXXXXXXXX    XXXXXXXXXXXXXXX   "
M(26) = "                                                                              " 
M(27) = "                                                                              "
M(28) = "                                                                              "
M(29) = "                                                                              "

RETURN
                                                                                       