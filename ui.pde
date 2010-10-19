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
  Boolean viewRedraw = true;

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

    // create pfont object for scale labels
    scaleText = loadFont("Helvetica-10.vlw");
    textFont(scaleText, 10);
    textAlign(CENTER, CENTER);
  };

  void togglePalette() {
    palette = reverse(palette);
  };
  void toggleConnectors() {
    if (scene.viewConnectors) {
      scene.viewConnectors = false;
    } else {
      scene.viewConnectors = true;
    };
  };
  void toggleDimension() {
    if (scene.viewDimension == "2D") {
      scene.viewDimension = "3D";
    } else {
      scene.viewDimension = "2D";
      // adjust for top-down view
      scene.rotationX = radians(-90);
      scene.rotationY = radians(-90);
    };
  };
  void toggleElevation() {
    if (scene.elevationExaggeration == 8) {
      scene.elevationExaggeration = 1;
    } else {
      scene.elevationExaggeration = 8;
    };
  };
  
  // kind of goofy that I need this, but I've committed to converting my internal coordinates to meters
  // so now I need this function to keep track of the average raw latitude of the scene. The value it 
  // produces is used in a calculation that compensates for Mercator distortion. See Tracks.getDimensions
  void averageParallel(float av) {
    averageLatCount++;
    // find average of preceding values + new one
    averageLat = ((av * (averageLatCount - 1)) + av) / averageLatCount;
  };


};



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
  PImage img;
  PImage imgHover;
  PImage imgPressed;
  PImage imgSelected;

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
      };
    };
  };
  
};


// simple panel to throw our UI elements into
class uiPanel extends uiElement {
  uiPanel(int newX, int newY, int newWide, int newHigh, String filename) {
    x = newX;
    y = newY;
    wide = newWide;
    high = newHigh;
    img = loadImage(dataPath("") + "interface/" + filename + ".png");
  };
};


// stand-alone buttons
class uiButton extends uiElement {

  String buttonAction;
  
  uiButton(int newX, int newY, int newWide, int newHigh, int keyPress1, int keyPress2, String filename, String action) {
    x = newX;
    y = newY;
    wide = newWide;
    high = newHigh;
    buttonAction = action;
    hotKey = keyPress1;
    hotKeyAlt = keyPress2;
    if (!filename.equals("")) {
      img = loadImage(dataPath("") + "interface/" + filename + ".png");
      imgHover = loadImage(dataPath("") + "interface/" + filename + "-hover.png");
      imgPressed = loadImage(dataPath("") + "interface/" + filename + "-pressed.png");
    };
  };
  
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
      };
      scene.uiKeyPress = 0;
     } else {
      // if we still have a lingering state, lets redraw and clear the hover / selected image
      if (state > 0) {
        scene.viewRedraw = true;
      };
      state = 0;
    };
    scene.uiMouseReleased = false;  
  };
  
};


// basic checkbox
class uiCheckbox extends uiElement {

  String checkboxAction;

  uiCheckbox(int newX, int newY, int newWide, int newHigh, int keyPress1, int keyPress2, String filename, String action, String defaultState) {
    x = newX;
    y = newY;
    wide = newWide;
    high = newHigh;
    checkboxAction = action;
    hotKey = keyPress1;
    hotKeyAlt = keyPress2;
    if (!filename.equals("")) {
      img = loadImage(dataPath("") + "interface/" + filename + ".png");
      imgSelected = loadImage(dataPath("") + "interface/" + filename + "-selected.png");
    };
    if (defaultState.equals("checked")) {
      state = 3; // check the checkbox by default
    } else {
      state = 0;
    };
  };

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
          };
          // Couldn't figure out a more elegant way of passing these instructions.
          // Soooo... string it is.
          if (checkboxAction.equals("crosshairs.toggle")) {crosshair.toggle();}
          if (checkboxAction.equals("scene.togglePalette")) {scene.togglePalette();}
          if (checkboxAction.equals("scene.toggleConnectors")) {scene.toggleConnectors();}
          if (checkboxAction.equals("scene.toggleDimension")) {scene.toggleDimension();}
          if (checkboxAction.equals("scene.toggleElevation")) {scene.toggleElevation();}
          
          scene.uiKeyPress = 0;
        };
     };
    scene.uiMouseReleased = false;  
  };
};


// switches are sort of a radio button type of control, where only one of the group can be selected
class uiSwitch extends uiElement {

  String switchAction;
  
