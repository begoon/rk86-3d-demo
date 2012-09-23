#include <stdlib.h>
#include <stdio.h>
#include <assert.h>

static char* image[78] = {
"                                                                              ",
"                                                                              ",
"                                                                              ",
"                                                                              ",
"   XXXXXXXXXXXXXXX    XXX         XXX    XXXXXXXXXXXXXXX    XXXXXXXXXXXXXXX   ",
"   XXXXXXXXXXXXXXX    XXX        XXXX    XXXXXXXXXXXXXXX    XXXXXXXXXXXXXXX   ",
"   XXX         XXX    XXX       XXXX     XXX         XXX    XXX               ",
"   XXX         XXX    XXX      XXXX      XXX         XXX    XXX               ",
"   XXX         XXX    XXX     XXXX       XXX         XXX    XXX               ",
"   XXX         XXX    XXX    XXXX        XXX         XXX    XXX               ",
"   XXX         XXX    XXX   XXXX         XXX         XXX    XXX               ",
"   XXX         XXX    XXX  XXXX          XXX         XXX    XXX               ",
"   XXX         XXX    XXX XXXX           XXX         XXX    XXX               ",
"   XXXXXXXXXXXXXXX    XXXXXXX            XXXXXXXXXXXXXXX    XXXXXXXXXXXXXXX   ",
"   XXXXXXXXXXXXXXX    XXXXXXX            XXXXXXXXXXXXXXX    XXXXXXXXXXXXXXX   ",
"   XXX                XXX XXXX           XXX         XXX    XXX         XXX   ",
"   XXX                XXX  XXXX          XXX         XXX    XXX         XXX   ",
"   XXX                XXX   XXXX         XXX         XXX    XXX         XXX   ",
"   XXX                XXX    XXXX        XXX         XXX    XXX         XXX   ",
"   XXX                XXX     XXXX       XXX         XXX    XXX         XXX   ",
"   XXX                XXX      XXXX      XXX         XXX    XXX         XXX   ",
"   XXX                XXX       XXXX     XXX         XXX    XXX         XXX   ",
"   XXX                XXX        XXXX    XXX         XXX    XXX         XXX   ",
"   XXX                XXX         XXX    XXX         XXX    XXX         XXX   ",
"   XXX                XXX         XXX    XXXXXXXXXXXXXXX    XXXXXXXXXXXXXXX   ",
"   XXX                XXX         XXX    XXXXXXXXXXXXXXX    XXXXXXXXXXXXXXX   ",
"                                                                              ",
"                                                                              ",
"                                                                              ",
"                                                                              ",
};

int main() {
  int prev = -1;
  int count = -1;
  int i, j;
  int line = 0;
  int size = 0;
  printf("  db ");
  for (i = 0; i < 30; ++i) {
    for (j = 0; j < 78; ++j) {
      char const ch = image[i][j];
      if (ch == prev && count < 127) {
        count += 1;
      } else {
        if (prev != -1) {
          printf("0%02xh", ((prev != ' ' ? 0x01 : 0x00) | (count << 1)));
          size += 1;
          if (++line == 8) {
            printf("\n  db ");
            line = 0;
          } else
            printf(", ");
        }
        prev = ch;
        count = 0;
      }
    }
  }
  if (count != -1) {
    printf("0%02xh\n", ((prev != ' ' ? 0x01 : 0x00) | (count << 1)));
    size += 1;
  }
  if (line != 0) printf("\n");
  printf("%04X\n", size);
}
