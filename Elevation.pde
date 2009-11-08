/*

 Elevation
 A route visualizer that renders GPS data in 3D space

 http://exnihilo.mezzoblue.com/elevation/
 http://github.com/mezzoblue/Elevation/
 November 2009 

*/

// a couple of libraries to get us started
import java.util.Date;
import java.text.SimpleDateFormat;
import processing.opengl.*;


// for file data
ArrayList filenames;

// for track data
Tracks[] tracklist;
int numTracks;

// scene-related objects
uiPanel UI;
Scene scene;
Crosshairs crosshair;
uiButton[] buttons;
uiCheckbox[] checkboxes;
uiSwitch[] switches;
uiCompass compass;




void setup() {
  frameRate(30);

  // create the scene object and assign a size to the sketch window
  scene = new Scene(1000, 700);
  size(scene.canvasWidth, scene.canvasHeight, OPENGL);
  // for some reason it seems as if both of these hints are necessary for true 4x sampling
  hint(DISABLE_OPENGL_2X_SMOOTH);
  hint(ENABLE_OPENGL_4X_SMOOTH);

  // set title bar frame
  frame.setTitle("Elevation"); 

  // stuff for the Windows EXE
  Image img = getToolkit().getImage("elevation-16px.gif");
  frame.setIconImage(img);

  // create the User Interface
  UI = new uiPanel(
    0, scene.canvasHeight - 100, scene.canvasWidth, 100,
    "Panel");

  buttons = new uiButton[8];

  // arrow buttons
  buttons[0] = new uiButton(
    44, scene.canvasHeight - 90, 35, 40, 
    "UI-DPad-up", "offsetX++");
  buttons[1] = new uiButton(
    44, scene.canvasHeight - 49, 35, 40,
    "UI-DPad-down", "offsetX--");
  buttons[2] = new uiButton(
    22, scene.canvasHeight - 67, 45, 30,
    "UI-DPad-left", "offsetZ++");
  buttons[3] = new uiButton(
    61, scene.canvasHeight - 67, 45, 30,
    "UI-DPad-right", "offsetZ--");

  // ^ / v buttons
  buttons[4] = new uiButton(
    216, scene.canvasHeight - 82, 52, 30,
    "UI-Button-up", "offsetY++");
  buttons[5] = new uiButton(
    266, scene.canvasHeight - 82, 52, 30,
    "UI-Button-down", "offsetY--");

  // + / - buttons
  buttons[6] = new uiButton(
    331, scene.canvasHeight - 82, 52, 30,
    "UI-Button-plus", "drawingScale++");
  buttons[7] = new uiButton(
    381, scene.canvasHeight - 82, 52, 30,
    "UI-Button-minus", "drawingScale--");

  // checkboxes
  checkboxes = new uiCheckbox[4];
  checkboxes[0] = new uiCheckbox(
    867, scene.canvasHeight - 74, 19, 18,
    "UI-Checkbox", "scene.toggleConnectors", "unchecked");
  checkboxes[1] = new uiCheckbox(
    867, scene.canvasHeight - 46, 19, 18,
    "UI-Checkbox", "crosshairs.toggle", "checked");
  checkboxes[2] = new uiCheckbox(
    951, scene.canvasHeight - 74, 19, 18,
    "UI-Checkbox", "scene.togglePalette", "unchecked");
  checkboxes[3] = new uiCheckbox(
    951, scene.canvasHeight - 46, 19, 18,
    "UI-Checkbox", "scene.toggleDimension", "checked");

  // switches
  switches = new uiSwitch[4];
  switches[0] = new uiSwitch(
    582, scene.canvasHeight - 82, 39, 28,
    "UI-Switch-1", "nada", "selected");
  switches[1] = new uiSwitch(
    621, scene.canvasHeight - 82, 35, 28,
    "UI-Switch-2", "nada", "");
  switches[2] = new uiSwitch(
    656, scene.canvasHeight - 82, 35, 28,
    "UI-Switch-3", "nada", "");
  switches[3] = new uiSwitch(
    691, scene.canvasHeight - 82, 40, 28,
    "UI-Switch-4", "nada", "");

  compass = new uiCompass(
    scene.canvasWidth / 2, scene.canvasHeight - 50, 31, 31);

  // create the crosshairs object
  crosshair = new Crosshairs();

  // get the map data XML files
  filenames = listFileNames(dataPath("") + "/xml/");
  try {
    numTracks = filenames.size();
  }
  catch (NullPointerException e) {
    // likely suspect: no /xml/ directory
  }

  // turn the XML into something a little more usable
  tracklist = new Tracks[numTracks];
  for (int i = 0; i < numTracks; i++) {
    tracklist[i] = parseXML((String) filenames.get(i));

    // pull out the track min and max values
    tracklist[i].createLimits();
  };

  // diagnostics
  println("Number of Tracks: " + numTracks);
  println("minX: " + scene.minX);
  println("maxX: " + scene.maxX);
  println("minY: " + scene.minY);
  println("maxY: " + scene.maxY);
  println("minZ: " + scene.minZ);
  println("maxZ: " + scene.maxZ);
  println("minSpeed: " + scene.minSpeed);
  println("maxSpeed: " + scene.maxSpeed);

  // set the viewRedraw flag coming out of setup so that we get the initial draw
  scene.viewRedraw = true;
};





