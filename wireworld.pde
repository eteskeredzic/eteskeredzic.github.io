int[][] grid = new int[50][50];
int counter = 0;
boolean simulate = false, started = false;

int[][] boje = {{0,0,0}, {230,175,25}, {134,189,252}, {255,94,94}};

void setup(){
  size(800,800);
  textFont(createFont("Courier", 20));
  fill(255);
  background(0);
  textAlign(CENTER);
  text("Simple Wireworld simulator\nLeft click / drag with left mouse button to place wire\nRight click / drag with right mouse button to remove wire\nLeft click on wire to turn into electron\nLeft click on electron to turn into wire\nPress 'R' to clear\nPress 'G' to start/stop simulating",400,300);
}
void restart(){
  grid = new int[50][50];
  counter = 0;
  simulate = false;
  started = true;
  noStroke();
}

void draw(){
  if(!started) return;
  background(0);
  counter++;
  if(counter == 30){ 
    counter = 0;
    step();
  }
  for(int i = 0; i < 50; ++i){
    for(int j = 0; j < 50; ++j){
      color c = color(boje[grid[i][j]][0], boje[grid[i][j]][1], boje[grid[i][j]][2]);
      rectt(16*i, 16*j, 16, 16, c);
    }
  }
}


void mouseDragged(){
  int rednix = (int)(mouseX / 16);
  int redniy = (int)(mouseY / 16);
  if(mouseButton == LEFT)
  grid[rednix][redniy] = 1;
  else if(mouseButton == RIGHT)
  grid[rednix][redniy] = 0;
}

void mouseClicked(){
  int rednix = (int)(mouseX / 16);
  int redniy = (int)(mouseY / 16);
  if(mouseButton == LEFT){
  grid[rednix][redniy]++;
  if(grid[rednix][redniy] == 4) 
  grid[rednix][redniy] = 1;
  }
  else if(mouseButton == RIGHT)
  grid[rednix][redniy] = 0;
}
  
void keyPressed(){
  if(key == 'R' || key == 'r') restart();
  else if(key == 'G' || key == 'g') simulate = !simulate;
}
  
void step(){
  if(!simulate) return;
  /* RULES
    empty -> empty,
    electron head -> electron tail,
    electron tail -> conductor,
    conductor -> electron head if exactly one or two of the neighbouring cells are electron heads, otherwise remains conductor.
  */
  int[][] newgrid = new int[50][50];
  for(int i = 0; i<50; ++i)
  for(int j = 0; j<50; ++j) newgrid[i][j] = grid[i][j];
  
  for(int i = 0; i<50; ++i)
  for(int j = 0; j<50; j++){
    if(grid[i][j] == 2){ 
      newgrid[i][j] = 3; // electron head -> electron tail
    } 
    else if(grid[i][j] == 3){ 
      newgrid[i][j] = 1; // electron tail -> conductor
    }
    else if(grid[i][j] == 1 && (moore(i,j) == 1 || moore(i,j) == 2)){ 
      newgrid[i][j] = 2;  // conductor -> electron head
    }
  }
  for(int i = 0; i<50; ++i)
  for(int j = 0; j<50; ++j) grid[i][j] = newgrid[i][j];
}

int moore(int x, int y){
  int count = 0;
  if(x != 0 && y != 0 && grid[x-1][y-1] == 2) count++;
  if(x != 0 && grid[x-1][y] == 2) count++;
  if(x != 0 && y != 49 && grid[x-1][y+1] == 2) count++;
  if(y != 0 && grid[x][y-1] == 2) count++;
  if(y != 49 && grid[x][y+1] == 2) count++;
  if(x != 49 && y != 0 && grid[x+1][y-1] == 2) count++;
  if(x != 49 && grid[x+1][y] == 2) count++;
  if(x != 49 && y != 49 && grid[x+1][y+1] == 2) count++;
  return count;
}


  void rectt(float x, float y, float w, float h, color c) {
   fill(c);
   rect(x, y, w, h);
  }
