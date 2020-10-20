/*
  This program takes care of recording the distance data collected by an ultrasonic sensor
  and sending them, via API, to a server using a GPRS connection.
*/

// Libraries used in the code.
#include <MKRGSM.h>
#include <SPI.h>
#include <SD.h>
#include <ArduinoJson.h>

#include "TankMonitorSecrets.h"

// Define the PIN wherw the ultrasonic sensor is connected
#define TRIG_PIN 6
#define ECHO_PIN 7

// Define the number of measured distance to create a measurement
#define NUMBER_OF_MEASURE 10

// Initialize the library instance
GSMClient client;
GPRS gprs;
GSM gsmAccess;
GSM_SMS sms;

// URL, path and port to connect the serverz
char server[] = "test.atmosphere.tools";
char path[] = "/v1/measurements";
int port = 80; // port 80 is the default for HTTP
String token = "";

// Global variables used to control recurring operation in loop function.
unsigned int measuringInterval = 5 * 1000;
unsigned int postingInterval = 600 * 1000;
unsigned int updatingScriptInterval = 1200 * 1000;
unsigned int levelAlarm1 = 60;
unsigned int levelAlarm2 = 80;
unsigned int unixTimeAtSync = 0;
unsigned long lastConnectionTime = 0;              // last connection to the server, in milliseconds
unsigned long lastMeasureTime = measuringInterval; // last measurement detected by the ultrasonic sensor, in milliseconds
unsigned long lastScriptUpdate = updatingScriptInterval;
unsigned long timeMillisAtSync = 0;
char phoneNumber[20];
bool bufferEmpty = true;
bool SDCardExist = false;      // indicate if an SD card is insert
bool networkConnected = false; // indicate if the network is avaiable

File myFile;

// The class manages the sending of notification  
class LevelAllarm
{ 
  private: 
    int currentState;
    int previousState;
    int numberOfLevel;
    int levels[4];
    int minHeight;
    int maxHeight;
    int height;

  public:
    bool check(int level);
    String getAllarm();
    void setData(int level1, int level2, int minH, int maxH);

    LevelAllarm()
    {
      currentState = 2;
      previousState = 0;
      numberOfLevel = 1;
      levels[4] = {0};
      minHeight = 0;
      maxHeight = 0;
    }

    int getPercentageLevel(int level)
    {
      int percentageLevel = ((100 / ((float)minHeight - (float)maxHeight)) * (level - maxHeight));
      if (0 < percentageLevel && percentageLevel < 100)
        return percentageLevel;
      else if (percentageLevel >= 100)
      {
        return 100;
      }
      else
      {
        return 0;
      }
    }
};

bool LevelAllarm::check(int level)
{
  int currentPercentage = getPercentageLevel(level);
  Serial.print(currentPercentage);
  Serial.println(" %");
  for (int i = 0; i < numberOfLevel - 1; i++)
  {
    if (levels[i] < currentPercentage && currentPercentage <= levels[i + 1])
    {
      currentState = i;
      Serial.println(currentState);
      if (previousState != currentState)
      {
        return true;
      }
      else
      {
        return false;
      }
    }
    //return false;
  }
}
String LevelAllarm::getAllarm()
{
  for (int i = 0; i < numberOfLevel - 1; i++)
  {
    for (int j = 0; j < numberOfLevel - 1; j++)
    {
      if (currentState == i && previousState == j)
      {

        Serial.println("test");
        if (i < j)
        {
          previousState = currentState;
          return String("ATTENZIONE!!!\nLivello sceso sotto " + String(levels[j]) + "%.");
        }
        else if (i > j)
        {
          previousState = currentState;
          //return String("Il livello è rientrato sopra il X %.");
          return String("Livello rientrato sopra " + String(levels[i]) + "%.");
        }
        else
        {
          previousState = currentState;
          return String("Il livello è rimasto invariato (possibile errore)!!");
        }
      }
    }
  }
  return String("Errore3! Contatta lo sviluppatore!!");
}

void LevelAllarm::setData(int level1, int level2, int minH, int maxH)
{
  numberOfLevel = sizeof(levels) / sizeof(levels[0]);
  ;
  levels[0] = 0;
  levels[1] = level1;
  levels[2] = level2;
  levels[3] = 100;
  previousState = 2;
  this->minHeight = minH;
  this->maxHeight = maxH;
}

