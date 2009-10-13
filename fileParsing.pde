/*
   For reference:

   Path to coordinates in a GPX file from RunKeeper:
   gpx > trk > trkseg > trkpt (multiple)

   Path to coordinates in a GPX file from GPSBabel:
   gpx > trk > trkseg > trkpt (multiple)

   Path to coordinates in a KML file from RunKeeper:
   kml > Document > Placemark > MultiGeometry > LineString > coordinates

   Path to coordinates in a KML file from SportsTracker:
   kml > Document > Placemark > LineString > coordinates

*/


Tracks parseXML(String file) {

  float ele = 0;
  float revisedEle = 0;
  int numPoints = 0;
  file = dataPath("") + "/xml/" + file;

  String[][] coordinates = getCoordinates(getRoot(file), getExtension(file));
  for (int i = 0; i < coordinates.length; i++) {
     numPoints++;
  };

  // create a throwaway object
  Tracks obj = new Tracks(numPoints);

  if (numPoints > 1) {
    // now let's go through and build a track from coordinates
    for (int i = 0; i < numPoints; i++) {
  
      // there are around 5 orders of magnitude difference between the
      // useful part of the lat/long data and the elevation value.
      // lets multiply the former by a thousand (and drop any negative values while we're at it)
      obj.X[i] = abs(Float.parseFloat(coordinates[i][0]) * 1000);
      obj.Z[i] = abs(Float.parseFloat(coordinates[i][1]) * 1000);
  
      // average out each point's elevation with the two preceding it to minimize spikes
      if (i > 1) {
        obj.Y[i] = ((Float.parseFloat(coordinates[i][2]) * 0.1) + obj.Y[i - 1] + obj.Y[i - 2]) / 3;
      } else {
        obj.Y[i] = Float.parseFloat(coordinates[i][2]) * 0.1;
      };
  
      // get the time and speed if they exist
      if (coordinates[i][3] != null) {
        obj.time[i] = coordinates[i][3];
    
        // calculate speeds
        if (i == 0) {
          obj.speed[i] = 0; 
        } else {
          // only do it if we have more than one point to compare
          if (i > 0) {
            long timeDifference = getTimeDifference(obj.time[i], obj.time[i - 1]);
    
            if (timeDifference > 0) {
              // speed = distance / time
              obj.speed[i] = 
              sqrt(
                pow(findDifference(obj.X[i], obj.X[i - 1]), 2) + 
                pow(findDifference(obj.Y[i], obj.Y[i - 1]), 2) + 
                pow(findDifference(obj.Z[i], obj.Z[i - 1]), 2)
              ) / timeDifference;
    
          } else {
            // catch the division by zero error before it happens
            obj.speed[i] = 0; 
          };
        } else {
            obj.speed[i] = 0; 
          };
        };
      };
    }; // end for loop
  }; // end if numPoints > 1

  return obj;

};





// This function returns all the files in a directory as an array of Strings  
// modified from: http://processing.org/learning/topics/directorylist.html
ArrayList listFileNames(String dir) {
  File file = new File(dir);
  if (file.isDirectory()) {
    // dump the files into a string array
    String names[] = file.list();
    // create an ArrayList for the final file list
    ArrayList names2 = new ArrayList();

    // run through and remove files that don't match the extension
    for (int i = 0; i < names.length; i++) {
      String fileExt = getExtension(names[i]);
      if ((fileExt.toLowerCase().equals("kml")) || (fileExt.toLowerCase().equals("gpx"))) {
        names2.add(names[i]);
      };

    };
    return names2;
  } 
  else {
    // If it's not a directory
    return null;
  }
}




// find the absolute difference between two numbers, 
float findDifference(float n1, float n2) {
  if (n1 - n2 < 0) {
    return abs(n1) + abs(n2);
  } 
  else {
    return abs(n1 - n2);
  }
}



