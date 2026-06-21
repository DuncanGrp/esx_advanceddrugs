-- Advanced Drugs Database Schema
-- ESX Legacy + ox_inventory compatible

-- Drop existing tables (if updating)
DROP TABLE IF EXISTS `player_addiction`;
DROP TABLE IF EXISTS `drug_plants`;
DROP TABLE IF EXISTS `drug_dealers`;
DROP TABLE IF EXISTS `drug_quality`;
DROP TABLE IF EXISTS `drug_sales_stats`;
DROP TABLE IF EXISTS `drug_territory`;

-- ===========================
-- DRUG PLANTS TABLE
-- ===========================

CREATE TABLE `drug_plants` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `owner_id` INT NOT NULL,
    `owner_name` VARCHAR(50) NOT NULL,
    `drug_type` VARCHAR(50) NOT NULL,
    `coords_x` FLOAT NOT NULL,
    `coords_y` FLOAT NOT NULL,
    `coords_z` FLOAT NOT NULL,
    `stage` VARCHAR(20) NOT NULL DEFAULT 'seed',
    `growth_percentage` INT DEFAULT 0,
    `health` INT DEFAULT 100,
    `water_level` INT DEFAULT 100,
    `fertilizer_level` INT DEFAULT 100,
    `indoor` TINYINT DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `last_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `destroyed` TINYINT DEFAULT 0,
    INDEX `idx_owner` (`owner_id`),
    INDEX `idx_drug_type` (`drug_type`),
    UNIQUE KEY `unique_plant` (`owner_id`, `coords_x`, `coords_y`, `coords_z`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ===========================
-- ADDICTION TABLE
-- ===========================

CREATE TABLE `player_addiction` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NOT NULL,
    `identifier` VARCHAR(100) NOT NULL UNIQUE,
    `weed_addiction` INT DEFAULT 0,
    `cocaine_addiction` INT DEFAULT 0,
    `meth_addiction` INT DEFAULT 0,
    `fentanyl_addiction` INT DEFAULT 0,
    `xanax_addiction` INT DEFAULT 0,
    `total_addiction` INT DEFAULT 0,
    
    -- Tolerance levels
    `weed_tolerance` INT DEFAULT 0,
    `cocaine_tolerance` INT DEFAULT 0,
    `meth_tolerance` INT DEFAULT 0,
    `fentanyl_tolerance` INT DEFAULT 0,
    `xanax_tolerance` INT DEFAULT 0,
    
    -- Last use timestamps
    `weed_last_use` INT DEFAULT 0,
    `cocaine_last_use` INT DEFAULT 0,
    `meth_last_use` INT DEFAULT 0,
    `fentanyl_last_use` INT DEFAULT 0,
    `xanax_last_use` INT DEFAULT 0,
    
    -- Withdrawal status
    `in_withdrawal` TINYINT DEFAULT 0,
    `withdrawal_drug` VARCHAR(50),
    `withdrawal_start` INT DEFAULT 0,
    
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_identifier` (`identifier`),
    INDEX `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ===========================
-- DRUG DEALERS TABLE
-- ===========================

CREATE TABLE `drug_dealers` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `dealer_id` VARCHAR(50) NOT NULL UNIQUE,
    `name` VARCHAR(100) NOT NULL,
    `location_id` INT NOT NULL,
    `coords_x` FLOAT NOT NULL,
    `coords_y` FLOAT NOT NULL,
    `coords_z` FLOAT NOT NULL,
    `heading` FLOAT DEFAULT 0.0,
    
    -- Inventory
    `weed_stock` INT DEFAULT 0,
    `cocaine_stock` INT DEFAULT 0,
    `meth_stock` INT DEFAULT 0,
    `fentanyl_stock` INT DEFAULT 0,
    `xanax_stock` INT DEFAULT 0,
    
    -- Reputation & Pricing
    `reputation` INT DEFAULT 50,
    `price_modifier` FLOAT DEFAULT 1.0,
    `last_restocked` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Stats
    `total_sales` INT DEFAULT 0,
    `customers_served` INT DEFAULT 0,
    
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_location` (`location_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ===========================
-- DRUG QUALITY TABLE
-- ===========================

CREATE TABLE `drug_quality` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `owner_id` INT NOT NULL,
    `drug_type` VARCHAR(50) NOT NULL,
    `quality_level` VARCHAR(20) NOT NULL,
    `batch_id` VARCHAR(100) NOT NULL UNIQUE,
    `quantity` INT DEFAULT 0,
    `price_multiplier` FLOAT DEFAULT 1.0,
    `purity_percentage` INT DEFAULT 100,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `expires_at` TIMESTAMP NULL,
    INDEX `idx_owner` (`owner_id`),
    INDEX `idx_drug_type` (`drug_type`),
    INDEX `idx_batch` (`batch_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ===========================
-- SALES STATISTICS TABLE
-- ===========================

CREATE TABLE `drug_sales_stats` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `seller_id` INT NOT NULL,
    `seller_name` VARCHAR(50) NOT NULL,
    `drug_type` VARCHAR(50) NOT NULL,
    `quality_level` VARCHAR(20) NOT NULL,
    `quantity_sold` INT DEFAULT 0,
    `price_per_unit` INT DEFAULT 0,
    `total_amount` INT DEFAULT 0,
    `buyer_type` VARCHAR(50) DEFAULT 'npc', -- 'npc', 'player', 'dealer'
    `police_alert` TINYINT DEFAULT 0,
    
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_seller` (`seller_id`),
    INDEX `idx_drug_type` (`drug_type`),
    INDEX `idx_date` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ===========================
-- TERRITORY TABLE (Optional)
-- ===========================

CREATE TABLE `drug_territory` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `owner_id` INT NOT NULL,
    `owner_gang` VARCHAR(50) NOT NULL,
    `coords_x` FLOAT NOT NULL,
    `coords_y` FLOAT NOT NULL,
    `coords_z` FLOAT NOT NULL,
    `radius` INT DEFAULT 100,
    `territory_type` VARCHAR(50) NOT NULL, -- 'dealing', 'manufacturing', 'farming'
    `protected` TINYINT DEFAULT 0,
    `last_claimed` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `claimed_until` TIMESTAMP NULL,
    INDEX `idx_owner` (`owner_id`),
    INDEX `idx_gang` (`owner_gang`),
    INDEX `idx_type` (`territory_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ===========================
-- DIRTY MONEY TABLE
-- ===========================

CREATE TABLE `player_dirty_money` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NOT NULL,
    `identifier` VARCHAR(100) NOT NULL UNIQUE,
    `dirty_money` INT DEFAULT 0,
    `last_earned` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `last_laundered` TIMESTAMP NULL,
    INDEX `idx_identifier` (`identifier`),
    INDEX `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ===========================
-- PLAYER PROCESSING COOLDOWN
-- ===========================

CREATE TABLE `player_processing_cooldown` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NOT NULL,
    `identifier` VARCHAR(100) NOT NULL,
    `drug_type` VARCHAR(50) NOT NULL,
    `location_id` INT NOT NULL,
    `cooldown_until` BIGINT NOT NULL,
    UNIQUE KEY `unique_cooldown` (`identifier`, `drug_type`, `location_id`),
    INDEX `idx_identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ===========================
-- INSERT SAMPLE DEALER DATA
-- ===========================

INSERT INTO `drug_dealers` (`dealer_id`, `name`, `location_id`, `coords_x`, `coords_y`, `coords_z`, `heading`, `weed_stock`, `cocaine_stock`, `meth_stock`, `fentanyl_stock`, `xanax_stock`, `reputation`, `price_modifier`)
VALUES 
    ('dealer_001', 'Marcus', 1, 324.35, -987.45, 29.41, 0.0, 5, 3, 2, 1, 4, 60, 0.95),
    ('dealer_002', 'DeShawn', 2, 410.25, -988.35, 29.41, 0.0, 4, 4, 3, 2, 3, 55, 1.0),
    ('dealer_003', 'Jerome', 3, -420.35, -328.45, 35.3, 0.0, 3, 2, 1, 0, 5, 50, 1.05),
    ('dealer_004', 'Andre', 4, -230.48, 6231.23, 31.48, 0.0, 6, 2, 2, 1, 4, 65, 0.90),
    ('dealer_005', 'Ghost', 5, -1273.45, -1376.25, 4.82, 0.0, 5, 3, 1, 1, 3, 58, 0.98);
