#include <WiFi.h>
#include <HTTPClient.h>
#include <WebServer.h>
#include <ArduinoJson.h>
#include <GxEPD2_BW.h>
#include <GxEPD2_4C.h>
#include <Fonts/FreeMonoBold9pt7b.h>

#define GxEPD2_DISPLAY_CLASS GxEPD2_4C
#define EPD_CS   5
#define EPD_DC   17
#define EPD_RST  16
#define EPD_BUSY 4

GxEPD2_BW<GxEPD2_420, GxEPD2_420::HEIGHT> display(GxEPD2_420(EPD_CS, EPD_DC, EPD_RST, EPD_BUSY));

// Wi-Fi Credentials
const char* ssid = "SI4's_Airtel_2.4GHz";
const char* password = "eezeepeezee#_273";

// Web Server on Port 80
WebServer server(80);

// Stock data
struct Stock {
  String ticker;
  String latestPrice;
  String priceChange;
};

Stock stocks[10]; // Maximum 5 stocks
int stockCount = 0;

// Function to fetch live data from Yahoo Finance API
bool fetchLiveData(Stock& stock) {
  HTTPClient http;
  String url = "https://query1.finance.yahoo.com/v8/finance/chart/" + stock.ticker;
  http.begin(url);
  int httpResponseCode = http.GET();

  if (httpResponseCode == 200) {
    String payload = http.getString();
    //Serial.println("Payload: " + payload);  // Log full response for debugging

    StaticJsonDocument<4096> doc; // Increased buffer size for large responses
    DeserializationError error = deserializeJson(doc, payload);

    if (!error) {
      JsonObject chart = doc["chart"];
      if (chart["error"].isNull()) {
        JsonObject result = chart["result"][0];
        JsonObject meta = result["meta"];

        if (!meta.isNull()) {
          double regularMarketPrice = meta["regularMarketPrice"] | 0.0;

          JsonArray openPrices = result["indicators"]["quote"][0]["open"];
          JsonArray closePrices = result["indicators"]["quote"][0]["close"];

          if (!openPrices.isNull() && !closePrices.isNull() && openPrices.size() > 0 && closePrices.size() > 0) {
            double openPrice = openPrices[0] | 0.0;
            double closePrice = closePrices[0] | 0.0;

            stock.latestPrice = String(regularMarketPrice, 2);
            stock.priceChange = (closePrice > openPrice ? "+" : "") + String(closePrice - openPrice, 2);

            Serial.println("Stock: " + stock.ticker);
            Serial.println("Latest Price: " + stock.latestPrice);
            Serial.println("Price Change: " + stock.priceChange);

            return true;
          } else {
            Serial.println("Error: Missing open or close price data.");
          }
        } else {
          Serial.println("Error: Missing 'meta' section in the JSON response.");
        }
      } else {
        Serial.println("Error: Chart response indicates an error.");
      }
    } else {
      Serial.println("JSON Deserialization Error: " + String(error.c_str()));
    }
  } else {
    Serial.println("HTTP Request Failed. Code: " + String(httpResponseCode));
  }

  http.end();
  return false;
}


// Function to display data on the e-paper
void displayData() {
  display.init();
  display.setRotation(1);
  display.setTextColor(GxEPD_BLACK);
  display.setFont(&FreeMonoBold9pt7b);

  display.fillScreen(GxEPD_WHITE);  // Clear the display

  for (int i = 0; i < 10; i++) {
    if (stocks[i].ticker != "") {
      display.setCursor(10, 50 + i * 20);
      display.print(stocks[i].ticker + ": $" + stocks[i].latestPrice + " (" + stocks[i].priceChange + ")");
    }
  }

  display.display();  // Refresh the display
}

// Function to handle data sent from the app
void handleUpdateStock() {
  if (server.hasArg("plain")) {
    String body = server.arg("plain");
    StaticJsonDocument<1024> doc;

    DeserializationError error = deserializeJson(doc, body);
    if (!error) {
      String ticker = doc["ticker"].as<String>();
      if (stockCount < 10) {
        stocks[stockCount] = {ticker, "0.00", "0.00"};
        stockCount++;
        displayData();
      }

      server.send(200, "application/json", "{\"status\":\"success\"}");
    } else {
      server.send(400, "application/json", "{\"status\":\"error\", \"message\":\"Invalid JSON\"}");
    }
  } else {
    server.send(400, "application/json", "{\"status\":\"error\", \"message\":\"No data received\"}");
  }
}

// Setup function
void setup() {
  Serial.begin(115200);

  // Connect to Wi-Fi
  WiFi.begin(ssid, password);
  Serial.print("Connecting to Wi-Fi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWi-Fi connected!");
  Serial.println("IP Address: " + WiFi.localIP().toString());

  // Start the server
  server.on("/update-stock", HTTP_POST, handleUpdateStock);
  server.begin();
  Serial.println("Server started!");
  display.setTextColor(GxEPD_BLACK);
  display.fillScreen(GxEPD_WHITE); 
}

// Main loop
void loop() {
  server.handleClient();

  static unsigned long lastUpdateTime = 0;
  if (millis() - lastUpdateTime > 60000) { // 1 minute
    for (int i = 0; i < stockCount; i++) {
      if (fetchLiveData(stocks[i])) {
        Serial.println("Updated stock: " + stocks[i].ticker);
      } else {
        Serial.println("Failed to update stock: " + stocks[i].ticker);
      }
    }
    displayData();
    lastUpdateTime = millis();
  }
}