// find the time difference between two strings formatted in iso8601 format (yyyy-MM-ddTHH:mm:ssZ)
long getTimeDifference(String date1, String date2) {
  // stuff I found useful about Java's date functions:
  // http://www.coderanch.com/t/378541/Java-General/java/Convert-date-difference-format 

  // create a pair of Java Date objects
  java.util.Date currentTimeStamp = new Date();
  java.util.Date prevTimeStamp = new Date();
  // create a filter for the ISO 8601 format we're (hopefully) going to find in the XML file
  SimpleDateFormat iso8601 = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'");

  long timeDifference = 0;
  try {
    // now convert that XML date stamp to a Date object
    currentTimeStamp = iso8601.parse(date1);
    prevTimeStamp = iso8601.parse(date2);
    // if it worked, return the difference
    timeDifference = currentTimeStamp.getTime() - prevTimeStamp.getTime();
  } catch (ParseException e) {
    // likely suspects: no date in the XML, or unexpected date format
    println("Date parsing broke."); 
  }
  return timeDifference;
}


// get the root element of the document
XMLElement getRoot(String file) {
  XMLElement geoData = new XMLElement(this, file);
  return(geoData);
}
// get the file extension of the document
String getExtension(String file) {
  return file.substring(file.length() - 3).toLowerCase();
};



// find the element in the DOM that holds coordinate data
// then, thanks in large part to KML's ugliness, rebuild the thing as a 2D String array
// 0 = lat, 1 = lon, 2 = ele, 3 = time (if available)
String[][] getCoordinates(XMLElement root, String fileType) {  

  // create the return array, initialize it with a dummy value
  String[][] coordinates = {{" "}};
  
  if (fileType.equals("kml")) {
    String coordinateList = "";

    // try a couple ways of navigating to the big list of coordinates in the KML file.
    // Crummy way of doing it, but navigating differing XML DOMs proved 
    // a little trickier than I'd have liked.
    try {
      // Nokia Sports Tracker uses this path
      coordinateList = root.getChild("Document/Placemark/LineString/coordinates").getContent();
    }
    catch(NullPointerException n) {
      println(n);
    }
    try {
      // RunKeeper Pro uses this one
      coordinateList = root.getChild("Document/Placemark/MultiGeometry/LineString/coordinates").getContent();
    }
    catch(NullPointerException n) {
      println(n);
    }
    
    // throw each line of coordinates into a temporary array
    String[] coordinateLines = reverse(trim(splitTokens(coordinateList)));

    // re-initialize coordinates with the proper number of points
    coordinates = new String[coordinateLines.length][4];
   
    String[] parsedLine;

    for (int i = 0; i < coordinateLines.length; i++) {
      parsedLine = trim(split(coordinateLines[i], ","));

      // latitude is the second value
      coordinates[i][0] = parsedLine[1];
      // longitude is the first value
      coordinates[i][1] = parsedLine[0];
      // elevation is the third value
      coordinates[i][2] = parsedLine[2];
      // KML doesn't give us times
      coordinates[i][3] = null;
    }
    
  } else if (fileType.equals("gpx")) {

    XMLElement node = null;
    
    // figure out how many elements there are
    try {
      // RunKeeper Pro and GPSBabel use this path
      node = root.getChild("trk/trkseg");
    }
    catch(NullPointerException n) {
      println(n);
    }
    
    
    // re-initialize coordinates with the proper number of points
    if ((node != null) && (node.getChildCount() > 0)) {
      coordinates = new String[node.getChildCount()][4];
      
      for (int i = 0; i < node.getChildCount(); i++) {
        // parse out the relevant child elements
        XMLElement child = node.getChild(i);
    
        // get the lat and long coordinates from attributes on this particular child
        coordinates[i][0] = trim(child.getStringAttribute("lat"));
        coordinates[i][1] = trim(child.getStringAttribute("lon"));
        
        // get the elevation from the first child
        coordinates[i][2] = trim(child.getChild(0).getContent());
  
        // get the time from the second child
        coordinates[i][3] = child.getChild(1).getContent();
        
      };
    }
  }

  return(coordinates);
  
};
