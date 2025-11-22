#!/bin/bash

# =====================================================
# Device Registration API Test Script
# =====================================================
# This script contains sample CURL commands to test
# the device registration and verification endpoints
# =====================================================

# Configuration
BASE_URL="https://demo.efeedor.com"
# For local testing, use: BASE_URL="http://localhost/your-project"

echo "=========================================="
echo "Device Registration API Test Script"
echo "=========================================="
echo ""

# =====================================================
# Test 1: Device Registration
# =====================================================
echo "Test 1: Registering Device..."
echo "----------------------------------------"

REGISTER_RESPONSE=$(curl -s -X POST "$BASE_URL/api/device/register" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "domain": "demo",
    "device_id": "test-device-'$(date +%s)'",
    "device_name": "Samsung Galaxy S21",
    "platform": "Android",
    "os_version": "12 (SDK 31)"
  }')

echo "Response:"
echo "$REGISTER_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$REGISTER_RESPONSE"
echo ""

# Extract token from response (requires jq or manual extraction)
TOKEN=$(echo "$REGISTER_RESPONSE" | grep -o '"token":"[^"]*' | cut -d'"' -f4)
DEVICE_ID=$(echo "$REGISTER_RESPONSE" | grep -o '"device_id":"[^"]*' | cut -d'"' -f4 || echo "test-device-$(date +%s)")

if [ -z "$TOKEN" ]; then
    echo "⚠️  Warning: Could not extract token from response"
    echo "Please manually extract the token and set it in TOKEN variable"
    echo ""
    read -p "Enter token manually (or press Enter to skip): " TOKEN
fi

if [ -z "$TOKEN" ]; then
    echo "Skipping verification test..."
    exit 0
fi

echo "Extracted Token: $TOKEN"
echo "Extracted Device ID: $DEVICE_ID"
echo ""

# =====================================================
# Test 2: Token Verification
# =====================================================
echo "Test 2: Verifying Token..."
echo "----------------------------------------"

VERIFY_RESPONSE=$(curl -s -X POST "$BASE_URL/api/device/verify" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d "{
    \"device_id\": \"$DEVICE_ID\",
    \"token\": \"$TOKEN\"
  }")

echo "Response:"
echo "$VERIFY_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$VERIFY_RESPONSE"
echo ""

# =====================================================
# Test 3: Admin Devices List (JSON API)
# =====================================================
echo "Test 3: Getting All Devices (Admin API)..."
echo "----------------------------------------"

ADMIN_RESPONSE=$(curl -s -X GET "$BASE_URL/api/device/admin_devices" \
  -H "Accept: application/json")

echo "Response:"
echo "$ADMIN_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$ADMIN_RESPONSE"
echo ""

# =====================================================
# Test 4: Admin Devices with Filters
# =====================================================
echo "Test 4: Getting Pending Devices Only..."
echo "----------------------------------------"

FILTERED_RESPONSE=$(curl -s -X GET "$BASE_URL/api/device/admin_devices?status=pending" \
  -H "Accept: application/json")

echo "Response:"
echo "$FILTERED_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$FILTERED_RESPONSE"
echo ""

echo "=========================================="
echo "Tests Complete!"
echo "=========================================="

# =====================================================
# Manual Test Commands (Copy and paste as needed)
# =====================================================

cat << 'EOF'

==========================================
Manual Test Commands
==========================================

1. Register Device:
curl -X POST https://demo.efeedor.com/api/device/register \
  -H "Content-Type: application/json" \
  -d '{
    "domain": "demo",
    "device_id": "test-device-123",
    "device_name": "iPhone 13 Pro",
    "platform": "iOS",
    "os_version": "15.0"
  }'

2. Verify Token:
curl -X POST https://demo.efeedor.com/api/device/verify \
  -H "Content-Type: application/json" \
  -d '{
    "device_id": "test-device-123",
    "token": "REG-ABCD1234"
  }'

3. Get All Devices (Admin):
curl https://demo.efeedor.com/api/device/admin_devices

4. Get Devices by Status:
curl "https://demo.efeedor.com/api/device/admin_devices?status=pending"

5. Get Devices by Tenant:
curl "https://demo.efeedor.com/api/device/admin_devices?tenant_id=demo"

==========================================
EOF

