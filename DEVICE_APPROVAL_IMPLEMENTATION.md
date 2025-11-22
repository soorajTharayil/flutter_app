# Device Approval Flow Implementation Guide

## Overview

This implementation replaces the old token-based device registration with a new admin approval flow. Users login, and their device requests are sent to admins for approval. Once approved, devices are automatically approved for future logins.

## Architecture

### Flow Diagram

```
Domain Entry → Login → Device Request Created → Waiting Page (Polling)
                                                      ↓
                                              Admin Approves/Blocks
                                                      ↓
                                              Dashboard / Error Message
```

## Backend Setup (CodeIgniter 3)

### 1. Database Setup

Run the SQL script to create the required tables:

```bash
mysql -u your_user -p your_database < backend_sql/device_requests_table.sql
```

This creates two tables:
- `device_requests`: Stores device approval requests
- `approved_devices`: Tracks one-time approved devices

### 2. CodeIgniter Configuration

#### Add Routes

Add these routes to `application/config/routes.php`:

```php
// Include device request routes
require_once(APPPATH . 'config/routes_device_requests.php');
```

Or manually add:

```php
$route['api/login'] = 'LoginController/login';
$route['api/check-device-status'] = 'DeviceRequestController/check_device_status';
$route['api/device/approve'] = 'DeviceRequestController/approve';
$route['api/device/block'] = 'DeviceRequestController/block';
$route['api/device/requests'] = 'DeviceRequestController/get_requests';
$route['admin/device-requests'] = 'DeviceRequestController/admin_view';
```

#### Update LoginController

**Important**: You need to update the `validate_login()` method in `LoginController.php` to use your actual user authentication logic. Currently, it's a placeholder.

Replace the `validate_login()` method with your actual user table query and password verification.

### 3. Admin Authentication

Add authentication checks to:
- `DeviceRequestController::approve()`
- `DeviceRequestController::block()`
- `DeviceRequestController::get_requests()`
- `DeviceRequestController::admin_view()`

Example:
```php
if (!$this->session->userdata('is_admin')) {
    $this->output->set_status_header(403);
    echo json_encode(array('status' => 'error', 'message' => 'Unauthorized'));
    return;
}
```

### 4. Timeout Cleanup (Cron Job)

Create a cron job to mark expired requests (10 minutes):

```bash
# Edit crontab
crontab -e

# Add this line (runs every 5 minutes)
*/5 * * * * php /path/to/your/codeigniter/index.php DeviceRequestController cleanup_expired
```

Or create a standalone cleanup script:

**File: `application/controllers/CronController.php`**
```php
<?php
defined('BASEPATH') or exit('No direct script access allowed');

class CronController extends CI_Controller {
    public function cleanup_expired() {
        $this->load->model('DeviceRequest_model');
        $count = $this->DeviceRequest_model->mark_expired_requests();
        echo "Marked $count requests as expired\n";
    }
}
```

## Flutter Setup

### 1. Dependencies

Ensure these packages are in `pubspec.yaml`:

```yaml
dependencies:
  http: ^1.1.0
  shared_preferences: ^2.2.0
  device_info_plus: ^9.0.0
  fluttertoast: ^8.2.0
```

### 2. API Endpoints

The Flutter app uses these endpoints:

- `POST /api/login` - Login with device info
- `GET /api/check-device-status?device_id=XXX&domain=YYY` - Check approval status
- `POST /api/device/approve` - Approve device (admin)
- `POST /api/device/block` - Block device (admin)

### 3. Flow

1. **Domain Entry**: User enters domain → Validates → Navigates to Login
2. **Login**: User enters email/password → Creates device request → Shows waiting page
3. **Waiting Page**: Polls every 5 seconds for approval status
4. **Approval**: Admin approves → Flutter receives status → Navigates to dashboard
5. **One-Time Approval**: Next login with same device → Directly goes to dashboard

## API Endpoints Reference

### POST /api/login

**Request:**
```json
{
  "email": "user@example.com",
  "password": "password123",
  "device_id": "abc123...",
  "device_name": "Samsung Galaxy S21",
  "platform": "Android",
  "ip_address": "192.168.1.1",
  "domain": "demo"
}
```

**Response (Approved Device):**
```json
{
  "status": "approved",
  "userid": "123",
  "email": "user@example.com",
  ... (other user data)
}
```

**Response (Waiting Approval):**
```json
{
  "status": "waiting_approval",
  "message": "Login successful, waiting for administrator approval"
}
```

### GET /api/check-device-status

**Query Parameters:**
- `device_id`: Device identifier
- `domain`: Domain identifier

**Response:**
```json
{
  "status": "approved" | "pending" | "blocked" | "expired",
  "message": "Status message"
}
```

### POST /api/device/approve

**Request:**
```json
{
  "request_id": 123
}
```

**Response:**
```json
{
  "status": "success",
  "message": "Device approved successfully"
}
```

### POST /api/device/block

**Request:**
```json
{
  "request_id": 123
}
```

**Response:**
```json
{
  "status": "success",
  "message": "Device blocked successfully"
}
```

## Admin Panel

Access the admin panel at:
```
https://your-domain.efeedor.com/admin/device-requests
```

Features:
- View all device requests
- Filter by domain and status
- Approve/Block devices
- Auto-refresh every 30 seconds
- Real-time status updates

## Timeout Logic

- Requests expire after **10 minutes** from creation
- Expired requests are automatically marked as "expired"
- Flutter app shows expiration message and redirects to login
- Cron job should run every 5 minutes to mark expired requests

## One-Time Approval

- Once a device is approved, it's added to `approved_devices` table
- Future logins with the same `device_id` and `domain` skip approval
- User goes directly to dashboard

## Security Considerations

1. **Admin Authentication**: Add proper authentication to admin endpoints
2. **Rate Limiting**: Consider adding rate limiting to prevent abuse
3. **IP Validation**: Backend gets IP from request headers
4. **Device ID**: Device ID is generated by device_info_plus (persistent per device)
5. **HTTPS**: Always use HTTPS in production

## Testing

### Test Scenarios

1. **New Device Login**:
   - Login with new device → Should show waiting page
   - Admin approves → Should navigate to dashboard

2. **Approved Device Login**:
   - Login with previously approved device → Should go directly to dashboard

3. **Blocked Device**:
   - Admin blocks device → Flutter should show blocked message

4. **Expired Request**:
   - Wait 10 minutes → Should show expired message

5. **Polling**:
   - Check that polling happens every 5 seconds
   - Verify timeout after 10 minutes

## Troubleshooting

### Backend Issues

1. **404 on API endpoints**: Check routes.php configuration
2. **Database errors**: Verify table creation and column names
3. **Login not working**: Update `validate_login()` method with actual logic

### Flutter Issues

1. **Device ID not found**: Ensure device_info_plus is properly configured
2. **Polling not working**: Check network connectivity and API endpoint
3. **Navigation issues**: Verify all imports and route definitions

## Migration from Old System

If migrating from the old token-based system:

1. Keep old `user_devices` table for reference
2. New system uses `device_requests` and `approved_devices`
3. Old tokens are no longer used
4. Users will need to re-approve devices through new flow

## Support

For issues or questions, check:
- Code comments in controllers and models
- Flutter service files for API integration
- Admin view HTML for UI customization

