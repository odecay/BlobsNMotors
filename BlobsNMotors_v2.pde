import processing.serial.*;
import processing.video.*;
import cc.arduino.*;
import blobDetection.*;
Arduino arduino;

Capture cam;
BlobDetection theBlobDetection;
PImage img;
boolean newFrame=false;
int[] pinList = new int[] {8,9,10,11};
float[] motorHeights = new float[] {0,0,0,0};


void setup()
{
  // Size of applet
  size(640, 480);
  // Capture
  cam = new Capture(this, 640, 480);
  arduino = new Arduino(this, Arduino.list()[0]);
  arduino.pinMode(pinList[0], Arduino.OUTPUT);
  arduino.pinMode(pinList[1], Arduino.OUTPUT);
  arduino.pinMode(pinList[2], Arduino.OUTPUT);
  arduino.pinMode(pinList[3], Arduino.OUTPUT);
  
  // BlobDetection
  // img which will be sent to detection (a smaller copy of the cam frame);
  img = new PImage(640, 480);
  theBlobDetection = new BlobDetection(img.width, img.height);
  theBlobDetection.setPosDiscrimination(true);
  theBlobDetection.setThreshold(0.2f); // will detect bright areas whose luminosity > 0.2f;
}

void captureEvent(Capture cam)
{
  cam.read();
  newFrame = true;
}

void draw()
{
  
  if (newFrame)
  {
    newFrame=false;
    image(cam, 0, 0, width, height);
    img.copy(cam, 0, 0, cam.width, cam.height, 
    0, 0, img.width, img.height);
    theBlobDetection.computeBlobs(img.pixels);
    drawBlobsAndEdges(true);
    motorMove();
  }
  //print (motorHeights[0]);
}

void drawBlobsAndEdges(boolean drawBlobs)
{
  noFill();
  Blob b;
  EdgeVertex eA, eB;
  for (int n=0 ; n<theBlobDetection.getBlobNb() ; n++)
  {
    b=theBlobDetection.getBlob(n);
    if (b!=null)
    {

      // Blobs
      if (drawBlobs)
      {
        strokeWeight(1);
        stroke(255, 0, 0);
        rect(
        b.xMin*width, b.yMin*height, 
        b.w*width, b.h*height
          );
      }
    }
  }
}

float[] motorZoneDetect()
{
  float centerX = 320;
  float centerY = 240;
  //pixel value lists for detection zones {x start,y start,x end, y end}
  //zone a
  float[] zoneA = new float[] {0,0,390,280};
  //zone b
  float[] zoneB = new float[] {250,0,640,280};
  //zone c
  float[] zoneC = new float[] {0,140,390,480};
  //zone d
  float[] zoneD = new float[] {250,140,640,480};
  //blobdetect
  
  Blob b;
  //ax + cx
  float closeXLeft = 320;
  //bx + dx
  float closeXRight = 320;
  //ay + by
  float closeYTop = 240;
  //cy + dy
  float closeYBot = 240;
  float[] xList = new float[theBlobDetection.getBlobNb()];
  float[] yList = new float[theBlobDetection.getBlobNb()];
  
  for (int n=0 ; n<theBlobDetection.getBlobNb() ; n++)
  {
    b=theBlobDetection.getBlob(n);
    if (b!=null)
    {
      float x = map(b.x,0,1,0,640);
      float y = map(b.y,0,1,0,480); 
      
      if (x < 390){
        if(abs(x-centerX) < closeXLeft){
         closeXLeft = x;
        }
      }
      
      if (x < 640){
        if(x > 250){
            if(abs(x-centerX) <  closeXRight){
            closeXRight = x;
          }
        }
      }
      
      if (y < 280){
        if(abs(y-centerY) < closeYTop){
         closeYTop = y;
        }
      }
      if (y < 480){
        if(y > 140){ 
          if(abs(y-centerY) < closeYTop){
           closeYTop = y;
          }
        }
      }
      
    print(x);
  print("     ") ;  
    }
    else{
      closeXLeft = 320;
      closeXRight = 320;
      closeYTop = 240;
      closeYBot = 240;
    }
    //print(xList.length);
    
  }
  
    
  return new float[] {closeXLeft,closeXRight,closeYTop,closeYBot};
}

void motorMove()
{
  
  //motor limits
  
  //float[] motorHeights = heights;
  /*
  print("pin 8");
  print (motorHeights[0]);
  print("pin 9");
  print(motorHeights[1]);
  print("pin10");
  print(motorHeights[2]);
  print("pin11");
  print(motorHeights[3]);
  */
  float[] motorLimits = motorZoneDetect();
  float motorLimit8 = motorLimits[0];
  float motorLimit9 = motorLimits[1];
  float motorLimit10 = motorLimits[2];
  float motorLimit11 = motorLimits[3];
  motorLimits[0] = abs(map(motorLimits[0], 320,0,0,320));
  motorLimits[1] = abs(map(motorLimits[1], 320,0,0,320));
  motorLimits[2] = abs(map(motorLimits[2], 240,0,0,240));
  motorLimits[3] = abs(map(motorLimits[3], 240,0,0,240));
  
  
  
  float motorHeight8 = 0;
  float motorHeight9 = 0;
  float motorHeight10 = 0;
  float motorHeight11 = 0;
  
  float timeStep = 1;
  //write to servos 180=up 0=dwn
  for (int n=0; n<4; n++){
    
    print("motorLimits");
    print(n);
    print(" : ");
    print(motorLimits[n]);
    if (motorLimits[n] > 0){
      //up
      if (motorHeights[n] < motorLimits[n]){
        arduino.analogWrite(pinList[n], 0 );
        motorHeights[n] = motorHeights[n] + timeStep;
      }
      //down
      if (motorHeights[n] > motorLimits[n]){
          arduino.analogWrite(pinList[n], 180);
          motorHeights[n] = motorHeights[n] - timeStep;
      }
      //stop
      if (motorHeights[n] == motorLimits[n]){
        arduino.analogWrite(pinList[n], 90);
      }  
    }
    //bottom limit
    else{
      if (motorHeights[n] > 0){
        arduino.analogWrite(pinList[n], 180 );
        motorHeights[n] = motorHeights[n] - timeStep;
      }
      else{
        arduino.analogWrite(pinList[n], 90 );
      }
    }
  }
        
  //print (motorLimit8);
  //print ("          ");
  print("motor 8 height : ");
  print( motorHeights[0]);
  print("motor 9 height : ");
  print( motorHeights[1]);
  print("motor 10 height : ");
  print( motorHeights[2]);
  print("motor 11 height : ");
  print( motorHeights[3]);
}

