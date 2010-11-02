// a container object to hold the various scene properties
class Scene {
  
  // basic environment variables
  PFont scaleText;
  int canvasWidth, canvasHeight;
  float rotationX = radians(-90), rotationY = radians(-90), rotationZ = radians(180);

  // define the movement cursor
  // PImage cursorHand = loadImage(dataPath("") + "interface/Cursor-Hand.png");

  // adjustable offset values
  float offsetX = 0, offsetY = 0, offsetZ = 0;
  float drawingScale = 1;
  int elevationExaggeration = 8;

  // scene min and max limits
  float minX = 0, minY = 0, minZ = 0;
  float maxX = 0, maxY = 0, maxZ = 0;
  float minSpeed = 0, maxSpeed = 0;
  float currentWidth = 0, currentHeight = 0;
  
  // map projection compensation
  float averageLat = 0;
  int averageLatCount = 0;

  // control the way tracks are rendered
  int viewMode = 0;
  String viewDimension = "3D";
  Boolean viewConnectors = false;

  // interaction variables
  Boolean viewRedraw = true;
  boolean writePDF;

  // prefix for saved-out files
  String filePrefix = "sketch";

  // ui adjustments
  int uiIncrement = 100;
  int uiKeyPress = 0;
  Boolean uiMouseReleased = false;

  color[] palette;

  Scene(int wide, int high) {
    canvasWidth = wide;
    canvasHeight = high;

    palette = new color[2];
    palette[0] = #000000;
    palette[1] = #FFFFFF;
  }

  void refreshScene() {
    // create pfont object for scale labels
    scaleText = loadFont("Helvetica-10.vlw");
    textFont(scaleText, 10);
    textAlign(CENTER, CENTER);
  }

  void togglePalette() {
    palette = reverse(palette);
  }
  void toggleConnectors() {
    if (scene.viewConnectors) {
      scene.viewConnectors = false;
    } else {
      scene.viewConnectors = true;
    }
  }
  void toggleDimension() {
    if (scene.viewDimension == "2D") {
      scene.viewDimension = "3D";
    } else {
      scene.viewDimension = "2D";
      // adjust for top-down view
      scene.rotationX = radians(-90);
      scene.rotationY = radians(-90);
    }
  }
  void toggleElevation() {
    if (scene.elevationExaggeration == 8) {
      scene.elevationExaggeration = 1;
    } else {
      scene.elevationExaggeration = 8;
    }
  }
  
  // kind of goofy that I need this, but I've committed to converting my internal coordinates to meters
  // so now I need this function to keep track of the average raw latitude of the scene. The value it 
  // produces is used in a calculation that compensates for Mercator distortion. See Tracks.getDimensions
  void averageParallel(float av) {
    averageLatCount++;
    // find average of preceding values + new one
    averageLat = ((av * (averageLatCount - 1)) + av) / averageLatCount;
  }


}



// Core UI Element class that defines basic properties and methods
class uiElement {

  // position
  int x, y;
  // dimensions
  int wide, high;

  // state
  int state = 0;
  
  // key code for this element
  int hotKey = 1;
  int hotKeyAlt = 1;

  // UI Element images
  PImage img, imgHover, imgPressed, imgSelected;
  String imgFile;

  void render() {
    if (img != null) {
      noStroke();
      noFill();
      if (state == 3) {
        image(imgSelected, x, y);
      } else if (state == 2) {
        image(imgPressed, x, y);
      } else if (state == 1) {
        image(imgHover, x, y);
      } else {
        image(img, x, y);
      }
    }
  }
  void setCoordinates(int newX, int newY, int newW, int newH) {
    x = newX;
    y = newY;
    wide = newW;
    high = newH;
  }
  
}


// simple panel to throw our UI elements into
class uiPanel extends uiElement {
  uiPanel(String filename) {
    imgFile = filename;
    refreshImages();
  }
  void refreshImages() {
    if (imgFile != null) {
      img = loadImage(dataPath("") + "interface/" + imgFile + ".png");
    }
  }
}


// stand-alone buttons
class uiButton extends uiElement {

  String buttonAction;
  
