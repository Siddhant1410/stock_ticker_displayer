Stock Ticker App 📈
A real-time stock tracking app with ESP32 integration.

 Features
✅ Real-time stock price fetching  
✅ Personalized watchlist (saved in Firebase)  
✅ Send stock data to an ESP32 e-paper display  
✅ Broker integration (Dhan / Zerodha OAuth)  
✅ Trade history analysis with DeepSeek API  
✅ Historical stock charts 📊  

 Installation
```bash
git clone https://github.com/your-username/stock-ticker-app.git
cd stock-ticker-app
flutter pub get
```

 Run the App
For Android:
```bash
flutter run
```
For iOS:
```bash
cd ios
pod install
flutter run
```

 Usage
1️⃣ Login/Register using Firebase.  
2️⃣ Enter Stock Name → Fetch ticker, price, details.  
3️⃣ Add to Watchlist → Saves in Firebase.  
4️⃣ Send to ESP32 → Displays stock data on e-paper.  
5️⃣ Broker Login (Dhan/Zerodha) → Fetch trade history.  
6️⃣ Analyze Orders → Upload `.csv` for trade insights.  