LevelAllarm levelAllarm = LevelAllarm();

//-------------------------------------------------------------------------------------------------------------------------------------

void setup()
{
  // Initialize serial communications and wait for port to open:
  Serial.begin(9600);
  //while (!Serial) {
  //  ; // wait for serial port to connect. Needed for native USB port only
  //}
  delay(1000);

  // Inizializate the digital PIN for ultrasonic sensor
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, LOW);
  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);
  digitalWrite(TRIG_PIN, LOW);

  Serial.print("Initializing SD card...");
  delay(1000);

  // Check if the SD card exist.
  if (!SD.begin(4))
  {
    Serial.println("initialization failed!");
    digitalWrite(LED_BUILTIN, HIGH);
    delay(2000);
    digitalWrite(LED_BUILTIN, LOW);
  }
  else
  {
    Serial.println("initialization done.");
    digitalWrite(LED_BUILTIN, HIGH);
    delay(1000);
    digitalWrite(LED_BUILTIN, LOW);
    SDCardExist = true;
    if (!SD.remove("Buffer.txt"))
    {
      Serial.println("Buffer.txt not removed");
    }
  }
  delay(2000);

  // Start the GSM and attach GPRS.
  startNetworkConnection();
  unixTimeAtSync = gsmAccess.getTime();
  updateParameters();
}

//-------------------------------------------------------------------------------------------------------------------------------------

void loop()
{

  // After a MEASURING_INTERVAL time make a new measure.
  if ((millis() - lastMeasureTime > measuringInterval))
  {
    lastMeasureTime = millis();
    int distance = measureDistance();
    Serial.println(distance);
    addMeasureToBuffer(distance);
    if (levelAllarm.check(distance))
    {
      sendSms(levelAllarm.getAllarm(), false);
    }
  }
  // After a POSTING_INTERVAL time send a new measure.
  if ((millis() - lastConnectionTime) > postingInterval)
  { //If the variable generates an overflow?
    Serial.println("Send Measure");
    lastConnectionTime = millis();
    sendData();
  }
  // After a UPDATE_SCRIPT_INTERVAL time update the settings script.
  if ((millis() - lastScriptUpdate) > updatingScriptInterval)
  {
    lastScriptUpdate = millis();
    unsigned int tempUnixTime = gsmAccess.getTime();
    if (tempUnixTime != 0)
    {
      timeMillisAtSync = millis();
      unixTimeAtSync = tempUnixTime;
    }
    else
    {
      logError("gsmAcces.getTime() Failed");
      //networkConnected = false;
      gsmAccess.shutdown();
      startNetworkConnection();
    }
    Serial.println("Updating script");
    updateParameters();
  }
}

//-------------------------------------------------------------------------------------------------------------------------------------

void addMeasureToBuffer(float tankLevel)
{
  String dateTime = getCurrentTimeFormatted(unixTimeAtSync + (millis() - timeMillisAtSync) / 1000);
  // Build the string of API body.
  String apiBody = String("{ \"startDate\": \"" + dateTime + "\", \"endDate\": \"" + dateTime + "\", \"thing\": \"tank\",  \"feature\": \"water-level\", \"device\": \"tank-level-sensor\",  \"samples\": [ { \"values\": [" + String((int)tankLevel / 10) + "] } ] }");

  myFile = SD.open("Buffer.txt", FILE_WRITE);
  if (myFile)
  {
    if (bufferEmpty)
    {
      myFile.println("[");
      bufferEmpty = false;
    }
    else
    {
      myFile.print(",");
    }
    myFile.println(apiBody);
    myFile.close();
  }
  else
  {
    //Log error
    logError("Problem adding a measure to Buffer");
  }
}

//-------------------------------------------------------------------------------------------------------------------------------------

