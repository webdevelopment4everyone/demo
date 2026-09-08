# Regenesys LMS Mobile App - Technical Documentation

Last verified: 2026-09-08 against branch lms_dev 
This document is the single source of truth for the application's architecture, navigation, page structure, and API integration. All entries have been cross-checked against actual source files.

---

## 1. Project Overview
The Regenesys LMS Mobile App is designed to provide students with a centralized, mobile-first educational experience. It facilitates seamless learning management, course enrollment, and academic tracking, targeting enrolled students who need flexible access to their coursework.

### A. User Journey
1. **Onboarding & Authentication**: The user launches the app, views the onboarding flow (if a new user), and logs in securely using their credentials.
2. **Student Dashboard**: Upon logging in, the user lands on a personalized dashboard to track immediate tasks, active courses, and fee statuses.
3. **Course Interaction**: The user explores courses, views learning resources (videos, PDFs), and optionally downloads encrypted content for offline studying.
4. **Assessments & Live Classes**: The user submits assignments, takes quizzes for knowledge evaluation, and joins live lectures via MS Teams integration.
5. **Account & Payments**: The user can manage fee payments, update their profile, and refer peers via the 'Refer & Earn' module.

### B. Active Environments
The application supports the following environments, which can be selected dynamically during development:
- **Production (`Environment.prod`)**
- **UAT (`Environment.uat`)**
- **Staging (`Environment.stag`)**
- **Development (`Environment.dev`)**

---

## 2. Project Folder Structure

```
lib/
├── app/
│   ├── common/                # Shared logic and UI components
│   │   ├── bindings.dart      # Global bindings
│   │   ├── controllers/       # Shared business logic
│   │   ├── mixins/            # Reusable mixins
│   │   ├── models/            # Shared data models
│   │   ├── services/          # App-wide services
│   │   ├── storage/           # Local storage utilities
│   │   ├── utils/             # Helper functions
│   │   ├── values/            # Constants, colors, and strings
│   │   └── widgets/           # Global reusable widgets
│   ├── config/                # Environment and app configuration
│   ├── data/                  # Data layer abstraction
│   │   ├── interface_controller/
│   │   ├── repositories/      # API and local data repositories
│   │   └── services/          # Data fetch services
│   ├── modules/               # Feature-based isolated modules
│   │   ├── app_web_view/      # Generic web view handler
│   │   ├── assignments/       # Assignment submission and viewing
│   │   ├── capstone_project/  # Capstone project management
│   │   ├── course_details/    # Course information and curriculum
│   │   ├── enrollment/        # Course enrollment flow
│   │   ├── environment_selector/# Dev/Staging/Prod switcher
│   │   ├── fee_and_payment/   # Fee structure and payments
│   │   ├── feedback/          # App and course feedback
│   │   ├── in_app_purchase/   # In-app purchase integration
│   │   ├── login/             # Authentication and login
│   │   ├── notification/      # Push notifications display
│   │   ├── offline_download/  # Offline content management
│   │   ├── onboarding/        # First-time user onboarding
│   │   ├── profile/           # User profile management
│   │   ├── quiz/              # Interactive quizzes
│   │   ├── refer_and_earn/    # Referral program
│   │   ├── splash/            # Splash screen logic
│   │   ├── student/           # Student dashboard and progress
│   │   ├── teams_call/        # MS Teams live class integration
│   │   ├── view_resources/    # Resource (PDF/Video) viewer
│   │   └── widgets/           # Module-specific widgets
│   └── routes/                # Application route management
│       ├── app_pages.dart     # Maps route strings to GetX pages/bindings
│       └── app_routes.dart    # Defines constant strings for all routes
├── services/                  # Core standalone application services
│   ├── config_manager.dart    # Manages global app configurations
│   ├── remote_config_service.dart # Firebase Remote Config integration
│   └── revenue_cat_service.dart # RevenueCat in-app purchase handling
├── main.dart                  # Application entry point
└── firebase_options.dart      # Firebase initialization config
```

---

