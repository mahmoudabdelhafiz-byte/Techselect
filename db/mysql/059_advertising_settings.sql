-- Admin-managed advertising / Google AdSense configuration
SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS advertising_settings (
  id TINYINT UNSIGNED NOT NULL PRIMARY KEY DEFAULT 1,
  enabled TINYINT(1) NOT NULL DEFAULT 0,
  adsense_client_id VARCHAR(40) NULL,
  auto_ads_enabled TINYINT(1) NOT NULL DEFAULT 1,
  page_types_json JSON NULL,
  updated_by_user_id BIGINT UNSIGNED NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_advertising_settings_user FOREIGN KEY(updated_by_user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO advertising_settings(id,enabled,auto_ads_enabled,page_types_json)
VALUES(1,0,1,JSON_ARRAY('software','category','capability','integration','comparison'));
