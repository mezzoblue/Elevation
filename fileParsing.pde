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
   
   Path to coordinates in a TCX file from Garmin:
   TrainingCenterDatabase > Activities > Activity > Lap > Track
     Trackpoint
       Time
       Position > LatitudeDegrees, LongitudeDegrees
       AltitudeMeters
       DistanceMeters

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

/*
   Some notes about latitude / longitude values. Wikipedia tells us (http://en.wikipedia.org/wiki/Decimal_degrees)
   that each degree is 111km at the equator. While it would be great to map this thing out on a sphere, there's no 
   need to make it that complicated. Distances of under a few hundred km oughtta be just fine as flat maps for now.

   +-- decimal places
   |
   |    +-- degrees
   |    |               +-- distance
   |    |               |

   0	1.0	        111 km
   1	0.1	        11.1 km
   2	0.01	        1.11 km
   3	0.001  	        111 m
   4	0.0001   	11.1 m
   5	0.00001  	1.11 m
   6	0.000001	0.111 m
   7	0.0000001	1.11 cm
   8	0.00000001	1.11 mm


   To convert from lat/lon to kilometers, we multiply by 111. Meters, 111,000. That's not a constant though;
   given degree length changes at different latitudes, it could be as low as 110.5km at the equator, or as
   high as 111.5km at 70 degrees. Not a huge margin of error, but something I might want to correct one day.
   
   I will need to convert the GPS points to a map projection though, Mercator in this case since that's what 
   Google, Microsoft, Yahoo all use and one day I may just get Elevation talking to them. Best to be on  
   the same system. Longitude is fine as-is, but latitude needs to be run through a formula adapted from 
   the maths on http://en.wikipedia.org/wiki/Mercator_projection
   



*/
      int degreeLength = 111000;
      scene.averageParallel(Float.parseFloat(coordinates[i][0]));

      if (coordinates[i][0] != null) {
        // pull out the raw latitude coordinates
        float phi = radians(Float.parseFloat(coordinates[i][0]));
        float adjustedPhi = degrees(0.5 * log((1 + sin(phi)) / (1 - sin(phi))));
        obj.X[i] = (adjustedPhi * degreeLength);
      }
      if (coordinates[i][1] != null) {
        float lambda = Float.parseFloat(coordinates[i][1]);
        obj.Z[i] = 0 - (lambda * degreeLength);
      }
  
  
      if (coordinates[i][2] != null) {
        // average out each point's elevation with the two preceding it to minimize spikes
        if (i > 1) {
          obj.Y[i] = (Float.parseFloat(coordinates[i][2]) + obj.Y[i - 1] + obj.Y[i - 2]) / 3;
        } else {
          obj.Y[i] = Float.parseFloat(coordinates[i][2]);
        };
      }
      

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
      }; // end if

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
      if (
        (fileExt.toLowerCase().equals("gpx")) ||
        (fileExt.toLowerCase().equals("kml")) || 
        (fileExt.toLowerCase().equals("tcx")) 
      ) {
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
//  if (n1 - n2 < 0) {
//    return abs(n1) + abs(n2);
//  }
//  else {
//    return abs(n1 - n2);
//  }
  return abs(n1 - n2) / 2;
}




// find the time difference between two strings formatted in iso8601 format (yyyy-MM-ddTHH:mm:ssZ)
long getTimeDifference(String date1, String date2) {
  // code I found useful for Java's date functions:
  // http://www.coderanch.com/t/378541/Java-General/java/Convert-date-difference-format 

  // create a pair of Java Date objects
  java.util.Date currentTimeStamp = new Date();
  java.util.Date prevTimeStamp = new Date();
  // create a filter for the ISO 8601 format we're (hopefully) going to find in the XML file
  SimpleDateFormat iso8601 = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'");
  SimpleDateFormat iso8601milli = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'");

  long timeDifference = 0;
  try {
    // now convert that XML date stamp to a Date object
    currentTimeStamp = iso8601.parse(date1);
    prevTimeStamp = iso8601.parse(date2);
    // if it worked, return the difference
    timeDifference = currentTimeStamp.getTime() - prevTimeStamp.getTime();
  }
  catch (ParseException e) {
    // likely suspects: unexpected date format
  }
  catch (NullPointerException e) {
    // likely suspects: points without a date stamp
  }
  try {
    // see if it works with milliseconds (TCX files have 'em)
    currentTimeStamp = iso8601milli.parse(date1);
    prevTimeStamp = iso8601milli.parse(date2);
    // if it worked, return the difference
    timeDifference = currentTimeStamp.getTime() - prevTimeStamp.getTime();
  }
  catch (ParseException e) {
    // likely suspects: unexpected date format
  }
  catch (NullPointerException e) {
    // likely suspects: points without a date stamp
  }
  return timeDifference;
}


