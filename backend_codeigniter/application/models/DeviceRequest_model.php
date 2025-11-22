<?php
defined('BASEPATH') OR exit('No direct script access allowed');

/**
 * Device Request Model
 * 
 * Handles database operations for device approval requests
 * 
 * @package    CodeIgniter
 * @subpackage Models
 * @category   Device Management
 */
class DeviceRequest_model extends CI_Model {

    /**
     * Constructor
     */
    public function __construct() {
        parent::__construct();
        $this->load->database();
    }

    /**
     * Create a new device request
     * 
     * @param array $request_data Request information array
     * @return int|false Returns request ID on success, false on failure
     */
    public function create_request($request_data) {
        $data = array(
            'user_id' => $request_data['user_id'],
            'name' => $request_data['name'],
            'email' => $request_data['email'],
            'device_name' => $request_data['device_name'],
            'platform' => $request_data['platform'],
            'device_id' => $request_data['device_id'],
            'ip_address' => $request_data['ip_address'] ?? null,
            'domain' => $request_data['domain'],
            'status' => 'pending',
            'created_at' => date('Y-m-d H:i:s'),
            'updated_at' => date('Y-m-d H:i:s')
        );
        
        // Check if request already exists for this device+user+domain
        $existing = $this->db->get_where('device_requests', array(
            'device_id' => $request_data['device_id'],
            'user_id' => $request_data['user_id'],
            'domain' => $request_data['domain']
        ))->row();
        
        if ($existing) {
            // Update existing request
            $this->db->where('id', $existing->id);
            $this->db->update('device_requests', $data);
            
            if ($this->db->affected_rows() > 0) {
                return $existing->id;
            }
            return false;
        } else {
            // Insert new request
            if ($this->db->insert('device_requests', $data)) {
                return $this->db->insert_id();
            }
            return false;
        }
    }

    /**
     * Check if device is already approved
     * 
     * @param string $device_id Device identifier
     * @param string $domain Domain identifier
     * @return bool True if approved, false otherwise
     */
    public function is_device_approved($device_id, $domain) {
        $approved = $this->db->get_where('approved_devices', array(
            'device_id' => $device_id,
            'domain' => $domain
        ))->row();
        
        return $approved !== null;
    }

    /**
     * Get device request status by device_id
     * 
     * @param string $device_id Device identifier
     * @return array|false Request data or false if not found
     */
    public function get_request_by_device_id($device_id) {
        $this->db->order_by('created_at', 'DESC');
        return $this->db->get_where('device_requests', array('device_id' => $device_id))->row_array();
    }

    /**
     * Update request status
     * 
     * @param int $request_id Request ID
     * @param string $status New status (pending/approved/blocked/expired)
     * @return bool Success status
     */
    public function update_status($request_id, $status) {
        $this->db->where('id', $request_id);
        $result = $this->db->update('device_requests', array(
            'status' => $status,
            'updated_at' => date('Y-m-d H:i:s')
        ));
        
        // If approved, add to approved_devices table
        if ($result && $status === 'approved') {
            $request = $this->db->get_where('device_requests', array('id' => $request_id))->row();
            if ($request) {
                // Check if already in approved_devices
                $existing = $this->db->get_where('approved_devices', array(
                    'device_id' => $request->device_id,
                    'domain' => $request->domain
                ))->row();
                
                if (!$existing) {
                    $this->db->insert('approved_devices', array(
                        'device_id' => $request->device_id,
                        'domain' => $request->domain,
                        'user_id' => $request->user_id
                    ));
                }
            }
        }
        
        return $result;
    }

    /**
     * Get all device requests for admin view
     * 
     * @param string|null $domain Optional domain filter
     * @param string|null $status Optional status filter
     * @return array Array of request records
     */
    public function get_all_requests($domain = null, $status = null) {
        if ($domain) {
            $this->db->where('domain', $domain);
        }
        
        if ($status) {
            $this->db->where('status', $status);
        }
        
        $this->db->order_by('created_at', 'DESC');
        return $this->db->get('device_requests')->result_array();
    }

    /**
     * Get request by ID
     * 
     * @param int $request_id Request ID
     * @return object|false Request record or false
     */
    public function get_request_by_id($request_id) {
        return $this->db->get_where('device_requests', array('id' => $request_id))->row();
    }

    /**
     * Mark expired requests (48 hours timeout)
     * 
     * @return int Number of records updated
     */
    public function mark_expired_requests() {
        $expiry_time = date('Y-m-d H:i:s', strtotime('-48 hours'));
        
        $this->db->where('status', 'pending');
        $this->db->where('created_at <', $expiry_time);
        $this->db->update('device_requests', array(
            'status' => 'expired',
            'updated_at' => date('Y-m-d H:i:s')
        ));
        
        return $this->db->affected_rows();
    }

    /**
     * Check if request is expired (48 hours from creation)
     * 
     * @param string $created_at Creation timestamp
     * @return bool True if expired, false otherwise
     */
    public function is_request_expired($created_at) {
        $expiry_time = strtotime($created_at) + (48 * 60 * 60); // 48 hours
        return time() > $expiry_time;
    }

    /**
     * Get approval expiry timestamp (48 hours from creation)
     * 
     * @param string $created_at Creation timestamp
     * @return string Expiry timestamp in ISO format
     */
    public function get_approval_expires_at($created_at) {
        $expiry_time = strtotime($created_at) + (48 * 60 * 60); // 48 hours
        return date('Y-m-d H:i:s', $expiry_time);
    }
}