## 3. Architecture & State Management
We use the **GetX pattern** for state management, dependency injection, and route management. 

| Layer | Role |
| :--- | :--- |
| `bindings/` | Dependency injection for the module. |
| `controllers/` | Business logic and state variables. |
| `views/` | The UI layer. |
| `repositories/` | API interactions and local data fetching. |
| `services/` | Module-specific background tasks and external integrations. |

### Key Permanent Controllers
To maintain global state across the app's lifecycle, the following controllers are initialized as permanent (`permanent: true`):
- **`AppScaffoldController`**: Manages the global UI scaffold and core navigation state.
- **`ProfileController`**: Maintains the user's profile and session data app-wide.
- **`NotificationController`**: Handles background and foreground push notifications globally.
- **`OfflineDownloadController`**: Manages background downloading and decryption of offline materials.
- **`FeeAndPaymentController`**: Keeps track of fee statuses and payment banners globally.
- **`StudentDashboardController`**: Retains the student's dashboard state to prevent constant re-fetching.

---

## 4. App Flow (Navigation Logic)

### A. Startup Sequence (Optimistic Cache-First)

The entry point is `SplashView` → `SplashController` → `onInit()` which triggers `_navigateToNextScreen()`.

The splash animation runs while the app verifies network connectivity and checks for mandatory upgrades via Firebase Remote Config. Once cleared, it proceeds to `onProceedToHome()`.

```
App Launch
    │
    ├─ No Access Token / Unauthenticated
    │       ├── Android (Onboarding Completed) ──► LOGIN
    │       ├── Android (First Launch) ──────────► ONBOARDING
    │       └── iOS ─────────────────────────────► SUBSCRIPTION_ONBOARDING
    │
    └─ Has Access Token
            │
            ├─ Cached User is Lead (`dregNo` is null)
            │       ├── Android ─────────► Logs out & routes to LOGIN
            │       └── iOS ─────────────► SUBSCRIPTION_COURSE_VIEW
            │
            └─ Cached User is Student
                    └──► STUDENT_DASHBOARD
```

> **Concurrent Evaluation**: Session validation and onboarding completion checks are executed concurrently via `Future.wait()` to optimize startup time. The system optimistically loads cached user data without waiting for API responses.

### B. Live Role Verification (Splash Routing)

When auto-routing from splash, the app performs a **live role and lead check**:

| Condition | Platform | Destination |
|---|---|---|
| Student has `dregNo` and role `STUDENT` | Android & iOS | `STUDENT_DASHBOARD` |
| User is a Lead (`dregNo` == null) | Android | `LOGIN` (Requires manual batch allocation) |
| User is a Lead (`dregNo` == null) | iOS | `SUBSCRIPTION_COURSE_VIEW` |
| Unauthenticated (First Launch) | Android | `ONBOARDING` |
| Unauthenticated (Returning) | Android | `LOGIN` |
| Unauthenticated | iOS | `SUBSCRIPTION_ONBOARDING` |

### C. Main Navigation (Scaffold Routing)

Admitted students navigate via a dynamic **Bottom Navigation Bar** (managed by `AppScaffoldController`). The tab indexes dynamically adjust based on feature flags:

| Tab Index | Screen | Feature Flagged? |
|---|---|---|
| 0 | Student Dashboard | No |
| 1 | All Courses | No |
| 2 | Fees & Payment | Yes (Requires `isFeeAndPaymentEnabled`) |
| 3 (or 2) | My Profile | No (Index shifts to 2 if Fees are disabled) |

> Note: If only one pending payment exists and Fees are enabled, the Fees tab automatically bypasses the list view and opens `FEE_AND_PAYMENT_ORDER_DETAILS`.

### D. Push Notification Routing (Deep Linking)

Push notifications are handled globally by `NotificationService` and `NotificationController`.
1. The FCM token is fetched during splash initialization for admitted students and synced to the backend.
2. If the app is launched from a killed state via a notification, the payload is cached.
3. Once the splash sequence finishes and the user lands on `STUDENT_DASHBOARD`, `SplashController` invokes `checkSavedNotification()` to parse the payload and route to the destination.
4. Notifications tapped while the app is in the background or foreground are intercepted and routed immediately.

