
// the main track object holds a collection of points
class Tracks {

  int pointCount;

  float X[];
  float Y[];
  float Z[];

  float[] speed;
  String[] time;

  int pointTracer = 0;

  // constructor
  Tracks(int num) {
    pointCount = num;
    X = new float[pointCount];
    Y = new float[pointCount];
    Z = new float[pointCount];
    speed = new float[pointCount];
    time = new String[pointCount];
  };
  
  void render() {
    strokeWeight(2);
    for (int i = 1; i < pointCount; i++) {

      // make sure this wasn't a skipped point in the data
      // (has the unfortunate side effect of breaking routes taking place at 0,0, but 
      // considering that's a few hundred km off the coast of Gabon, I'm okay with that)
      if (X[i] != 0) {

        float speedLimit = findDifference(scene.maxSpeed, scene.minSpeed) / 5;

        switch(scene.viewMode) {
  
          // plain white
          case 0:
            stroke(scene.palette[1], 60);
            noFill();
            if (X[i - 1] != 0) {
              drawConnectors(X[i - 1], Y[i - 1], Z[i - 1], X[i], Y[i], Z[i]);
            }
            break;
  

    
          // elevation indicators:
          // red for the high elevations, blue for the low
          case 1:
            float heightLimit = findDifference(scene.maxY, scene.minY) / 11;
            for (int j = 0; j < 10; j++) {
              if (Y[i] > (j * 0.9 * heightLimit)) {
                stroke(j * 25, 0, 255 - j * 25, 255);
              } 
            }
            noFill();
            if (X[i - 1] != 0) {
              drawConnectors(X[i - 1], Y[i - 1], Z[i - 1], X[i], Y[i], Z[i]);
            }
            break;
  
  
  
          // speed indicators: a manual spectrum from dark blue to red
          // lots of stops on the low end, because that's where speed data seems to be weakest
          case 2:
            // there's a lot
            if (speed[i] > (0 * speedLimit)) {stroke(0, 0, 255, 64);} // even more faded blue
            if (speed[i] > (0.1 * speedLimit)) {stroke(0, 0, 255, 128);} // faded blue
            if (speed[i] > (0.2 * speedLimit)) {stroke(0, 0, 255, 192);} // faded blue
            if (speed[i] > (0.4 * speedLimit)) {stroke(0, 0, 255, 255);} // full blue
            if (speed[i] > (0.8 * speedLimit)) {stroke(0, 255, 0, 255);} // green
            if (speed[i] > (1.6 * speedLimit)) {stroke(255, 255, 0, 255);}  // yellow
            if (speed[i] > (2.0 * speedLimit)) {stroke(255, 192, 0, 255);} // yellow orange
            if (speed[i] > (2.4 * speedLimit)) {stroke(255, 128, 0, 255);} // orange
            if (speed[i] > (2.8 * speedLimit)) {stroke(255, 64, 0, 255);} // orange red
            if (speed[i] > (3.2 * speedLimit)) {stroke(255, 0, 0, 255);} // red
            noFill();
            if (X[i - 1] != 0) {
              drawConnectors(X[i - 1], Y[i - 1], Z[i - 1], X[i], Y[i], Z[i]);
            };
            break;
  
  
  
          // animated tracers
          case 3:
            noStroke();
            noFill();
  
            color strokeColor = color(0, 0, 0, 0);
            if (speed[i] > (0.4 * speedLimit)) {strokeColor = color(0, 0, 255);} // blue
            if (speed[i] > (0.8 * speedLimit)) {strokeColor = color(0, 255, 0);} // green
            if (speed[i] > (1.6 * speedLimit)) {strokeColor = color(255, 255, 0);}  // yellow
            if (speed[i] > (2.0 * speedLimit)) {strokeColor = color(255, 192, 0);} // yellow orange
            if (speed[i] > (2.4 * speedLimit)) {strokeColor = color(255, 128, 0);} // orange
            if (speed[i] > (2.8 * speedLimit)) {strokeColor = color(255, 64, 0);} // orange red
            if (speed[i] > (3.2 * speedLimit)) {strokeColor = color(255, 0, 0);} // red

            // create the fadeout trails
            for (int j = 0; j < 64; j++) {
              if (i == pointTracer - j) {stroke(strokeColor, 128 - 2 * j);};
            }
            // more strongly define the current point
            if (i == pointTracer) {stroke(strokeColor, 255);};
            if (X[i - 1] != 0) {
              drawConnectors(X[i - 1], Y[i - 1], Z[i - 1], X[i], Y[i], Z[i]);
            }
            break;




          // elevation spikes
          case 4:
            noFill();
            stroke(scene.palette[1], 32);
            drawConnectors(X[i], scene.minY, Z[i], X[i], Y[i], Z[i]);
            break;  




          // quad fills
          // don't work at the moment because something strange is happening with the rotation.
          // only works for X, need to rotate on Y. strange.
          case 5:
            noStroke();
            fill(scene.palette[1], 64);
            if (X[i - 1] != 0) {
              pushMatrix();
                translate(0, 0, Z[i]);
//                rotateY(-PI * 0.25);
                quad(
                  X[i], scene.minY,
                  X[i], Y[i] * scene.elevationExaggeration,
                  X[i - 1], Y[i - 1] * scene.elevationExaggeration,
                  X[i - 1], scene.minY
                );
              popMatrix();
            }
            break;




        }; // end switch
      }; //end if
    }; // end for
    
    pointTracer++;
    if (pointTracer > pointCount) {
      pointTracer = 0; 
    }
    
  }; // end render()