void draw() {
  
  // if we're using an animated view, we'll need to re-draw each loop
  if (scene.viewMode == 3) {
    scene.viewRedraw = true;
  }

  // if the canvas is being dragged, set the cursor and adjust rotation
  if(mousePressed) {

    // any mouse action should probably toggle a re-draw
      scene.viewRedraw = true;

      if (!(
      (mouseX > UI.x && mouseX < (UI.x + UI.wide)) &&
      (mouseY > UI.y && mouseY < (UI.y + UI.high))
      )) {
        // use a cursor image while rotating the scene
        // (I suspect this is causing crashes in OS X, removed for now)
        // cursor(scene.cursorHand, scene.cursorHand.width / 2, scene.cursorHand.height / 2);
        scene.rotationY += ((float) (mouseX - pmouseX) / 180);
        if (scene.viewDimension == "3D") {
          scene.rotationX += ((float) (mouseY - pmouseY) / 180);
        }
      }
  }


  // check the UI components; iz render needed nao?
  for (int i = 0; i < buttons.length; i++) {
    buttons[i].check();
  }
  for (int i = 0; i < switches.length; i++) {
    switches[i].check();
  }


  // if we're going to redraw, let's go for it
  if (scene.viewRedraw == true) {
  
    background(scene.palette[0]);
    stroke(scene.palette[1]);
    noFill();
  
    // move the sketch to the center of the canvas, accounting for height of the UI panel
    translate(scene.canvasWidth / 2, scene.canvasHeight / 2 - 50);
  
    // rotate the canvas
    rotateX(scene.rotationX);
    rotateY(scene.rotationY);
    rotateZ(scene.rotationZ);
  
    // draw the crosshairs
    crosshair.render(scene.palette[1]);
  
    // adjust the scale based on user input
    scale(scene.drawingScale);
  
    // move the tracks around based on user input
    translate(scene.offsetX, scene.offsetY, scene.offsetZ);
  
    // translate the tracks to the center of the canvas
    translate(
      0 - (findDifference(scene.minX, scene.maxX) / 2),
      0 - (findDifference(scene.minY, scene.maxY) / 2),
      0 - (findDifference(scene.minZ, scene.maxZ) / 2)
    );
  
    // draw each track
    for (int i = 0; i < numTracks; i++) {
      tracklist[i].render();
    }
    
    
    // disable deth ordering for the sake of drawing 2D controls over top of the 3D scene
    hint(DISABLE_DEPTH_TEST);
    // reset the camera view for 2D drawing
    camera();
  
    // draw the various UI components
    UI.render();
    for (int i = 0; i < buttons.length; i++) {
      buttons[i].render();
    }
    for (int i = 0; i < checkboxes.length; i++) {
      checkboxes[i].render();
    }
    for (int i = 0; i < switches.length; i++) {
      switches[i].render();
    }
    
    // draw mini-compass
    compass.translateThenRender();
  };

  // reset the viewRedraw switch for each loop so we don't peg the CPU
  scene.viewRedraw = false;
};