---

## 5. Page Inventory

### A. Dynamic Pages (Data-Driven, Actively Registered)

| Page | Route Constant | Module | Purpose |
|---|---|---|---|
| `StudentDashboardView` | `Routes.STUDENT_DASHBOARD` | student | Central student dashboard overview, active courses, and fee statuses. |
| `AllSessionView` | `Routes.ALL_SESSION_VIEW` | student | List of all live sessions. |
| `AllCoursesView` | `Routes.ALL_COURSES_VIEW` | student | List of all enrolled courses. |
| `CourseDetailsView` | `Routes.COURSE_DETAILS` | course_details | Detailed view of course curriculum and syllabus. |
| `ResourcesView` | `Routes.VIEW_RESOURCES` | view_resources | Viewer for course resources and learning materials. |
| `QuizView` | `Routes.QUIZ_VIEW` | quiz | Interactive quiz assessment interface. |
| `QuizReportView` | `Routes.QUIZ_REPORT_VIEW` | quiz | Quiz results and performance report. |
| `AssignmentProjectView` | `Routes.ASSIGNMENT_PROJECT` | assignments | Assignment details and submission interface. |
| `CapstoneProjectView` | `Routes.CAPSTONE_PROJECT` | capstone_project | Capstone project tracking and management. |
| `FeeAndPaymentView` | `Routes.FEE_AND_PAYMENT` | fee_and_payment | Dashboard for fee statuses and payments. |
| `FeeAndPaymentOrderDetailsView` | `Routes.FEE_AND_PAYMENT_ORDER_DETAILS` | fee_and_payment | Detailed order breakdown for fees. |
| `FeeAndPaymentPayFullView` | `Routes.FEE_AND_PAYMENT_PAY_FULL` | fee_and_payment | Full payment transaction interface. |
| `FeeAndPaymentPayDueView` | `Routes.FEE_AND_PAYMENT_PAY_DUE` | fee_and_payment | Due amount payment transaction interface. |
| `FeeAndPaymentUploadPaymentProofView` | `Routes.FEE_AND_PAYMENT_UPLOAD_PAYMENT_PROOF` | fee_and_payment | Upload interface for offline/manual payment proofs. |
| `FeeAndPaymentStatusView` | `Routes.FEE_AND_PAYMENT_STATUS` | fee_and_payment | Status of a completed or failed payment transaction. |
| `ProfileView` | `Routes.PROFILE` | profile | Main profile and settings hub. |
| `MyProfileView` | `Routes.MY_PROFILE` | profile | Detailed personal information view. |
| `ShowcaseMyProfileView` | `Routes.MY_PROFILE_SHOWCASE` | profile | Showcase/public view of user profile. |
| `SettingsView` | `Routes.SETTINGS` | profile | App-wide user settings. |
| `HelpCenterView` | `Routes.HELP_CENTER` | profile | Help and support resources (FAQs). |
| `NotificationView` | `Routes.NOTIFICATION` | notification | Inbox for push notifications. |
| `FeedbackFormView` | `Routes.FEEDBACK_FORM` | feedback | Form for submitting course/app feedback. |
| `EnrollDialog` | `Routes.ENROLLMENT_DIALOG` | enrollment | Dialog interface for enrolling into a course. |
| `ReferAndEarnView` | `Routes.REFER_AND_EARN` | refer_and_earn | Referral system and reward tracking. |
| `OfflineDownloadView` | `Routes.OFFLINE_DOWNLOAD` | offline_download | Management of downloaded offline files. |
| `CourseDownloadDetailView` | `Routes.COURSE_SPECIFIC_OFFLINE_DOWNLOAD` | offline_download | Course-specific offline content management. |
| `SubscriptionCourseView` | `Routes.SUBSCRIPTION_COURSE_VIEW` | in_app_purchase | Display available premium courses for subscription. |
| `SubscriptionRestorePurchaseView` | `Routes.SUBSCRIPTION_RESTORE_PURCHASE` | in_app_purchase | Interface to restore previous IAP transactions. |
| `SubscriptionPaymentStatusView` | `Routes.SUBSCRIPTION_PAYMENT_STATUS` | in_app_purchase | Subscription payment success/failure status. |
| `SelectReasonRefundScreen` | `Routes.SELECT_REASON_REFUND` | in_app_purchase | Form for selecting a reason to request a refund. |

