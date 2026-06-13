# Jo Finance App (Mobile)

A modern, feature-rich finance management application built with Flutter. 

## 🌟 Features
- **Authentication**: Secure login and registration flows, including biometric authentication (`local_auth`).
- **State Management**: Robust state management using `provider`.
- **Data Visualization**: Interactive financial charts using `fl_chart`.
- **Local Storage**: Persistent user sessions and preferences with `shared_preferences`.
- **Media Support**: Audio and video integrations (`video_player`, `audioplayers`, `record`).
- **API Integration**: Connects to backend services via `http`.

## 🛠 Tech Stack
- **Framework**: [Flutter](https://flutter.dev/)
- **Language**: Dart
- **Key Packages**:
  - `provider` (State Management)
  - `http` (Network Requests)
  - `shared_preferences` (Local Data)
  - `fl_chart` (Data Visualization)
  - `local_auth` (Biometrics)
  - `google_fonts` (Typography)

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.12.0 or higher)
- Android Studio / Xcode for emulators
- VS Code (recommended)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/scripteros/jofinance_mobile.git
```

2. Navigate to the project directory:
```bash
cd jofinance_mobile
```

3. Install dependencies:
```bash
flutter pub get
```

4. Run the app:
```bash
flutter run
```

## 🌐 Running on Web (VPS/Remote)
If you are developing remotely, you can run the app as a web server to preview it in your local browser:
```bash
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
```
Then access `http://<YOUR_IP>:8080` in your browser.

## 📄 License
This project is proprietary.
