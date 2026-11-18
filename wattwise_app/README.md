# WattWise — Smart Electricity Bill & Consumption Analyzer

A unified Flutter application combining:
- **Member 1 (Auth, Dashboard & Bill Management):** Login, Registration, Profile, Manual Bill Entry, and PDF/Image Bill Upload with on-device OCR (`google_mlkit_text_recognition` + `printing` PDF rasterizer) and user confirmation before saving to SQLite.
- **Member 2 (Appliance Management & Consumption Analysis):** Predefined & custom Appliance Inventory, core calculation `E = (P * H * D * N) / 1000`, appliance-wise consumption breakdown with charts, and Bill vs. Estimated Usage Comparison with unallocated load calculation.
- **Member 3 (Insights, Anomaly Detection & Savings Simulator):** Month-on-month consumption trends, automated anomaly detection with appliance-linked root-cause analysis, personalized recommendations, and an interactive Savings Simulator with real-time unit and cost savings.

## Running in Android Studio
1. Extract `WattWise_Flutter_Project.zip` to a folder (e.g., `wattwise_app`).
2. Open **Android Studio** -> **Open** -> select the `wattwise_app` folder.
3. Wait for Gradle/Flutter sync, or run in the Android Studio terminal:
   ```bash
   flutter pub get
   ```
4. Select an Android Emulator or physical Android device (API 21+ / Android 5.0+) and click **Run** (`main.dart`).
5. On the Login screen, you can **Register** a new account or tap **Use Demo Account** to explore preloaded bills, appliances, and anomaly insights immediately.
