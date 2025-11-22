# Routes Setup Instructions

## Important: Add Routes to CodeIgniter

You need to add the device approval routes to your main `routes.php` file.

### Option 1: Include the routes file (Recommended)

Add this line to `application/config/routes.php`:

```php
// Device Approval Routes
require_once(APPPATH . 'config/routes_device_requests.php');
```

### Option 2: Add routes directly

Add these lines to `application/config/routes.php`:

```php
// Device Approval Endpoints
$route['deviceApproval/requestAccess'] = 'DeviceApprovalController/requestAccess';
$route['deviceApproval/checkStatus'] = 'DeviceApprovalController/checkStatus';
```

## URL Structure

The Flutter app uses these URLs:
- `https://{domain}.efeedor.com/index.php/deviceApproval/requestAccess`
- `https://{domain}.efeedor.com/index.php/deviceApproval/checkStatus`

If your CodeIgniter installation uses URL rewriting (removes `index.php`), you can update the Flutter URLs to:
- `https://{domain}.efeedor.com/deviceApproval/requestAccess`
- `https://{domain}.efeedor.com/deviceApproval/checkStatus`

## .htaccess Configuration (if using URL rewriting)

If you want to remove `index.php` from URLs, ensure your `.htaccess` file in the root directory has:

```apache
RewriteEngine On
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^(.*)$ index.php/$1 [L]
```

## Verify Routes

After adding routes, test the endpoints:

```bash
# Test requestAccess
curl -X POST https://demo.efeedor.com/index.php/deviceApproval/requestAccess \
  -H "Content-Type: application/json" \
  -d '{"user_id":"123","name":"Test","email":"test@test.com","device_id":"test123","device_name":"Test Device","platform":"Web","domain":"demo"}'

# Test checkStatus
curl "https://demo.efeedor.com/index.php/deviceApproval/checkStatus?device_id=test123&domain=demo"
```

## CORS Configuration

The controller already sets CORS headers. If you still have CORS issues, check:
1. Server configuration (Apache/Nginx)
2. PHP version compatibility
3. Headers being sent before controller execution