void sendData()
{
  // Note the time that the connection was made.
  lastConnectionTime = millis();
  String apiBody = "";

  myFile = SD.open("Buffer.txt", FILE_WRITE);
  if (myFile)
  {
    myFile.println("]");
    myFile.close();
    myFile = SD.open("Buffer.txt");
    if (myFile)
    {
      unsigned int timer = millis();
      while (myFile.available() && (millis() - timer) < 100000)
      {
        apiBody += (char)myFile.read();
        //apiBody.concat((char)myFile.read());
      }
      Serial.println("");
      // close the file:
      myFile.close();

      Serial.print("The body of API POST is: ");
      Serial.println(apiBody);
      Serial.println("");

      bool makeHttpRequest = true;
      String response = "";
      timer = millis();
      while (makeHttpRequest && (millis() - timer) < 60000)
      {
        Serial.println("");
        Serial.println("Send measures...");
        response = httpRequest(path, "POST", apiBody, true);

        // Call function that make the HTTP request.
        if (response.substring(9, 25).equals("401 Unauthorized"))
        {
          updateToken();
        }
        else if (response.substring(9, 15).equals("200 OK") ||
                 response.substring(9, 21).equals("202 Accepted"))
        {
          Serial.println("");
          // Reset the buffer of measure;
          if (!SD.remove("Buffer.txt"))
          {
            logError("Problem during empty buffer");
          }
          else
          {
            bufferEmpty = true;
          }
          makeHttpRequest = false;
        }
        else
        {
          // Reset the buffer of measure;
          if (SD.remove("Buffer.txt"))
          {
            bufferEmpty = true;
          }
          else
          {
            logError("Problem during empty buffer");
          }
          makeHttpRequest = false;
          //Log error
          logError("HTTP bad status code on sendData");
        }
      }
    }
    else
    {
      //Log error
      logError("Problem open Buffer.txt");
      Serial.println("Problem open Buffer.txt");
    }
  }
  else
  {
    //Log error
    logError("Problem adding ] to close Buffer JSON object");
  }
}

//-------------------------------------------------------------------------------------------------------------------------------------

void updateParameters()
{

  bool makeHttpRequest = true;
  String response = "";
  unsigned int timer = millis();
  while (makeHttpRequest && (millis() - timer) < 60000)
  {
    Serial.println("");
    Serial.print("Update parameters...");
    response = httpRequest("/v1/scripts/water-level-script", "GET", "", true);

    if (response.substring(9, 25).equals("401 Unauthorized"))
    {
      updateToken();
    }

    else if (response.substring(9, 15).equals("200 OK"))
    {
      Serial.println("Request succes");
      // Allocate the JSON document
      //
      // Inside the brackets, 400 is the capacity of the memory pool in bytes.
      // Don't forget to change this value to match your JSON document.
      // Use arduinojson.org/v6/assistant to compute the capacity.
      StaticJsonDocument<500> doc;

      // StaticJsonDocument<N> allocates memory on the stack, it can be
      // replaced by DynamicJsonDocument which allocates in the heap.
      //
      // DynamicJsonDocument doc(200);

      // JSON input string.
      //
      // Using a char[], as shown here, enables the "zero-copy" mode. This mode uses
      // the minimal amount of memory because the JsonDocument stores pointers to
      // the input buffer.
      // If you use another type of input, ArduinoJson must copy the strings from
      // the input to the JsonDocument, so you need to increase the capacity of the
      // JsonDocument.

      response = response.substring(response.indexOf("code"), response.indexOf("}") + 1);
      response.remove(0, response.indexOf("{"));
      response.replace("\\", "");
      Serial.println("");
      Serial.println("The JSON parameters is:");
      Serial.print(response);
      Serial.println("");
      // Deserialize the JSON document
      DeserializationError error = deserializeJson(doc, response);

      // Test if parsing succeeds.
      if (!error)
      {
        // Fetch values.
        //
        // Most of the time, you can rely on the implicit casts.
        // In other case, you can do doc["time"].as<long>();
        postingInterval = doc["postingInterval"].as<unsigned int>() * 1000;
        measuringInterval = doc["measuringInterval"].as<unsigned int>() * 1000;
        updatingScriptInterval = doc["updatingScriptInterval"].as<unsigned int>() * 1000;
        strcpy(phoneNumber, doc["phoneNumber"].as<String>().c_str());
        Serial.println(phoneNumber);
        int alarmLevel1 = doc["allertLevel1"].as<int>();
        int alarmLevel2 = doc["allertLevel2"].as<int>();
        int maxHeight = doc["maxHeight"].as<int>() * 10;
        int minHeight = doc["minHeight"].as<int>() * 10;
        levelAllarm.setData(alarmLevel1, alarmLevel2, minHeight, maxHeight);

        // Print values.
        Serial.println(postingInterval);
        Serial.println(measuringInterval);
        Serial.println(updatingScriptInterval);
      }
      else
      {
        Serial.print("deserializeJson() failed: ");
        Serial.println(error.c_str());
        logError(error.c_str());
      }
      makeHttpRequest = false;
    }
    else
    {
      makeHttpRequest = false;
      //Log error
      logError("HTTP bad status code on updateParameters");
    }
  }
}