### B. Static / Utility Pages

| Page | Route Constant | Purpose |
|---|---|---|
| `SplashView` | `Routes.SPLASH` | Branding animation and startup routing orchestration. |
| `EnvironmentSelectorScreen` | `Routes.ENVIRONMENT_SELECTOR` | Dev utility to switch between Prod/Stag/UAT/Dev. |
| `OnboardingView` | `Routes.ONBOARDING` | Walkthrough screens for first-time users. |
| `LoginView` | `Routes.LOGIN` | Phone/Email entry for authentication. |
| `OtpAuthView` | `Routes.OTP` | OTP input and session initialization. |
| `SubscriptionOnboardingView` | `Routes.SUBSCRIPTION_ONBOARDING_VIEW` | Onboarding specifically for subscription users. |
| `SubscriptionLoginView` | `Routes.SUBSCRIPTION_LOGIN_VIEW` | Login specifically for subscription users. |
| `SubscriptionOtpView` | `Routes.SUBSCRIPTION_OTP_VIEW` | OTP validation for subscription users. |
| `SubscriptionSuccessView` | `Routes.SUBSCRIPTION_SUCCESS_VIEW` | Confirmation screen after successful subscription. |
| `RefundRequestSuccessScreen` | `Routes.REFUND_REQUET_SUCCESS` | Confirmation screen after requesting a refund. |
| `UserOfflineView` | `Routes.OFFLINE` | Global no-internet connectivity screen. |
| `AppWebView` | `Routes.APP_WEB_VIEW` | Generic in-app web view for external links. |
| `PaymentWebView` | `Routes.PAYMENT_WEB_VIEW` | Web view dedicated to online payment gateways. |
| `AppVideoPlayer` | `Routes.APP_VIDEO_PLAYER` | Generic video player interface. |
| `VideoPlayerScreen` | `Routes.VIDEO_PLAYER_PAGE` | Standalone video player screen. |
| `PdfViewerPage` | `Routes.PDF_VIEWER_PAGE` | Full-screen PDF viewer with caching. |
| `ImageViewerScreen` | `Routes.IMAGE_VIEWER_PAGE` | Full-screen image viewer. |

---

## 6. Core Infrastructure

### A. Networking
- **`api_helper_impl.dart`**: Central network client. Handles request formatting, common headers, and error parsing across all endpoints.
- **`token_refresh_interceptor.dart`**: HTTP interceptor that catches `401 Unauthorized` responses, calls the token refresh endpoint, and automatically retries the original request seamlessly.

### B. Storage & Persistence
- **`app_storage.dart`**: Wrapper around `flutter_secure_storage`. It securely stores the `AccessToken`, `RefreshToken`, `UserDetail`, offline content caches, and first-launch statuses to persist session data securely.
- **Offline Storage**: Employs a dedicated `_offlineSecureStorage` instance strictly for caching encrypted download metadata and offline course lists.

### C. Remote Configuration
- **`remote_config_service.dart`**: Integrates with Firebase Remote Config to fetch and activate dynamic configurations (like flags or variables) at app startup, allowing remote toggling of features without app updates.

### D. Push Notifications & Event Management
- **`notification_service.dart`**: Initializes Firebase Cloud Messaging (FCM) to handle incoming push notifications (background and foreground), parse payloads, and orchestrate tap-routing to specific modules.
- **`event_bus_service.dart`**: A lightweight event bus mechanism that enables decoupled, app-wide communication between independent controllers without tight coupling.
- **`connectivity_service.dart`**: Actively monitors the device's internet connection status and automatically triggers the global `UserOfflineView` when connectivity is lost.
- **`azure_communication_service.dart`**: Dedicated service residing under the Teams Call module for integrating with Azure Communication Services (ACS), enabling live class or meeting functionality natively.

