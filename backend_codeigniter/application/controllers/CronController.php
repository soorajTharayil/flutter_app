<?php
defined('BASEPATH') or exit('No direct script access allowed');

/**
 * Cron Controller
 * 
 * Handles scheduled tasks like cleaning up expired device requests
 * 
 * @package    CodeIgniter
 * @subpackage Controllers
 * @category   Cron
 */
class CronController extends CI_Controller
{

    /**
     * Constructor
     */
    public function __construct()
    {
        parent::__construct();
        $this->load->model('DeviceRequest_model');
        
        // Only allow CLI access for security
        if (!$this->input->is_cli_request()) {
            show_error('This controller can only be accessed via CLI', 403);
        }
    }

    /**
     * Cleanup expired device requests
     * 
     * Run via cron: php index.php CronController cleanup_expired
     * Or: */5 * * * * cd /path/to/project && php index.php CronController cleanup_expired
     */
    public function cleanup_expired()
    {
        $count = $this->DeviceRequest_model->mark_expired_requests();
        echo date('Y-m-d H:i:s') . " - Marked $count requests as expired\n";
    }
}

