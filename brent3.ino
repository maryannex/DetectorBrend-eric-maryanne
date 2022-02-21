
const int thermistorPin = 1;
const int masterButtonPin = 0; 
const int redPin = 1; 
const int bluePin = 5; 
const int greenPin = 2; 
int buttonState = 0; 

int Vo;
double Vdisplay; 
float R1 = 6000;
float logR2, R2, R2o, T, TC, Tf;
float Rt1, Rt2, Rt3; 
float Tt1, Tt2, Tt3;

const int numReadings = 200; 
float R2values[numReadings]; 

double c1 = 1.0278921e-03, c2 = 2.511441e-04, c3 = 1.864351e-08; // orange thermometer whatever 
//double c1 = 1.1414068e-03, c2 = 2.30478e-04, c3 = 1.134361e-07; // black thermometer but better I think 
//double c1 = 1.1513038e-03, c2 = 2.2859467e-04, c3 = 1.2726896e-07; // black thermometer 1 
//double c1 = 1.153964700e-03, c2 = 2.305628069e-04, c3 = 1.130219976e-07; //ametherm ACC-004
//double c1 = 1.153964700e-03, c2 = 2.355628069e-04, c3 = 1.130219976e-07; //bullshit
//double c1 = 1.058143844e-03, c2 = 2.346176620e-04, c3 = 2.001218834e-07; //omega 44031z

double polyCoefficients[5]; 

boolean testMode; 
boolean steinhart;
boolean redOn, greenOn, blueOn; 
boolean redHolder, greenHolder, blueHolder; 

const int zoneCount = 5; 
double redZone[zoneCount][2];
double greenZone[zoneCount][2];
double blueZone[zoneCount][2];

String serialIn; 

int loopDelayCount; 

void setup() {
  Serial.begin(9600);
  
  pinMode(masterButtonPin, INPUT);
  pinMode(redPin, OUTPUT);
  pinMode(greenPin, OUTPUT);
  pinMode(bluePin, OUTPUT);

  digitalWrite(redPin, LOW); 
  digitalWrite(greenPin, LOW);
  digitalWrite(bluePin, LOW);
  
  analogReference(AR_EXTERNAL);
  analogReadResolution(12); 

  testMode = false; 
  steinhart = true; 
  
  for(int i = 0; i < numReadings; i++){
    R2values[i] = 0; 
  }

  for(int i = 0; i < zoneCount; i++){
    redZone[i][0] = -5;
    redZone[i][1] = -5;

    greenZone[i][0] = -5;
    greenZone[i][1] = -5;

    blueZone[i][0] = -5;
    blueZone[i][1] = -5; 
  }
  
  loopDelayCount = 0; 
  
  establishContact();
}

void loop() {
  Vo = analogRead(thermistorPin);
  Vdisplay = ((int)((Vo * (3.3/4095)) * 10) / 10.0);
  R2o = R1 * ((-1 * Vo) / ((float)Vo - 4095.0));
  
  for(int i = 0; i < numReadings - 1; i++){
    R2values[i] = R2values[i+1]; 
  }
  R2values[numReadings - 1] = R2o; 
  
  float sum = 0; 
  for(int i = 0; i < numReadings; i++){
    sum += R2values[i];
  }
  R2 = sum/((float)numReadings); 
  
  if (testMode && loopDelayCount == 0) {
    testTemperature();
  } else {  
    calibration(); 
  }
  modeSwitch();

  loopDelayCount++; 
  loopDelayCount = loopDelayCount % 100; 
  delay(5);
}


