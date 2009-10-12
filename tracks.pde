/*

  

*/
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

        // line
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
        
          // I tried some proportional math for this, but good old manual colour looks better.
          // should be formulaic; didn't figure it out. Whatever.
          float heightLimit = findDifference(scene.maxY, scene.minY) / 11;
          if (Y[i] > (0 * heightLimit)) {stroke(0, 0, 255, 255);}
          if (Y[i] > (0.9 * heightLimit)) {stroke(25, 0, 230, 255);}
          if (Y[i] > (1.8 * heightLimit)) {stroke(50, 0, 205, 255);}
          if (Y[i] > (2.7 * heightLimit)) {stroke(75, 0, 180, 255);}
          if (Y[i] > (3.6 * heightLimit)) {stroke(100, 0, 155, 255);}
          if (Y[i] > (4.5 * heightLimit)) {stroke(125, 0, 130, 255);}
          if (Y[i] > (5.4 * heightLimit)) {stroke(150, 0, 105, 255);}
          if (Y[i] > (6.3 * heightLimit)) {stroke(175, 0, 80, 255);}
          if (Y[i] > (7.2 * heightLimit)) {stroke(200, 0, 55, 255);}
          if (Y[i] > (8.1 * heightLimit)) {stroke(225, 0, 30, 255);}
          if (Y[i] > (9 * heightLimit)) {stroke(255, 0, 0, 255);}

          noFill();
          point(
            X[i], Y[i], Z[i]
          );
          break;


        // speed points:
        // red for the high speeds, blue for the low
        case 3:
          float speedLimit = findDifference(scene.maxSpeed, scene.minSpeed) / 5;

          if (speed[i] > (0 * speedLimit)) {stroke(0, 64, 255, 255);}
          if (speed[i] > (0.8 * speedLimit)) {stroke(0, 255, 0, 255);}
          if (speed[i] > (1.6 * speedLimit)) {stroke(255, 255, 0, 255);}
          if (speed[i] > (2.4 * speedLimit)) {stroke(255, 255, 0, 255);}
          if (speed[i] > (3.2 * speedLimit)) {stroke(255, 0, 0, 255);}
          noFill();

          line(
            X[i - 1], Y[i - 1], Z[i - 1], 
            X[i], Y[i], Z[i]
          );
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
  
