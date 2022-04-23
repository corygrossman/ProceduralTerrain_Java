//Cory Grossman

import controlP5.*;

Camera cam;

//initializing UI
ControlP5 cp5;
int rows = 1;
int columns = 1;
float terrain_size = 20.00;

boolean ui_stroke = false;
boolean ui_color = false;

float height_Mod = 1.0;
float snow_Thresh = 5.0;

String terrain_file = "";

boolean programRun = false;

ArrayList<Integer> triangles;
ArrayList<PVector> vertexData;
ArrayList<PVector> smoothed_VD;

int update_Rows = 1;
int update_Columns = 1;
float update_Size = 20.00;
String update_File = "";


PImage heightMap;
Button generate;

Button smooth;

PShape sphereShape;
PImage sphereTexture;

void setup() {
  size(1800, 1200, P3D);

  cam = new Camera();

  perspective(radians(90.0f), width/(float)height, 0.1, 1000);

  //creates and sets up the UI
  cp5 = new ControlP5(this);

  cp5.addSlider("rows", 1, 400)
    .setPosition(10, 10).setSize(300, 30)
    .setFont(createFont("arial", 15))
    .setLabel("Rows");

  cp5.addSlider("columns", 1, 400)
    .setPosition(10, 60).setSize(300, 30)
    .setFont(createFont("arial", 15))
    .setLabel("Columns");

  cp5.addSlider("terrain_size", 20.00, 250.00)
    .setPosition(10, 110).setSize(300, 30)
    .setFont(createFont("arial", 15))
    .setLabel("Terrain Size");

  cp5.addToggle("ui_stroke")
    .setPosition(1300, 10).setSize(40, 30)
    .setFont(createFont("arial", 15))
    .setLabel("Stroke");

  cp5.addToggle("ui_color")
    .setPosition(1400, 10).setSize(40, 30)
    .setFont(createFont("arial", 15))
    .setLabel("Color");

  smooth = cp5.addButton("SmoothVert")
    .setPosition(1500, 10).setSize(90, 30)
    .setFont(createFont("arial", 15))
    .setLabel("Smooth");

  cp5.addSlider("height_Mod", 0.00, 40.00)
    .setPosition(1300, 80).setSize(300, 30)
    .setFont(createFont("arial", 15))
    .setLabel("Height Modifier");

  cp5.addSlider("snow_Thresh", 1.00, 40.00)
    .setPosition(1300, 150).setSize(300, 30)
    .setFont(createFont("arial", 15))
    .setLabel("Snow Threshold");

  cp5.addTextfield("terrain_file")
    .setPosition(10, 175).setSize(300, 40)
    .setLabel("Load From File")
    .setFont(createFont("arial", 15))
    .setAutoClear(false);

  generate = cp5.addButton("Generate")
    .setSize(300, 40)
    .setFont(createFont("arial", 20))
    .setPosition(10, 250);

  sphereTexture = loadImage("mountains-and-clouds-aerial-survey-hdri-panorama-01.jpeg");
  sphereShape = createShape(SPHERE, height/2);
}

void draw() {
  background(50);
  //float dirY = (mouseY / float(height) - 0.5) * 2;
  //float dirX = (mouseX / float(width) - 0.5) * 2;
  
  float dirY = 0.087;
  float dirX = -0.09;
  ambientLight(120, 120, 120);
  directionalLight(204, 204, 204, -dirX, -dirY, -1);

  perspective(radians(90.0f), width/(float)height, 0.1, 1000);
  camera(cam.posX, cam.posY, cam.posZ, // Where is the camera?
    cam.targetX, cam.targetY, cam.targetZ, // Where is the camera looking?
    0, 1, 0); // Camera Up vector (0, 1, 0 often, but not always, works)

  //the generate button changes this value to true
  if (programRun == true) {
    drawTriangles();
  }
  drawGrid();
  
  int triCount = rows*columns*2;
  textSize(3);
  println("Triangle count: " + triCount);
  camera();
  perspective();
}

//class for camera functionality
public class Camera {