// get the root element of the document
XMLElement getRoot(String file) {
  XMLElement data = new XMLElement(this, file);
  return(data);
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


  // Google .kml files, probably fairly generic
  if (fileType.equals("kml")) {
    String coordinateList = "";
    // try a couple ways of navigating to the big list of coordinates in the KML file,
    // catch the exceptions if it doesn't work. Seems a bit of a crummy way of doing it.
    try {
      // Nokia Sports Tracker uses this path
      coordinateList = root.getChild("Document/Placemark/LineString/coordinates").getContent();
    }
    catch(NullPointerException n) {
      // likely suspect: point without any useful data. No need to do anything, just ignore it.
    }
    try {
      // RunKeeper Pro uses this one
      coordinateList = root.getChild("Document/Placemark/MultiGeometry/LineString/coordinates").getContent();
    }
    catch(NullPointerException n) {
      // likely suspect: point without any useful data. No need to do anything, just ignore it.
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
    
    
    
  // GPS Exchange Format .gpx files
  // used by RunKeeper Pro and GPSBabel
  } else if (fileType.equals("gpx")) {
    XMLElement node = null;
    // figure out how many elements there are
    try {
      node = root.getChild("trk/trkseg");
    }
    catch(NullPointerException n) {
      // likely suspect: point without any useful data. No need to do anything, just ignore it.
    }
    // re-initialize coordinates with the proper number of points
    if ((node != null) && (node.getChildCount() > 0)) {
      coordinates = new String[node.getChildCount()][4];
      for (int i = 0; i < node.getChildCount(); i++) {
          // parse out the relevant child elements
          XMLElement child = node.getChild(i);
          if (node.getChildCount() > 3) {
            // get the lat and long coordinates from attributes on this particular child
            coordinates[i][0] = trim(child.getStringAttribute("lat"));
            coordinates[i][1] = trim(child.getStringAttribute("lon"));
            // get the elevation from the first child
            coordinates[i][2] = trim(child.getChild(0).getContent());
            // get the time from the second child
            coordinates[i][3] = child.getChild(1).getContent();
          } else {
            coordinates[i][0] = null; coordinates[i][1] = null;
            coordinates[i][2] = null; coordinates[i][3] = null;
          }
      };
    }



  // Garmin Training Center .tcx files
  } else if (fileType.equals("tcx")) {
    XMLElement node = null;
    // figure out how many elements there are
    try {
      node = root.getChild("Activities/Activity/Lap/Track");
    }
    catch(NullPointerException n) {
      // likely suspect: point without any useful data. No need to do anything, just ignore it.
      // Garmin likes these. I can't understand why.
    }
    
    // re-initialize coordinates with the proper number of points
    if ((node != null) && (node.getChildCount() > 0)) {
      coordinates = new String[node.getChildCount()][4];
      
      for (int i = 0; i < node.getChildCount(); i++) {
        // parse out the relevant child elements
        XMLElement child = node.getChild(i);

        if (child.getChildCount() > 3) {
          // can't rely on any of these being present in Garmin files, it seems
          try {
            coordinates[i][0] = trim(child.getChild("Position/LatitudeDegrees").getContent());
            coordinates[i][1] = trim(child.getChild("Position/LongitudeDegrees").getContent());
          }
          catch(NullPointerException n) {
            // likely suspect: point without any useful data. No need to do anything, just ignore it.
          }
          try {
            coordinates[i][2] = trim(child.getChild("AltitudeMeters").getContent());
          }
          catch(NullPointerException n) {
            // likely suspect: point without any useful data. No need to do anything, just ignore it.
          }
          try {
            coordinates[i][3] = child.getChild("Time").getContent();
          }
          catch(NullPointerException n) {
            // likely suspect: point without any useful data. No need to do anything, just ignore it.
          }
        } else {
          coordinates[i][0] = null; coordinates[i][1] = null;
          coordinates[i][2] = null; coordinates[i][3] = null;
        }
        
      };
    }
  }

  return(coordinates);
  
};
