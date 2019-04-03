import java.util.Random;
private static final int W = 256;
private static final int H = 256;
double[][] arr = new double[H][W];



void setup() {
  size(256, 256);
  generateNoise();
  noStroke();
colorMode(HSB,360,100,255, 1);
  for (int i = 0; i < H; ++i) {
    for (int j = 0; j < W; ++j) {

      int num = (int)(createTurbulence(i, j, 128));
      if (num > 255) { 
        num-=num-255;
      }
      num = (int)(191 + (int)(num/4));
      num = (int)(0.79365079365079 * num  - 152.38095238095);
     
      color c = color(240, num, 255,1);

      set(i, j, c);
    }

  }
}


void draw() {
  colorMode(HSB,255,255,255, 1);
}

void generateNoise() {
  for (int i = 0; i<H; ++i)
    for (int j = 0; j<W; ++j) {
      arr[i][j] = (random(255));
    }
}

double smoothNoise(double x, double y) {
  double val = 0;
  double fX = x - (int)x, fY = y - (int)y;
  int x1 = ((int)x + W) % W, y1 = ((int)y + H) % H;
  int x2 = (x1 + W -1) % W, y2 = (y1+H-1) % H;
  val += fX * fY * arr[y1][x1];
  val += (1-fX) * fY * arr[y1][x2];
  val += fX * (1 - fY) * arr[y2][x1];
  val += (1 - fX) * (1 - fY) * arr[y2][x2];

  return val;
}

double createTurbulence(double x, double y, double size) {
  double val = 0, initSize = size;
  while (size >= 1) {
    val += smoothNoise(x/size, y/size) * size;
    size /= 4.00;
  }
  return (val / initSize);
}