  uiButton(int keyPress1, int keyPress2, String filename, String action) {
    buttonAction = action;
    hotKey = keyPress1;
    hotKeyAlt = keyPress2;
    if (!filename.equals("")) {
      imgFile = filename;
      refreshImages();
    }
  }
  void refreshImages() {
    if (imgFile != null) {
      img = loadImage(dataPath("") + "interface/" + imgFile + ".png");
      imgHover = loadImage(dataPath("") + "interface/" + imgFile + "-hover.png");
      imgPressed = loadImage(dataPath("") + "interface/" + imgFile + "-pressed.png");
    }
  }
  
  void check() {
    // is the mouse over this control?
    if ((
       mouseX >= x && mouseX <= (x + wide) &&
       mouseY >= y && mouseY <= (y + high)
      ) || (hotKey == scene.uiKeyPress) || (hotKeyAlt == scene.uiKeyPress) || (hotKeyAlt == scene.uiKeyPress)) {
      
      if(mousePressed || (hotKey == scene.uiKeyPress) || (hotKeyAlt == scene.uiKeyPress)) {
        // fair point to toggle the screen viewRedraw back on
        scene.viewRedraw = true;

        state = 2;
        // Couldn't figure out a more elegant way of passing these instructions.
        // Soooo... string it is.
        if (buttonAction.equals("offsetX--")) {scene.offsetX -= determineOffset();}
        if (buttonAction.equals("offsetX++")) {scene.offsetX += determineOffset();}
        // only modify the Y axis if we're in 3D mode
        if (scene.viewDimension == "3D") {
          if (buttonAction.equals("offsetY--")) {scene.offsetY -= determineOffset();}
          if (buttonAction.equals("offsetY++")) {scene.offsetY += determineOffset();}
        }
        if (buttonAction.equals("offsetZ--")) {scene.offsetZ -= determineOffset();}
        if (buttonAction.equals("offsetZ++")) {scene.offsetZ += determineOffset();}
        if (buttonAction.equals("drawingScale--")) {scene.drawingScale -= (determineOffset() * scene.drawingScale * 0.0001); checkBoundaries();}
        if (buttonAction.equals("drawingScale++")) {scene.drawingScale += (determineOffset() * scene.drawingScale * 0.0001); checkBoundaries();}
      } else {
        // no need to redraw every loop, just the initial hover event
        if (state != 1) {
          scene.viewRedraw = true;
        }
        state = 1;
      }
      scene.uiKeyPress = 0;
     } else {
      // if we still have a lingering state, lets redraw and clear the hover / selected image
      if (state > 0) {
        scene.viewRedraw = true;
      }
      state = 0;
    }
    scene.uiMouseReleased = false;  
  }
  
}


// basic checkbox
class uiCheckbox extends uiElement {

  String checkboxAction;

  uiCheckbox(int keyPress1, int keyPress2, String filename, String action, String defaultState) {
    checkboxAction = action;
    hotKey = keyPress1;
    hotKeyAlt = keyPress2;
    if (!filename.equals("")) {
      imgFile = filename;
      refreshImages();
    }
    if (defaultState.equals("checked")) {
      state = 3; // check the checkbox by default
    } else {
      state = 0;
    }
  }
  void refreshImages() {
    if (imgFile != null) {
      img = loadImage(dataPath("") + "interface/" + imgFile + ".png");
      imgSelected = loadImage(dataPath("") + "interface/" + imgFile + "-selected.png");
    }
  }

  void check() {
    if ((
      mouseX >= x && mouseX <= (x + wide) &&
      mouseY >= y && mouseY <= (y + high)
    ) || (hotKey == scene.uiKeyPress) || (hotKeyAlt == scene.uiKeyPress)) {

        if(scene.uiMouseReleased || (hotKey == scene.uiKeyPress) || (hotKeyAlt == scene.uiKeyPress)) {
          scene.viewRedraw = true;
          if (state == 3) {
            state = 0;
          } else {
            state = 3;
          }
          // Couldn't figure out a more elegant way of passing these instructions.
          // Soooo... string it is.
          if (checkboxAction.equals("crosshairs.toggle")) {crosshair.toggle();}
          if (checkboxAction.equals("scene.togglePalette")) {scene.togglePalette();}
          if (checkboxAction.equals("scene.toggleConnectors")) {scene.toggleConnectors();}
          if (checkboxAction.equals("scene.toggleDimension")) {scene.toggleDimension();}
          if (checkboxAction.equals("scene.toggleElevation")) {scene.toggleElevation();}
          
          scene.uiKeyPress = 0;
        }
     }
    scene.uiMouseReleased = false;  
  }
}


