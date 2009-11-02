// a container object to hold the various scene properties
class Scene {

  // basic environment variables
  int canvasWidth, canvasHeight;
  float rotationX = radians(-90), rotationY = radians(-90), rotationZ = radians(180);

  // define the movement cursor
  // PImage cursorHand = loadImage(dataPath("") + "interface/Cursor-Hand.png");

  // adjustable offset values
  float offsetX = 0, offsetY = 0, offsetZ = 0;
  float drawingScale = 1;

  // scene min and max limits
  float minX = 0, minY = 0, minZ = 0;
  float maxX = 0, maxY = 0, maxZ = 0;
  float minSpeed = 0, maxSpeed = 0;

  // control the way tracks are rendered
  String viewDimension = "3D";
  int viewMode = 0;

  // ui adjustment increment value
  int increment = 1;

  color[] palette;

  Scene(int wide, int high) {
    canvasWidth = wide;
    canvasHeight = high;

    palette = new color[2];
    palette[0] = #000000;
    palette[1] = #FFFFFF;
  }

  void togglePalette() {
    palette = reverse(palette);
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

  // UI Element images
  PImage img;
  PImage imgHover;
  PImage imgPressed;
  PImage imgSelected;

  void render() {
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
  
  uiButton(int newX, int newY, int newWide, int newHigh, String filename, String action) {
    x = newX;
    y = newY;
    wide = newWide;
    high = newHigh;
    buttonAction = action;
    img = loadImage(dataPath("") + "interface/" + filename + ".png");
    imgHover = loadImage(dataPath("") + "interface/" + filename + "-hover.png");
    imgPressed = loadImage(dataPath("") + "interface/" + filename + "-pressed.png");
  };
  
  void check() {
    if (
      mouseX >= x && mouseX <= (x + wide) &&
      mouseY >= y && mouseY <= (y + high)) {
        if(mousePressed) {
          state = 2;
          // Couldn't figure out a more elegant way of passing these instructions.
          // Soooo... string it is.
          if (buttonAction.equals("offsetX--")) {scene.offsetX -= scene.increment;}
          if (buttonAction.equals("offsetX++")) {scene.offsetX += scene.increment;}
          // only modify the Y axis if we're in 3D mode
          if (scene.viewDimension == "3D") {
            if (buttonAction.equals("offsetY--")) {scene.offsetY -= scene.increment;}
            if (buttonAction.equals("offsetY++")) {scene.offsetY += scene.increment;}
          }
          if (buttonAction.equals("offsetZ--")) {scene.offsetZ -= scene.increment;}
          if (buttonAction.equals("offsetZ++")) {scene.offsetZ += scene.increment;}
          if (buttonAction.equals("drawingScale--")) {scene.drawingScale -= scene.increment * 0.1; checkBoundaries();}
          if (buttonAction.equals("drawingScale++")) {scene.drawingScale += scene.increment * 0.1;}
        } else {
          state = 1;
        }
     } else {
       state = 0;
    }
  };
  
};

// basic checkbox
class uiCheckbox extends uiElement {

  String checkboxAction;

  uiCheckbox(int newX, int newY, int newWide, int newHigh, String filename, String action, String defaultState) {
    x = newX;
    y = newY;
    wide = newWide;
    high = newHigh;
    checkboxAction = action;
    img = loadImage(dataPath("") + "interface/" + filename + ".png");
    imgSelected = loadImage(dataPath("") + "interface/" + filename + "-selected.png");
    if (defaultState.equals("checked")) {
      state = 3; // check the checkbox by default
    } else {
      state = 0;
    }
  };

  void check() {
    if (
      mouseX >= x && mouseX <= (x + wide) &&
      mouseY >= y && mouseY <= (y + high)) {
        if (state == 3) {
          state = 0;
        } else {
          state = 3;
        };
        // Couldn't figure out a more elegant way of passing these instructions.
        // Soooo... string it is.
        if (checkboxAction.equals("crosshairs.toggle")) {crosshair.toggle();}
        if (checkboxAction.equals("scene.togglePalette")) {scene.togglePalette();}
     }
  };
};


// switches are sort of a radio button type of control, where only one of the group can be selected
class uiSwitch extends uiElement {

  String switchAction;
  
  uiSwitch(int newX, int newY, int newWide, int newHigh, String filename, String action, String defaultState) {
    x = newX;
    y = newY;
    wide = newWide;
    high = newHigh;
    switchAction = action;
    img = loadImage(dataPath("") + "interface/" + filename + ".png");
    imgHover = loadImage(dataPath("") + "interface/" + filename + "-hover.png");
    imgSelected = loadImage(dataPath("") + "interface/" + filename + "-selected.png");
    if (defaultState.equals("selected")) {
      state = 3; // select this switch by default
    } else {
      state = 0;
    }
  };

  void check() {
    if (
      mouseX >= x && mouseX <= (x + wide) &&
      mouseY >= y && mouseY <= (y + high)) {
        // if it was clicked, toggle it
        if(mousePressed) {
          toggle(this);
        }
        // if this one isn't selected, apply a hover state        
        if (state != 3) {
          state = 1;
        }
     } else {
      // if this one isn't selected, remove the hover state        
      if (state != 3) {
        state = 0;
      }
     };
  };
  
  void toggle(uiSwitch me) {
    for (int i = 0; i < switches.length; i++) {
      if (switches[i] == me) {
        switches[i].state = 3;
        scene.viewMode = i;
      } else {
        switches[i].state = 0; 
      }
    };
  }

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
    fill(#616c7c);
    quad(0,-16,4,-5,0,0,-4,-5);
    // all other arms are darker blue
    fill(#39414f);
    quad(0,0,5,-4,16,0,5,4);
    quad(0,0,4,5,0,16,-4,5);
    quad(0,0,-5,-4,-16,0,-5,4);
  };
  
};



// main crosshairs
class Crosshairs {

  Boolean toggle;
  
  Crosshairs() {
    toggle = true; 
  }

  void render(color col) {
    if (toggle) {
      stroke(col, 60);
      strokeWeight(1);
      line(-999999, 0, 0, 999999, 0, 0);
      line(0, -999999, 0, 0, 999999, 0);
      line(0, 0, -999999, 0, 0, 999999);
    }
  }
  
  void toggle() {
    if (toggle) {
      toggle = false;
    } else {
      toggle = true;
    };
  };
};





// mouse released event handler
void mouseReleased() {
  // see if anything happened with the checkboxes
  for (int i = 0; i < checkboxes.length; i++) {
    checkboxes[i].check();
  }
}


// keyboard event handler
void keyPressed() {
  
  // toggle 2D / 3D modes
  if (int(key) == 50) {
    scene.viewDimension = "2D";
    scene.rotationX = radians(-90);
    scene.rotationY = radians(-90);
  };
  if (int(key) == 51) {scene.viewDimension = "3D";};
  
  // if '+ / =' is pressed, zoom in
  // if '-' is pressed, zoom out
  // use shift modifier to move more
  if (int(key) == 61) {scene.drawingScale += 0.1;};
    if (int(key) == 43) {scene.drawingScale += 1;};
  if (int(key) == 45) {scene.drawingScale -= 0.1;};
    if (int(key) == 95) {scene.drawingScale -= 1;};

  // use arrow keys to move around
  // use shift modifier to move more
  if (key == CODED) {
      if (keyCode == UP) {
        scene.offsetX += determineOffset();
      } else if (keyCode == DOWN) {
        scene.offsetX -= determineOffset();
      } else if (keyCode == LEFT) {
        scene.offsetZ += determineOffset();
      } else if (keyCode == RIGHT) {
        scene.offsetZ -= determineOffset();
      }
  }

  // if 'c' pressed, toggle crosshairs
   if (int(key) == 99) {
     crosshair.toggle();
   };

  // if 'i' pressed, invert display
   if (int(key) == 105) {
     scene.togglePalette();
   };

  // if 't' pressed, toggle render mode
   if (int(key) == 116) {
     scene.viewMode++;
     if (scene.viewMode > 5) {
       scene.viewMode = 0;
     }
   };

  // multiply the amount the track moves if shift is held
  if (keyCode == SHIFT) {
    scene.increment = 10;
  }

  checkBoundaries();

};

int determineOffset() {
    if (keyEvent.isControlDown()) {
      return(100);
    } else if (keyEvent.isShiftDown()) {
      return(10);
    } else {
      return(1);
    }
}

void keyReleased() {
  // clean up once shift is released
  if (keyCode == SHIFT) {
    scene.increment = 1;
  }
}

void checkBoundaries() {
  // set a lower boundary
  if (scene.drawingScale < 0.001) {
     scene.drawingScale = 0.001;
  };  
}
