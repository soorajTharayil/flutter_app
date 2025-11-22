<?php
defined('BASEPATH') OR exit('No direct script access allowed');

/**
 * Device Model
 * 
 * Handles database operations for device registration and token management
 * 
 * @package    CodeIgniter
 * @subpackage Models
 * @category   Device Management
 * @author     Your Name
 */
class Device_model extends CI_Model {

    /**
     * Constructor
     */
    public function __construct() {
        parent::__construct();
        $this->load->database();
    }

    /**
     * Register a new device
     * 
     * @param array $device_data Device information array
     * @return array|false Returns device record with token on success, false on failure
     */
    public function register_device($device_data) {
        // Generate unique registration token
        $token = $this->generate_registration_token();
        
        // Set token expiry (30 minutes from now)
        $token_expiry = date('Y-m-d H:i:s', strtotime('+30 minutes'));
        
        // Get client IP address
        $ip_address = $this->input->ip_address();
        
        // Prepare data for insertion
        $data = array(
            'tenant_id' => $device_data['tenant_id'],
            'device_id' => $device_data['device_id'],
            'device_name' => $device_data['device_name'],
            'platform' => $device_data['platform'],
            'os_version' => $device_data['os_version'] ?? null,
            'ip_address' => $ip_address,
            'registration_token' => $token,
            'token_expiry' => $token_expiry,
            'token_used' => 0,
            'status' => 'pending',
            'created_at' => date('Y-m-d H:i:s'),
            'updated_at' => date('Y-m-d H:i:s')
        );
        
        // Check if device already exists for this tenant
        $existing = $this->db->get_where('user_devices', array(
            'tenant_id' => $device_data['tenant_id'],
            'device_id' => $device_data['device_id']
        ))->row();
        
        if ($existing) {
            // Update existing device record with new token
            $this->db->where('id', $existing->id);
            $this->db->update('user_devices', $data);
            
            if ($this->db->affected_rows() > 0) {
                $data['id'] = $existing->id;
                return $data;
            }
            return false;
        } else {
            // Insert new device record
            if ($this->db->insert('user_devices', $data)) {
                $data['id'] = $this->db->insert_id();
                return $data;
            }
            return false;
        }
    }

    /**
     * Verify registration token
     * 
     * @param string $device_id Device identifier
     * @param string $token Registration token
     * @return array|false Returns device record on success, false on failure
     */
    public function verify_token($device_id, $token) {
        // Find device with matching token and device_id
        $this->db->where('device_id', $device_id);
        $this->db->where('registration_token', strtoupper(trim($token)));
        $this->db->where('token_used', 0); // Token must not be used
        $this->db->where('status', 'pending'); // Device must be pending
        $device = $this->db->get('user_devices')->row();
        
        if (!$device) {
            return false;
        }
        
        // Check if token has expired
        $now = date('Y-m-d H:i:s');
        if (strtotime($device->token_expiry) < strtotime($now)) {
            return false; // Token expired
        }
        
        // Mark token as used and approve device
        $update_data = array(
            'token_used' => 1,
            'status' => 'approved',
            'updated_at' => $now
        );
        
        $this->db->where('id', $device->id);
        $this->db->update('user_devices', $update_data);
        
        if ($this->db->affected_rows() > 0) {
            // Return updated device record
            $device->token_used = 1;
            $device->status = 'approved';
            return $device;
        }
        
        return false;
    }

    /**
     * Get all devices for admin view
     * 
     * @param string|null $tenant_id Optional tenant filter
     * @param string|null $status Optional status filter (pending/approved/blocked)
     * @return array Array of device records
     */
    public function get_all_devices($tenant_id = null, $status = null) {
        if ($tenant_id) {
            $this->db->where('tenant_id', $tenant_id);
        }
        
        if ($status) {
            $this->db->where('status', $status);
        }
        
        $this->db->order_by('created_at', 'DESC');
        return $this->db->get('user_devices')->result_array();
    }

    /**
     * Get device by ID
     * 
     * @param int $device_id Device record ID
     * @return object|false Device record or false
     */
    public function get_device_by_id($device_id) {
        return $this->db->get_where('user_devices', array('id' => $device_id))->row();
    }

    /**
     * Update device status
     * 
     * @param int $device_id Device record ID
     * @param string $status New status (pending/approved/blocked)
     * @return bool Success status
     */
    public function update_device_status($device_id, $status) {
        $this->db->where('id', $device_id);
        return $this->db->update('user_devices', array(
            'status' => $status,
            'updated_at' => date('Y-m-d H:i:s')
        ));
    }

    /**
     * Clean up expired tokens (optional: run via cron)
     * 
     * @return int Number of records updated
     */
    public function cleanup_expired_tokens() {
        $now = date('Y-m-d H:i:s');
        $this->db->where('token_expiry <', $now);
        $this->db->where('token_used', 0);
        $this->db->where('status', 'pending');
        $this->db->update('user_devices', array(
            'status' => 'blocked',
            'updated_at' => $now
        ));
        return $this->db->affected_rows();
    }

    /**
     * Generate unique registration token
     * Format: REG-XXXX1234 (8 alphanumeric characters)
     * 
     * @return string Unique registration token
     */
    private function generate_registration_token() {
        $prefix = 'REG-';
        $characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
        $max_attempts = 10;
        $attempt = 0;
        
        do {
            $token = $prefix;
            for ($i = 0; $i < 8; $i++) {
                $token .= $characters[rand(0, strlen($characters) - 1)];
            }
            
            // Check if token already exists
            $exists = $this->db->get_where('user_devices', array(
                'registration_token' => $token
            ))->row();
            
            if (!$exists) {
                return $token;
            }
            
            $attempt++;
        } while ($attempt < $max_attempts);
        
        // Fallback: add timestamp if all attempts failed
        return $prefix . strtoupper(substr(md5(uniqid(rand(), true)), 0, 8));
    }
}

