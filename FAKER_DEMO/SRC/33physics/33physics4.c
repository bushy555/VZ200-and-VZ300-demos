#include <graphics.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <games.h>
#include <vz.h>

char smile[] =
{
	7,7,
	56, /*  ooo   */
	68, /* o   o  */
	170,/*o o o o */
	130,/*o     o */
	186,/*o ooo o */
	68, /* o   o  */
	56  /*  ooo   */
};

char smile2[] =
{
	7,7,
	0, /*  ooo   */
	0, /* o   o  */
	0,/*o o o o */
	0,/*o     o */
	0,/*o ooo o */
	0, /* o   o  */
	0  /*  ooo   */
};





void wait(int time) {
  int a;
  for (int i = 0; i < time; i++) {
    a += 1;
  }
}

#define ITEMS 10
#define XMAX 126
#define YMAX 62
#define WAIT 1

int x[ITEMS], y[ITEMS];
int vx[ITEMS], vy[ITEMS];
int oldx, oldy;

void reset() {
  for (int i = 0; i < ITEMS; i++) {
    x[i] = rand() % (XMAX-8) +4;
    y[i] = rand() % (YMAX-8) / 2 +4;
    vy[i] = rand() % 4 - 2;
    vx[i] = rand() % 10 - 4;
  }
}

void main() {
  int r = 1;			// RADIUS OF BALL
  clg();
  reset();

  while (1) {
    for (int i = 0; i < ITEMS; i++) {
      vy[i] = vy[i] + 1.0;

      oldx = x[i];
      oldy = y[i];
      x[i] = x[i] + vx[i];
      y[i] = y[i] + vy[i];

      if ((x[i] > XMAX-r) || (x[i] < r)) {
        vx[i] = -vx[i];
      }

      if ((y[i] > YMAX-r )|| (y[i]<r)) {
        vy[i] = -vy[i];
      }



      if(y[i]>YMAX-1){y[i]=YMAX-r;};
      if(y[i]<0){y[i]=r;};
      if(x[i]>XMAX-1){x[i]=XMAX-r;};
      if(x[i]<0){x[i]=r;};

	vz_color (4);

      uncircle(oldx, oldy, r, 1);
    circle(x[i], y[i], r, 1);
//      putsprite(spr_or, x[i],  y[i], smile);
//      putsprite(spr_and, x[i],  y[i], smile);

    }

//    wait(WAIT);
 //   if(getk()==10){break;}
    // Enter key is defined to be 10 (not 13)
    // It blocks when clib=g850
    // so this code should be build with clib=g850b
  }
}