  float targetX;
  float targetY;
  float targetZ;
  float deltaX, deltaY;
  float phi, theta;
  float posX;
  float posY;
  float posZ;
  float zoomFact;

  public Camera() {
    targetX = 0;
    targetY = 0;
    targetZ = 0;
    zoomFact = 50;
    phi = 0;
    theta = radians(120);
    posX = (zoomFact*cos(phi)*sin(theta));
    posY = (zoomFact*cos(theta));
    posZ = (zoomFact*sin(phi)*sin(theta));
  }

  void Update() {
    //updates the rotation based on mouseX and mouseY
    deltaX = radians((mouseX - pmouseX) * 0.30f);

    deltaY = radians((mouseY - pmouseY) * 0.30f);

    //clamps theta to 1-179
    phi += deltaX;
    theta += deltaY;
    if (theta <= radians(1)) {
      theta = radians(1);
    }
    if (theta >= radians(179)) {
      theta = radians(179);
    }

    posX = (zoomFact*cos(phi)*sin(theta));
    posY = (zoomFact*cos(theta));
    posZ = (zoomFact*sin(phi)*sin(theta));
  }


  void Zoom(float zoom) {
    zoomFact = zoomFact + zoom;
    //locks the range of radius to be 30-200
    if (zoomFact < 5) {
      zoomFact = 5;
    } else if (zoomFact > 200) {
      zoomFact = 200;
    }
  }
}
//calls function when mouse is dragged
void mouseDragged() {
  if (!cp5.isMouseOver()) {
    //updates the camera every frame
    cam.Update();
  }
}
//generate terrain when the enter key is pressed
void keyPressed() {
  if (key == ENTER) {
    Generate();
  }
}

//for scrolling the mouse wheel
void mouseWheel(MouseEvent event) {
  float e = event.getCount();
  //adjusts for zooming in vs out
  if (e > 0) {
    cam.Zoom(-10);
  } else {
    cam.Zoom(10);
  }
  cam.Update();
}

//is called in draw when programRun == true
void Run(int r, int c, float size, String file) {
  int startIndex;
  int verticesInARow = c + 1;

  float rowIncrease = size/r;
  float colIncrease = size/c;
  PVector temp;

  //initializes the data that is going to make the pvector that is the vertex data
  float posX = size/(-2);
  float posY = 0;
  float posZ = size/(-2);

  //initializes vertex data
  vertexData = new ArrayList<PVector>();
  smoothed_VD = new ArrayList<PVector>();
  triangles = new ArrayList<Integer>();

  //if there is no file to generate off of
  for (int i = 0; i <= r; i++) {
    for (int j = 0; j <= c; j++) {
      //starting index = currentRow * the amount of colums + current column
      temp = new PVector(posX + rowIncrease*i, posY, posZ + colIncrease*j);
      vertexData.add(temp);
      smoothed_VD.add(temp);

      //println(triangles.size());
    }

    //draws rows and columns
    //print("generated");
  }

  for (int i = 0; i < r; i++) {
    for (int j = 0; j < c; j++) {
      startIndex = i * verticesInARow + j;

      //triangle A
      triangles.add(startIndex);
      triangles.add(startIndex+1);
      triangles.add(startIndex+verticesInARow);

      //triangle B
      triangles.add(startIndex+1);
      triangles.add(startIndex+verticesInARow+1);
      triangles.add(startIndex+verticesInARow);
    }
  }
  //programRun = false;
}

void Generate() {
  programRun = true;
  update_Rows = rows;
  update_Columns = columns;
  update_Size = terrain_size;
  //resets the grid to the new values
  Run(update_Rows, update_Columns, update_Size, update_File);
  update_File = cp5.get(Textfield.class, "terrain_file").getText();
  //if there is a file to load
  if (update_File != null) {
    update_File = update_File +  ".png";
    heightMap = loadImage(update_File);
    ApplyImageHeight(update_Rows, update_Columns);
  }
}

