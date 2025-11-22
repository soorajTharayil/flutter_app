-- =====================================================
-- SQL Schema for Token-Based Device Registration
-- Table: user_devices
-- =====================================================
-- This table stores device registration information
-- and one-time registration tokens for device approval
-- =====================================================

CREATE TABLE IF NOT EXISTS `user_devices` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `tenant_id` VARCHAR(100) NOT NULL COMMENT 'Tenant identifier (e.g., demo, krr)',
  `user_id` INT(11) UNSIGNED DEFAULT NULL COMMENT 'User ID after login (nullable until user logs in)',
  `device_id` VARCHAR(255) NOT NULL COMMENT 'Unique device identifier from device_info_plus',
  `device_name` VARCHAR(255) NOT NULL COMMENT 'Device name (e.g., Samsung Galaxy S21)',
  `platform` VARCHAR(50) NOT NULL COMMENT 'Platform: Android or iOS',
  `os_version` VARCHAR(100) DEFAULT NULL COMMENT 'OS version information',
  `ip_address` VARCHAR(45) DEFAULT NULL COMMENT 'IP address from registration request',
  `registration_token` VARCHAR(50) NOT NULL COMMENT 'One-time registration token (e.g., REG-ABCD1234)',
  `token_expiry` DATETIME NOT NULL COMMENT 'Token expiration time (30 minutes from creation)',
  `token_used` TINYINT(1) DEFAULT 0 COMMENT 'Flag: 1 if token has been used, 0 if unused',
  `status` ENUM('pending', 'approved', 'blocked') DEFAULT 'pending' COMMENT 'Device status',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_device_tenant` (`tenant_id`, `device_id`),
  KEY `idx_registration_token` (`registration_token`),
  KEY `idx_status` (`status`),
  KEY `idx_tenant_id` (`tenant_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_token_expiry` (`token_expiry`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Device registration and token management table';

-- =====================================================
-- Indexes Explanation:
-- - unique_device_tenant: Prevents duplicate device registrations per tenant
-- - idx_registration_token: Fast lookup for token verification
-- - idx_status: Filter devices by status (pending/approved/blocked)
-- - idx_tenant_id: Filter by tenant
-- - idx_user_id: Link devices to users after login
-- - idx_token_expiry: Cleanup expired tokens
-- =====================================================

