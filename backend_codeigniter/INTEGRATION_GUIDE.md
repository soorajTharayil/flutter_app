# Device Registration Integration Guide

This guide explains how to integrate the Token-Based Device Registration system into your CodeIgniter application.

## 📁 File Structure

```
application/
├── controllers/
│   └── DeviceController.php          # API endpoints for device registration
├── models/
│   └── Device_model.php              # Database operations
├── views/
│   └── admin/
│       └── device_list.php           # Admin panel view
└── config/
    └── routes_device.php             # Route definitions (add to routes.php)
```

## 🗄️ Database Setup

1. **Run the SQL script** to create the `user_devices` table:
   ```bash
   mysql -u your_user -p your_database < backend_sql/user_devices_table.sql
   ```
   
   Or import via phpMyAdmin:
   - Open phpMyAdmin
   - Select your database
   - Go to SQL tab
   - Paste the contents of `user_devices_table.sql`
   - Execute

## 🔧 CodeIgniter Configuration

### Step 1: Copy Files

Copy the following files to your CodeIgniter project:

1. `application/controllers/DeviceController.php` → `your_project/application/controllers/`
2. `application/models/Device_model.php` → `your_project/application/models/`
3. `application/views/admin/device_list.php` → `your_project/application/views/admin/`

### Step 2: Configure Routes

Add these routes to `application/config/routes.php`:

```php
// Device Registration API Routes
$route['api/device/register'] = 'DeviceController/register';
$route['api/device/verify'] = 'DeviceController/verify';
$route['api/device/admin_devices'] = 'DeviceController/admin_devices';
$route['admin/devices'] = 'DeviceController/admin_view';
```

### Step 3: Multi-Tenant Database (Optional)

If you have separate databases per tenant, modify the `switch_tenant_database()` method in `DeviceController.php`:

```php
private function switch_tenant_database($tenant_id) {
    $tenant_db_map = array(
        'demo' => 'efeedor_demo',
        'krr' => 'efeedor_krr',
        // Add more tenants
    );
    
    if (isset($tenant_db_map[$tenant_id])) {
        $db_config = $this->config->item('database');
        $db_config['database'] = $tenant_db_map[$tenant_id];
        $this->load->database($db_config);
    }
}
```

### Step 4: Add Admin Authentication (Recommended)

In `DeviceController.php`, uncomment and implement the admin authentication check in `admin_devices()`:

```php
public function admin_devices() {
    // Add your authentication logic here
    if (!$this->session->userdata('is_admin')) {
        $this->output->set_status_header(403);
        echo json_encode(array('status' => 'error', 'message' => 'Unauthorized'));
        return;
    }
    // ... rest of the method
}
```

Also add authentication to `admin_view()`:

```php
public function admin_view() {
    // Add your authentication logic here
    if (!$this->session->userdata('is_admin')) {
        redirect('login');
        return;
    }
    // ... rest of the method
}
```

### Step 5: Verify Admin View Method

The `admin_view()` method is already included in `DeviceController.php`. It:
- Gets unique tenants for filter dropdown
- Loads the admin view with device data
- Displays the device_list.php view

## 🧪 Testing the API

### Test Device Registration

```bash
curl -X POST https://demo.efeedor.com/api/device/register \
  -H "Content-Type: application/json" \
  -d '{
    "domain": "demo",
    "device_id": "test-device-123",
    "device_name": "Samsung Galaxy S21",
    "platform": "Android",
    "os_version": "12 (SDK 31)"
  }'
```

**Expected Response:**
```json
{
  "status": "success",
  "message": "Device registered successfully",
  "token": "REG-ABCD1234"
}
```

### Test Token Verification

```bash
curl -X POST https://demo.efeedor.com/api/device/verify \
  -H "Content-Type: application/json" \
  -d '{
    "device_id": "test-device-123",
    "token": "REG-ABCD1234"
  }'
```

**Expected Response:**
```json
{
  "status": "success",
  "message": "Token verified successfully. Device approved."
}
```

### Test Admin Devices List (JSON API)

```bash
curl https://demo.efeedor.com/api/device/admin_devices
```

**With Filters:**
```bash
curl "https://demo.efeedor.com/api/device/admin_devices?status=pending"
curl "https://demo.efeedor.com/api/device/admin_devices?tenant_id=demo"
```

### Test Admin View (HTML)

Visit in browser:
```
https://demo.efeedor.com/admin/devices
```

## 📱 Flutter Integration

The Flutter app is already configured to:
1. Register device when user enters domain
2. Show token entry screen
3. Verify token and navigate to login

Make sure the Flutter app points to the correct API endpoints in `DeviceService.dart`.

**Flow:**
1. User enters domain → Domain validation
2. Device registration → Backend generates token
3. Token Entry Screen → User enters token from IT admin
4. Token verification → Device approved
5. Navigate to Login Screen

## 🔒 Security Considerations

1. **Add Rate Limiting**: Prevent brute force token attempts
   ```php
   // Example using CodeIgniter's throttling
   $this->load->library('throttle');
   if (!$this->throttle->check('device_verify', 5, 60)) {
       // Max 5 attempts per 60 seconds
       $this->output->set_status_header(429);
       echo json_encode(array('status' => 'error', 'message' => 'Too many attempts'));
       return;
   }
   ```

2. **HTTPS Only**: Ensure all API calls use HTTPS in production

3. **Admin Authentication**: Protect admin endpoints with session or JWT authentication

4. **Token Expiry**: Tokens expire after 30 minutes or first use

5. **IP Logging**: IP addresses are logged for security auditing

6. **Input Validation**: All inputs are validated and sanitized

## 🧹 Maintenance

### Cleanup Expired Tokens (Cron Job)