  void getDimensions() {
    // loop through all points and find the ranges
    for (int i = 1; i < pointCount; i++) {
      scene.minX = checkMe(scene.minX, X[i], "min");
      scene.maxX = checkMe(scene.maxX, X[i], "max");

      scene.minY = checkMe(scene.minY, Y[i], "min");
      scene.maxY = checkMe(scene.maxY, Y[i], "max");

      scene.minZ = checkMe(scene.minZ, Z[i], "min");
      scene.maxZ = checkMe(scene.maxZ, Z[i], "max");

      scene.minSpeed = checkMe(scene.minSpeed, speed[i], "min");
      scene.maxSpeed = checkMe(scene.maxSpeed, speed[i], "max");
    };

    // move the scene center point to 0, 0
    scene.offsetX = 0 - (scene.minX + findDifference(scene.minX, scene.maxX));
    scene.offsetY = 0 - (scene.minY + findDifference(scene.minY, scene.maxY));
    scene.offsetZ = 0 - (scene.minZ + findDifference(scene.minZ, scene.maxZ));

    // math to compensate for latitude distortion
    // adapted from http://msdn.microsoft.com/en-us/library/bb259689.aspx
    scene.currentWidth = findDifference(scene.minZ, scene.maxZ) * 2 * cos(scene.averageLat * PI/180);
    scene.currentHeight = findDifference(scene.minX, scene.maxX) * 2 * cos(scene.averageLat * PI/180);
    
    // find out which direction is the largest, then adjust drawingScale to fit the scene
    if ((scene.maxX - scene.minX) > (scene.maxY - scene.minY)) {
      scene.drawingScale = scene.canvasWidth / (scene.maxX - scene.minX) / 2;
    } else {
      scene.drawingScale = scene.canvasHeight / (scene.maxY - scene.minY) / 2;
    }

  };


  void drawConnectors(float x1, float y1, float z1, float x2, float y2, float z2) {
    // flatten out the Y axis if we're in 2D mode
    if (scene.viewDimension == "2D") {
      y1 = 0;
      y2 = 0;
    };
    // check viewConnectors and draw lines or points, respectively
    if (scene.viewConnectors) {
      line(
        x1, y1 * scene.elevationExaggeration, z1,
        x2, y2 * scene.elevationExaggeration, z2
      );
    } else {
      point(x2, y2 * scene.elevationExaggeration, z2);
    };
  };


  float checkMe(float val, float iteration, String dir) {
    // if the value hasn't been set yet, lets initialize it
    if (val == 0) {
      val = iteration;
    } else {
      // if we're looking for a minimum, see if the current value is lower than the current minimum
      if (dir == "min") {
        // see the note above re:Gabon for the reason why this check is necessary
        if (iteration != 0) {
          if (iteration < val) {
            val = iteration;
          };
        };
      // otherwise see if the current value is higher than the current maximum
      } else {
        if (iteration > val) {
          val = iteration;
        };
      };
    };
    return val;
  }


};
  