void calibration(){
  
  Serial.print("R: ");
  Serial.print(R2); 
  Serial.print(" V: ");
  Serial.println(Vdisplay);

  if(Serial.available() > 0){
    serialIn = Serial.read(); 
    if(serialIn.charAt(0) == 'c'){
      int firstIndex = 1; 
      int secondIndex; 
      for(int i = 0; i < 5; i++){
        secondIndex = serialIn.indexOf('-', firstIndex + 1);
        polyCoefficients[i] = serialIn.substring(firstIndex + 1, secondIndex).toDouble(); 
        firstIndex = secondIndex; 
      }
      steinhart = false;
    }
    if(serialIn.charAt(0) == 'R'){
      int number = serialIn.substring(2,3).toInt(); 
      int lastIndex = serialIn.indexOf(':', 2);
      for(int i = 0; i < number; i++){
        int nextIndex; 
        String rangeString; 
        if(i < number - 1){
          nextIndex = serialIn.indexOf(',', lastIndex);
          rangeString = serialIn.substring(lastIndex+1, nextIndex);
          lastIndex = nextIndex;
        } else {
          rangeString = serialIn.substring(lastIndex + 1); 
        }
        int breakIndex = rangeString.indexOf('-');
        redZone[i][0] = rangeString.substring(0, breakIndex).toDouble(); 
        redZone[i][1] = rangeString.substring(breakIndex + 1).toDouble(); 
      }
    }
    if(serialIn.charAt(0) == 'G'){
      int number = serialIn.substring(2,3).toInt(); 
      int lastIndex = serialIn.indexOf(':', 2);
      for(int i = 0; i < number; i++){
        int nextIndex; 
        String rangeString; 
        if(i < number - 1){
          nextIndex = serialIn.indexOf(',', lastIndex);
          rangeString = serialIn.substring(lastIndex+1, nextIndex);
          lastIndex = nextIndex;
        } else {
          rangeString = serialIn.substring(lastIndex + 1); 
        }
        int breakIndex = rangeString.indexOf('-');
        greenZone[i][0] = rangeString.substring(0, breakIndex).toDouble(); 
        greenZone[i][1] = rangeString.substring(breakIndex + 1).toDouble(); 
      }
    }
    if(serialIn.charAt(0) == 'B'){
      int number = serialIn.substring(2,3).toInt(); 
      int lastIndex = serialIn.indexOf(':', 2);
      for(int i = 0; i < number; i++){
        int nextIndex; 
        String rangeString; 
        if(i < number - 1){
          nextIndex = serialIn.indexOf(',', lastIndex);
          rangeString = serialIn.substring(lastIndex+1, nextIndex);
          lastIndex = nextIndex;
        } else {
          rangeString = serialIn.substring(lastIndex + 1); 
        }
        int breakIndex = rangeString.indexOf('-');
        blueZone[i][0] = rangeString.substring(0, breakIndex).toDouble(); 
        blueZone[i][1] = rangeString.substring(breakIndex + 1).toDouble(); 
      }
    }
    //if this shit doesn't work ima eat the detector  
  }
}

void testTemperature(){
  logR2 = log(R2);

  if (steinhart){
    T = (1.0 / (c1 + c2*logR2 + c3*pow(logR2,3.0)));
  } else {
    double polySum = 0; 
    for(int i = 0; i < 5; i++){
      polySum += (polyCoefficients[i]*pow(logR2, i));
    }
    T = (1.0 / polySum); 
  }
  TC = (T - 273.15);
  Tf = (TC* 9.0)/ 5.0 + 32.0; 

  Serial.print("T: ");
  Serial.print(TC);  
  Serial.print(" V: ");
  Serial.println(Vdisplay);
  
  if(redOn){
    digitalWrite(redPin, HIGH); 
  } else {
    digitalWrite(redPin, LOW); 
  }
  
  if(greenOn){
    digitalWrite(greenPin, HIGH); 
  } else {
    digitalWrite(greenPin, LOW); 
  }

  if(blueOn){
    digitalWrite(bluePin, HIGH); 
  } else {
    digitalWrite(bluePin, LOW); 
  }

  redHolder = false; 
  greenHolder = false;
  blueHolder = false; 
  for(int i = 0; i < zoneCount; i++){
    if(TC >= redZone[zoneCount][0] && TC <= redZone[zoneCount][1]){
      redHolder = true; 
    }
    if(TC >= greenZone[zoneCount][0] && TC <= greenZone[zoneCount][1]){
      greenHolder = true; 
    }
    if(TC >= blueZone[zoneCount][0] && TC <= blueZone[zoneCount][1]){
      blueHolder = true; 
    }
  }
  redOn = redHolder; 
  greenOn = greenHolder;
  blueOn = blueHolder;
}


void modeSwitch(){
  buttonState = digitalRead(masterButtonPin);
  if (buttonState == HIGH) {
    testMode = !testMode;

    digitalWrite(redPin, LOW);
    digitalWrite(greenPin, LOW); 
    digitalWrite(bluePin, LOW); 
    Serial.println(testMode); 
    delay(1000);

  }
}

void establishContact() {
  while (Serial.available() <= 0) {
  Serial.println("A");   
  delay(300);
  }
}