// switches are sort of a radio button type of control, where only one of the group can be selected
class uiSwitch extends uiElement {

  String switchAction;
  
  uiSwitch(int keyPress1, int keyPress2, String filename, String action, String defaultState) {
    switchAction = action;
    hotKey = keyPress1;
    hotKeyAlt = keyPress2;
    if (!filename.equals("")) {
      imgFile = filename;
      refreshImages();
    }
    if (defaultState.equals("selected")) {
      state = 3; // select this switch by default
    } else {
      state = 0;
    }
  }
  void refreshImages() {
    if (imgFile != null) {
      img = loadImage(dataPath("") + "interface/" + imgFile + ".png");
      imgHover = loadImage(dataPath("") + "interface/" + imgFile + "-hover.png");
      imgSelected = loadImage(dataPath("") + "interface/" + imgFile + "-selected.png");
    }
  }

  void check() {
    if ((
      mouseX >= x && mouseX <= (x + wide) &&
      mouseY >= y && mouseY <= (y + high)
    ) || (hotKey == scene.uiKeyPress) || (hotKeyAlt == scene.uiKeyPress)) {
        // if it was clicked, toggle it
        if(mousePressed || (hotKey == scene.uiKeyPress) || (hotKeyAlt == scene.uiKeyPress)) {
          toggle(this);

          // fair point to toggle the screen viewRedraw back on
          scene.viewRedraw = true;
        }
        // if this one isn't selected, apply a hover state        
        if (state != 3) {
          // no need to redraw every loop, just the initial hover event
          if (state != 1) {
            scene.viewRedraw = true;
          }
          state = 1;
        }
        scene.uiMouseReleased = false;  
     } else {
      // if this one isn't selected, remove the hover state        
      if (state != 3) {
        // if we still have a lingering state, lets redraw and clear the hover / selected image
        if (state > 0) {
          scene.viewRedraw = true;
        }
        state = 0;
      }
     }
  }
  
  void toggle(uiSwitch me) {
    for (int i = 0; i < switches.length; i++) {
      if (switches[i] == me) {
        switches[i].state = 3;
        scene.viewMode = i;
      } else {
        switches[i].state = 0; 
      }
    }
  }

}