---

## 7. API Catalog & Data Flow

All routes are **relative paths** appended to a base URL. The application utilizes environment-specific base URLs (configured via `.env`):
- e.g., `https://lms-uat-learn-api.regenesys.digital/api/V1`

---

### A. Authentication & User

| Endpoint | Method | Description |
|---|---|---|
| `/user/login/` | POST | Primary login endpoint (phone or email based). |
| `/user/verify-otp/` | POST | Verifies the OTP and returns session tokens (`AccessToken`, `RefreshToken`). |
| `/user/resend-otp/` | POST | Resends the OTP to the user's registered phone/email. |
| `/user/login-with-google/` | POST | Handles Google Single Sign-On (SSO) authentication. |
| `/user/exists` | GET | Validates if a user account already exists before onboarding. |
| `/user/logout` | POST | Invalidates the active session on the server. |
| `/user/` | GET | Fetches the full profile details for the authenticated user. |

---

### B. Student Dashboard & Academics

| Endpoint | Method | Description |
|---|---|---|
| `/student/` | GET | Fetches student overview data for the main dashboard. |
| `/student/session/` | GET | Retrieves active and upcoming live sessions for the student. |
| `/student/quizzes/` | GET | Lists all quizzes available for the student. |
| `/student/self-learn-details/` | GET | Fetches details for enrolled self-paced learning courses. |
| `/user-certificate/certificate/download/` | GET | Downloads the academic certificate (returns PDF URL). |

---

### C. Finance & Payments

| Endpoint | Method | Description |
|---|---|---|
| `/external/bnp/customer-account/list` | GET | Fetches the list of customer fee accounts and payment statuses. |
| `/external/bnp/customer-account/info` | GET | Retrieves detailed information for a specific fee account. |
| `/external/bnp/recent-transaction` | GET | Fetches the recent payment transaction history. |
| `/external/bnp/customer-statement` | GET | Retrieves the customer's financial statement. |
| `/external/bnp/bank-details` | GET | Fetches official bank details for manual EFT/offline payments. |
| `/external/bnp/file-upload-url` | GET | Retrieves an S3 signed URL to upload offline payment proof. |
| `/external/bnp/offline-payment` | POST | Submits the uploaded offline payment proof for verification. |
| `/external/bnp/online-payment` | POST | Initiates the online payment gateway transaction. |
| `/external/payment-log/transaction` | GET | Checks the real-time status of a pending online payment. |
| `/batch-user/overdue-status` | GET | Checks if the student has overdue fees that block LMS access. |

---

### D. Assignments & Capstone

| Endpoint | Method | Description |
|---|---|---|
| `/assignment/draft-assignment/` | POST | Saves an assignment locally/remotely as a draft before final submission. |
| `/assignment/submit/` | POST | Submits a completed assignment for grading. |
| `/student/assignment-report/` | GET | Retrieves grades and feedback for submitted assignments. |
| `/quiz/capstone/capstone-project/` | GET | Fetches details and requirements for the capstone project. |
| `/quiz/capstone/draft-capstone/` | POST | Saves the capstone project progress as a draft. |

---

### E. Quizzes & Assessments

| Endpoint | Method | Description |
|---|---|---|
| `/quiz/start/` | POST | Initiates a new quiz session and starts the timer. |
| `/quiz/submit/` | POST | Submits quiz answers for automated grading. |
| `/report/quiz/` | GET | Retrieves the detailed performance report for a completed quiz. |
| `/quiz/attempt-request/retest/` | POST | Submits a formal request to retake a failed quiz. |

---

### F. Push Notifications

