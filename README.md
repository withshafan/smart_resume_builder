<div align="center">

  <h1>🚀 AI Resume Builder</h1>
  
  <p>
    <strong>A modern, beautiful, and intelligent Flutter application to build professional resumes in minutes.</strong>
  </p>
  
  <p>
    <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
    <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
    <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase" />
  </p>

</div>

---

## 📖 Overview

**AI Resume Builder** is a powerful cross-platform application built with Flutter. It streamlines the process of creating professional, eye-catching resumes. Leveraging Firebase for real-time data sync and secure authentication, this app allows users to seamlessly design, preview, and export high-quality PDF resumes on the go.

## ✨ Features

- **🔐 Secure Authentication:** Seamless sign-up and login experience powered by Firebase Auth.
- **☁️ Cloud Sync:** Your resumes and data are safely stored in Firestore and accessible from anywhere.
- **📄 Instant PDF Generation:** Create, preview, and export pixel-perfect PDF resumes using the `pdf` and `printing` packages.
- **🎨 Modern UI/UX:** Clean, intuitive interface with beautiful typography (Google Fonts) and smooth loading states (Shimmer).
- **🖼️ Asset Management:** Upload and manage profile pictures and assets via Firebase Storage and File Picker.
- **📱 Cross-Platform:** Works flawlessly on Android, iOS, Web, and Desktop.

## 🛠️ Tech Stack

- **Framework:** [Flutter](https://flutter.dev/)
- **Language:** [Dart](https://dart.dev/)
- **Backend as a Service:** [Firebase](https://firebase.google.com/) (Auth, Firestore, Storage)
- **State Management:** Provider
- **Key Packages:**
  - `pdf` & `printing` for document generation
  - `google_fonts` for typography
  - `shimmer` for skeleton loaders
  - `file_picker` for local file selection

## 🚀 Getting Started

Follow these instructions to get a copy of the project up and running on your local machine.

### Prerequisites

Ensure you have the following installed:
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (Version 3.11.5 or higher)
- [Dart SDK](https://dart.dev/get-dart)
- IDE (VS Code, Android Studio, or IntelliJ)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/ai_resume_builder.git
   cd ai_resume_builder
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase:**
   Make sure you have set up your Firebase project and added the corresponding `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) files.

4. **Run the app:**
   ```bash
   flutter run
   ```

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! 
Feel free to check the [issues page](https://github.com/yourusername/ai_resume_builder/issues).

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---
<div align="center">
  Made with ❤️ by the AI Resume Builder Team
</div>
