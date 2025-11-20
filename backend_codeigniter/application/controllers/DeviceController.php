<?php
defined('BASEPATH') or exit('No direct script access allowed');

/**
 * Device Controller
 * 
 * Handles device registration and token verification API endpoints
 * 
 * @package    CodeIgniter
 * @subpackage Controllers
 * @category   API
 * @author     Your Name
 */
class DeviceController extends CI_Controller
{

    /**
     * Constructor
     */
    public function __construct()
    {
        parent::__construct();
        $this->load->model('Device_model');
        $this->load->helper('url');

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
     * POST /api/device/register
     * 
     * Register a new device and generate registration token
     * 
     * Expected JSON Body:
     * {
     *   "domain": "demo",
     *   "device_id": "abc123...",
     *   "device_name": "Samsung Galaxy S21",
     *   "platform": "Android",
     *   "os_version": "12 (SDK 31)"
     * }
     * 
     * Success Response:
     * {
     *   "status": "success",
     *   "message": "Device registered successfully",
     *   "token": "REG-ABCD1234"
     * }
     * 
     * Error Response:
     * {
     *   "status": "error",
     *   "message": "Error message here"
     * }
     */
    public function register()
    {
        // Set JSON response header
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
            $required_fields = array('domain', 'device_id', 'device_name', 'platform');
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

            // Extract tenant_id from domain
            $domain = strtolower(trim($input['domain']));
            $tenant_id = $domain; // Use domain as tenant_id (e.g., "demo" -> tenant_id: "demo")

            // Switch database connection based on tenant if needed
            // This is where you'd implement multi-tenant DB switching
            // For now, we assume all tenants use the same database
            // Example: $this->switch_tenant_database($tenant_id);

            // Prepare device data
            $device_data = array(
                'tenant_id' => $tenant_id,
                'device_id' => trim($input['device_id']),
                'device_name' => trim($input['device_name']),
                'platform' => trim($input['platform']),
                'os_version' => isset($input['os_version']) ? trim($input['os_version']) : null
            );

            // Register device
            $result = $this->Device_model->register_device($device_data);

            if ($result) {
                $this->output->set_status_header(200);
                echo json_encode(array(
                    'status' => 'success',
                    'message' => 'Device registered successfully',
                    'token' => $result['registration_token']
                ));
            } else {
                $this->output->set_status_header(500);
                echo json_encode(array(
                    'status' => 'error',
                    'message' => 'Failed to register device'
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
     * POST /api/device/verify
     * 
     * Verify registration token and approve device
     * 
     * Expected JSON Body:
     * {
     *   "device_id": "abc123...",
     *   "token": "REG-ABCD1234"
     * }
     * 
     * Success Response:
     * {
     *   "status": "success",
     *   "message": "Token verified successfully. Device approved."
     * }
     * 
     * Error Response:
     * {
     *   "status": "error",
     *   "message": "Invalid or expired token"
     * }
     */
    public function verify()
    {
        // Set JSON response header
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
            if (empty($input['device_id']) || empty($input['token'])) {
                $this->output->set_status_header(400);
                echo json_encode(array(
                    'status' => 'error',
                    'message' => 'Missing required fields: device_id and token'
                ));
                return;
            }

            $device_id = trim($input['device_id']);
            $token = strtoupper(trim($input['token']));

            // Verify token
            $result = $this->Device_model->verify_token($device_id, $token);

            if ($result) {
                $this->output->set_status_header(200);
                echo json_encode(array(
                    'status' => 'success',
                    'message' => 'Token verified successfully. Device approved.'
                ));
            } else {
                $this->output->set_status_header(400);
                echo json_encode(array(
                    'status' => 'error',
                    'message' => 'Invalid or expired token'
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
     * GET /api/device/admin_devices
     * 
     * Admin endpoint to view all registered devices
     * 
     * Query Parameters:
     * - tenant_id (optional): Filter by tenant
     * - status (optional): Filter by status (pending/approved/blocked)
     * 
     * Success Response:
     * {
     *   "status": "success",
     *   "count": 10,
     *   "data": [
     *     {
     *       "id": 1,
     *       "tenant_id": "demo",
     *       "device_id": "abc123...",
     *       "device_name": "Samsung Galaxy S21",
     *       "platform": "Android",
     *       "registration_token": "REG-ABCD1234",
     *       "status": "pending",
     *       "created_at": "2025-01-15 10:30:00"
     *     },
     *     ...
     *   ]
     * }
     * 
     * Note: Add authentication/authorization check here for admin access
     */
    public function admin_devices()
    {
        // Set JSON response header
        $this->output->set_content_type('application/json');

        // TODO: Add admin authentication check here
        // Example:
        // if (!$this->session->userdata('is_admin')) {
        //     $this->output->set_status_header(403);
        //     echo json_encode(array('status' => 'error', 'message' => 'Unauthorized'));
        //     return;
        // }

        try {
            $tenant_id = $this->input->get('tenant_id');
            $status = $this->input->get('status');

            // Get all devices
            $devices = $this->Device_model->get_all_devices($tenant_id, $status);

            $this->output->set_status_header(200);
            echo json_encode(array(
                'status' => 'success',
                'count' => count($devices),
                'data' => $devices
            ));

        } catch (Exception $e) {
            $this->output->set_status_header(500);
            echo json_encode(array(
                'status' => 'error',
                'message' => 'Server error: ' . $e->getMessage()
            ));
        }
    }

    /**
     * GET /admin/devices
     * 
     * Admin HTML view for device management
     * Displays the device_list.php view with all registered devices
     * 
     * Note: Add authentication/authorization check here for admin access
     */
    public function admin_view()
    {
        // TODO: Add admin authentication check here
        // Example:
        // if (!$this->session->userdata('is_admin')) {
        //     redirect('login');
        //     return;
        // }

        // Get unique tenants for filter dropdown
        $all_devices = $this->Device_model->get_all_devices();
        $tenants = array();

        if ($all_devices) {
            $tenant_list = array_column($all_devices, 'tenant_id');
            $tenants = array_values(array_unique(array_filter($tenant_list)));
        }

        $data['tenants'] = $tenants;
        $this->load->view('admin/device_list', $data);
    }

    /**
     * Helper method to switch database connection based on tenant
     * 
     * @param string $tenant_id Tenant identifier
     * @return void
     * 
     * Example implementation for multi-tenant database switching:
     */
    private function switch_tenant_database($tenant_id)
    {
        // Example: Load different database config based on tenant
        // $db_config = $this->config->item('database');
        // $db_config['database'] = "efeedor_{$tenant_id}";
        // $this->load->database($db_config);

        // Or use a database mapping:
        // $tenant_db_map = array(
        //     'demo' => 'efeedor_demo',
        //     'krr' => 'efeedor_krr',
        //     // ... more tenants
        // );
        // if (isset($tenant_db_map[$tenant_id])) {
        //     $this->load->database($tenant_db_map[$tenant_id]);
        // }
    }
}

