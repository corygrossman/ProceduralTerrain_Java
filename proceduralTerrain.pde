//Cory Grossman

import controlP5.*;
import java.io.*;
import java.util.*;


Camera cam;

//initializing UI
ControlP5 cp5;
int rows = 1;
int columns = 1;
float terrain_size = 20.00;

float daytime = -1;

boolean ui_stroke = false;
boolean ui_color = false;
boolean perlinBut = false;

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

//perlin noise generated texture
PImage perlin;

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

  cp5.addSlider("daytime", -1, 1)
    .setPosition(600, 10).setSize(300, 30)
    .setFont(createFont("arial", 15))
    .setLabel("Time of Day");

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
    
    cp5.addToggle("perlinBut")
    .setPosition(1050,10).setSize(40, 30)
    .setFont(createFont("arial", 15))
    .setLabel("Built-In Perlin Generator");

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

  //sets the lighting of the environment
  ambientLight(120, 120, 120);
  directionalLight(204, 204, 204, daytime, daytime, -1);

  perspective(radians(90.0f), width/(float)height, 0.1, 1000);
  camera(cam.posX, cam.posY, cam.posZ, // Where is the camera?
    cam.targetX, cam.targetY, cam.targetZ, // Where is the camera looking?
    0, 1, 0); // Camera Up vector (0, 1, 0 often, but not always, works)

  //the generate button changes this value to true
  if (programRun == true) {
    drawTriangles();
  }
  drawGrid();

  //calculates and outputs the triangle count in the command line
  int triCount = rows*columns*2;
  textSize(3);
  //println("Triangle count: " + triCount);
  
  
  //GeneratePerlinNoise();
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

  //adds the vertices to an index based array
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
    
    //uses perlin noise algorithm
    if(perlinBut){
      heightMap = GeneratePerlinNoise();
    }
    else{
      update_File = update_File +  ".png";
      heightMap = loadImage(update_File);
    }
  }
  
  ApplyImageHeight(update_Rows, update_Columns);
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

  //gets 3 vertices to make a triangle
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

    //lerpcolor interpolates between colors
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

    //iterates through the next vertex
    i++;

    vertIndex = triangles.get(i);
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

    //iterates through the next vertex
    i++;

    vertIndex = triangles.get(i);
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
      //reads the red pixel data from the texture image and maps it from 0-255 to 0-1
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

//smooths by averaging out each vertex based on its neighbors height value
//have to adjust program by keeping an original array of data
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
      } else {
        heightAvg = (vertexData.get(i).y + vertexData.get(i+1).y + vertexData.get(i+c).y + vertexData.get(i-c).y) / 4;
      }

      PVector temp = new PVector(vertexData.get(i).x, heightAvg, vertexData.get(i).z);
      smoothed_VD.set(i, temp);
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
      } else {
        heightAvg = (vertexData.get(i).y + vertexData.get(i-1).y + vertexData.get(i+c).y + vertexData.get(i-c).y) / 4;
      }

      PVector temp = new PVector(vertexData.get(i).x, heightAvg, vertexData.get(i).z);
      smoothed_VD.set(i, temp);
    }
    //if the vertex is anywhere else
    else {
      //checks if the vertex is at the top of the grid
      if ((i-c) < 0) {
        heightAvg = (vertexData.get(i).y + vertexData.get(i-1).y + vertexData.get(i+1).y + vertexData.get(i+c).y) / 4;
      }
      //checks if the vertex is at the bottom of the grid
      else if ((i+c) > (r*c)) {
        heightAvg = (vertexData.get(i).y + vertexData.get(i-1).y + vertexData.get(i+1).y + vertexData.get(i-c).y) / 4;
      } else {
        heightAvg = (vertexData.get(i).y + vertexData.get(i-1).y + vertexData.get(i+1).y + vertexData.get(i+c).y + vertexData.get(i-c).y) / 5;
      }

      PVector temp = new PVector(vertexData.get(i).x, heightAvg, vertexData.get(i).z);
      smoothed_VD.set(i, temp);
    }
  }

  //updates the original vertexData vector with the new values
  for (int j = 0; j < vertexData.size(); j++) {
    vertexData.set(j, smoothed_VD.get(j));
  }
}


//function that generates an image off of a perlin noise algoirthm included
PImage GeneratePerlinNoise() {
  final int perlinH = 400;
  final int perlinW = 400;
  
  
  heightMap = createImage(perlinW, perlinH, RGB);
  
  Vector<Float> rgbArray = new Vector<Float>(width*height);

  PerlinNoise p = new PerlinNoise(254);
  for (float y = 0; y< 2; y += .005) {
    for (float x = 0; x<2; x += .005) {
      //System.out.print(p.noise(x, y, 0) + "\t");
      rgbArray.add(p.noise(x, y, 0));
    }
    //System.out.println();
  }

  heightMap.loadPixels();
  for (int i = 0; i < heightMap.pixels.length; i++) {
    float mappedColor = map(rgbArray.elementAt(i), -1,1, 0,255);
    heightMap.pixels[i] = color(mappedColor, mappedColor, mappedColor);
  }
  
  for(int i = 0; i < perlinW; i++){
    for(int j = 0; i < perlinW; i++){
    println(heightMap.get(i, j));
  }
  }
  heightMap.updatePixels();
  image(heightMap, 68,68);
  
  return heightMap;
}




