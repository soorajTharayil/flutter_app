-- =====================================================
-- SQL Schema for Device Approval Flow
-- Table: device_requests
-- =====================================================
-- This table stores device approval requests after user login
-- Admin can approve or block devices
-- =====================================================

CREATE TABLE IF NOT EXISTS `device_requests` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` INT(11) UNSIGNED NOT NULL COMMENT 'User ID from login',
  `name` VARCHAR(255) NOT NULL COMMENT 'User name',
  `email` VARCHAR(255) NOT NULL COMMENT 'User email',
  `device_name` VARCHAR(255) NOT NULL COMMENT 'Device name (e.g., Samsung Galaxy S21)',
  `platform` VARCHAR(50) NOT NULL COMMENT 'Platform: Android, iOS, or Web Browser',
  `device_id` VARCHAR(255) NOT NULL COMMENT 'Unique device identifier',
  `ip_address` VARCHAR(45) DEFAULT NULL COMMENT 'IP address from login request',
  `domain` VARCHAR(100) NOT NULL COMMENT 'Domain identifier (e.g., demo)',
  `status` ENUM('pending', 'approved', 'blocked', 'expired') DEFAULT 'pending' COMMENT 'Request status',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_device_user` (`device_id`, `user_id`, `domain`),
  KEY `idx_device_id` (`device_id`),
  KEY `idx_status` (`status`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_domain` (`domain`),
  KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Device approval requests table';

-- =====================================================
-- Indexes Explanation:
-- - unique_device_user: Prevents duplicate requests for same device+user+domain
-- - idx_device_id: Fast lookup for device status checks
-- - idx_status: Filter requests by status
-- - idx_user_id: Filter by user
-- - idx_domain: Filter by domain
-- - idx_created_at: For timeout cleanup queries
-- =====================================================

-- =====================================================
-- Table to track approved devices (one-time approval)
-- =====================================================
CREATE TABLE IF NOT EXISTS `approved_devices` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `device_id` VARCHAR(255) NOT NULL COMMENT 'Unique device identifier',
  `domain` VARCHAR(100) NOT NULL COMMENT 'Domain identifier',
  `user_id` INT(11) UNSIGNED NOT NULL COMMENT 'User ID',
  `approved_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_device_domain` (`device_id`, `domain`),
  KEY `idx_device_id` (`device_id`),
  KEY `idx_domain` (`domain`),
  KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Track approved devices for one-time approval';

