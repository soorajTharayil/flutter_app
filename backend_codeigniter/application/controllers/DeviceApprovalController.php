<?php
defined('BASEPATH') or exit('No direct script access allowed');

/**
 * Device Approval Controller
 * 
 * Handles device approval requests and status checks
 * 
 * @package    CodeIgniter
 * @subpackage Controllers
 * @category   API
 */
class DeviceApprovalController extends CI_Controller
{

    /**
     * Constructor
     */
    public function __construct()
    {
        parent::__construct();
        $this->load->model('DeviceRequest_model');
        $this->load->helper('url');

        // Enable CORS - must be set before any output
        header('Access-Control-Allow-Origin: *');
        header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
        header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
        header('Access-Control-Max-Age: 86400');

        // Handle preflight OPTIONS request
        if ($this->input->server('REQUEST_METHOD') === 'OPTIONS') {
            http_response_code(200);
            exit(0);
        }
    }

    /**
     * POST /deviceApproval/requestAccess
     * 
     * Request device approval after successful login
     * 
     * Expected JSON Body:
     * {
     *   "user_id": "123",
     *   "name": "John Doe",
     *   "email": "john@example.com",
     *   "device_id": "abc123...",
     *   "device_name": "iPhone 12",
     *   "platform": "iOS",
     *   "ip_address": "192.168.1.5",
     *   "domain": "demo"
     * }
     * 
     * Success Response:
     * {
     *   "status": "success",
     *   "message": "Device approval request created"
     * }
     */
    public function requestAccess()
    {
        $this->output->set_content_type('application/json');

        try {
            // Get JSON input
            $input = json_decode(file_get_contents('php://input'), true);

            if (!$input) {
                $this->output->set_status_header(400);
                echo json_encode(array(
                    'status' => 'error',
                    'message' => 'Invalid JSON input'
                ));
                return;
            }

            // Validate required fields
            $required_fields = array('user_id', 'name', 'email', 'device_id', 'device_name', 'platform', 'domain');
            foreach ($required_fields as $field) {
                if (empty($input[$field])) {
                    $this->output->set_status_header(400);
                    echo json_encode(array(
                        'status' => 'error',
                        'message' => "Missing required field: $field"
                    ));
                    return;
                }
            }

            // Check if device is already approved (one-time approval)
            $device_id = trim($input['device_id']);
            $domain = trim($input['domain']);

            if ($this->DeviceRequest_model->is_device_approved($device_id, $domain)) {
                $this->output->set_status_header(200);
                echo json_encode(array(
                    'status' => 'success',
                    'message' => 'Device is already approved'
                ));
                return;
            }

            // Get IP address from request - try multiple sources
            $ip_address = '0.0.0.0';

            // First priority: Use IP provided from Flutter (if valid and not 0.0.0.0)
            if (isset($input['ip_address'])) {
                $provided_ip = trim($input['ip_address']);
                if ($provided_ip && $provided_ip !== '0.0.0.0' && filter_var($provided_ip, FILTER_VALIDATE_IP)) {
                    $ip_address = $provided_ip;
                }
            }

            // If Flutter didn't provide a valid IP, try to get from request headers
            if ($ip_address === '0.0.0.0') {
                // Check various proxy headers for real client IP (if behind proxy/load balancer)
                $headers = array(
                    'HTTP_CF_CONNECTING_IP',     // Cloudflare
                    'HTTP_X_REAL_IP',            // Nginx proxy
                    'HTTP_X_FORWARDED_FOR',      // Proxy/Load balancer
                    'HTTP_CLIENT_IP',            // Some proxies
                    'HTTP_X_FORWARDED',          // Another proxy header
                    'HTTP_X_CLUSTER_CLIENT_IP',  // Cluster
                    'HTTP_FORWARDED_FOR',        // Alternative
                    'HTTP_FORWARDED'             // Standard forwarded
                );

                foreach ($headers as $header) {
                    if (!empty($_SERVER[$header])) {
                        $ip = trim($_SERVER[$header]);
                        // Handle comma-separated IPs (take first one)
                        if (strpos($ip, ',') !== false) {
                            $ip = trim(explode(',', $ip)[0]);
                        }
                        // Validate IP (accept both public and private)
                        if (filter_var($ip, FILTER_VALIDATE_IP)) {
                            $ip_address = $ip;
                            break;
                        }
                    }
                }
            }

            // If still no IP, check REMOTE_ADDR (most direct)
            if ($ip_address === '0.0.0.0' && !empty($_SERVER['REMOTE_ADDR'])) {
                $remote_ip = trim($_SERVER['REMOTE_ADDR']);
                if (filter_var($remote_ip, FILTER_VALIDATE_IP)) {
                    $ip_address = $remote_ip;
                }
            }

            // Final fallback: Try CodeIgniter's ip_address() method
            if ($ip_address === '0.0.0.0') {
                $ci_ip = $this->input->ip_address();
                if ($ci_ip && $ci_ip !== '0.0.0.0' && filter_var($ci_ip, FILTER_VALIDATE_IP)) {
                    $ip_address = $ci_ip;
                }
            }

            // Get device_name and platform from request
            $device_name = $input['device_name'];
            $platform = trim($input['platform']);

            // Only enhance device_name for web browsers, preserve exact value for mobile devices
            $is_web_browser = ($device_name === 'Web Browser' || $platform === 'Web Browser');

            if ($is_web_browser) {
                // Parse User-Agent to enhance device_name and platform for web only
                $user_agent = isset($_SERVER['HTTP_USER_AGENT']) ? $_SERVER['HTTP_USER_AGENT'] : '';

                if (!empty($user_agent)) {
                    $ua_lower = strtolower($user_agent);

                    // Detect device type
                    if (strpos($ua_lower, 'mac') !== false) {
                        $device_name = 'Mac Laptop';
                        $platform = 'macOS';
                    } else if (strpos($ua_lower, 'windows') !== false) {
                        $device_name = 'Windows PC';
                        $platform = 'Windows';
                    } else if (strpos($ua_lower, 'linux') !== false) {
                        $device_name = 'Linux PC';
                        $platform = 'Linux';
                    } else if (strpos($ua_lower, 'iphone') !== false) {
                        $device_name = 'iPhone';
                        $platform = 'iOS';
                    } else if (strpos($ua_lower, 'ipad') !== false) {
                        $device_name = 'iPad';
                        $platform = 'iOS';
                    } else if (strpos($ua_lower, 'android') !== false) {
                        $device_name = 'Android Device';
                        $platform = 'Android';
                    }

                    // Detect browser
                    $browser = '';
                    if (strpos($ua_lower, 'chrome') !== false && strpos($ua_lower, 'edg') === false) {
                        $browser = 'Chrome';
                    } else if (strpos($ua_lower, 'safari') !== false && strpos($ua_lower, 'chrome') === false) {
                        $browser = 'Safari';
                    } else if (strpos($ua_lower, 'firefox') !== false) {
                        $browser = 'Firefox';
                    } else if (strpos($ua_lower, 'edg') !== false) {
                        $browser = 'Edge';
                    } else if (strpos($ua_lower, 'opera') !== false) {
                        $browser = 'Opera';
                    }

                    if (!empty($browser)) {
                        $platform = $platform . ' ' . $browser;
                    }
                }
            }
            // For mobile devices (Android/iOS), device_name is preserved exactly as sent from Flutter
            // No trimming or modification is applied

            // Prepare request data
            // device_name: exact value from Flutter for mobile, enhanced for web
            $request_data = array(
                'user_id' => intval($input['user_id']),
                'name' => trim($input['name']),
                'email' => trim($input['email']),
                'device_name' => $device_name, // Exact value from Flutter (mobile) or enhanced (web)
                'platform' => $platform,
                'device_id' => $device_id,
                'ip_address' => $ip_address,
                'domain' => $domain
            );

            // Create device request
            $request_id = $this->DeviceRequest_model->create_request($request_data);

            if ($request_id) {
                $this->output->set_status_header(200);
                echo json_encode(array(
                    'status' => 'success',
                    'message' => 'Device approval request created successfully'
                ));
            } else {
                $this->output->set_status_header(500);
                echo json_encode(array(
                    'status' => 'error',
                    'message' => 'Failed to create device approval request'
                ));
            }

        } catch (Exception $e) {
            $this->output->set_status_header(500);
            echo json_encode(array(
                'status' => 'error',
                'message' => 'Server error: ' . $e->getMessage()
            ));
        }
    }