| Endpoint | Method | Description |
|---|---|---|
| `/user/fcm-tokens` | POST | Registers the device's FCM token with the backend. |
| `/external/comms/push-notification/filter/list` | GET | Fetches the user's push notification inbox history. |
| `/external/comms/push-notification/unread-count` | GET | Retrieves the badge count of unread notifications. |
| `/external/comms/push-notification/mark-as-read/` | PATCH | Marks a specific notification as read. |

---

### G. Profile & Miscellaneous

| Endpoint | Method | Description |
|---|---|---|
| `/config?configName=FAQ` | GET | Fetches dynamic FAQ content for the Help Center. |
| `/config?configName=LMS_SUPPORT` | GET | Fetches contact details for LMS support. |
| `/user/fcm-tokens/get-dnd-status` | GET | Checks if the user has Do-Not-Disturb (DND) mode enabled. |
| `/user/fcm-tokens/update-dnd-status` | POST | Updates the DND mode preference. |
| `/common/s3/file-upload/` | POST | Retrieves an S3 signed URL for profile picture uploads. |
| `/feedback/` | POST | Submits in-app feedback or course ratings. |

---

## 8. Logical Data Flow (Cross-Module)

```
1. IDENTITY PHASE
   └─ Login (OTP or Email) → saves to AppStorage:
         AccessToken, RefreshToken, UserDetail (contains dregNo, email, roles)

2. ROUTING PHASE (SplashController → AuthRepository)
   └─ Reads isLoggedIn and cachedUser from AppStorage
         ├─ Has valid dregNo and STUDENT role → Route to STUDENT_DASHBOARD
         └─ No dregNo (Lead) → Route to LOGIN (Android) or SUBSCRIPTION_COURSE (iOS)

3. DASHBOARD PHASE (StudentDashboardController.loadDashboard)
   ├─ Step 1 (Config & FCM): Fetch Remote Config (Refer & Earn) and sync FCM token in background.
   ├─ Step 2 (Parallel Load): Executes via `Future.wait`:
   │     ├─ `loadCourses()` → Fetches enrolled courses and determines if all are "self-learn".
   │     └─ `loadSessions()` → Fetches "SCHEDULED" and "INPROGRESS" live sessions.
   └─ Step 3 (Pre-fetch): Silently pre-fetches "COMPLETED" sessions to cache for tab switching.

4. BACKGROUND TASKS (after dashboard load)
   ├─ `ProfileController.fetchUserProfileDetails()` → Fetches full profile to ensure `dregNo` is valid.
   │     └─ If `dregNo` is missing or profile isn't updated, redirects to `LOGIN` or `PROFILE`.
   └─ `AppScaffoldController.initializeFeeAndPayment()` → Fetches Fee & Payment data if enabled.
```

**Key data dependencies:**
- **`dregNo` (Student Registration Number)** — required to determine if the user is a Lead (prospect) or a fully enrolled Student, driving all routing logic.
- **`fcmToken`** — generated locally on device and synced in the background to enable push notifications.
- **`isFeeAndPaymentEnabled`** — a remote configuration flag that dictates whether the Fee & Payment module and its background synchronization should be initialized on launch.

---

## 9. Optimization Layer (Instant-On Architecture)

The application employs several strategies to ensure a seamless, "instant-on" user experience by eliminating redundant network latency and UI flickering.

### A. Memory-First Rendering & Shimmer Suppression

The `StudentDashboardController` utilizes an in-memory caching mechanism to store data from previous fetches:

```dart
// Example from StudentDashboardController
if (_cachedCourseModel != null && !forceRefresh) {
  courseModel = _cachedCourseModel;
  hasCache = true;
  isCoursesLoading.value = false; // Instantly hides shimmer
}
```

**Shimmer Suppression**: If `hasCache` is true, the `isLoading` and `isCoursesLoading` flags are explicitly kept false. The app instantly renders the cached courses and sessions on launch, entirely skipping the skeleton/shimmer loaders.

### B. Silent Background Synchronization

When a user opens the dashboard, the app displays the cached data immediately, but still triggers the API calls in the background. Once the fresh data returns, the app silently replaces the models and calls `.refresh()` to update the UI without disrupting the user's flow or showing a loading spinner.