// the directional compass in the UI
class uiCompass extends uiElement {
  void translateThenRender() {
    if (!scene.writePDF) {
      translate(x, y, 0);
      // zero out the scene default rotation values
      rotateX(scene.rotationX + PI / 2);
      rotateZ(-scene.rotationY - PI / 2);
      // north is light blue
      noStroke();
      fill(#616c7c);
      quad(0,-16,4,-5,0,0,-4,-5);
      // all other arms are darker blue
      fill(#39414f);
      quad(0,0,5,-4,16,0,5,4);
      quad(0,0,4,5,0,16,-4,5);
      quad(0,0,-5,-4,-16,0,-5,4);
    }
  }
  
}



// map scale indicator
class uiScale {

  Boolean toggle;

  // position
  int x, y;
  // dimensions
  int wide, high;
  // kilometer markers
  float kmInterval, kmScale, kmCount;

  uiScale() {
    toggle = true; 
  }  

  void setCoordinates(int newX, int newY, int newW, int newH) {
    x = newX;
    y = newY;
    wide = newW;
    high = newH;
  }
  void render(color col) {
    if (toggle) {

      // how many kilometers wide the base scale is, based on scene width and variable drawingScale value
      kmScale = (wide / (wide * scene.drawingScale) * cos(scene.averageLat * PI / 180));
      
      // how many pixels between each km marker
      kmInterval = (wide / kmScale) * (1000.00 / wide); // (1000 / 32.625) = 30.65

      if (!scene.writePDF) {
        pushMatrix();
          translate(x, y);

          // draw the 1000k markers
          drawLine(kmInterval, kmScale, 1000, 0, 0.5, 2, 4, col);

          // draw the 100k markers
          drawLine(kmInterval, kmScale, 100, 0.5, 5, 2, 4, col);

          // draw the 10k markers
          drawLine(kmInterval, kmScale, 10, 5, 50, 2, 4, col);
  
          // draw the kilometer markers
          drawLine(kmInterval, kmScale, 1, 50, 500, 1, 3, col);
  
          // draw the 100m markers
          drawLine(kmInterval, kmScale, 0.1, 500, 200000, 1, 3, col);
  
        popMatrix();
      }

    }
  }

  void drawLine(float kmInterval, float kmScale, float currentMultiplier, float minVal, float maxVal, int strokeVal, int thisLength, color col) {
    if ((kmInterval > minVal) && (kmInterval < maxVal)) {
        stroke(col, 128);
        strokeWeight(strokeVal);

        for (int i = 0; i <= round(kmScale) / currentMultiplier; i++) {
          float thisVal = (i * kmInterval * currentMultiplier) - wide / 2;
          line(thisVal, 0 - thisLength, thisVal, thisLength);

          fill(scene.palette[1], 128);
          text(createLabel(i, currentMultiplier), thisVal, -10);
        }
    }
  }

  String createLabel(int value, float currentMultiplier) {
    if (currentMultiplier >= 1) {
      return Integer.toString(int(value * currentMultiplier)) + "km";
    } else {
      return Integer.toString(int(value * currentMultiplier * 1000)) + "m";
    }
  }

}



// main crosshairs
class uiCrosshairs {

  Boolean toggle;
  
  uiCrosshairs() {
    toggle = true; 
  }

  void render(color col) {
    if (toggle) {
      if (!scene.writePDF) {
        stroke(col, 60);
        strokeWeight(1);
        line(-999999, 0, 0, 999999, 0, 0);
        line(0, -999999, 0, 0, 999999, 0);
        line(0, 0, -999999, 0, 0, 999999);
      }
    }
  }
  
  void toggle() {
    if (toggle) {
      toggle = false;
    } else {
      toggle = true;
    }
  }
}




void keyPressed() {
  scene.uiKeyPress = int(key);
  println(int(key));
  // need to translate coded keys to something else
  // arrows = a/w/s/d
  if (key == CODED) {
    if (keyCode == UP) {
      scene.uiKeyPress = 119;
    } else if (keyCode == DOWN) {
      scene.uiKeyPress = 115; 
    } else if (keyCode == LEFT) {
      scene.uiKeyPress = 97; 
    } else if (keyCode == RIGHT) {
      scene.uiKeyPress = 100; 
    }
  }
  // if 'p' is pressed, save out a PNG
  // if 'P' is pressed, save out a PDF
  if (int(key) == 112) {
    save(scene.filePrefix + "-" + int(random(0, 9999)) + ".png");
  }
  if (int(key) == 80) {
    scene.writePDF = true;
  }
  // if 'r' is pressed, then reload the XML files
  if (int(key) == 82) {
    refreshTracks(); 
    scene.viewRedraw = true;
  }
}


void mouseReleased() {
  // it'd be nice if mouseReleased was a native variable the 
  // same way mousePressed is, but no matter. 
  for (int i = 0; i < checkboxes.length; i++) {
    scene.uiMouseReleased = true;
    checkboxes[i].check();
  }
}



int determineOffset() {
  try {
   if (keyEvent.isControlDown()) {
      if (keyEvent.isShiftDown()) {
        return(scene.uiIncrement * 1000);
      } else {
        return(scene.uiIncrement * 100);
      }
    } else if (keyEvent.isShiftDown()) {
      return(scene.uiIncrement * 10);
    } else {
      return(scene.uiIncrement);
    }
  }
  catch (NullPointerException e) {
    // this is really dumb:
    // if a keypress event doesn't happen before the above code fires, Processing throws a NullPointer
    // but if it does, no problem. So... catch the error, duplicate my code. Whatever.
    return(scene.uiIncrement);
  }
}


void checkBoundaries() {
  // set a lower boundary
  if (scene.drawingScale > 0.65) {
     scene.drawingScale = 0.65;
  }
  // set an upper boundary
  if (scene.drawingScale < 0.00004) {
     scene.drawingScale = 0.00004;
  }
}




// setup the PDF save
void startPDFCheck(String fileName) {
  if (scene.writePDF) {
    beginRaw(PDF, fileName + ".pdf");
    scene.viewRedraw = true;
  }
}

// execute the PDF save
void stopPDFCheck() {
  if (scene.writePDF) {
    endRaw();
    scene.writePDF = false;
  }
}


// handle window resize events
void resizeHandler(ComponentEvent e) {
  // set minimum boundaries
  int minWidth = sceneStartingWidth;
  int minHeight = sceneStartingHeight;
  
  int w = frame.getWidth();
  int h = frame.getHeight();

  if(e.getSource() == frame) { // resize event has been detected
    // set minimum boundaries
    if (w < minWidth) frame.setSize(minWidth, h); 
    if (h < minHeight) frame.setSize(w, minHeight); 

    // reset scene variables
    scene.canvasWidth = w;
    scene.canvasHeight = h;
    setSceneScale();
 
    positionUI(w, h);
    cacheUI();

    scene.viewRedraw = true;
  }
}


// utility function to create / refresh the UI images
// (need to re-call this on window size to kill the previous image cache)
void cacheUI() {
    scene.refreshScene();
    UI.refreshImages();
    for (int i = 0; i < buttons.length; i++) {
      buttons[i].refreshImages();
    }
    for (int i = 0; i < checkboxes.length; i++) {
      checkboxes[i].refreshImages();
    }
    for (int i = 0; i < chrome.length; i++) {
      chrome[i].refreshImages();
    }
    for (int i = 0; i < switches.length; i++) {
      switches[i].refreshImages();
    }
}


// utility function to establish the scene scale based on canvas dimensions
void setSceneScale() {
  // find out which direction is the largest, then adjust drawingScale to fit the scene
  if ((scene.maxX - scene.minX) > (scene.maxY - scene.minY)) {
    scene.drawingScale = scene.canvasWidth / (scene.maxX - scene.minX) / 2;
  } else {
    scene.drawingScale = scene.canvasHeight / (scene.maxY - scene.minY) / 2;
  }
}


// place the UI elements according to current scene width and height
void positionUI(int w, int h) {
  h -= sceneOffset;
  UI.setCoordinates(0, h - 100, w, 100);

  int posElevation = int(w * 0.22);
  int posZoom = int(w * 0.35);
  int posSwitches = int(w * 0.635);

  compass.setCoordinates(w / 2, h - 50, 31, 31);
  mapScale.setCoordinates(w / 2, h - 106, w, 5);

  chrome[0].setCoordinates(w / 2 - 20, h - 70, 41, 41);
  chrome[1].setCoordinates(w - 205, h - 70, 147, 39);
  chrome[2].setCoordinates(posSwitches, h - 43, 82, 28);
  chrome[3].setCoordinates(posElevation, h - 43, 79, 29);
  chrome[4].setCoordinates(107, h - 64, 83, 29);
  chrome[5].setCoordinates(posZoom, h - 43, 59, 29);
  
  checkboxes[0].setCoordinates(w - 134, h - 74, 19, 18);
  checkboxes[1].setCoordinates(w - 134, h - 46, 19, 18);
  checkboxes[2].setCoordinates(w - 49, h - 74, 19, 18);
  checkboxes[3].setCoordinates(w - 49, h - 46, 19, 18);

  switches[0].setCoordinates(posSwitches - 32, h - 82, 39, 28);
  switches[1].setCoordinates(posSwitches + 7, h - 82, 35, 28);
  switches[2].setCoordinates(posSwitches + 42, h - 82, 35, 28);
  switches[3].setCoordinates(posSwitches + 77, h - 82, 40, 28);

  buttons[0].setCoordinates(44, h - 90, 35, 40);
  buttons[1].setCoordinates(44, h - 49, 35, 40);
  buttons[2].setCoordinates(22, h - 67, 45, 30);
  buttons[3].setCoordinates(61, h - 67, 45, 30);

  buttons[4].setCoordinates(posElevation - 13, h - 82, 52, 30);
  buttons[5].setCoordinates(posElevation + 37, h - 82, 52, 30);

  buttons[6].setCoordinates(posZoom - 21, h - 82, 52, 30);
  buttons[7].setCoordinates(posZoom + 29, h - 82, 52, 30);
}