void drawTriangles() {
  fill(255, 255, 255);

  //draws stroke if selected
  if (ui_stroke) {
    stroke(0);
    strokeWeight(1);
  } else {
    noStroke();
  }

  beginShape(TRIANGLE);
  //draws the individual triangles for each vertex
  for (int i = 0; i < triangles.size(); i++) {
    //gets the index that the vertex is at. repeats this until all 3 vertices are recieved
    int vertIndex = triangles.get(i);
    PVector vert = smoothed_VD.get(vertIndex);
    float relativeHeight = abs(vert.y) * height_Mod / snow_Thresh;
    //print(vertIndex);

    //colors
    color snow = color(255, 255, 255);
    color grass = color(143, 170, 64);
    color rock = color(135, 135, 135);
    color dirt = color(160, 126, 84);
    color water = color(0, 75, 200);


    if (ui_color) {
      if (relativeHeight >= 0.2 && relativeHeight <= 0.4) {
        float ratio = (relativeHeight - 0.2)/0.2f;
        fill(lerpColor(water, dirt, ratio));
      } else if (relativeHeight > 0.4 && relativeHeight <= 0.8) {
        float ratio = (relativeHeight - 0.4)/0.4f;
        fill(lerpColor(grass, rock, ratio));
      } else if (relativeHeight > 0.8) {
        float ratio = (relativeHeight - 0.8)/0.2f;
        fill(lerpColor(rock, snow, ratio));
      } else {
        fill(water);
      }
    }
    //adjusts for the height
    vertex (vert.x, height_Mod*-1*vert.y, vert.z);

    i++;
    vertIndex = triangles.get(i);
    //print(vertIndex);
    vert = smoothed_VD.get(vertIndex);
    relativeHeight = abs(vert.y) * height_Mod / snow_Thresh;
    if (ui_color) {
      if (relativeHeight >= 0.2 && relativeHeight <= 0.4) {
        float ratio = (relativeHeight - 0.2)/0.2f;
        fill(lerpColor(water, dirt, ratio));
      } else if (relativeHeight > 0.4 && relativeHeight <= 0.8) {
        float ratio = (relativeHeight - 0.4)/0.4f;
        fill(lerpColor(grass, rock, ratio));
      } else if (relativeHeight > 0.8) {
        float ratio = (relativeHeight - 0.8)/0.2f;
        fill(lerpColor(rock, snow, ratio));
      } else {
        fill(water);
      }
    }
    //adjusts for the height
    vertex (vert.x, height_Mod*-1*vert.y, vert.z);

    i++;
    vertIndex = triangles.get(i);
    //print(vertIndex);
    vert = smoothed_VD.get(vertIndex);
    relativeHeight = abs(vert.y) * height_Mod / snow_Thresh;
    if (ui_color) {
      if (relativeHeight >= 0.2 && relativeHeight <= 0.4) {
        float ratio = (relativeHeight - 0.2)/0.2f;
        fill(lerpColor(water, dirt, ratio));
      } else if (relativeHeight > 0.4 && relativeHeight <= 0.8) {
        float ratio = (relativeHeight - 0.4)/0.4f;
        fill(lerpColor(grass, rock, ratio));
      } else if (relativeHeight > 0.8) {
        float ratio = (relativeHeight - 0.8)/0.2f;
        fill(lerpColor(rock, snow, ratio));
      } else {
        fill(water);
      }
    }
    //adjusts for the height
    vertex (vert.x, height_Mod*-1*vert.y, vert.z);
    //println();
  }
  endShape();
}

void ApplyImageHeight(int r, int c) {
  int xIndex, yIndex;
  float imgW = heightMap.width;
  float imgH = heightMap.height;
  float heightFromColor;
  //println(imgW);
  //print(", ");
  //print(imgH);
  int vertex_index;
  for (int i = 0; i <= r; i++) {
    for (int j = 0; j <= c; j++) {
      //maps the rows and columns to width and height of the texture map
      xIndex = int(map(j, 0, c+1, 0, imgW));
      yIndex = int(map(i, 0, r+1, 0, imgH));

      color tempCol = heightMap.get(xIndex, yIndex);
      heightFromColor = map(red(tempCol), 0, 255, 0, 1.0f);

      vertex_index = i * (c + 1) + j;

      vertexData.get(vertex_index).y = heightFromColor;
      smoothed_VD.get(vertex_index).y = heightFromColor;
    }
  }
}

