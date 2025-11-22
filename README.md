# Efeedor Healthcare Feedback System

A comprehensive healthcare feedback and management system built with Flutter (mobile/web) and CodeIgniter backend. This application enables healthcare facilities to collect patient feedback, manage incidents, conduct audits, and track quality metrics.

## 📱 Features

### Core Functionality
- **Multi-tenant Domain Support**: Each healthcare facility has its own domain (e.g., `demo.efeedor.com`)
- **Device Approval System**: Secure device registration with admin approval workflow
- **Auto-login**: Persistent login with 15-day inactivity auto-logout
- **Cross-platform**: Supports Android, iOS, and Web browsers

### Healthcare Modules
- **IP Discharge Feedback**: Collect feedback from in-patient discharge experiences
- **Outpatient Feedback**: Gather outpatient visit feedback
- **IP Concern/Request**: Raise concerns or submit requests for in-patients
- **Internal Request Management**: Create and track internal department requests
- **Incident Reporting**: Document and report healthcare incidents
- **Quality KPI Forms**: Access quality key performance indicator forms
- **Healthcare Audit Forms**: Complete audit and compliance forms
- **Departmental Monthly Reports**: View and submit monthly reports
- **PREM Forms**: Patient Reported Experience Measures forms
- **Asset Registration**: Register and manage hospital assets

## 🏗️ Architecture

### Frontend (Flutter)
- **Framework**: Flutter 3.x
- **State Management**: StatefulWidget with SharedPreferences
- **Platforms**: Android, iOS, Web
- **Key Packages**:
  - `device_info_plus`: Device information collection
  - `shared_preferences`: Local data persistence
  - `http`: API communication
  - `webview_flutter`: Embedded web content
  - `google_maps_flutter`: Location services

### Backend (CodeIgniter)
- **Framework**: CodeIgniter 3.x
- **Database**: MySQL
- **API**: RESTful JSON APIs
- **Features**:
  - Device registration and approval
  - Multi-tenant support
  - CORS enabled for cross-origin requests

## 📋 Prerequisites

### For Flutter Development
- Flutter SDK (>=2.12.0 <3.0.0)
- Dart SDK
- Android Studio / Xcode (for mobile development)
- VS Code or Android Studio (recommended IDE)

### For Backend Development
- PHP 7.4 or higher
- MySQL 5.7 or higher
- Apache/Nginx web server
- CodeIgniter 3.x

## 🚀 Getting Started

### 1. Clone the Repository

```bash
git clone <repository-url>
cd flutter_app_buildapk
```

### 2. Flutter Setup

```bash
# Install dependencies
flutter pub get

# Run on connected device/emulator
flutter run

# Build APK for Android
flutter build apk --release

# Build for iOS
flutter build ios --release

# Build for Web
flutter build web
```

### 3. Backend Setup

#### Database Configuration

1. Create a MySQL database:
```sql
CREATE DATABASE efeedor_db;
```

2. Import database schemas:
```bash
mysql -u your_user -p efeedor_db < backend_sql/user_devices_table.sql
mysql -u your_user -p efeedor_db < backend_sql/device_requests_table.sql
```

3. Configure database connection in `backend_codeigniter/application/config/database.php`:
```php
$db['default'] = array(
    'dsn'   => '',
    'hostname' => 'localhost',
    'username' => 'your_username',
    'password' => 'your_password',
    'database' => 'efeedor_db',
    // ... other config
);
```

#### CodeIgniter Configuration

1. Copy backend files to your CodeIgniter installation:
```bash
cp -r backend_codeigniter/application/controllers/* /path/to/codeigniter/application/controllers/
cp -r backend_codeigniter/application/models/* /path/to/codeigniter/application/models/
cp -r backend_codeigniter/application/views/* /path/to/codeigniter/application/views/
```

2. Add routes to `application/config/routes.php`:
```php
// Device Registration Routes
$route['api/device/register'] = 'DeviceController/register';
$route['api/device/verify'] = 'DeviceController/verify';

// Device Approval Routes
$route['deviceApproval/requestAccess'] = 'DeviceApprovalController/requestAccess';
$route['deviceApproval/checkStatus'] = 'DeviceApprovalController/checkStatus';
```

3. Configure base URL in `application/config/config.php`:
```php
$config['base_url'] = 'https://your-domain.efeedor.com/';
```

## 🔐 Device Approval Flow

### Overview
The app implements a secure device approval system where:
1. User logs in with credentials
2. Device information is collected and sent to backend
3. Admin approves/blocks the device
4. Approved devices can access the dashboard directly on future logins

### Flow Diagram

```
User Login → Device Registration → Admin Approval → Dashboard Access
     ↓              ↓                    ↓
  Domain      Device Info         Approval Status
  Entry       Collection         (pending/approved/blocked)
```

### Key Features
- **48-hour approval window**: Requests expire after 48 hours if not approved
- **Persistent approval**: Once approved, device remains approved (one-time approval)
- **Auto-resume**: App remembers approval state and resumes from waiting page if needed
- **Cross-platform device detection**: Accurate device info for Android, iOS, and Web