- **Pre-fetching**: `preFetchCompletedSessions()` is executed silently in the background during the initial dashboard load, ensuring that if the user taps the "Completed" tab, the data is already available instantly.

### C. Parallel Fetching

The app avoids sequential network requests during startup. `StudentDashboardController.loadDashboard()` fires the heaviest endpoints concurrently:

```dart
await Future.wait([
  loadCourses(...),
  loadSessions(...),
]);
```

### D. Permanent Global Controllers

Several core controllers are registered with `permanent: true` via GetX to prevent state destruction and subsequent re-fetching during standard navigation:

| Controller | Purpose / Impact |
|---|---|
| `AppScaffoldController` | Maintains the `BottomNavigationBar` state and tab index, avoiding re-initialization of the UI scaffold when switching modules. |
| `StudentDashboardController` | Retains the entire dashboard state (cached models, tab selection, payment banners) when navigating to deeper views (e.g., Profile or Course Details) and returning. |
| `FeeAndPaymentController` | Caches fee states, overdue limits, and transaction statuses globally so banners load instantly without an API call. |
| `NotificationController` | Keeps the FCM push notification listeners active globally at all times. |

---

## 10. Feature Flags (Firebase Remote Config)

The application utilizes Firebase Remote Config to toggle features dynamically based on the current environment and platform.

**Remote Config Key:** `lms_feature_flags`
*(Evaluated dynamically via `ApiRoutes.getLmsFeatureFlagRemoteConfigKey()`)*

### A. Evaluated Flags

The Remote Config JSON structure evaluates flags using the path: `featureFlags['environments'][currentEnv][platform]['flag_name']`. The application actively parses and acts on the following flags:

| Flag Key | Effect & Usage |
|---|---|
| `fee_and_payment` | Drives `isFeesAndPaymentsEnabled()`. If `true`, the `FeeAndPaymentController` is initialized globally, and the "Fees" tab is displayed in the bottom navigation bar (`AppScaffoldController`). |
| `refer_and_earn` | Drives `isReferAndEarnEnabled()`. Evaluated at dashboard launch to determine whether the "Refer & Earn" feature card/CTA should be visible. |

> **Documentation Verification Notice**:
> Older documentation references to flags such as `apply_qulification` and `web_resource` are completely obsolete. Those keys are neither parsed nor utilized anywhere in the current application logic or `AppConfigService`.

### B. Persistence & Fallbacks

- When the `fee_and_payment` flag is fetched successfully, it is instantly persisted to the offline cache via `AppStorage.saveIsFeeAndPaymentEnabled()`.
- If the Remote Config fetch fails or returns empty data, both features aggressively default to `true` to ensure the application does not break core functionality.

### C. App Update Enforcement

In addition to feature flags, `AppConfigService` listens to environment-specific config keys (e.g., `android_config_UAT`, `ios_config_Prod`) to evaluate `AppVersionConfig`. This strictly drives the **Soft Update** and **Hard Update** (blocking) bottom sheets when a new application version is deployed to the respective app stores.

---

## 11. CI/CD & Environments

### A. Environment Configuration

The application utilizes a single-domain API structure per environment, driven entirely by a local `.env` configuration file. There is no separate "Auth Base URL" mapping in the current implementation.

| Environment (`ACTIVE_ENVIRONMENT`) | Base URL |
|---|---|
| `dev` | `https://lms-dev-learn-api.regenesys.digital/api/V1` |
| `uat` *(Default Fallback)* | `https://lms-uat-learn-api.regenesys.digital/api/V1` |
| `stag` | `https://lms-staging-learn-api.regenesys.digital/api/V1` |
| `prod` | `https://learn-api.regenesys.digital/api/V1` |
| `fnp` | `https://dev-fnp-api.regenesys.digital/api/V1` |

Jenkins CI pipeline runs `flutter analyze` and `dart format --set-exit-if-changed` on every push to `lms_dev`.
