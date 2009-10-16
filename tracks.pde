// the main track object holds a collection of points
// and 
class Tracks {
  
  int pointCount;

  float X[];
  float Y[];
  float Z[];

  float[] speed;
  String[] time;
  int direction[];


  // constructor
  Tracks(int num) {
    pointCount = num;
    X = new float[pointCount];
    Y = new float[pointCount];
    Z = new float[pointCount];
    speed = new float[pointCount];
    time = new String[pointCount];
    direction = new int[pointCount];
  };
  
  void render() {
    strokeWeight(2);
    for (int i = 1; i < pointCount; i++) {
      switch(scene.renderMode) {

        
        // line between points
        case 0:
          stroke(scene.palette[1], 50);
          noFill();
          line(
            X[i - 1], Y[i - 1], Z[i - 1], 
            X[i], Y[i], Z[i]
          );
          break;


        // raw points
        case 1:
          stroke(scene.palette[1], 80);
          noFill();
          point(
            X[i], Y[i], Z[i]
          );
          break;


        // elevation points:
        // red for the high elevations, blue for the low
        case 2:
          float heightLimit = findDifference(scene.maxY, scene.minY) / 11;
          for (int j = 0; j < 10; j++) {
            if (Y[i] > (j * 0.9 * heightLimit)) {
              stroke(j * 25, 0, 255 - j * 25, 255);
            } 
          }
          noFill();
          point(
            X[i], Y[i], Z[i]
          );
          break;


        // speed lines: a manual spectrum from dark blue to red
        // lots of stops on the low end, because that's where speed data seems to be weakest
        case 3:
          float speedLimit = findDifference(scene.maxSpeed, scene.minSpeed) / 5;
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

          line(
            X[i - 1], Y[i - 1], Z[i - 1],
            X[i], Y[i], Z[i]
          );
          break;

        // elevation spikes
        case 4:
          noFill();
          stroke(scene.palette[1], 32);
          line(
            X[i], scene.minY, Z[i],
            X[i], Y[i], Z[i]
          );

// nice variation, but sloooooow. 
// Would look better logarithmic rather than linear, too, which couldn't possibly speed things up.
//          for (int j = 0; j < 10; j++) {
//            stroke(scene.palette[1], 3);
//            line(
//              X[i], scene.minY + findDifference(Y[i], scene.minY) / j, Z[i],
//              X[i], Y[i], Z[i]
//            );
//          }
          break;


      };
    };
  };


  void createLimits() {
    for (int i = 1; i < pointCount; i++) {
      scene.minX = checkMe(scene.minX, X[i], "min");
      scene.minY = checkMe(scene.minY, Y[i], "min");
      scene.minZ = checkMe(scene.minZ, Z[i], "min");
      scene.maxX = checkMe(scene.maxX, X[i], "max");
      scene.maxY = checkMe(scene.maxY, Y[i], "max");
      scene.maxZ = checkMe(scene.maxZ, Z[i], "max");

      scene.minSpeed = checkMe(scene.minSpeed, speed[i], "min");
      scene.maxSpeed = checkMe(scene.maxSpeed, speed[i], "max");
      
      // find out which direction is the largest, then adjust drawingScale to fit the scene
      if ((scene.maxX - scene.minX) > (scene.maxY - scene.minY)) {
        scene.drawingScale = scene.canvasWidth / (scene.maxX - scene.minX) / 2;
      } else {
        scene.drawingScale = scene.canvasHeight / (scene.maxY - scene.minY) / 2;
      }
      
    };
  };


  float checkMe(float val, float iteration, String dir) {
    // if the value hasn't been set yet, lets initialize it
    if (val == 0) {
      val = iteration;
    } else {
      // if we're looking for a minimum, see if the current value is lower than the current minimum
      if (dir == "min") {
        if (iteration < val) {
          val = iteration;
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
  
