
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
<<<<<<< HEAD
            if (speed[i] > 0) {stroke(scene.palette[4].value, scene.palette[4].opacity);}
            if (speed[i] > 5) {stroke(scene.palette[5].value, scene.palette[5].opacity);}
            if (speed[i] > 10) {stroke(scene.palette[6].value, scene.palette[6].opacity);}
            if (speed[i] > 15) {stroke(scene.palette[7].value, scene.palette[7].opacity);}
            if (speed[i] > 20) {stroke(scene.palette[8].value, scene.palette[8].opacity);}
            if (speed[i] > 25) {stroke(scene.palette[9].value, scene.palette[9].opacity);}
            if (speed[i] > 30) {stroke(scene.palette[10].value, scene.palette[10].opacity);}
            if (speed[i] > 35) {stroke(scene.palette[11].value, scene.palette[11].opacity);}
            if (speed[i] > 40) {stroke(scene.palette[12].value, scene.palette[12].opacity);}
            if (speed[i] > 45) {stroke(scene.palette[13].value, scene.palette[13].opacity);}
            if (speed[i] > 50) {stroke(scene.palette[14].value, scene.palette[14].opacity);}
            if (speed[i] > 55) {stroke(scene.palette[15].value, scene.palette[15].opacity);}
            if (speed[i] > 60) {stroke(scene.palette[16].value, scene.palette[16].opacity);}
            if (speed[i] > 65) {stroke(scene.palette[17].value, scene.palette[17].opacity);}
            if (speed[i] > 70) {stroke(scene.palette[18].value, scene.palette[18].opacity);}
            if (speed[i] > 75) {stroke(scene.palette[19].value, scene.palette[19].opacity);}
            if (speed[i] > 80) {stroke(scene.palette[20].value, scene.palette[20].opacity);}
            if (speed[i] > 85) {stroke(scene.palette[21].value, scene.palette[21].opacity);}
            if (speed[i] > 90) {stroke(scene.palette[22].value, scene.palette[22].opacity);}
            if (speed[i] > 95) {stroke(scene.palette[23].value, scene.palette[23].opacity);}
            if (speed[i] > 100) {stroke(scene.palette[24].value, scene.palette[24].opacity);}
=======
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
>>>>>>> parent of bbb3e10... Fixed speed data (aside from anomalies), started refactoring XML parsing to work with config files
            noFill();
            if (X[i - 1] != 0) {
              drawConnectors(X[i - 1], Y[i - 1], Z[i - 1], X[i], Y[i], Z[i]);
            };
            break;
  
  
  
          // animated tracers
          case 3:
            noStroke();
            noFill();
  
            color strokeColor = color(0, 0, 255);
//            if (speed[i] > (0.4 * speedLimit)) {strokeColor = color(0, 0, 255);} // blue
//            if (speed[i] > (0.8 * speedLimit)) {strokeColor = color(0, 255, 0);} // green
//            if (speed[i] > (1.6 * speedLimit)) {strokeColor = color(255, 255, 0);}  // yellow
//            if (speed[i] > (2.0 * speedLimit)) {strokeColor = color(255, 192, 0);} // yellow orange
//            if (speed[i] > (2.4 * speedLimit)) {strokeColor = color(255, 128, 0);} // orange
//            if (speed[i] > (2.8 * speedLimit)) {strokeColor = color(255, 64, 0);} // orange red
//            if (speed[i] > (3.2 * speedLimit)) {strokeColor = color(255, 0, 0);} // red

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
            stroke(scene.palette[1].value, 32);
            drawConnectors(X[i], scene.minY, Z[i], X[i], Y[i], Z[i]);
            drawConnectors(X[i - 1], scene.minY, Z[i - 1], X[i], scene.minY, Z[i]);
            drawConnectors(X[i - 1], Y[i - 1], Z[i - 1], X[i], Y[i], Z[i]);
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
  
