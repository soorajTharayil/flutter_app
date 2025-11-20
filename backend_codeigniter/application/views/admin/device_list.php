<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Device Registration Management - Admin Panel</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            background: #f5f5f5;
            color: #333;
            line-height: 1.6;
        }
        
        .container {
            max-width: 1400px;
            margin: 0 auto;
            padding: 20px;
        }
        
        .header {
            background: linear-gradient(135deg, #009688 0%, #00796b 100%);
            color: white;
            padding: 30px;
            border-radius: 10px;
            margin-bottom: 30px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }
        
        .header h1 {
            font-size: 28px;
            margin-bottom: 10px;
        }
        
        .header p {
            opacity: 0.9;
            font-size: 14px;
        }
        
        .filters {
            background: white;
            padding: 20px;
            border-radius: 10px;
            margin-bottom: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.05);
            display: flex;
            gap: 15px;
            flex-wrap: wrap;
            align-items: center;
        }
        
        .filters label {
            font-weight: 600;
            color: #555;
            font-size: 14px;
        }
        
        .filters select,
        .filters input {
            padding: 8px 12px;
            border: 1px solid #ddd;
            border-radius: 5px;
            font-size: 14px;
        }
        
        .filters button {
            padding: 8px 20px;
            background: #009688;
            color: white;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-size: 14px;
            font-weight: 600;
        }
        
        .filters button:hover {
            background: #00796b;
        }
        
        .stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin-bottom: 20px;
        }
        
        .stat-card {
            background: white;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.05);
        }
        
        .stat-card h3 {
            font-size: 12px;
            color: #777;
            text-transform: uppercase;
            margin-bottom: 8px;
        }
        
        .stat-card .number {
            font-size: 32px;
            font-weight: bold;
            color: #009688;
        }
        
        .table-container {
            background: white;
            border-radius: 10px;
            overflow: hidden;
            box-shadow: 0 2px 4px rgba(0,0,0,0.05);
        }
        
        table {
            width: 100%;
            border-collapse: collapse;
        }
        
        thead {
            background: #009688;
            color: white;
        }
        
        th {
            padding: 15px;
            text-align: left;
            font-weight: 600;
            font-size: 13px;
            text-transform: uppercase;
        }
        
        td {
            padding: 15px;
            border-bottom: 1px solid #eee;
            font-size: 14px;
        }
        
        tbody tr:hover {
            background: #f9f9f9;
        }
        
        .status-badge {
            display: inline-block;
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 600;
            text-transform: uppercase;
        }
        
        .status-pending {
            background: #fff3cd;
            color: #856404;
        }
        
        .status-approved {
            background: #d4edda;
            color: #155724;
        }
        
        .status-blocked {
            background: #f8d7da;
            color: #721c24;
        }
        
        .token {
            font-family: 'Courier New', monospace;
            font-weight: bold;
            color: #009688;
            background: #e0f2f1;
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 13px;
        }
        
        .action-btn {
            padding: 6px 12px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-size: 12px;
            font-weight: 600;
            margin-right: 5px;
        }
        
        .btn-approve {
            background: #28a745;
            color: white;
        }
        
        .btn-block {
            background: #dc3545;
            color: white;
        }
        
        .btn-approve:hover {
            background: #218838;
        }
        
        .btn-block:hover {
            background: #c82333;
        }
        
        .empty-state {
            text-align: center;
            padding: 60px 20px;
            color: #999;
        }
        
        .empty-state svg {
            width: 80px;
            height: 80px;
            margin-bottom: 20px;
            opacity: 0.5;
        }
        
        .refresh-btn {
            position: fixed;
            bottom: 30px;
            right: 30px;
            width: 60px;
            height: 60px;
            background: #009688;
            color: white;
            border: none;
            border-radius: 50%;
            font-size: 24px;
            cursor: pointer;
            box-shadow: 0 4px 12px rgba(0,0,0,0.15);
            transition: transform 0.2s;
        }
        
        .refresh-btn:hover {
            transform: scale(1.1);
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔐 Device Registration Management</h1>
            <p>View and manage all registered devices and their registration tokens</p>
        </div>
        
        <div class="filters">
            <div>
                <label>Tenant:</label>
                <select id="filter-tenant">
                    <option value="">All Tenants</option>
                    <?php if (isset($tenants) && is_array($tenants)): ?>
                        <?php foreach ($tenants as $tenant): ?>
                            <option value="<?php echo htmlspecialchars($tenant); ?>">
                                <?php echo htmlspecialchars($tenant); ?>
                            </option>
                        <?php endforeach; ?>
                    <?php endif; ?>
                </select>
            </div>
            <div>
                <label>Status:</label>
                <select id="filter-status">
                    <option value="">All Status</option>
                    <option value="pending">Pending</option>
                    <option value="approved">Approved</option>
                    <option value="blocked">Blocked</option>
                </select>
            </div>
            <button onclick="applyFilters()">Apply Filters</button>
            <button onclick="refreshData()" style="background: #17a2b8;">Refresh</button>
        </div>
        
        <div class="stats">
            <div class="stat-card">
                <h3>Total Devices</h3>
                <div class="number" id="stat-total">0</div>
            </div>
            <div class="stat-card">
                <h3>Pending</h3>
                <div class="number" id="stat-pending" style="color: #ffc107;">0</div>
            </div>
            <div class="stat-card">
                <h3>Approved</h3>
                <div class="number" id="stat-approved" style="color: #28a745;">0</div>
            </div>
            <div class="stat-card">
                <h3>Blocked</h3>
                <div class="number" id="stat-blocked" style="color: #dc3545;">0</div>
            </div>
        </div>
        
        <div class="table-container">
            <table id="devices-table">
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Tenant</th>
                        <th>Device Name</th>
                        <th>Platform</th>
                        <th>Device ID</th>
                        <th>IP Address</th>
                        <th>Registration Token</th>
                        <th>Status</th>
                        <th>Created At</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody id="devices-tbody">
                    <!-- Data will be loaded here -->
                </tbody>
            </table>
        </div>
    </div>
    
    <button class="refresh-btn" onclick="refreshData()" title="Refresh Data">🔄</button>
    
    <script>
        // Load devices data
        function loadDevices(tenantId = '', status = '') {
            let url = '<?php echo base_url("api/device/admin_devices"); ?>';
            const params = new URLSearchParams();
            if (tenantId) params.append('tenant_id', tenantId);
            if (status) params.append('status', status);
            if (params.toString()) url += '?' + params.toString();
            
            fetch(url)
                .then(response => response.json())
                .then(data => {
                    if (data.status === 'success') {
                        displayDevices(data.data);
                        updateStats(data.data);
                    } else {
                        console.error('Error loading devices:', data.message);
                    }
                })
                .catch(error => {
                    console.error('Error:', error);
                    document.getElementById('devices-tbody').innerHTML = 
                        '<tr><td colspan="10" class="empty-state">Error loading data</td></tr>';
                });
        }
        
        function displayDevices(devices) {
            const tbody = document.getElementById('devices-tbody');
            
            if (devices.length === 0) {
                tbody.innerHTML = '<tr><td colspan="10" class="empty-state">No devices found</td></tr>';
                return;
            }
            
            tbody.innerHTML = devices.map(device => `
                <tr>
                    <td>${device.id}</td>
                    <td><strong>${device.tenant_id || 'N/A'}</strong></td>
                    <td>${device.device_name || 'N/A'}</td>
                    <td>${device.platform || 'N/A'}</td>
                    <td><small>${device.device_id ? device.device_id.substring(0, 20) + '...' : 'N/A'}</small></td>
                    <td>${device.ip_address || 'N/A'}</td>
                    <td><span class="token">${device.registration_token || 'N/A'}</span></td>
                    <td><span class="status-badge status-${device.status || 'pending'}">${device.status || 'pending'}</span></td>
                    <td><small>${device.created_at || 'N/A'}</small></td>
                    <td>
                        ${device.status === 'pending' ? 
                            `<button class="action-btn btn-approve" onclick="updateStatus(${device.id}, 'approved')">Approve</button>
                             <button class="action-btn btn-block" onclick="updateStatus(${device.id}, 'blocked')">Block</button>` 
                            : ''}
                    </td>
                </tr>
            `).join('');
        }
        
        function updateStats(devices) {
            document.getElementById('stat-total').textContent = devices.length;
            document.getElementById('stat-pending').textContent = 
                devices.filter(d => d.status === 'pending').length;
            document.getElementById('stat-approved').textContent = 
                devices.filter(d => d.status === 'approved').length;
            document.getElementById('stat-blocked').textContent = 
                devices.filter(d => d.status === 'blocked').length;
        }
        
        function applyFilters() {
            const tenantId = document.getElementById('filter-tenant').value;
            const status = document.getElementById('filter-status').value;
            loadDevices(tenantId, status);
        }
        
        function refreshData() {
            applyFilters();
        }
        
        function updateStatus(deviceId, newStatus) {
            if (!confirm(`Are you sure you want to ${newStatus} this device?`)) {
                return;
            }
            
            // TODO: Implement API call to update device status
            // For now, just refresh the data
            alert('Status update functionality needs to be implemented in the backend');
            refreshData();
        }
        
        // Load data on page load
        document.addEventListener('DOMContentLoaded', function() {
            loadDevices();
        });
    </script>
</body>
</html>

