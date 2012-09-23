#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

char* image[30] = {
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

char* f1[30];
char* f2[30];

#define screen_width 78
#define screen_height 30

#define sin_table_scale 128
#define sin_table_quarter (sin_table_scale / 4)

int TWO_PI = 6;
int PI = 3;

int sin_table[] = {
    0, 12, 24, 36, 48, 59, 71, 83, 94, 105, 116, 126, 137, 147, 156, 166, 174,
    183, 191, 199, 206, 213, 220, 226, 231, 236, 240, 244, 248, 250, 253, 254,
    255
};

int lookup_sin(int x) {
  x = (x/12) % 128;

  int y = x % sin_table_quarter;
  int r = sin_table_scale*2;
  if (x < sin_table_quarter)          r += sin_table[   y];
  else if (x < sin_table_quarter * 2) r += sin_table[sin_table_quarter-y];
  else if (x < sin_table_quarter * 3) r -= sin_table[   y];
  else if (x < sin_table_quarter * 4) r -= sin_table[sin_table_quarter-y];
  return r;
}

int sin_(int a) {
  return lookup_sin(a);
}

int z_offset(x, y, time) {
  return sin_(sin_(time + 384) + x*2) + sin_(sin_(time) + y*2 + 384);
}

int time = 0;
int frames = 0;

int width = screen_width;
int height = screen_height;

char** current = &f1[0];
char** prev = &f2[0];

int max_diff = 0;

void play() {

  int iy, ix;
  for (iy = 15; iy < 45; iy++) {
    int y = 512 + (iy < 30 ? - (17*(30-iy)) : + (17*(iy-30)));

    for (ix = 39; ix < 117; ix++) {
      int x = 512 + (ix < 78 ? - (7*(78-ix)) : + (7*(ix-78)));

      int z_ofs = sin_(sin_(time + 384) + x*2) + sin_(sin_(time) + y*2 + 384);

      int z = (z_ofs / 2);

      int zdiv = (61440/(384 + z));

      int iu, iv;

      if (x >= 512) {
        int u = (x-512)*zdiv;
        iu = 39 + (u/439);
      } else {
        int u = (512-x)*zdiv;
        iu = 39 - (u/439);
      }
      iu += 2;

      if (y >= 512) {
        int v = (y-512)*zdiv;
        iv = 15 + (v/(256*6));
      } else {
        int v = (512-y)*zdiv;
        iv = 15 - (v/(256*6));
      }
      iv += 1;

      int pixel = ' ';
      if (iu >= 0 && iu < width && iv >= 0 && iv < height) {
        pixel = image[iv][iu];
      }
      current[iy-15][ix-39] = pixel & 0xff;
      printf("%c", pixel);
    }
    printf("\n");
  }

  if (time == 0) {
    fprintf(stderr, "initial_frame:\n");
    int x, y;
    for (y = 0; y < height; ++y) {
      fprintf(stderr, "  db \"");
      for (x = 0; x < width/2; ++x)
        fprintf(stderr, "%c", current[y][x]);
      fprintf(stderr, "\"\n");
      fprintf(stderr, "  db \"");
      for (; x < width; ++x)
        fprintf(stderr, "%c", current[y][x]);
      fprintf(stderr, "\"\n");
    }
    fprintf(stderr, "\n");
  } else {
    int diffs = 0;
    int offsets[200];
    int offset_n = 0;
    for (iy = 0; iy < height; ++iy) {
      for (ix = 0; ix < width; ++ix) {
        if (current[iy][ix] != prev[iy][ix]) {
          printf("y = %d, x = %d, '%c' -> '%c'", iy, ix,
                 current[iy][ix], prev[iy][ix]);
          int offset = iy*width + ix;
          printf(", ofs = %d]\n", offset);
          assert(offset_n < sizeof(offsets)/sizeof(*offsets));
          offsets[offset_n++] = offset;
          diffs += 1;
        }
      }
    }
    int i;
    fprintf(stderr, "frame_%03d: db %d\n", frames, offset_n);
    for (i = 0; i < offset_n; ++i) {
      fprintf(stderr, "  dw %xh\n", offsets[i] + 0x76d0);
    }
    fprintf(stderr, "\n");
    if (diffs > max_diff) max_diff = diffs;
  }

  char** tmp = prev;
  prev = current;
  current = tmp;

  frames += 1;
  time = time + 8;
  if (time >= 256*256) {
    time = 0;
  }
}

int main() {
  int i;
  for (i = 0; i < height; ++i) {
    f1[i] = malloc(width + 1);
    f2[i] = malloc(width + 1);
  }
  for (i = 1; i <= 384; ++i) {
    printf("#%03d\n", i);
    play();
  }
  fprintf(stderr, "frame_%03d: db %d\n", frames, 255);
  printf("%d\n", max_diff);
}