## 📱 App Flow

### Initial Launch
1. **Splash Screen** → Checks login state and device approval
2. **Onboarding** (first time) → Introduction screens
3. **Domain Entry** → User enters domain (e.g., "demo")
4. **Login** → User credentials
5. **Device Approval** → Waiting for admin approval (if not already approved)
6. **Dashboard** → Main application interface

### Subsequent Launches
- If logged in and approved → Direct to Dashboard
- If domain exists but not logged in → Direct to Login
- If waiting for approval → Resume waiting page

## 🔧 Configuration

### Flutter Configuration

#### Domain Validation API
Update `lib/config/constant.dart`:
```dart
const String domainValidationApi = 'https://your-api.com/domains';
```

#### API Base URLs
The app automatically constructs API URLs based on domain:
- Format: `https://{domain}.efeedor.com/api/...`
- Example: `https://demo.efeedor.com/api/device/register`

### Backend Configuration

#### CORS Settings
CORS is enabled in controllers. If you need to restrict origins:
```php
header('Access-Control-Allow-Origin: https://your-app-domain.com');
```

#### Multi-tenant Database (Optional)
If using separate databases per tenant, update `DeviceController.php`:
```php
private function switch_tenant_database($tenant_id) {
    $tenant_db_map = array(
        'demo' => 'efeedor_demo',
        'krr' => 'efeedor_krr',
    );
    // Implementation...
}
```

## 📡 API Endpoints

### Device Registration
- `POST /api/device/register` - Register a new device
- `POST /api/device/verify` - Verify registration token

### Device Approval
- `POST /deviceApproval/requestAccess` - Request device approval
- `GET /deviceApproval/checkStatus` - Check approval status

### Authentication
- `POST /api/login` - User login

See `backend_codeigniter/INTEGRATION_GUIDE.md` for detailed API documentation.

## 🗂️ Project Structure

```
flutter_app_buildapk/
├── lib/
│   ├── config/              # App configuration and constants
│   ├── services/            # Business logic services
│   │   ├── device_service.dart
│   │   ├── device_info_service.dart
│   │   └── ip_service.dart
│   ├── ui/                  # UI screens
│   │   ├── splash_screen.dart
│   │   ├── domain_login_page.dart
│   │   ├── signin.dart
│   │   ├── waiting_approval_page.dart
│   │   └── home_module_button.dart
│   └── widgets/             # Reusable widgets
├── backend_codeigniter/
│   ├── application/
│   │   ├── controllers/     # API controllers
│   │   ├── models/          # Database models
│   │   └── views/           # Admin views
│   └── config/              # Route configurations
├── backend_sql/              # Database schemas
├── assets/                   # Images and resources
└── android/ios/web/         # Platform-specific code
```

## 🔒 Security Features

- **Device Fingerprinting**: Unique device identification
- **IP Address Tracking**: Records device IP for security
- **Admin Approval**: All devices require admin approval
- **Token-based Registration**: Secure token generation for device registration
- **Session Management**: 15-day inactivity auto-logout
- **Domain Validation**: Domain verification before access

## 🧪 Testing

### Flutter Tests
```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/
```

### API Testing
Use the provided curl scripts:
```bash
cd backend_codeigniter
bash TEST_API_CURL.sh
```

## 📦 Building for Production

### Android APK
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle (for Play Store)
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS
```bash
flutter build ios --release
# Then open Xcode to archive and upload
```

### Web
```bash
flutter build web --release
# Output: build/web/
```

## 🐛 Troubleshooting

### Common Issues

#### Device Approval Not Working
- Check backend routes are properly configured
- Verify database tables exist
- Check CORS headers in backend
- Ensure domain is correctly set in SharedPreferences

#### Login Issues
- Verify API endpoints are accessible
- Check network connectivity
- Review backend logs for errors
- Ensure domain validation API is working

#### Build Errors
- Run `flutter clean` and `flutter pub get`
- Check Flutter SDK version compatibility
- Verify all dependencies in `pubspec.yaml`

## 📚 Documentation

- [Device Approval Implementation Guide](DEVICE_APPROVAL_IMPLEMENTATION.md)
- [Backend Integration Guide](backend_codeigniter/INTEGRATION_GUIDE.md)
- [Routes Setup](backend_codeigniter/ROUTES_SETUP.md)
- [Implementation Summary](IMPLEMENTATION_SUMMARY.md)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is proprietary software. All rights reserved.

## 👥 Support

For support and questions:
- Create an issue in the repository
- Contact the development team
- Check the documentation files in the project

## 🔄 Version History

- **v3.0.3+6** - Current version
  - Device approval system
  - Multi-tenant support
  - Auto-login with inactivity timeout
  - Cross-platform device detection
  - Enhanced security features

## 🎯 Roadmap

- [ ] Push notifications for approval status
- [ ] Offline mode support
- [ ] Enhanced analytics dashboard
- [ ] Multi-language support
- [ ] Biometric authentication
- [ ] Advanced reporting features

---

**Built with ❤️ for Healthcare Excellence**
