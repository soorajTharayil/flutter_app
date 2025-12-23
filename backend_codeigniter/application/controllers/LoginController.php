<?php
defined('BASEPATH') or exit('No direct script access allowed');

/**
 * Login Controller
 * 
 * Handles user login with device approval flow
 * 
 * @package    CodeIgniter
 * @subpackage Controllers
 * @category   API
 */
class LoginController extends CI_Controller
{

    /**
     * Constructor
     */
    public function __construct()
    {
        parent::__construct();
        $this->load->model('DeviceRequest_model');
        $this->load->helper('url');
        $this->load->database();

        // Enable CORS if needed
        header('Access-Control-Allow-Origin: *');
        header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
        header('Access-Control-Allow-Headers: Content-Type, Authorization');

        // Handle preflight OPTIONS request
        if ($this->input->method() === 'options') {
            exit(0);
        }
    }

    /**
     * POST /api/login
     * 
     * User login with device approval flow
     * 
     * Expected JSON Body:
     * {
     *   "email": "user@example.com",
     *   "password": "password123",
     *   "device_id": "abc123...",
     *   "ip_address": "192.168.1.1",
     *   "domain": "demo"
     * }
     * 
     * Success Response (if device already approved):
     * {
     *   "status": "approved",
     *   "userid": "123",
     *   "email": "user@example.com",
     *   ... (other user data)
     * }
     * 
     * Success Response (if waiting for approval):
     * {
     *   "status": "waiting_approval",
     *   "message": "Login successful, waiting for administrator approval"
     * }
     * 
     * Error Response:
     * {
     *   "status": "error",
     *   "message": "Invalid credentials"
     * }
     */
    public function login()
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
            $required_fields = array('email', 'password', 'device_id', 'domain');
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

            $email = trim($input['email']);
            $password = trim($input['password']);
            $device_id = trim($input['device_id']);
            $ip_address = $input['ip_address'] ?? $this->input->ip_address();
            $domain = trim($input['domain']);

            // TODO: Replace this with your actual login validation logic
            // This is a placeholder - you should integrate with your existing user authentication
            $user = $this->validate_login($email, $password);

            if (!$user) {
                $this->output->set_status_header(401);
                echo json_encode(array(
                    'status' => 'error',
                    'message' => 'Invalid credentials'
                ));
                return;
            }

            // Check if device is already approved (one-time approval)
            if ($this->DeviceRequest_model->is_device_approved($device_id, $domain)) {
                // Device already approved - return user data directly
                $this->output->set_status_header(200);
                echo json_encode(array_merge(array(
                    'status' => 'approved'
                ), $user));
                return;
            }

            // Get device info (you may need to get this from device_info_plus in Flutter)
            $device_name = $input['device_name'] ?? 'Unknown Device';
            $platform = $input['platform'] ?? 'Unknown';

            // Create device request
            $request_data = array(
                'user_id' => $user['userid'],
                'name' => $user['name'] ?? $user['email'],
                'email' => $user['email'],
                'device_name' => $device_name,
                'platform' => $platform,
                'device_id' => $device_id,
                'ip_address' => $ip_address,
                'domain' => $domain
            );

            $request_id = $this->DeviceRequest_model->create_request($request_data);

            if ($request_id) {
                $this->output->set_status_header(200);
                echo json_encode(array(
                    'status' => 'waiting_approval',
                    'message' => 'Login successful, waiting for administrator approval'
                ));
            } else {
                $this->output->set_status_header(500);
                echo json_encode(array(
                    'status' => 'error',
                    'message' => 'Failed to create device request'
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
     * Validate user login credentials
     * 
     * TODO: Replace this method with your actual login validation logic
     * This should query your users table and verify credentials
     * 
     * @param string $email User email
     * @param string $password User password
     * @return array|false User data array on success, false on failure
     */
    private function validate_login($email, $password)
    {
        // Query user by email
        $this->db->where('email', $email);
        $user = $this->db->get('users')->row_array();

        if (!$user) {
            return false;
        }

        // Verify password (using MD5 for now - update to password_hash if possible)
        if (md5($password) !== $user['password']) {
            return false;
        }

        // Return actual user data from database
        return array(
            'userid' => $user['userid'],
            'email' => $user['email'],
            'name' => $user['name'],
            'designation' => $user['designation'] ?? '',
            'mobile' => $user['mobile'] ?? '',
        );
    }
}
