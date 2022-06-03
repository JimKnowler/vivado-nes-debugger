const int PIN_CLK = 49;     // GREEN
const int PIN_LATCH = 51;   // YELLOW
const int PIN_DATA = 53;    // BLACK

void setup() {
  pinMode(PIN_CLK, OUTPUT);
  pinMode(PIN_LATCH, OUTPUT);
  pinMode(PIN_DATA, INPUT);

  digitalWrite(PIN_CLK, 1);
  digitalWrite(PIN_LATCH, 1);
  Serial.begin(9600);
  
}

void writeClockCycle(int pin, int activeValue) {
  const int delayMilliseconds = 1;

  // NOTE: trigger with 0, instead of 1
  digitalWrite(pin, activeValue);
  delay(delayMilliseconds);
  digitalWrite(pin, 1 - activeValue);
  delay(delayMilliseconds);
}

void loop() {
  // poll the controller to refresh its' shift register
  writeClockCycle(PIN_LATCH, 0);

  int data = 0;
  for (int i=0; i<8; i++) {
    int button = (digitalRead(PIN_DATA) == HIGH) ? 1 : 0;
    
    Serial.print(button);
    data = (data << 1) | button;

    // clock the next button
    writeClockCycle(PIN_CLK, 1);
  }

  Serial.print("joypad read:");
  Serial.println(data, HEX); 

  // sleep before next frame
  delay(100);
}
