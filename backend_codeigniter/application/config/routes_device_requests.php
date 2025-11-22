<?php
defined('BASEPATH') or exit('No direct script access allowed');

/**
 * Device Request Routes
 * 
 * Add these routes to your main routes.php file or include this file
 * 
 * Place this in: application/config/routes.php
 * Or include it: $route['device'] = include(APPPATH . 'config/routes_device_requests.php');
 */

/*
||--------------------------------------------------------------------------
|| Device Request API Routes
||--------------------------------------------------------------------------
||
|| These routes handle device approval requests after login
||
*/

// Device Approval Endpoints (new flow)
$route['deviceApproval/requestAccess'] = 'DeviceApprovalController/requestAccess';
$route['deviceApproval/checkStatus'] = 'DeviceApprovalController/checkStatus';

// Login with device approval flow (old - kept for reference)
$route['api/login'] = 'LoginController/login';

// Device Status Check (old - kept for reference)
$route['api/check-device-status'] = 'DeviceRequestController/check_device_status';

// Device Approval/Block Actions
$route['api/device/approve'] = 'DeviceRequestController/approve';
$route['api/device/block'] = 'DeviceRequestController/block';
$route['api/device/requests'] = 'DeviceRequestController/get_requests';

// Admin View (HTML page)
$route['admin/device-requests'] = 'DeviceRequestController/admin_view';

