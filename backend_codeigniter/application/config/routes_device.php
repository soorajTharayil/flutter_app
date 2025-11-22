<?php
defined('BASEPATH') or exit('No direct script access allowed');

/**
 * Device Registration Routes
 * 
 * Add these routes to your main routes.php file or include this file
 * 
 * Place this in: application/config/routes.php
 * Or include it: $route['device'] = include(APPPATH . 'config/routes_device.php');
 */

/*
|--------------------------------------------------------------------------
| Device Registration API Routes
|--------------------------------------------------------------------------
|
| These routes handle device registration and token verification
|
*/

// Device Registration Endpoint
$route['api/device/register'] = 'DeviceController/register';
$route['api/device/verify'] = 'DeviceController/verify';

// Admin Device Management Endpoint
$route['api/device/admin_devices'] = 'DeviceController/admin_devices';

// Admin View (HTML page)
$route['admin/devices'] = 'DeviceController/admin_view';