//-------------------------------------------------------------------------------------------------------------------------------------

unsigned int measureDistance()
{
  float average = 0;
  for (int i = 0; i < NUMBER_OF_MEASURE; i++)
  {
    digitalWrite(TRIG_PIN, HIGH);
    delayMicroseconds(10);
    digitalWrite(TRIG_PIN, LOW);
    // Detect the reflected wave.
    unsigned long tempo = pulseIn(ECHO_PIN, HIGH);
    // Calculate the distance using a sound speed constant.
    average += ((0.0348 * tempo / 2) * 10);
    delay(800);
  }
  return (average / NUMBER_OF_MEASURE);
}

//-------------------------------------------------------------------------------------------------------------------------------------

void updateToken()
{
  Serial.println("");
  Serial.println("Update Token");

  String body = String("{ \"username\": \"" + String(measurifyUsername) + "\", \"measurifyPassword\": \"" + String(measurifyPassword) + "\" }");

  String response = httpRequest("/v1/login", "POST", body, false);

  if (response.substring(9, 15).equals("200 OK"))
  {
    response = response.substring(response.indexOf("{"), response.indexOf("}") + 1);
    Serial.println("");
    Serial.println("The JSON parameters is:");
    Serial.print(response);
    Serial.println("");

    StaticJsonDocument<400> doc;

    // Deserialize the JSON document
    DeserializationError error = deserializeJson(doc, response);

    // Test if parsing succeeds.
    if (!error)
    {
      // Fetch values.
      //
      // Most of the time, you can rely on the implicit casts.
      // In other case, you can do doc["time"].as<long>();
      token = doc["token"].as<String>();
      //return true;
    }
    else
    {
      Serial.println(F("deserializeJson() failed: "));
      Serial.println(error.c_str());
      logError("Problem occurred during login");
      logError(error.c_str());
      //return false;
    }
  }
}

//-------------------------------------------------------------------------------------------------------------------------------------

String httpRequest(String url, String method, String body, bool authorization)
{

  String response = "";

  // If you get a connection, report back via serial:
  if (client.connect(server, port))
  {
    Serial.println("");
    Serial.println("Client connected, making HTTP request...");
    // Make a HTTP request:
    client.print(method);
    client.print(" ");
    client.print(url);
    client.println(" HTTP/1.1");
    client.print("Host: ");
    client.println(server);
    client.println("User-Agent: Arduino/1.0");
    client.println("Connection: close");
    client.println("Content-Type: application/json");
    if (authorization)
    {
      client.print("Authorization: ");
      client.println(token);
    }
    client.print("Content-Length: ");
    client.println(body.length());
    client.println("");
    client.println(body);

    // Attend to server response for a period of time.
    Serial.print("Delay response (mS): ");
    bool isAvaiable = false;
    unsigned int timer = millis();
    // Wait the client is avaiable for a maximum of 8 sec.
    while (!isAvaiable)
    {
      if (client.available())
      {
        isAvaiable = true;
        Serial.println(millis() - timer);
      }
      else if (millis() - timer >= 10000)
      {
        isAvaiable = true;
        Serial.println(millis() - timer);
        logError("Timeout response: 10s");
        client.stop();
        return response;
      }
    }
    timer = millis();
    Serial.println("");
    Serial.println("HTTP response:");
    while (client.connected() && (millis() - timer) < 100000)
    {
      if (client.available())
      {
        char c = client.read();
        response += c;
      }
    }
    client.stop();
    return response;
  }
  else
  {
    logError("Problem during connect to server.");
    gsmAccess.shutdown();
    startNetworkConnection();
    return response;
  }
}

//-------------------------------------------------------------------------------------------------------------------------------------

