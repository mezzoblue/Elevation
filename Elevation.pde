/*

 Elevation
 A route visualizer that renders GPS data in 3D space
 http://exnihilo.mezzoblue.com/elevation/
 http://github.com/mezzoblue/Elevation/
 Started September 2009

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
uiCrosshairs crosshair;
uiScale mapScale;
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
  // would love to know why
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
    44, scene.canvasHeight - 90, 35, 40, 119, 87,
    "UI-DPad-up", "offsetX++");
  buttons[1] = new uiButton(
    44, scene.canvasHeight - 49, 35, 40, 115, 83,
    "UI-DPad-down", "offsetX--");
  buttons[2] = new uiButton(
    22, scene.canvasHeight - 67, 45, 30, 97, 65,
    "UI-DPad-left", "offsetZ++");
  buttons[3] = new uiButton(
    61, scene.canvasHeight - 67, 45, 30, 100, 68,
    "UI-DPad-right", "offsetZ--");

  // ^ / v buttons
  buttons[4] = new uiButton(
    216, scene.canvasHeight - 82, 52, 30, 93, 125,
    "UI-Button-up", "offsetY++");
  buttons[5] = new uiButton(
    266, scene.canvasHeight - 82, 52, 30, 91, 123,
    "UI-Button-down", "offsetY--");

  // + / - buttons
  buttons[6] = new uiButton(
    331, scene.canvasHeight - 82, 52, 30, 43, 61,
    "UI-Button-plus", "drawingScale++");
  buttons[7] = new uiButton(
    381, scene.canvasHeight - 82, 52, 30, 45, 95,
    "UI-Button-minus", "drawingScale--");



  // checkboxes
  checkboxes = new uiCheckbox[5];
  checkboxes[0] = new uiCheckbox(
    867, scene.canvasHeight - 74, 19, 18, 120, 88,
    "UI-Checkbox", "scene.toggleConnectors", "unchecked");
  checkboxes[1] = new uiCheckbox(
    867, scene.canvasHeight - 46, 19, 18, 99, 67,
    "UI-Checkbox", "crosshairs.toggle", "checked");
  checkboxes[2] = new uiCheckbox(
    951, scene.canvasHeight - 74, 19, 18, 105, 73,
    "UI-Checkbox", "scene.togglePalette", "unchecked");
  checkboxes[3] = new uiCheckbox(
    951, scene.canvasHeight - 46, 19, 18, 122, 90,
    "UI-Checkbox", "scene.toggleDimension", "checked");

  // hidden checkboxes
  // toggle true elevation
  checkboxes[4] = new uiCheckbox(
    1500, 1, 1, 1, 54, 94,
    "", "scene.toggleElevation", "unchecked");


  // switches
  switches = new uiSwitch[5];
  switches[0] = new uiSwitch(
    582, scene.canvasHeight - 82, 39, 28, 49, 1,
    "UI-Switch-1", "nada", "selected");
  switches[1] = new uiSwitch(
    621, scene.canvasHeight - 82, 35, 28, 50, 1,
    "UI-Switch-2", "nada", "");
  switches[2] = new uiSwitch(
    656, scene.canvasHeight - 82, 35, 28, 51, 1,
    "UI-Switch-3", "nada", "");
  switches[3] = new uiSwitch(
    691, scene.canvasHeight - 82, 40, 28, 52, 1,
    "UI-Switch-4", "nada", "");

  // hidden switches
  // toggle mode 5
  switches[4] = new uiSwitch(
    1500, 1, 1, 1, 53, 1,
    "", "nada", "");


  // drop in the compass
  compass = new uiCompass(
    scene.canvasWidth / 2, scene.canvasHeight - 50, 31, 31);

  // create the crosshairs object
  crosshair = new uiCrosshairs();

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

    // pull out the track dimensions
    tracklist[i].getDimensions();
  };

  // create the map scale object once the map data is loaded
  mapScale = new uiScale(scene.canvasWidth / 2, scene.canvasHeight - 106, scene.canvasWidth, 5);

  // diagnostics
  println("Number of Tracks: " + numTracks);
  println("minX: " + scene.minX);
  println("maxX: " + scene.maxX);
  println("offsetX: " + scene.offsetX);
  println("minY: " + scene.minY);
  println("maxY: " + scene.maxY);
  println("offsetY: " + scene.offsetY);
  println("minZ: " + scene.minZ);
  println("maxZ: " + scene.maxZ);
  println("offsetZ: " + scene.offsetZ);
  println("minSpeed: " + scene.minSpeed);
  println("maxSpeed: " + scene.maxSpeed);
  
  println("scene width (in meters): " + scene.currentWidth);
  println("scene height (in meters): " + scene.currentHeight);

  // set the viewRedraw flag coming out of setup() so that we get the initial draw
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
        // cursor(scene.cursorHand, scene.cursorHand.width / 2, scene.cursorHand.height / 2);
          // (I suspect this was causing crashes in OS X, removed for now)
        scene.rotationY += ((float) (mouseX - pmouseX) / 180);
        if (scene.viewDimension == "3D") {
          scene.rotationX += ((float) (mouseY - pmouseY) / 180);
        }
      }
  }


  // check the UI components; render needed?
  for (int i = 0; i < buttons.length; i++) {
    buttons[i].check();
  }
  for (int i = 0; i < switches.length; i++) {
    switches[i].check();
  }
  for (int i = 0; i < checkboxes.length; i++) {
    checkboxes[i].check();
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
    
    // draw the map scale
    mapScale.render(scene.palette[1]);

    // draw mini-compass
    compass.translateThenRender();

  };

  // reset the viewRedraw switch for each loop so we don't peg the CPU
  scene.viewRedraw = false;
};

