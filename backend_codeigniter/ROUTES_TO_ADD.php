<?php
/**
 * COPY THESE ROUTES TO YOUR application/config/routes.php FILE
 * 
 * Add these routes BEFORE the default_controller line
 * 
 * IMPORTANT: These routes must be in your main routes.php file,
 * not just in routes_device.php (which is just a reference file)
 */

// =====================================================
// Device Registration API Routes
// =====================================================
// Add these lines to your routes.php file:

$route['api/device/register'] = 'DeviceController/register';
$route['api/device/verify'] = 'DeviceController/verify';
$route['api/device/admin_devices'] = 'DeviceController/admin_devices';

// Admin View (HTML page)
$route['admin/devices'] = 'DeviceController/admin_view';

// =====================================================
// Example of how your routes.php should look:
// =====================================================
/*
<?php
defined('BASEPATH') OR exit('No direct script access allowed');

// Device Registration API Routes
$route['api/device/register'] = 'DeviceController/register';
$route['api/device/verify'] = 'DeviceController/verify';
$route['api/device/admin_devices'] = 'DeviceController/admin_devices';
$route['admin/devices'] = 'DeviceController/admin_view';

// Your other existing routes here...
$route['default_controller'] = 'welcome';
$route['404_override'] = '';
$route['translate_uri_dashes'] = FALSE;
*/
?>

