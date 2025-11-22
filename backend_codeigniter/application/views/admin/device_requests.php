<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Device Approval Requests - Admin Panel</title>
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
            max-width: 1600px;
            margin: 0 auto;
            padding: 20px;
        }

        .header {
            background: linear-gradient(135deg, #009688 0%, #00796b 100%);
            color: white;
            padding: 30px;
            border-radius: 10px;
            margin-bottom: 30px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
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
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
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

        .filters select {
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
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
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
            overflow-x: auto;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
        }

        table {
            width: 100%;
            border-collapse: collapse;
            min-width: 1200px;
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

        .status-expired {
            background: #e2e3e5;
            color: #383d41;
        }

        .device-id {
            font-family: 'Courier New', monospace;
            font-size: 12px;
            color: #666;
            word-break: break-all;
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

        .btn-approve:disabled,
        .btn-block:disabled {
            opacity: 0.5;
            cursor: not-allowed;
        }

        .empty-state {
            text-align: center;
            padding: 60px 20px;
            color: #999;
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
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
            transition: transform 0.2s;
        }

        .refresh-btn:hover {
            transform: scale(1.1);
        }

        .loading {
            text-align: center;
            padding: 20px;
            color: #999;
        }
    </style>
</head>

<body>
    <div class="container">
        <div class="header">
            <h1>🔐 Device Approval Requests</h1>
            <p>Review and approve/block device access requests from users</p>
        </div>

        <div class="filters">
            <div>
                <label>Domain:</label>
                <select id="filter-domain">
                    <option value="">All Domains</option>
                    <?php if (isset($domains) && is_array($domains)): ?>
                        <?php foreach ($domains as $domain): ?>
                            <option value="<?php echo htmlspecialchars($domain); ?>">
                                <?php echo htmlspecialchars($domain); ?>
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
                    <option value="expired">Expired</option>
                </select>
            </div>
            <button onclick="applyFilters()">Apply Filters</button>
            <button onclick="refreshData()" style="background: #17a2b8;">Refresh</button>
        </div>

        <div class="stats">
            <div class="stat-card">
                <h3>Total Requests</h3>
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
            <table id="requests-table">
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Name</th>
                        <th>Email</th>
                        <th>Device Name</th>
                        <th>Platform</th>
                        <th>Device ID</th>
                        <th>IP Address</th>
                        <th>Domain</th>
                        <th>Created At</th>
                        <th>Status</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody id="requests-tbody">
                    <tr>
                        <td colspan="11" class="loading">Loading...</td>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>

    <button class="refresh-btn" onclick="refreshData()" title="Refresh Data">🔄</button>

    <script>
        const baseUrl = '<?php echo base_url(); ?>';

        // Load requests data
        function loadRequests(domain = '', status = '') {
            let url = baseUrl + 'api/device/requests';
            const params = new URLSearchParams();
            if (domain) params.append('domain', domain);
            if (status) params.append('status', status);
            if (params.toString()) url += '?' + params.toString();

            fetch(url)
                .then(response => response.json())
                .then(data => {
                    if (data.status === 'success') {
                        displayRequests(data.data);
                        updateStats(data.data);
                    } else {
                        console.error('Error loading requests:', data.message);
                        document.getElementById('requests-tbody').innerHTML =
                            '<tr><td colspan="11" class="empty-state">Error loading data: ' + (data.message || 'Unknown error') + '</td></tr>';
                    }
                })
                .catch(error => {
                    console.error('Error:', error);
                    document.getElementById('requests-tbody').innerHTML =
                        '<tr><td colspan="11" class="empty-state">Error loading data. Please check your connection.</td></tr>';
                });
        }

        function displayRequests(requests) {
            const tbody = document.getElementById('requests-tbody');

            if (requests.length === 0) {
                tbody.innerHTML = '<tr><td colspan="11" class="empty-state">No device requests found</td></tr>';
                return;
            }

            tbody.innerHTML = requests.map(request => {
                const canApprove = request.status === 'pending';
                const canBlock = request.status === 'pending';

                return `
                    <tr>
                        <td>${request.id}</td>
                        <td><strong>${request.name || 'N/A'}</strong></td>
                        <td>${request.email || 'N/A'}</td>
                        <td>${request.device_name || 'N/A'}</td>
                        <td>${request.platform || 'N/A'}</td>
                        <td><span class="device-id">${request.device_id ? (request.device_id.length > 30 ? request.device_id.substring(0, 30) + '...' : request.device_id) : 'N/A'}</span></td>
                        <td>${request.ip_address || 'N/A'}</td>
                        <td><strong>${request.domain || 'N/A'}</strong></td>
                        <td><small>${request.created_at || 'N/A'}</small></td>
                        <td><span class="status-badge status-${request.status || 'pending'}">${request.status || 'pending'}</span></td>
                        <td>
                            ${canApprove ? `<button class="action-btn btn-approve" onclick="approveRequest(${request.id})">Approve</button>` : ''}
                            ${canBlock ? `<button class="action-btn btn-block" onclick="blockRequest(${request.id})">Block</button>` : ''}
                        </td>
                    </tr>
                `;
            }).join('');
        }

        function updateStats(requests) {
            document.getElementById('stat-total').textContent = requests.length;
            document.getElementById('stat-pending').textContent =
                requests.filter(r => r.status === 'pending').length;
            document.getElementById('stat-approved').textContent =
                requests.filter(r => r.status === 'approved').length;
            document.getElementById('stat-blocked').textContent =
                requests.filter(r => r.status === 'blocked').length;
        }

        function applyFilters() {
            const domain = document.getElementById('filter-domain').value;
            const status = document.getElementById('filter-status').value;
            loadRequests(domain, status);
        }

        function refreshData() {
            applyFilters();
        }

        function approveRequest(requestId) {
            if (!confirm('Are you sure you want to approve this device?')) {
                return;
            }

            // Ensure baseUrl ends with /
            const url = (baseUrl.endsWith('/') ? baseUrl : baseUrl + '/') + 'api/device/approve';

            fetch(url, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json'
                },
                body: JSON.stringify({
                    request_id: requestId
                })
            })
                .then(response => {
                    return response.text().then(text => {
                        try {
                            const data = JSON.parse(text);
                            return { ok: response.ok, data: data };
                        } catch (e) {
                            console.error('Raw response:', text);
                            throw new Error('Invalid JSON response: ' + text.substring(0, 100));
                        }
                    });
                })
                .then(result => {
                    if (result.ok && result.data && result.data.success === true) {
                        alert('Device approved successfully!');
                        location.reload();
                    } else {
                        const message = result.data ? (result.data.message || 'Failed to approve device') : 'Unknown error';
                        alert('Error: ' + message);
                    }
                })
                .catch(error => {
                    console.error('Error:', error);
                    console.log('Raw response:', error.message);
                    alert('Server error: ' + error.message);
                });
        }

        function blockRequest(requestId) {
            if (!confirm('Are you sure you want to block this device?')) {
                return;
            }

            // Ensure baseUrl ends with /
            const url = (baseUrl.endsWith('/') ? baseUrl : baseUrl + '/') + 'api/device/block';

            fetch(url, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json'
                },
                body: JSON.stringify({
                    request_id: requestId
                })
            })
                .then(response => {
                    return response.text().then(text => {
                        try {
                            const data = JSON.parse(text);
                            return { ok: response.ok, data: data };
                        } catch (e) {
                            console.error('Raw response:', text);
                            throw new Error('Invalid JSON response: ' + text.substring(0, 100));
                        }
                    });
                })
                .then(result => {
                    if (result.ok && result.data && result.data.success === true) {
                        alert('Device blocked successfully!');
                        location.reload();
                    } else {
                        const message = result.data ? (result.data.message || 'Failed to block device') : 'Unknown error';
                        alert('Error: ' + message);
                    }
                })
                .catch(error => {
                    console.error('Error:', error);
                    console.log('Raw response:', error.message);
                    alert('Server error: ' + error.message);
                });
        }

        // Auto-refresh every 30 seconds
        setInterval(refreshData, 30000);

        // Load data on page load
        document.addEventListener('DOMContentLoaded', function () {
            loadRequests();
        });
    </script>
</body>

</html>