Add this to your cron jobs to clean up expired tokens daily:

```bash
# Run daily at 2 AM
0 2 * * * php /path/to/your/project/index.php DeviceController cleanup_expired_tokens
```

Or create a separate cleanup script:

```php
// application/controllers/CronController.php
public function cleanup_devices() {
    $this->load->model('Device_model');
    $count = $this->Device_model->cleanup_expired_tokens();
    echo "Cleaned up $count expired tokens\n";
}
```

Then add to cron:
```bash
0 2 * * * php /path/to/your/project/index.php CronController cleanup_devices
```

## 📊 Database Queries

### View Pending Devices
```sql
SELECT * FROM user_devices WHERE status = 'pending' ORDER BY created_at DESC;
```

### View Approved Devices
```sql
SELECT * FROM user_devices WHERE status = 'approved' ORDER BY created_at DESC;
```

### Find Device by Token
```sql
SELECT * FROM user_devices WHERE registration_token = 'REG-ABCD1234';
```

### Find Devices by Tenant
```sql
SELECT * FROM user_devices WHERE tenant_id = 'demo' ORDER BY created_at DESC;
```

### Count Devices by Status
```sql
SELECT status, COUNT(*) as count 
FROM user_devices 
GROUP BY status;
```

### Find Expired Tokens
```sql
SELECT * FROM user_devices 
WHERE token_expiry < NOW() 
AND token_used = 0 
AND status = 'pending';
```

## 🐛 Troubleshooting

### Issue: "Invalid JSON input"
- **Cause**: Request body is not valid JSON or Content-Type header is missing
- **Solution**: 
  - Ensure `Content-Type: application/json` header is set
  - Verify JSON syntax is valid
  - Check that `file_get_contents('php://input')` is working

### Issue: "Domain not found"
- **Cause**: Tenant ID doesn't match database configuration
- **Solution**: 
  - Ensure tenant_id matches your database tenant configuration
  - Check multi-tenant database switching logic
  - Verify domain validation is working correctly

### Issue: "Token expired"
- **Cause**: Token has passed its 30-minute expiry time
- **Solution**: 
  - Tokens expire after 30 minutes
  - Generate a new token by re-registering the device
  - Check server time is correct

### Issue: "Token already used"
- **Cause**: Token has already been used for verification
- **Solution**: 
  - Each token can only be used once
  - Register device again to get a new token
  - Check `token_used` flag in database

### Issue: "Failed to register device"
- **Cause**: Database connection issue or table doesn't exist
- **Solution**: 
  - Verify database connection is working
  - Ensure `user_devices` table exists
  - Check database permissions
  - Review error logs

### Issue: Admin view shows empty
- **Cause**: No devices registered or JavaScript error
- **Solution**: 
  - Check browser console for JavaScript errors
  - Verify API endpoint `/api/device/admin_devices` is accessible
  - Check CORS settings if accessing from different domain
  - Ensure devices exist in database

### Issue: CORS errors in browser
- **Cause**: Cross-origin requests blocked
- **Solution**: 
  - Add CORS headers in `DeviceController.php` constructor (already included)
  - Configure server to allow CORS
  - For production, specify allowed origins instead of `*`

## 📝 Notes

- **Token Format**: Tokens are automatically generated in format: `REG-XXXXXXXX` (8 alphanumeric characters)
- **Device Registration**: Creates new record or updates existing device for the same tenant
- **Token Expiry**: Set to 30 minutes from creation time
- **Status Values**: Can be `pending`, `approved`, or `blocked`
- **Unique Constraint**: One device per tenant (enforced by `unique_device_tenant` index)
- **IP Address**: Automatically captured from request headers
- **Timestamps**: `created_at` and `updated_at` are automatically managed

## 🔄 API Response Formats

### Success Response (Standard)
```json
{
  "status": "success",
  "message": "Operation completed successfully",
  "data": { ... }
}
```

### Error Response (Standard)
```json
{
  "status": "error",
  "message": "Error description here"
}
```

### Device Registration Response
```json
{
  "status": "success",
  "message": "Device registered successfully",
  "token": "REG-ABCD1234"
}
```

### Token Verification Response
```json
{
  "status": "success",
  "message": "Token verified successfully. Device approved."
}
```

### Admin Devices List Response
```json
{
  "status": "success",
  "count": 10,
  "data": [
    {
      "id": 1,
      "tenant_id": "demo",
      "device_id": "abc123...",
      "device_name": "Samsung Galaxy S21",
      "platform": "Android",
      "os_version": "12 (SDK 31)",
      "ip_address": "192.168.1.1",
      "registration_token": "REG-ABCD1234",
      "token_expiry": "2025-01-15 11:00:00",
      "token_used": 0,
      "status": "pending",
      "created_at": "2025-01-15 10:30:00",
      "updated_at": "2025-01-15 10:30:00"
    }
  ]
}
```

## ✅ Checklist

Before going live, ensure:

- [ ] Database table `user_devices` is created
- [ ] All files are copied to correct locations
- [ ] Routes are added to `routes.php`
- [ ] Admin authentication is implemented
- [ ] Multi-tenant database switching is configured (if needed)
- [ ] HTTPS is enabled for production
- [ ] Rate limiting is implemented
- [ ] CORS is properly configured
- [ ] Error logging is enabled
- [ ] Cron job for cleanup is set up
- [ ] Flutter app is tested end-to-end
- [ ] Admin panel is accessible and functional

## 📞 Support

For issues or questions:
1. Check the troubleshooting section above
2. Review error logs in CodeIgniter
3. Check browser console for JavaScript errors
4. Verify database connectivity
5. Test API endpoints with CURL or Postman

---

**Integration Complete!** Your Token-Based Device Registration system is ready to use.