void drawGrid() {
  //grid system
  strokeWeight(2);
  for (int i = -200; i <= 200; i = i+10) {
    //white lines
    stroke(255, 255, 255);

    //x
    line(-200, 0, i, 200, 0, i);

    //z
    line(i, 0, -200, i, 0, 200);
  }
  //x-axis
  stroke(255, 0, 0);
  line(-100, 0, 0, 100, 0, 0);

  //y-axis
  stroke(0, 255, 0);
  line(0, -20, 0, 0, 20, 0);

  //z-axis
  stroke(0, 0, 255);
  line(0, 0, -100, 0, 0, 100);

  //draws environment hdri texture
  pushMatrix();
  translate(0, -50);
  sphereShape.setTexture(sphereTexture);
  sphereShape.setStroke(false);
  shape(sphereShape);
  popMatrix();
}

void SmoothVert() {
  //function called
  println("smoothVert function called");
  println(rows + "," + columns);
  
  int r = rows;
  int c = columns;
  
  println(vertexData.size() + "," + smoothed_VD.size());
  
  for (int i = 0; i < vertexData.size(); i++) {
    float heightAvg;

    //checks to see if the vertex is at the left of a row
    if ((i%c) == 0) {
      //checks if the vertex is at the top of the grid
      if ((i-c) < 0) {
        heightAvg = (vertexData.get(i).y + vertexData.get(i+1).y + vertexData.get(i+c).y) / 3;
      }
      //checks if the vertex is at the bottom of the grid
      else if ((i+c) > (r*c)) {
        heightAvg = (vertexData.get(i).y + vertexData.get(i+1).y + vertexData.get(i-c).y) / 3;
      }
      else{
        heightAvg = (vertexData.get(i).y + vertexData.get(i+1).y + vertexData.get(i+c).y + vertexData.get(i-c).y) / 4;
      }
      
      PVector temp = new PVector(vertexData.get(i).x, heightAvg, vertexData.get(i).z);
      smoothed_VD.set(i,temp);
    }
    //checks if the vertex is at the right of a row
    else if ((i+1)%c == 0) {
      //checks if the vertex is at the top of the grid
      if ((i-c) < 0) {
        heightAvg = (vertexData.get(i).y + vertexData.get(i-1).y + vertexData.get(i+c).y) / 3;
      }
      //checks if the vertex is at the bottom of the grid
      else if ((i+c) > (r*c)) {
        heightAvg = (vertexData.get(i).y + vertexData.get(i-1).y + vertexData.get(i-c).y) / 3;
      }
      else{
        heightAvg = (vertexData.get(i).y + vertexData.get(i-1).y + vertexData.get(i+c).y + vertexData.get(i-c).y) / 4;
      }
      
      PVector temp = new PVector(vertexData.get(i).x, heightAvg, vertexData.get(i).z);
      smoothed_VD.set(i,temp);
    }
    //if the vertex is anywhere else
    else{
      //checks if the vertex is at the top of the grid
      if ((i-c) < 0) {
        heightAvg = (vertexData.get(i).y + vertexData.get(i-1).y + vertexData.get(i+1).y + vertexData.get(i+c).y) / 4;
      }
      //checks if the vertex is at the bottom of the grid
      else if ((i+c) > (r*c)) {
        heightAvg = (vertexData.get(i).y + vertexData.get(i-1).y + vertexData.get(i+1).y + vertexData.get(i-c).y) / 4;
      }
      else{
        heightAvg = (vertexData.get(i).y + vertexData.get(i-1).y + vertexData.get(i+1).y + vertexData.get(i+c).y + vertexData.get(i-c).y) / 5;
      }
      
      PVector temp = new PVector(vertexData.get(i).x, heightAvg, vertexData.get(i).z);
      smoothed_VD.set(i,temp);
    }
  }
  
  //updates the original vertexData vector with the new values
  for(int j = 0; j < vertexData.size(); j++){
    vertexData.set(j, smoothed_VD.get(j));
  }
}