  uiSwitch(int newX, int newY, int newWide, int newHigh, int keyPress1, int keyPress2, String filename, String action, String defaultState) {
    x = newX;
    y = newY;
    wide = newWide;
    high = newHigh;
    switchAction = action;
    hotKey = keyPress1;
    hotKeyAlt = keyPress2;
    if (!filename.equals("")) {
      img = loadImage(dataPath("") + "interface/" + filename + ".png");
      imgHover = loadImage(dataPath("") + "interface/" + filename + "-hover.png");
      imgSelected = loadImage(dataPath("") + "interface/" + filename + "-selected.png");
    };
    if (defaultState.equals("selected")) {
      state = 3; // select this switch by default
    } else {
      state = 0;
    };
  };

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
        };

        scene.uiMouseReleased = false;  
     } else {
      // if this one isn't selected, remove the hover state        
      if (state != 3) {
        // if we still have a lingering state, lets redraw and clear the hover / selected image
        if (state > 0) {
          scene.viewRedraw = true;
        };
        state = 0;
      };
     };
  };
  
  void toggle(uiSwitch me) {
    for (int i = 0; i < switches.length; i++) {
      if (switches[i] == me) {
        switches[i].state = 3;
        scene.viewMode = i;
      } else {
        switches[i].state = 0; 
      };
    };
  };

};


// the directional compass in the UI
class uiCompass extends uiElement {
  uiCompass(int newX, int newY, int newWide, int newHigh) {
    x = newX;
    y = newY;
    wide = newWide;
    high = newHigh;
  };

  void translateThenRender() {
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
  };
  
};



// map scale indicator
class uiScale {

  Boolean toggle;

  // position
  int x, y;
  // dimensions
  int wide, high;
  // kilometer markers
  float kmInterval, kmScale, kmCount;

  uiScale(int newX, int newY, int newWide, int newHigh) {
    toggle = true; 
    x = newX;
    y = newY;
    wide = newWide;
    high = newHigh;
  };  

  void render(color col) {
    if (toggle) {

      // find out current width of scene
      kmCount = scene.currentWidth;

      // how many kilometers wide the base scale is, based on scene width and variable drawingScale value
      kmScale = (kmCount / (kmCount * scene.drawingScale) * cos(scene.averageLat * PI/180));
      
      // how many pixels between each km marker
      kmInterval = wide / kmScale;
      
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

    };
  };

  void drawLine(float currentVal, float currentScale, float currentMultiplier, float minVal, float maxVal, int strokeVal, int thisLength, color col) {
    if ((currentVal > minVal) && (currentVal < maxVal)) {
        stroke(col, 128);
        strokeWeight(strokeVal);

        for (int i = 0; i <= round(currentScale) / currentMultiplier; i++) {
          float thisVal = (i * currentVal * currentMultiplier) - wide / 2;
          line(thisVal, 0 - thisLength, thisVal, thisLength);

          fill(scene.palette[1], 128);
          text(createLabel(i, currentMultiplier), thisVal, -10);
        };
    };
  };

  String createLabel(int value, float currentMultiplier) {
    if (currentMultiplier >= 1) {
      return Integer.toString(int(value * currentMultiplier)) + "km";
    } else {
      return Integer.toString(int(value * currentMultiplier * 1000)) + "m";
    }
  };

};



// main crosshairs
class uiCrosshairs {

  Boolean toggle;
  
  uiCrosshairs() {
    toggle = true; 
  };

  void render(color col) {
    if (toggle) {
      stroke(col, 60);
      strokeWeight(1);
      line(-999999, 0, 0, 999999, 0, 0);
      line(0, -999999, 0, 0, 999999, 0);
      line(0, 0, -999999, 0, 0, 999999);
    };
  };
  
  void toggle() {
    if (toggle) {
      toggle = false;
    } else {
      toggle = true;
    };
  };
};




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
    };
  };
  // if 'r' is pressed, then reload the XML files
  if (int(key) == 82) {
    refreshTracks(); 
    scene.viewRedraw = true;
  }
};


void mouseReleased() {
  // it'd be nice if mouseReleased was a native variable the 
  // same way mousePressed is, but no matter. 
  for (int i = 0; i < checkboxes.length; i++) {
    scene.uiMouseReleased = true;
    checkboxes[i].check();
  }
};



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
};


void checkBoundaries() {
  // set a lower boundary
  if (scene.drawingScale > 0.65) {
     scene.drawingScale = 0.65;
  };  
  // set an upper boundary
  if (scene.drawingScale < 0.00004) {
     scene.drawingScale = 0.00004;
  };
};
