# Regenesys LMS Mobile

Regenesys LMS Mobile is a comprehensive, feature-rich Flutter application designed to deliver a seamless Learning Management System (LMS) experience on mobile devices. Built with performance and user experience in mind, the app allows students to manage their academic journey, access learning materials, and stay connected on the go.

---

## 🚀 Key Features

Based on the project's robust modular architecture, the app includes the following core functionalities:

*   **Course Management & Enrollment**: Browse available courses, view detailed course information, and seamlessly enroll in programs.
*   **Student Dashboard**: A dedicated, personalized space to track progress, upcoming tasks, and payments.
*   **Assignments & Quizzes**: Submit assignments and take interactive quizzes directly within the app.
*   **Offline Learning**: Download course materials (videos, PDFs, etc.) securely for offline access.
*   **Capstone Projects**: Dedicated modules to manage and track capstone project requirements and submissions.
*   **Live Classes Integration**: Built-in MS Teams call integration for attending live lectures and webinars.
*   **Fee & Payment Management**: Manage fee structures, view due dates, and handle in-app purchases and payments.
*   **Resource Library**: Access a wide variety of learning resources, including encrypted PDFs and videos (YouTube & direct playback).
*   **Refer & Earn**: Built-in referral system to reward users for bringing in new students.
*   **Real-time Notifications**: Stay up-to-date with course announcements, assignment deadlines, and payment reminders via Firebase Cloud Messaging.

---

## 🛠 Tech Stack

*   **Framework**: Flutter (SDK ^3.5.3)
*   **State Management & Routing**: GetX architecture
*   **Networking**: Dio & http with `either_dart` for robust error handling.
*   **Backend & Analytics**: Firebase (Auth, Analytics, Crashlytics, Messaging, Remote Config).
*   **Local Storage & Security**: `flutter_secure_storage`, `encrypt` (for secure offline downloads), and `crypto`.
*   **Media & Viewers**: `chewie`, `video_player`, `youtube_player_flutter`, and custom PDF viewers (`flutter_pdfview`, `syncfusion_flutter_pdfviewer`).
*   **UI/UX**: Custom design system utilizing `flutter_screenutil`, `skeletonizer` for loading states, and custom Gilroy typography.

---

## 📂 Documentation
For detailed technical documentation regarding API endpoints, folder structures, and app logic, please refer to:
👉 **[Technical Documentation](app_documentation.md)**

---

## ⚙️ Getting Started

### Prerequisites
*   **Flutter SDK**: ^3.7.2
*   **Dart SDK**: ^3.7.2

### Setup
1.  **Clone the repository**:
    ```bash
    git clone https://github.com/regenesys-team/lms-mobile.git
    ```
2.  **Install dependencies**:
    ```bash
    flutter pub get
    ```
3.  **Run the application**:
    ```bash
    flutter run
    ```

---

## 📁 Project Structure

The project follows a modular, feature-first approach organized under the `lib/` directory using the GetX pattern:

```text
lib/
├── app/
│   ├── common/        # Shared widgets, utilities, and constants
│   ├── config/        # Environment and app configuration
│   ├── data/          # Models, providers, and local storage logic
│   ├── modules/       # Feature modules (Assignments, Courses, Offline Download, etc.)
│   └── routes/        # App routing definitions
├── services/          # Core services (Network, Firebase, etc.)
├── main.dart          # Application entry point
└── firebase_options.dart # Firebase initialization config
```

*Developed for Regenesys Business School*