/**
 * <p>
 * Adapted from Riven's Implementation of Perlin noise. Modified it to be more
 * OOP rather than C like.
 * </p>
 * 
 * @author Matthew A. Johnston (WarmWaffles)
 * 
 */
public class PerlinNoise {
  private float   xo, yo, zo;
  private float[] pow;
  private int[]   perm;
  
  /**
   * Builds the Perlin Noise generator.
   * 
   * @param seed The seed for the random number generator
   */
  public PerlinNoise(int seed) {
    pow  = new float[32];
    perm = new int[512];
    
    
    for (int i = 0; i < pow.length; i++)
      pow[i] = (float) Math.pow(2, i);
    
    int[] permutation = new int[256];
    
    Random r = new Random(seed);
    
    for(int i = 0; i < permutation.length; i++)
      permutation[i] = r.nextInt(256);

    if (permutation.length != 256)
      throw new IllegalStateException();

    for (int i = 0; i < 256; i++)
      perm[256 + i] = perm[i] = permutation[i];
  }

  /**
   * 
   * @param x
   * @param y
   * @param z
   */
  public void offset(float x, float y, float z) {
    this.xo = x;
    this.yo = y;
    this.zo = z;
  }

  /**
   * 
   * @param x
   * @param y
   * @param z
   * @param octaves
   * @return
   */
  public float smoothNoise(float x, float y, float z, int octaves) {
    float height = 0.0f;
    for (int octave = 1; octave <= octaves; octave++)
      height += noise(x, y, z, octave);
    return height;
  }

  /**
   * 
   * @param x
   * @param y
   * @param z
   * @param octaves
   * @return
   */
  public float turbulentNoise(float x, float y, float z, int octaves) {
    float height = 0.0f;
    for (int octave = 1; octave <= octaves; octave++) {
      float h = noise(x, y, z, octave);
      if (h < 0.0f)
        h *= -1.0f;
      height += h;
    }
    return height;
  }

  /**
   * 
   * @param x
   * @param y
   * @param z
   * @return
   */
  public float noise(float x, float y, float z) {
    float fx = floor(x);
    float fy = floor(y);
    float fz = floor(z);

    int gx = (int) fx & 0xFF;
    int gy = (int) fy & 0xFF;
    int gz = (int) fz & 0xFF;

    float u = fade(x -= fx);
    float v = fade(y -= fy);
    float w = fade(z -= fz);

    int a0 = perm[gx + 0] + gy;
    int b0 = perm[gx + 1] + gy;
    int aa = perm[a0 + 0] + gz;
    int ab = perm[a0 + 1] + gz;
    int ba = perm[b0 + 0] + gz;
    int bb = perm[b0 + 1] + gz;

    float a1 = grad(perm[bb + 1], x - 1, y - 1, z - 1);
    float a2 = grad(perm[ab + 1], x - 0, y - 1, z - 1);
    float a3 = grad(perm[ba + 1], x - 1, y - 0, z - 1);
    float a4 = grad(perm[aa + 1], x - 0, y - 0, z - 1);
    float a5 = grad(perm[bb + 0], x - 1, y - 1, z - 0);
    float a6 = grad(perm[ab + 0], x - 0, y - 1, z - 0);
    float a7 = grad(perm[ba + 0], x - 1, y - 0, z - 0);
    float a8 = grad(perm[aa + 0], x - 0, y - 0, z - 0);

    float a2_1 = lerp(u, a2, a1);
    float a4_3 = lerp(u, a4, a3);
    float a6_5 = lerp(u, a6, a5);
    float a8_7 = lerp(u, a8, a7);
    float a8_5 = lerp(v, a8_7, a6_5);
    float a4_1 = lerp(v, a4_3, a2_1);
    float a8_1 = lerp(w, a8_5, a4_1);

    return a8_1;
  }
  
  // ========================================================================
  //                                PRIVATE
  // ========================================================================

  /**
   * 
   * @param x
   * @param y
   * @param z
   * @param octave
   * @return
   */
  private float noise(float x, float y, float z, int octave) {
    float p = pow[octave];
    return this.noise(x * p + this.xo, y * p + this.yo, z * p + this.zo) / p;
  }

  /**
   * 
   * @param v
   * @return
   */
  private final float floor(float v) {
    return (int) v;
  }

  /**
   * 
   * @param t
   * @return
   */
  private final float fade(float t) {
    return t * t * t * (t * (t * 6.0f - 15.0f) + 10.0f);
  }

  /**
   * 
   * @param t
   * @param a
   * @param b
   * @return
   */
  private final float lerp(float t, float a, float b) {
    return a + t * (b - a);
  }

  /**
   * 
   * @param hash
   * @param x
   * @param y
   * @param z
   * @return
   */
  private float grad(int hash, float x, float y, float z) {
    int h = hash & 15;
    float u = (h < 8) ? x : y;
    float v = (h < 4) ? y : ((h == 12 || h == 14) ? x : z);
    return ((h & 1) == 0 ? u : -u) + ((h & 2) == 0 ? v : -v);
  }

}
