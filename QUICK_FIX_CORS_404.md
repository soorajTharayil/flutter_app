# Quick Fix for CORS and 404 Errors

## Problem
- CORS policy blocking requests
- 404 Not Found errors for deviceApproval endpoints

## Solution Steps

### Step 1: Add Routes to CodeIgniter

**CRITICAL**: You must add the routes to your main `routes.php` file.

Open `application/config/routes.php` and add at the end:

```php
// Device Approval Routes
require_once(APPPATH . 'config/routes_device_requests.php');
```

OR add directly:

```php
$route['deviceApproval/requestAccess'] = 'DeviceApprovalController/requestAccess';
$route['deviceApproval/checkStatus'] = 'DeviceApprovalController/checkStatus';
```

### Step 2: Check URL Format

The Flutter app now uses:
- `https://demo.efeedor.com/index.php/deviceApproval/requestAccess`
- `https://demo.efeedor.com/index.php/deviceApproval/checkStatus`

**If your server removes `index.php` from URLs** (via .htaccess), update the Flutter URLs:

In `lib/config/constant.dart`, change:
```dart
return 'https://$domain.efeedor.com/index.php/deviceApproval/requestAccess';
```
to:
```dart
return 'https://$domain.efeedor.com/deviceApproval/requestAccess';
```

Same for `checkStatus` endpoint.

### Step 3: Verify Controller Exists

Ensure `DeviceApprovalController.php` exists at:
```
application/controllers/DeviceApprovalController.php
```

### Step 4: Test Endpoints

Test if endpoints work:

```bash
# Test 1: With index.php
curl -X POST https://demo.efeedor.com/index.php/deviceApproval/requestAccess \
  -H "Content-Type: application/json" \
  -d '{"user_id":"2","name":"Test","email":"test@test.com","device_id":"test123","device_name":"Test","platform":"Web","domain":"demo"}'

# Test 2: Without index.php (if URL rewriting enabled)
curl -X POST https://demo.efeedor.com/deviceApproval/requestAccess \
  -H "Content-Type: application/json" \
  -d '{"user_id":"2","name":"Test","email":"test@test.com","device_id":"test123","device_name":"Test","platform":"Web","domain":"demo"}'
```

### Step 5: Check CORS

The controller already sets CORS headers. If still blocked:

1. Check if PHP is outputting anything before headers
2. Check server configuration (Apache/Nginx)
3. Verify no whitespace before `<?php` in controller file

### Step 6: Database Tables

Ensure tables exist:
```sql
-- Run this SQL
source backend_sql/device_requests_table.sql
```

## Common Issues

### Issue: Still getting 404
- Routes not added to `routes.php`
- Controller file name mismatch
- URL format incorrect (try with/without `index.php`)

### Issue: Still getting CORS error
- Headers set after output
- Server blocking CORS
- Check browser console for exact error

### Issue: 500 Internal Server Error
- Database tables missing
- Model not loading
- Check PHP error logs

## Quick Test Script

Create `test_endpoints.php` in your CodeIgniter root:

```php
<?php
// Test if routes work
header('Content-Type: application/json');

$base = 'https://demo.efeedor.com';

// Test 1
$url1 = $base . '/index.php/deviceApproval/checkStatus?device_id=test&domain=demo';
echo "Test 1 (with index.php): $url1\n";

// Test 2  
$url2 = $base . '/deviceApproval/checkStatus?device_id=test&domain=demo';
echo "Test 2 (without index.php): $url2\n";

// Try both and see which works
```

