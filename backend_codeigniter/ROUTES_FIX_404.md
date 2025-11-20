# Fix 404 Error for Device Registration Routes

## Problem
Getting 404 error when accessing:
- `https://demo.efeedor.com/api/device/admin_devices`
- `https://demo.efeedor.com/api/device/register`
- `https://demo.efeedor.com/api/device/verify`

## Solution Steps

### Step 1: Add Routes to Main routes.php

The routes in `routes_device.php` are just a reference. You MUST add them to your main `application/config/routes.php` file.

**Open:** `application/config/routes.php`

**Add these routes BEFORE the default route:**

```php
// Device Registration API Routes
$route['api/device/register'] = 'DeviceController/register';
$route['api/device/verify'] = 'DeviceController/verify';
$route['api/device/admin_devices'] = 'DeviceController/admin_devices';

// Admin View (HTML page)
$route['admin/devices'] = 'DeviceController/admin_view';

// Default route (keep this at the end)
$route['default_controller'] = 'welcome';
$route['404_override'] = '';
$route['translate_uri_dashes'] = FALSE;
```

### Step 2: Verify Controller File Name

Make sure the controller file is named exactly:
- `DeviceController.php` (capital D, capital C)
- Located in: `application/controllers/DeviceController.php`

### Step 3: Check .htaccess Configuration

Make sure your `.htaccess` file in the project root has URL rewriting enabled:

```apache
<IfModule mod_rewrite.c>
    RewriteEngine On
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteRule ^(.*)$ index.php/$1 [L]
</IfModule>
```

### Step 4: Verify Base URL Configuration

Check `application/config/config.php`:

```php
$config['base_url'] = 'https://demo.efeedor.com/';
// OR for auto-detection:
// $config['base_url'] = '';
```

### Step 5: Test with index.php

Try accessing with `index.php` to verify routing works:
- `https://demo.efeedor.com/index.php/api/device/admin_devices`

If this works, the issue is with URL rewriting (.htaccess).

### Step 6: Check Controller Loading

Verify the controller can be loaded. Add this temporary test to `DeviceController.php`:

```php
public function test() {
    echo "DeviceController is working!";
}
```

Then access: `https://demo.efeedor.com/api/device/test`

If this doesn't work, the controller isn't being found.

## Common Issues

### Issue 1: Routes Not Added to routes.php
**Symptom:** 404 on all device endpoints
**Fix:** Copy routes from `routes_device.php` to main `routes.php`

### Issue 2: Case Sensitivity
**Symptom:** 404 even with routes added
**Fix:** Ensure controller file name matches exactly: `DeviceController.php`

### Issue 3: .htaccess Not Working
**Symptom:** Works with `index.php` but not without
**Fix:** Check `.htaccess` file and Apache mod_rewrite module

### Issue 4: Model Not Loading
**Symptom:** 500 error instead of 404
**Fix:** Ensure `Device_model.php` exists in `application/models/`

## Quick Test Commands

### Test Route Registration
```bash
# Check if route exists (add this temporarily to routes.php)
$route['test-route'] = 'DeviceController/test';
```

### Test Controller Access
```bash
# Direct controller access
https://demo.efeedor.com/index.php/DeviceController/admin_devices
```

### Test Model Loading
Add to `DeviceController` constructor:
```php
public function __construct() {
    parent::__construct();
    $this->load->model('Device_model');
    // Test if model loads
    if (!$this->Device_model) {
        die('Model not loaded');
    }
}
```

## Verification Checklist

- [ ] Routes added to `application/config/routes.php`
- [ ] Controller file exists: `application/controllers/DeviceController.php`
- [ ] Model file exists: `application/models/Device_model.php`
- [ ] `.htaccess` file exists in project root
- [ ] Apache mod_rewrite is enabled
- [ ] Base URL is configured correctly
- [ ] Database table `user_devices` exists

## Still Getting 404?

1. **Enable CodeIgniter Logging:**
   ```php
   // In config.php
   $config['log_threshold'] = 4; // Log all messages
   ```
   Check: `application/logs/log-YYYY-MM-DD.php`

2. **Check Apache Error Log:**
   ```bash
   tail -f /var/log/apache2/error.log
   ```

3. **Verify File Permissions:**
   ```bash
   chmod 644 application/controllers/DeviceController.php
   chmod 644 application/models/Device_model.php
   ```

4. **Test Direct Access:**
   Try: `https://demo.efeedor.com/index.php/DeviceController/admin_devices`
   If this works, the issue is URL rewriting.