    /**
     * GET /deviceApproval/checkStatus
     * 
     * Check device approval status
     * 
     * Query Parameters:
     * - device_id: Device identifier
     * - domain: Domain identifier
     * 
     * Success Response:
     * {
     *   "status": "approved" | "pending" | "blocked" | "expired",
     *   "message": "Status message"
     * }
     */
    public function checkStatus()
    {
        $this->output->set_content_type('application/json');

        try {
            $device_id = $this->input->get('device_id');
            $domain = $this->input->get('domain');

            if (empty($device_id) || empty($domain)) {
                $this->output->set_status_header(400);
                echo json_encode(array(
                    'status' => 'error',
                    'message' => 'Missing required parameters: device_id and domain'
                ));
                return;
            }

            // Check if device is already approved (one-time approval)
            if ($this->DeviceRequest_model->is_device_approved($device_id, $domain)) {
                $this->output->set_status_header(200);
                echo json_encode(array(
                    'status' => 'approved',
                    'message' => 'Device is approved'
                ));
                return;
            }

            // Get latest request for this device
            $request = $this->DeviceRequest_model->get_request_by_device_id($device_id);

            if (!$request) {
                $this->output->set_status_header(200);
                echo json_encode(array(
                    'status' => 'pending',
                    'message' => 'No request found'
                ));
                return;
            }

            // Check if request is expired (48 hours)
            if ($this->DeviceRequest_model->is_request_expired($request['created_at'])) {
                // Mark as expired
                $this->DeviceRequest_model->update_status($request['id'], 'expired');

                $this->output->set_status_header(200);
                echo json_encode(array(
                    'status' => 'expired',
                    'message' => 'Request has expired. Please login again.',
                    'approval_expires_at' => $this->DeviceRequest_model->get_approval_expires_at($request['created_at'])
                ));
                return;
            }

            // Get approval expiry timestamp
            $approval_expires_at = $this->DeviceRequest_model->get_approval_expires_at($request['created_at']);

            // Return current status with expiry timestamp
            $this->output->set_status_header(200);
            echo json_encode(array(
                'status' => $request['status'],
                'message' => 'Request status: ' . $request['status'],
                'approval_expires_at' => $approval_expires_at
            ));

        } catch (Exception $e) {
            $this->output->set_status_header(500);
            echo json_encode(array(
                'status' => 'error',
                'message' => 'Server error: ' . $e->getMessage()
            ));
        }
    }
}

