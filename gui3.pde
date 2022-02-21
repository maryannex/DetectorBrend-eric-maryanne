import controlP5.*;

import java.util.List; 
import org.apache.commons.math3.fitting.leastsquares.*;
import org.apache.commons.math3.fitting.*;
import org.apache.commons.math3.analysis.polynomials.PolynomialFunction;
import org.apache.commons.math3.stat.descriptive.DescriptiveStatistics;
/*
yikes 
 */
import processing.serial.*;

ControlP5 cp5; 
Serial myPort;  
String val; 
boolean firstContact = false;
boolean testMode = false; 

double Rin, Tin, Vin; 

double inputTemp[];
double inputResistance[]; 
double coefficients[];
double rSquared; 

double redZone[][]; 
PolynomialFunction poly; 

PFont mono; 
ControlFont monospaced; 

Textfield[] textfield; 
int textfieldcount;  

Textfield[] redtextfield; 
int redtextfieldcount; 

Textfield[] greentextfield; 
int greentextfieldcount;

Textfield[] bluetextfield;
int bluetextfieldcount; 


boolean calibrated; 

void setup() {
  size(1500, 750); 


  calibrated = false; 

  mono = loadFont("Monospaced.bold-48.vlw");
  myPort = new Serial(this, Serial.list()[0], 9600);
  myPort.bufferUntil('\n');

  inputTemp = new double[10]; 
  inputResistance = new double[10]; 

  cp5 = new ControlP5(this); 
  monospaced = new ControlFont(mono, 20);
  cp5.setAutoDraw(true);

  textfield = new Textfield[10];
  textfieldcount = 0; 
  for (int i = 0; i < 3; i++) {
    textfield[i] = cp5.addTextfield("" + i, 200, (i)*50 + 100, 150, 20).setFont(monospaced)
      .setInputFilter(ControlP5.FLOAT).setColorValue(255).setColorBackground(#67B9FF)
        .setColorActive(255).setAutoClear(false); 
    Label label = textfield[i].getCaptionLabel(); 
    label.setFont(monospaced);
    label.toUpperCase(false);
    label.setText("Temperature " + (i+1));
    label.setSize(20);

    textfieldcount++;
  }
  
  redtextfield = new Textfield[5]; 
  redtextfieldcount = 0; 
  
  greentextfield = new Textfield[5]; 
  greentextfieldcount = 0; 
  
  bluetextfield = new Textfield[5]; 
  bluetextfieldcount = 0; 

  cp5.addBang("Add").setPosition(400, 500).setSize(50, 25).setFont(monospaced)
    .getCaptionLabel().toUpperCase(false).setSize(20);
  cp5.addBang("Remove").setPosition(400, 550).setSize(50, 25).setFont(monospaced)
    .getCaptionLabel().toUpperCase(false).setSize(20);
  cp5.addBang("Calibrate").setPosition(400, 600).setSize(50, 25).setFont(monospaced)
    .getCaptionLabel().toUpperCase(false).setSize(20);
    
    
  cp5.addBang("AddR").setPosition(600, 100).setSize(50, 25).setFont(monospaced)
    .getCaptionLabel().toUpperCase(false).setSize(15).setText("Add Red");
  cp5.addBang("AddG").setPosition(900, 100).setSize(50, 25).setFont(monospaced)
    .getCaptionLabel().toUpperCase(false).setSize(15).setText("Add Green");
  cp5.addBang("AddB").setPosition(1200, 100).setSize(50, 25).setFont(monospaced)
    .getCaptionLabel().toUpperCase(false).setSize(15).setText("Add Blue");
    
  cp5.addBang("RemoveR").setPosition(700, 100).setSize(50, 25).setFont(monospaced)
    .getCaptionLabel().toUpperCase(false).setSize(15).setText("Remove Red");
  cp5.addBang("RemoveG").setPosition(1000, 100).setSize(50, 25).setFont(monospaced)
    .getCaptionLabel().toUpperCase(false).setSize(15).setText("Remove Green");
  cp5.addBang("RemoveB").setPosition(1300, 100).setSize(50, 25).setFont(monospaced)
    .getCaptionLabel().toUpperCase(false).setSize(15).setText("Remove Blue");
    
 
  cp5.addBang("SendColors").setPosition(1200, 150).setSize(50, 25).setFont(monospaced)
    .getCaptionLabel().toUpperCase(false).setSize(15).setText("Send");
    
}

void draw() {
  background(#C6C6C6); 
  if (firstContact) {
    fill(255); 
    if (testMode) {
      cp5.hide(); 
      textFont(mono); 
      textAlign(CENTER); 
      textSize(50); 
      text("Temperature Test Mode", 750, 50); 

      textAlign(LEFT);
      textSize(45); 
      text("T: " + Tin + " C", 200, 200); 
      textAlign(RIGHT); 
      text("V: " + Vin + " V", 800, 200);
    } else {
      textFont(mono); 
      textAlign(CENTER); 
      textSize(50);
      text("Calibration Mode", 750, 50); 
      cp5.show();

      if (calibrated) {
        textAlign(LEFT); 
        textSize(15);
        textFont(mono); 
        text(poly.toString() + " r^2: " + rSquared , 50, 700);
      }
    }
  } else {
    cp5.hide();
    //"loading" message 
    textFont(mono); 
    textAlign(CENTER);
    textSize(70); 
    text("Establishing Contact...", 750, 375);
  }
}

void serialEvent( Serial myPort) {
  val = myPort.readStringUntil('\n');
  if (val != null) {
    val = trim(val);
    println(val);
    if (firstContact == false) {
      if (val.equals("A")) {
        myPort.clear();
        firstContact = true;
        myPort.write("A");
        println("contact");
      }
    } else { 
      if (val.equals("1")) {
        testMode = true;
      } else if (val.equals("0")) {
        testMode = false;
      } else {
        int vIndex = val.indexOf("V"); 
        if (testMode == true) {
          Tin = Double.parseDouble(val.substring(3, vIndex - 1));
          Vin = Double.parseDouble(val.substring(vIndex + 3));
        } else if (testMode == false) {
          Rin = Double.parseDouble(val.substring(3, vIndex - 1)); 
          Vin = Double.parseDouble(val.substring(vIndex + 3));
        }
      }
    }
  }
}

void Add() {
  if (textfieldcount < 10) { 

    textfield[textfieldcount] = cp5.addTextfield("" + textfieldcount, 200, (textfieldcount)*50 + 100, 150, 20).setFont(monospaced).setInputFilter(ControlP5.FLOAT).setColorValue(255).setColorBackground(#67B9FF).setColorActive(255).setAutoClear(false); 
    Label label = textfield[textfieldcount].getCaptionLabel(); 
    label.setFont(monospaced);
    label.toUpperCase(false);
    label.setText("Temperature " + (textfieldcount+1));
    label.setSize(20); 

    textfieldcount++;
  }
}

void Remove() {
  if (textfieldcount > 0) {
    textfield[textfieldcount-1].remove();
    textfieldcount--;
  }
}


void AddR() {
  if (redtextfieldcount < 5) { 

    redtextfield[redtextfieldcount] = cp5.addTextfield("R" + redtextfieldcount, 600, (redtextfieldcount)*50 + 150, 150, 20)
      .setFont(monospaced).setColorValue(255)
        .setColorBackground(#67B9FF).setColorActive(255).setAutoClear(false); 
        //remember to change these values to a cute red color 
    Label label = redtextfield[redtextfieldcount].getCaptionLabel(); 
    label.setFont(monospaced);
    label.toUpperCase(false);
    label.setText("Red Zone " + (redtextfieldcount+1));
    label.setSize(20); 

    

    redtextfieldcount++;
  }
}

void RemoveR() {
  if (redtextfieldcount > 0) {
    redtextfield[redtextfieldcount-1].remove();
    redtextfieldcount--;
  }
}

void AddG() {
  if (greentextfieldcount < 5) { 

    greentextfield[greentextfieldcount] = cp5.addTextfield("G" + greentextfieldcount, 900, (greentextfieldcount)*50 + 150, 150, 20)
      .setFont(monospaced).setColorValue(255)
        .setColorBackground(#67B9FF).setColorActive(255).setAutoClear(false); 
        //remember to change these values to a cute red color 
    Label label = greentextfield[greentextfieldcount].getCaptionLabel(); 
    label.setFont(monospaced);
    label.toUpperCase(false);
    label.setText("Green Zone " + (greentextfieldcount+1));
    label.setSize(20); 

    greentextfieldcount++;
  }
}

void RemoveG() {
  if (greentextfieldcount > 0) {
    greentextfield[greentextfieldcount-1].remove();
    greentextfieldcount--;
  }
}

void AddB() {
  if (bluetextfieldcount < 5) { 

    bluetextfield[bluetextfieldcount] = cp5.addTextfield("B" + bluetextfieldcount, 1200, (bluetextfieldcount)*50 + 150, 150, 20)
      .setFont(monospaced).setColorValue(255)
        .setColorBackground(#67B9FF).setColorActive(255).setAutoClear(false); 
        //remember to change these values to a cute red color 
    Label label = bluetextfield[bluetextfieldcount].getCaptionLabel(); 
    label.setFont(monospaced);
    label.toUpperCase(false);
    label.setText("Blue Zone " + (bluetextfieldcount+1));
    label.setSize(20); 

    bluetextfieldcount++;
  }
}

void RemoveB() {
  if (bluetextfieldcount > 0) {
    bluetextfield[bluetextfieldcount-1].remove();
    bluetextfieldcount--;
  }
}

void sendColors(){
  String toSendR = "R:";
  toSendR += (redtextfieldcount + ":");
  for(int i = 0; i < redtextfieldcount; i++){
    toSendR += (Double.parseDouble((redtextfield[i].getText()).substring(0, (redtextfield[i].getText()).indexOf("-")))
      + "-" + (Double.parseDouble((redtextfield[i].getText()).substring((redtextfield[i].getText()).indexOf("-") + 1))));
    if(i < redtextfieldcount - 1){
      toSendR += ",";
    }
  }
  myPort.write(toSendR);
  delay(500); 
  
  String toSendG = "G:"; 
  toSendG += (greentextfieldcount + ":");
  for(int i = 0; i < greentextfieldcount; i++){
    toSendG += (Double.parseDouble((greentextfield[i].getText()).substring(0, (greentextfield[i].getText()).indexOf("-")))
      + "-" + (Double.parseDouble((greentextfield[i].getText()).substring((greentextfield[i].getText()).indexOf("-") + 1))));
    if(i < greentextfieldcount - 1){
      toSendG += ",";
    }
  }
  myPort.write(toSendG);
  delay(500);
  
  String toSendB = "B:";
  toSendB += (bluetextfieldcount + ":");
  for(int i = 0; i < bluetextfieldcount; i++){
    toSendB += (Double.parseDouble((bluetextfield[i].getText()).substring(0, (bluetextfield[i].getText()).indexOf("-")))
      + "-" + (Double.parseDouble((bluetextfield[i].getText()).substring((bluetextfield[i].getText()).indexOf("-") + 1))));
    if(i < bluetextfieldcount - 1){
      toSendB += ",";
    }
  }
  myPort.write(toSendB);
  delay(500); 
}

void keyPressed() {
  if (key == ENTER) {
    for (int i = 0; i < textfieldcount; i++) {
      if (textfield[i].isFocus()) {
        inputTemp[i] = Double.parseDouble(textfield[i].getText());
        inputResistance[i] = Rin;
      }
    }
  }
}

void Calibrate() {
  if (textfieldcount > 4) {
    final WeightedObservedPoints obs = new WeightedObservedPoints();
    for (int i = 0; i < textfieldcount; i++) {
      obs.add(Math.log(inputResistance[i]), (double)1/inputTemp[i]);
    }

    final PolynomialCurveFitter fitter = PolynomialCurveFitter.create(4); 
    coefficients = fitter.fit(obs.toList());
    
    poly = new PolynomialFunction(coefficients);
    
    rSquared = getRSquare(poly, obs.toList()); 
    
    myPort.write("c-" + coefficients[0] + "-" + coefficients[1] + "-" + coefficients[2] + "-" + coefficients[3] + "-" + coefficients[4] + "-"); 
    calibrated = true; 
  }
}

private double getRSquare(PolynomialFunction fitter, List<WeightedObservedPoint> pointList) {
    double[] predictedValues = new double[pointList.size()];
    double residualSumOfSquares = 0;
    final DescriptiveStatistics descriptiveStatistics = new DescriptiveStatistics();
    for (int i=0; i< pointList.size(); i++) {
        predictedValues[i] = fitter.value(pointList.get(i).getX());
        double actualVal = pointList.get(i).getY();
        double t = Math.pow((predictedValues[i] - actualVal), 2);
        residualSumOfSquares  += t;
        descriptiveStatistics.addValue(actualVal);
    }
    final double avgActualValues = descriptiveStatistics.getMean();
    double totalSumOfSquares = 0;
    for (int i=0; i<pointList.size(); i++) {
        totalSumOfSquares += Math.pow( (predictedValues[i] - avgActualValues),2);
    }
    return 1.0 - (residualSumOfSquares/totalSumOfSquares);
}