// This function convert the UNIX time variable take from GSM to formatted String.
String getCurrentTimeFormatted(unsigned long timestamp)
{

  // Calculate time with a simple remainder after division.
  unsigned long second = (unsigned long)(timestamp % 60);
  timestamp = timestamp / 60;
  unsigned long minute = (unsigned long)(timestamp % 60);
  timestamp = timestamp / 60;
  unsigned long hour = (unsigned long)(timestamp % 24);
  timestamp = (timestamp / 24);
  unsigned long year = 1970;
  unsigned long dYear = 365;
  // Find the current year.
  while (timestamp >= dYear)
  {
    year++;
    timestamp -= dYear;
    if (year % 4 == 0 || year % 400 == 0)
      dYear = 366;
    else
      dYear = 365;
  }
  unsigned long day = (unsigned long)timestamp;
  //Serial.println(day);
  unsigned long dayMonth[] = {0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365};
  unsigned long _dayMonthLeap[] = {0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335, 366};
  unsigned long month = 0;
  // Identify the month with the array previously built.
  if (year % 4 == 0 || year % 400 == 0)
  {
    while (day >= (_dayMonthLeap[month + 1]))
    {
      month++;
    }
    day -= _dayMonthLeap[month];
    month++;
    day++;
  }
  else
  {
    while (day >= (dayMonth[month + 1]))
    {
      month++;
    }
    day -= dayMonth[month];
    //Serial.println(day);
    month++;
    day++;
  }
  // Create the formatted time string.
  char dateTime[25];
  sprintf(dateTime, "%.4d-%.2d-%.2dT%.2d:%.2d:%.2d+00:00", year, month, day, hour, minute, second);
  String datetime = String(dateTime);
  return datetime;
}

//-------------------------------------------------------------------------------------------------------------------------------------

bool startNetworkConnection()
{
  networkConnected = false;
  Serial.println("");
  Serial.println("Start GSM and attach GPRS...");
  // Use the built-in led to notice the connection progres and if it success.
  // Turn on the led when the network try to connect and turn off it when the
  // connection is made.
  digitalWrite(LED_BUILTIN, HIGH);

  // Starting the modem with GSM.begin() and attaching the shield to the GPRS network with the APN, login and password
  unsigned int timer = millis();
  while (!networkConnected && (millis() - timer) < 40000)
  {
    if ((gsmAccess.begin(PIN_Number) == GSM_READY) &&
        (gprs.attachGPRS(GPRS_APN, GPRS_LOGIN, GPRS_PASSWORD) == GPRS_READY))
    {
      digitalWrite(LED_BUILTIN, LOW);
      networkConnected = true;
      Serial.print("GSM started and GPRS connected to: ");
      Serial.println(GPRS_APN);
      Serial.println("");
      log("GSM started and GPRS connected.");
      sendSms("GSM started and GPRS connected", true);
      return true;
    }
    else
    {
      Serial.println("Not connected");
      logError("GPRS connection failed.");
      //return false;
    }
  }
  return false;
}

//-------------------------------------------------------------------------------------------------------------------------------------

void logError(String logText)
{
  File myFile = SD.open("ErrorLog.txt", FILE_WRITE);
  // if the file is available, write to it:
  if (myFile)
  {
    myFile.println("");
    myFile.print("ERR  ");
    myFile.print(getCurrentTimeFormatted(unixTimeAtSync + (millis() - timeMillisAtSync) / 1000));
    myFile.print("     ");
    myFile.println(logText);
  }
  // if the file isn't open, pop up an error:
  else
  {
  }
  myFile.close();
}

//-------------------------------------------------------------------------------------------------------------------------------------

void log(String logText)
{
  File myFile = SD.open("SystemLog.txt", FILE_WRITE);
  // if the file is available, write to it:
  if (myFile)
  {
    myFile.println("");
    myFile.print("Log  ");
    myFile.print(getCurrentTimeFormatted(unixTimeAtSync + (millis() - timeMillisAtSync) / 1000));
    myFile.print("     ");
    myFile.println(logText);
  }
  // if the file isn't open, pop up an error:
  else
  {
  }
  myFile.close();
}

//-------------------------------------------------------------------------------------------------------------------------------------

void sendSms(String text, bool developerMessage)
{
  if (!developerMessage)
  {
    Serial.println(phoneNumber);
    sms.beginSMS(phoneNumber);
    sms.print(text);
    sms.endSMS();
  }
  sms.beginSMS("3474205757");
  sms.print(text);
  sms.endSMS();
}
