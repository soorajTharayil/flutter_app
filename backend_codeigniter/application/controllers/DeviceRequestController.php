<?php
defined('BASEPATH') or exit('No direct script access allowed');

/**
 * Device Request Controller
 * 
 * Handles device approval request API endpoints
 * 
 * @package    CodeIgniter
 * @subpackage Controllers
 * @category   API
 */
class DeviceRequestController extends CI_Controller
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
     * GET /api/check-device-status
     * 
     * Check device approval status
     * 
     * Query Parameters:
     * - device_id: Device identifier
     * 
     * Success Response:
     * {
     *   "status": "approved" | "pending" | "blocked" | "expired",
     *   "message": "Status message"
     * }
     */
    public function check_device_status()
    {
        $this->output->set_content_type('application/json');

        try {
            $device_id = $this->input->get('device_id');

            if (empty($device_id)) {
                $this->output->set_status_header(400);
                echo json_encode(array(
                    'status' => 'error',
                    'message' => 'Missing required parameter: device_id'
                ));
                return;
            }

            // Check if device is already approved (one-time approval)
            $domain = $this->input->get('domain') ?: '';
            if (!empty($domain) && $this->DeviceRequest_model->is_device_approved($device_id, $domain)) {
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

    /**
     * POST /api/device/approve
     * 
     * Approve a device request
     * 
     * Expected JSON Body:
     * {
     *   "request_id": 123
     * }
     * 
     * Success Response:
     * {
     *   "status": "success",
     *   "message": "Device approved successfully"
     * }
     */
    public function approve()
    {
        // Clear all output buffers before sending JSON
        while (ob_get_level()) {
            ob_end_clean();
        }

        // TODO: Add admin authentication check here

        try {
            // Get JSON input
            $raw_input = file_get_contents('php://input');
            $input = json_decode($raw_input, true);

            // Handle case where request might be form-encoded
            if (!$input && !empty($_POST['request_id'])) {
                $input = array('request_id' => $_POST['request_id']);
            }

            if (!$input || empty($input['request_id'])) {
                $this->output
                    ->set_status_header(400)
                    ->set_content_type('application/json', 'utf-8')
                    ->set_output(json_encode(array(
                        'success' => false,
                        'status' => 'error',
                        'message' => 'Missing required field: request_id'
                    )));
                return;
            }

            $request_id = intval($input['request_id']);

            // Verify request exists
            $request = $this->DeviceRequest_model->get_request_by_id($request_id);
            if (!$request) {
                $this->output
                    ->set_status_header(404)
                    ->set_content_type('application/json', 'utf-8')
                    ->set_output(json_encode(array(
                        'success' => false,
                        'status' => 'error',
                        'message' => 'Device request not found'
                    )));
                return;
            }

            $result = $this->DeviceRequest_model->update_status($request_id, 'approved');

            if ($result) {
                $this->output
                    ->set_status_header(200)
                    ->set_content_type('application/json', 'utf-8')
                    ->set_output(json_encode(array(
                        'success' => true,
                        'status' => 'success',
                        'message' => 'Device approved successfully'
                    )));
            } else {
                $this->output
                    ->set_status_header(500)
                    ->set_content_type('application/json', 'utf-8')
                    ->set_output(json_encode(array(
                        'success' => false,
                        'status' => 'error',
                        'message' => 'Failed to approve device'
                    )));
            }
            return;

        } catch (Exception $e) {
            $this->output
                ->set_status_header(500)
                ->set_content_type('application/json', 'utf-8')
                ->set_output(json_encode(array(
                    'success' => false,
                    'status' => 'error',
                    'message' => 'Server error: ' . $e->getMessage()
                )));
            return;
        }
    }

    /**
     * POST /api/device/block
     * 
     * Block a device request
     * 
     * Expected JSON Body:
     * {
     *   "request_id": 123
     * }
     * 
     * Success Response:
     * {
     *   "status": "success",
     *   "message": "Device blocked successfully"
     * }
     */
    public function block()
    {
        // Clear all output buffers before sending JSON
        while (ob_get_level()) {
            ob_end_clean();
        }

        // TODO: Add admin authentication check here

        try {
            // Get JSON input
            $raw_input = file_get_contents('php://input');
            $input = json_decode($raw_input, true);

            // Handle case where request might be form-encoded
            if (!$input && !empty($_POST['request_id'])) {
                $input = array('request_id' => $_POST['request_id']);
            }

            if (!$input || empty($input['request_id'])) {
                $this->output
                    ->set_status_header(400)
                    ->set_content_type('application/json', 'utf-8')
                    ->set_output(json_encode(array(
                        'success' => false,
                        'status' => 'error',
                        'message' => 'Missing required field: request_id'
                    )));
                return;
            }

            $request_id = intval($input['request_id']);

            // Verify request exists
            $request = $this->DeviceRequest_model->get_request_by_id($request_id);
            if (!$request) {
                $this->output
                    ->set_status_header(404)
                    ->set_content_type('application/json', 'utf-8')
                    ->set_output(json_encode(array(
                        'success' => false,
                        'status' => 'error',
                        'message' => 'Device request not found'
                    )));
                return;
            }

            $result = $this->DeviceRequest_model->update_status($request_id, 'blocked');

            if ($result) {
                $this->output
                    ->set_status_header(200)
                    ->set_content_type('application/json', 'utf-8')
                    ->set_output(json_encode(array(
                        'success' => true,
                        'status' => 'success',
                        'message' => 'Device blocked successfully'
                    )));
            } else {
                $this->output
                    ->set_status_header(500)
                    ->set_content_type('application/json', 'utf-8')
                    ->set_output(json_encode(array(
                        'success' => false,
                        'status' => 'error',
                        'message' => 'Failed to block device'
                    )));
            }
            return;

        } catch (Exception $e) {
            $this->output
                ->set_status_header(500)
                ->set_content_type('application/json', 'utf-8')
                ->set_output(json_encode(array(
                    'success' => false,
                    'status' => 'error',
                    'message' => 'Server error: ' . $e->getMessage()
                )));
            return;
        }
    }

    /**
     * GET /api/device/requests
     * 
     * Get all device requests (admin endpoint)
     * 
     * Query Parameters:
     * - domain (optional): Filter by domain
     * - status (optional): Filter by status
     * 
     * Success Response:
     * {
     *   "status": "success",
     *   "count": 10,
     *   "data": [...]
     * }
     */
    public function get_requests()
    {
        $this->output->set_content_type('application/json');

        // TODO: Add admin authentication check here

        try {
            $domain = $this->input->get('domain');
            $status = $this->input->get('status');

            $requests = $this->DeviceRequest_model->get_all_requests($domain, $status);

            $this->output->set_status_header(200);
            echo json_encode(array(
                'status' => 'success',
                'count' => count($requests),
                'data' => $requests
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
     * GET /admin/device-requests
     * 
     * Admin HTML view for device request management
     */
    public function admin_view()
    {
        // TODO: Add admin authentication check here

        // Mark expired requests
        $this->DeviceRequest_model->mark_expired_requests();

        // Get all requests
        $data['requests'] = $this->DeviceRequest_model->get_all_requests();

        // Get unique domains for filter
        $all_requests = $this->DeviceRequest_model->get_all_requests();
        $domains = array();
        if ($all_requests) {
            $domain_list = array_column($all_requests, 'domain');
            $domains = array_values(array_unique(array_filter($domain_list)));
        }
        $data['domains'] = $domains;

        $this->load->view('admin/device_requests', $data);
    }
}

