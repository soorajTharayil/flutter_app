<?php
defined('BASEPATH') or exit('No direct script access allowed');

/**
 * Mobile-friendly incident management endpoints (JSON).
 * Does not use CSRF tokens; validates uid against `user` table instead.
 *
 * Deploy: copy this file to your CodeIgniter application/controllers/
 * Routes (default CI3): incident_mobile/update_risk_matrix, etc.
 *
 * Requires tables: bf_feedback_incident (dataset JSON), tickets_incident
 * Adjust table/column names if your schema differs.
 */
class Incident_mobile extends CI_Controller
{
    public function __construct()
    {
        parent::__construct();
        $this->load->database();
        header('Access-Control-Allow-Origin: *');
        header('Access-Control-Allow-Methods: POST, OPTIONS');
        header('Access-Control-Allow-Headers: Content-Type, Accept');
        if ($this->input->method(true) === 'OPTIONS') {
            exit(0);
        }
    }

    /**
     * POST JSON or form:
     * uid, id (bf_feedback_incident.id), pid (tickets_incident.id), empid,
     * impact, likelihood, level, status=EditAssignedRisk
     */
    public function update_risk_matrix()
    {
        $this->_json_response();
        $in = $this->_input_array();
        if (!$this->_require_uid($in)) {
            return;
        }
        $id = isset($in['id']) ? trim((string) $in['id']) : '';
        $pid = isset($in['pid']) ? trim((string) $in['pid']) : '';
        if ($id === '' || $pid === '') {
            $this->_fail(400, 'id and pid required');
            return;
        }
        $id = $this->_resolve_feedback_id($pid, $id);
        if (!$this->_verify_ticket_feedback($pid, $id)) {
            $this->_fail(403, 'ticket/feedback mismatch');
            return;
        }
        $impact = isset($in['impact']) ? (string) $in['impact'] : '';
        $likelihood = isset($in['likelihood']) ? (string) $in['likelihood'] : '';
        $level = isset($in['level']) ? (string) $in['level'] : '';
        if ($impact === '' || $likelihood === '' || $level === '') {
            $this->_fail(400, 'impact, likelihood, level required');
            return;
        }

        $row = $this->db->get_where('bf_feedback_incident', array('id' => $id))->row();
        if (!$row) {
            $this->_fail(404, 'feedback row not found');
            return;
        }
        $param = json_decode($row->dataset, true);
        if (!is_array($param)) {
            $param = array();
        }
        $param['risk_matrix'] = array(
            'impact' => $impact,
            'likelihood' => $likelihood,
            'level' => $level,
        );
        $this->db->where('id', $id);
        $ok = $this->db->update('bf_feedback_incident', array(
            'dataset' => json_encode($param),
        ));
        if ($ok) {
            $this->_ok(array('message' => 'Risk matrix updated'));
        } else {
            $this->_fail(500, 'Database update failed');
        }
    }

    /**
     * POST: uid, id, pid, empid, priority, status=EditPriority
     */
    public function edit_priority_type()
    {
        $this->_json_response();
        $in = $this->_input_array();
        if (!$this->_require_uid($in)) {
            return;
        }
        $id = isset($in['id']) ? trim((string) $in['id']) : '';
        $pid = isset($in['pid']) ? trim((string) $in['pid']) : '';
        if ($id === '' || $pid === '') {
            $this->_fail(400, 'id and pid required');
            return;
        }
        $id = $this->_resolve_feedback_id($pid, $id);
        if (!$this->_verify_ticket_feedback($pid, $id)) {
            $this->_fail(403, 'ticket/feedback mismatch');
            return;
        }
        $priority = isset($in['priority']) ? (string) $in['priority'] : '';

        $row = $this->db->get_where('bf_feedback_incident', array('id' => $id))->row();
        if (!$row) {
            $this->_fail(404, 'feedback row not found');
            return;
        }
        $param = json_decode($row->dataset, true);
        if (!is_array($param)) {
            $param = array();
        }
        $param['priority'] = $priority;
        $this->db->where('id', $id);
        $ok = $this->db->update('bf_feedback_incident', array(
            'dataset' => json_encode($param),
        ));
        if ($ok) {
            $this->_ok(array('message' => 'Priority updated'));
        } else {
            $this->_fail(500, 'Database update failed');
        }
    }

    /**
     * POST: uid, id, pid, incident_type, status=EditSeverity
     */
    public function edit_priority_serverity()
    {
        $this->_json_response();
        $in = $this->_input_array();
        if (!$this->_require_uid($in)) {
            return;
        }
        $id = isset($in['id']) ? trim((string) $in['id']) : '';
        $pid = isset($in['pid']) ? trim((string) $in['pid']) : '';
        if ($id === '' || $pid === '') {
            $this->_fail(400, 'id and pid required');
            return;
        }
        $id = $this->_resolve_feedback_id($pid, $id);
        if (!$this->_verify_ticket_feedback($pid, $id)) {
            $this->_fail(403, 'ticket/feedback mismatch');
            return;
        }
        $incidentType = isset($in['incident_type']) ? (string) $in['incident_type'] : '';

        $row = $this->db->get_where('bf_feedback_incident', array('id' => $id))->row();
        if (!$row) {
            $this->_fail(404, 'feedback row not found');
            return;
        }
        $param = json_decode($row->dataset, true);
        if (!is_array($param)) {
            $param = array();
        }
        $param['incident_type'] = $incidentType;
        $this->db->where('id', $id);
        $ok = $this->db->update('bf_feedback_incident', array(
            'dataset' => json_encode($param),
        ));
        if ($ok) {
            $this->_ok(array('message' => 'Severity updated'));
        } else {
            $this->_fail(500, 'Database update failed');
        }
    }

    // -------------------------------------------------------------------------

    private function _json_response()
    {
        $this->output->set_content_type('application/json');
    }

    private function _input_array()
    {
        $raw = file_get_contents('php://input');
        $json = json_decode($raw, true);
        if (is_array($json)) {
            return $json;
        }
        return $this->input->post();
    }

    /**
     * Require uid to exist in user table (same idea as other mobile APIs).
     */
    private function _require_uid(array $in)
    {
        $uid = isset($in['uid']) ? trim((string) $in['uid']) : '';
        if ($uid === '') {
            $this->_fail(403, 'uid required');
            return false;
        }
        $q = $this->db->get_where('user', array('user_id' => $uid), 1);
        if ($q->num_rows() === 0) {
            $this->_fail(403, 'invalid uid');
            return false;
        }
        return true;
    }

    /**
     * Flutter may send ticket id for both id and pid when feedbackId is unknown.
     */
    private function _resolve_feedback_id($ticketId, $idOrTicket)
    {
        if ((string) $idOrTicket !== (string) $ticketId) {
            return $idOrTicket;
        }
        $row = $this->db->get_where('tickets_incident', array('id' => $ticketId), 1)->row();
        if ($row && isset($row->feedbackid) && $row->feedbackid !== '') {
            return (string) $row->feedbackid;
        }
        return $idOrTicket;
    }

    private function _verify_ticket_feedback($ticketId, $feedbackId)
    {
        $q = $this->db->get_where('tickets_incident', array(
            'id' => $ticketId,
            'feedbackid' => $feedbackId,
        ), 1);
        return $q->num_rows() > 0;
    }

    private function _ok(array $data)
    {
        $this->output->set_status_header(200);
        echo json_encode(array_merge(array('success' => true), $data));
    }

    private function _fail($code, $message)
    {
        $this->output->set_status_header((int) $code);
        echo json_encode(array('success' => false, 'message' => $message));
    }
}
