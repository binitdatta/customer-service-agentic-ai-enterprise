-- MySQL dump 10.13  Distrib 8.0.45, for macos15 (x86_64)
--
-- Host: localhost    Database: order_ops_ai
-- ------------------------------------------------------
-- Server version	8.2.0

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `address`
--

DROP TABLE IF EXISTS `address`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `address` (
  `address_id` bigint NOT NULL AUTO_INCREMENT,
  `tenant_id` bigint NOT NULL,
  `customer_id` bigint DEFAULT NULL,
  `name_line` varchar(128) DEFAULT NULL,
  `line1` varchar(255) NOT NULL,
  `line2` varchar(255) DEFAULT NULL,
  `city` varchar(128) NOT NULL,
  `region` varchar(64) NOT NULL,
  `postal_code` varchar(32) NOT NULL,
  `country` char(2) NOT NULL,
  `is_validated` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`address_id`),
  KEY `ix_address_customer` (`tenant_id`,`customer_id`),
  KEY `fk_address_customer` (`customer_id`),
  CONSTRAINT `fk_address_customer` FOREIGN KEY (`customer_id`) REFERENCES `customer` (`customer_id`),
  CONSTRAINT `fk_address_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `tenant` (`tenant_id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `address`
--

LOCK TABLES `address` WRITE;
/*!40000 ALTER TABLE `address` DISABLE KEYS */;
INSERT INTO `address` VALUES (1,1,1,'Ava Patel','1020 W Addison St','Apt 12B','Chicago','IL','60613','US',1,'2026-02-03 11:30:18'),(2,1,1,'Ava Patel','401 N Michigan Ave','Ste 900','Chicago','IL','60611','US',1,'2026-02-03 11:30:18'),(3,1,2,'Noah Kim','55 E Monroe St',NULL,'Chicago','IL','60603','US',1,'2026-02-03 11:30:18'),(4,1,1,'Ava Patel','123 Main St',NULL,'Naperville','IL','60540','US',0,'2026-02-12 18:03:18'),(5,1,NULL,NULL,'200 Lake Shore Dr',NULL,'Chicago','IL','60611','US',0,'2026-02-20 18:47:05'),(6,1,1,NULL,'1200 MBK Drive',NULL,'Chicago','IL','60611','US',0,'2026-02-20 21:23:29');
/*!40000 ALTER TABLE `address` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `agent_run`
--

DROP TABLE IF EXISTS `agent_run`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `agent_run` (
  `agent_run_id` bigint NOT NULL AUTO_INCREMENT,
  `tenant_id` bigint NOT NULL,
  `correlation_id` varchar(64) NOT NULL,
  `channel` enum('WEB_UI','API','BATCH') NOT NULL DEFAULT 'WEB_UI',
  `input_text` text NOT NULL,
  `classification_json` json DEFAULT NULL,
  `state_json` json DEFAULT NULL,
  `final_response` text,
  `status` enum('STARTED','COMPLETED','FAILED') NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`agent_run_id`),
  UNIQUE KEY `ux_run_corr` (`tenant_id`,`correlation_id`),
  CONSTRAINT `fk_run_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `tenant` (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `agent_run`
--

LOCK TABLES `agent_run` WRITE;
/*!40000 ALTER TABLE `agent_run` DISABLE KEYS */;
/*!40000 ALTER TABLE `agent_run` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `alembic_version`
--

DROP TABLE IF EXISTS `alembic_version`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `alembic_version` (
  `version_num` varchar(32) NOT NULL,
  PRIMARY KEY (`version_num`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `alembic_version`
--

LOCK TABLES `alembic_version` WRITE;
/*!40000 ALTER TABLE `alembic_version` DISABLE KEYS */;
/*!40000 ALTER TABLE `alembic_version` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `app_user`
--

DROP TABLE IF EXISTS `app_user`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `app_user` (
  `user_id` bigint NOT NULL AUTO_INCREMENT,
  `tenant_id` bigint NOT NULL,
  `username` varchar(64) NOT NULL,
  `display_name` varchar(128) NOT NULL,
  `email` varchar(255) DEFAULT NULL,
  `role` enum('AGENT','SUPERVISOR','SYSTEM') NOT NULL DEFAULT 'AGENT',
  `status` enum('ACTIVE','DISABLED') NOT NULL DEFAULT 'ACTIVE',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `ux_user_tenant_username` (`tenant_id`,`username`),
  CONSTRAINT `fk_user_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `tenant` (`tenant_id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `app_user`
--

LOCK TABLES `app_user` WRITE;
/*!40000 ALTER TABLE `app_user` DISABLE KEYS */;
INSERT INTO `app_user` VALUES (1,1,'agent.jane','Jane Agent','jane@acme.example','AGENT','ACTIVE','2026-02-03 11:30:18'),(2,1,'super.sam','Sam Supervisor','sam@acme.example','SUPERVISOR','ACTIVE','2026-02-03 11:30:18'),(3,1,'system.bot','OrderOps System',NULL,'SYSTEM','ACTIVE','2026-02-03 11:30:18');
/*!40000 ALTER TABLE `app_user` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `customer`
--

DROP TABLE IF EXISTS `customer`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `customer` (
  `customer_id` bigint NOT NULL AUTO_INCREMENT,
  `tenant_id` bigint NOT NULL,
  `customer_ref` varchar(64) NOT NULL,
  `first_name` varchar(64) NOT NULL,
  `last_name` varchar(64) NOT NULL,
  `email` varchar(255) NOT NULL,
  `phone` varchar(32) DEFAULT NULL,
  `status` enum('ACTIVE','BLOCKED') NOT NULL DEFAULT 'ACTIVE',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`customer_id`),
  UNIQUE KEY `ux_customer_tenant_ref` (`tenant_id`,`customer_ref`),
  KEY `ix_customer_email` (`email`),
  CONSTRAINT `fk_customer_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `tenant` (`tenant_id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `customer`
--

LOCK TABLES `customer` WRITE;
/*!40000 ALTER TABLE `customer` DISABLE KEYS */;
INSERT INTO `customer` VALUES (1,1,'CUST-1001','Ava','Patel','ava.patel@example.com','+1-312-555-0101','ACTIVE','2026-02-03 11:30:18'),(2,1,'CUST-1002','Noah','Kim','noah.kim@example.com','+1-773-555-0199','ACTIVE','2026-02-03 11:30:18');
/*!40000 ALTER TABLE `customer` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `idempotency_key`
--

DROP TABLE IF EXISTS `idempotency_key`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `idempotency_key` (
  `idempotency_id` bigint NOT NULL AUTO_INCREMENT,
  `tenant_id` bigint NOT NULL,
  `scope` varchar(64) NOT NULL,
  `idempotency_key` varchar(128) NOT NULL,
  `request_hash` char(64) NOT NULL,
  `response_json` json DEFAULT NULL,
  `status` enum('IN_PROGRESS','SUCCEEDED','FAILED') NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`idempotency_id`),
  UNIQUE KEY `ux_idem` (`tenant_id`,`scope`,`idempotency_key`),
  CONSTRAINT `fk_idem_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `tenant` (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `idempotency_key`
--

LOCK TABLES `idempotency_key` WRITE;
/*!40000 ALTER TABLE `idempotency_key` DISABLE KEYS */;
/*!40000 ALTER TABLE `idempotency_key` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `inventory`
--

DROP TABLE IF EXISTS `inventory`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `inventory` (
  `inventory_id` bigint NOT NULL AUTO_INCREMENT,
  `tenant_id` bigint NOT NULL,
  `product_id` bigint NOT NULL,
  `location_code` varchar(64) NOT NULL,
  `on_hand_qty` int NOT NULL DEFAULT '0',
  `reserved_qty` int NOT NULL DEFAULT '0',
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`inventory_id`),
  UNIQUE KEY `ux_inv` (`tenant_id`,`product_id`,`location_code`),
  KEY `fk_inv_product` (`product_id`),
  CONSTRAINT `fk_inv_product` FOREIGN KEY (`product_id`) REFERENCES `product` (`product_id`),
  CONSTRAINT `fk_inv_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `tenant` (`tenant_id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `inventory`
--

LOCK TABLES `inventory` WRITE;
/*!40000 ALTER TABLE `inventory` DISABLE KEYS */;
INSERT INTO `inventory` VALUES (1,1,1,'CHI-DC',120,5,'2026-02-03 11:30:18'),(2,1,2,'CHI-DC',40,2,'2026-02-03 11:30:18');
/*!40000 ALTER TABLE `inventory` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `orders`
--

DROP TABLE IF EXISTS `orders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `orders` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `order_number` varchar(32) NOT NULL,
  `status` varchar(32) NOT NULL,
  `customer_id` bigint NOT NULL,
  `ship_to_address_id` bigint NOT NULL,
  `delivered_address_id` bigint DEFAULT NULL,
  `tracking_number` varchar(64) DEFAULT NULL,
  `carrier` varchar(32) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `ix_orders_order_number` (`order_number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `orders`
--

LOCK TABLES `orders` WRITE;
/*!40000 ALTER TABLE `orders` DISABLE KEYS */;
/*!40000 ALTER TABLE `orders` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `policy_rule`
--

DROP TABLE IF EXISTS `policy_rule`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `policy_rule` (
  `policy_rule_id` bigint NOT NULL AUTO_INCREMENT,
  `tenant_id` bigint NOT NULL,
  `rule_key` varchar(64) NOT NULL,
  `rule_json` json NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`policy_rule_id`),
  UNIQUE KEY `ux_policy` (`tenant_id`,`rule_key`),
  CONSTRAINT `fk_policy_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `tenant` (`tenant_id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `policy_rule`
--

LOCK TABLES `policy_rule` WRITE;
/*!40000 ALTER TABLE `policy_rule` DISABLE KEYS */;
INSERT INTO `policy_rule` VALUES (1,1,'REPLACEMENT_WINDOW_DAYS','{\"days\": 14, \"requires_delivery_scan\": true}',1,'2026-02-03 11:30:18'),(2,1,'ALLOW_OVERNIGHT_FOR_REPLACEMENT','{\"allowed\": true, \"max_order_total\": 150.00, \"priority_required\": \"HIGH\"}',1,'2026-02-03 11:30:18'),(3,1,'AUTO_REFUND_ALLOWED','{\"allowed\": false, \"requires_supervisor\": true}',1,'2026-02-03 11:30:18');
/*!40000 ALTER TABLE `policy_rule` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `product`
--

DROP TABLE IF EXISTS `product`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `product` (
  `product_id` bigint NOT NULL AUTO_INCREMENT,
  `tenant_id` bigint NOT NULL,
  `sku` varchar(64) NOT NULL,
  `name` varchar(255) NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`product_id`),
  UNIQUE KEY `ux_product_tenant_sku` (`tenant_id`,`sku`),
  CONSTRAINT `fk_product_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `tenant` (`tenant_id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `product`
--

LOCK TABLES `product` WRITE;
/*!40000 ALTER TABLE `product` DISABLE KEYS */;
INSERT INTO `product` VALUES (1,1,'SKU-RED-MUG','Ceramic Mug - Red',1,'2026-02-03 11:30:18'),(2,1,'SKU-BLK-TSHIRT-M','T-Shirt - Black - Medium',1,'2026-02-03 11:30:18');
/*!40000 ALTER TABLE `product` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `replacement_link`
--

DROP TABLE IF EXISTS `replacement_link`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `replacement_link` (
  `replacement_link_id` bigint NOT NULL AUTO_INCREMENT,
  `tenant_id` bigint NOT NULL,
  `original_order_id` bigint NOT NULL,
  `replacement_order_id` bigint NOT NULL,
  `reason_code` enum('WRONG_ADDRESS','LOST','DAMAGED','MISSING_ITEMS','OTHER') NOT NULL,
  `created_by_user_id` bigint DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`replacement_link_id`),
  UNIQUE KEY `ux_repl` (`tenant_id`,`original_order_id`,`replacement_order_id`),
  KEY `fk_repl_orig` (`original_order_id`),
  KEY `fk_repl_new` (`replacement_order_id`),
  KEY `fk_repl_user` (`created_by_user_id`),
  CONSTRAINT `fk_repl_new` FOREIGN KEY (`replacement_order_id`) REFERENCES `sales_order` (`order_id`),
  CONSTRAINT `fk_repl_orig` FOREIGN KEY (`original_order_id`) REFERENCES `sales_order` (`order_id`),
  CONSTRAINT `fk_repl_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `tenant` (`tenant_id`),
  CONSTRAINT `fk_repl_user` FOREIGN KEY (`created_by_user_id`) REFERENCES `app_user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `replacement_link`
--

LOCK TABLES `replacement_link` WRITE;
/*!40000 ALTER TABLE `replacement_link` DISABLE KEYS */;
/*!40000 ALTER TABLE `replacement_link` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sales_order`
--

DROP TABLE IF EXISTS `sales_order`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sales_order` (
  `order_id` bigint NOT NULL AUTO_INCREMENT,
  `tenant_id` bigint NOT NULL,
  `order_number` varchar(32) NOT NULL,
  `customer_id` bigint NOT NULL,
  `bill_to_address_id` bigint DEFAULT NULL,
  `ship_to_address_id` bigint NOT NULL,
  `order_status` enum('CREATED','PAID','FULFILLING','SHIPPED','DELIVERED','CANCELLED','CLOSED') NOT NULL,
  `currency` char(3) NOT NULL DEFAULT 'USD',
  `order_total` decimal(12,2) NOT NULL DEFAULT '0.00',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`order_id`),
  UNIQUE KEY `ux_order_tenant_number` (`tenant_id`,`order_number`),
  KEY `ix_order_customer` (`tenant_id`,`customer_id`,`created_at`),
  KEY `fk_order_customer` (`customer_id`),
  KEY `fk_order_bill_to` (`bill_to_address_id`),
  KEY `fk_order_ship_to` (`ship_to_address_id`),
  CONSTRAINT `fk_order_bill_to` FOREIGN KEY (`bill_to_address_id`) REFERENCES `address` (`address_id`),
  CONSTRAINT `fk_order_customer` FOREIGN KEY (`customer_id`) REFERENCES `customer` (`customer_id`),
  CONSTRAINT `fk_order_ship_to` FOREIGN KEY (`ship_to_address_id`) REFERENCES `address` (`address_id`),
  CONSTRAINT `fk_order_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `tenant` (`tenant_id`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sales_order`
--

LOCK TABLES `sales_order` WRITE;
/*!40000 ALTER TABLE `sales_order` DISABLE KEYS */;
INSERT INTO `sales_order` VALUES (1,1,'88421',1,1,2,'DELIVERED','USD',39.98,'2026-02-03 11:30:18','2026-02-03 11:30:18'),(2,1,'88422',2,3,3,'SHIPPED','USD',14.99,'2026-02-03 11:30:18','2026-02-03 11:30:18'),(4,1,'91001',1,NULL,3,'DELIVERED','USD',129.99,'2026-02-06 19:42:55','2026-02-06 20:30:24'),(5,1,'91001-R1',1,NULL,3,'CREATED','USD',0.00,'2026-02-06 20:39:58','2026-02-06 20:39:58'),(6,1,'99001',1,1,2,'CREATED','USD',0.00,'2026-02-13 00:41:12','2026-02-13 00:41:12'),(7,1,'99002',1,1,4,'CREATED','USD',0.00,'2026-02-13 00:49:13','2026-02-13 03:55:06'),(8,1,'1771530566',1,1,2,'CREATED','USD',0.00,'2026-02-20 01:49:27','2026-02-20 01:49:27'),(9,1,'1771600184',1,1,5,'CREATED','USD',0.00,'2026-02-20 21:09:44','2026-02-21 00:47:06'),(10,1,'1771622461',1,1,6,'CREATED','USD',0.00,'2026-02-21 03:21:02','2026-02-21 03:23:30');
/*!40000 ALTER TABLE `sales_order` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sales_order_event`
--

DROP TABLE IF EXISTS `sales_order_event`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sales_order_event` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `tenant_id` bigint NOT NULL,
  `order_id` bigint NOT NULL,
  `order_number` varchar(64) NOT NULL,
  `event_type` varchar(64) NOT NULL,
  `message` varchar(1024) DEFAULT NULL,
  `actor_sub` varchar(64) DEFAULT NULL,
  `actor_username` varchar(128) DEFAULT NULL,
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  KEY `idx_soe_order_id` (`order_id`),
  KEY `idx_soe_order_number` (`order_number`),
  KEY `idx_soe_tenant_created` (`tenant_id`,`created_at`),
  KEY `idx_soe_event_type` (`event_type`)
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sales_order_event`
--

LOCK TABLES `sales_order_event` WRITE;
/*!40000 ALTER TABLE `sales_order_event` DISABLE KEYS */;
INSERT INTO `sales_order_event` VALUES (1,1,4,'91001','ORDER_CREATED','total=129.99 USD','4f1eb95d-5e11-4737-b442-260b960899fa','alice','2026-02-06 13:42:55.387141'),(2,1,4,'91001','ADDRESS_UPDATED','2 -> 3','4f1eb95d-5e11-4737-b442-260b960899fa','alice','2026-02-06 13:54:49.629341'),(3,1,4,'91001','STATUS_UPDATED','CREATED -> PAID; source=OPS_TOOL; notes=manual status correction','4f1eb95d-5e11-4737-b442-260b960899fa','alice','2026-02-06 14:18:42.475030'),(4,1,4,'91001','STATUS_UPDATED','PAID -> FULFILLING; source=OPS_TOOL; notes=manual status correction','4f1eb95d-5e11-4737-b442-260b960899fa','alice','2026-02-06 14:22:07.891339'),(5,1,4,'91001','STATUS_UPDATED','FULFILLING -> SHIPPED; source=OPS_TOOL; notes=manual status correction','4f1eb95d-5e11-4737-b442-260b960899fa','alice','2026-02-06 14:29:52.845384'),(6,1,4,'91001','STATUS_UPDATED','SHIPPED -> DELIVERED; source=OPS_TOOL; notes=manual status correction','4f1eb95d-5e11-4737-b442-260b960899fa','alice','2026-02-06 14:30:24.125597'),(7,1,4,'91001','REPLACEMENT_REQUESTED','replacement=91001-R1; ship_speed=STANDARD','4f1eb95d-5e11-4737-b442-260b960899fa','alice','2026-02-06 14:39:58.412773'),(8,1,5,'91001-R1','REPLACEMENT_CREATED','original=91001; ship_speed=STANDARD','4f1eb95d-5e11-4737-b442-260b960899fa','alice','2026-02-06 14:39:58.418180'),(9,1,6,'99001','ORDER_CREATED','total=0.00 USD',NULL,NULL,'2026-02-12 18:41:12.546189'),(10,1,7,'99002','ORDER_CREATED','total=0.00 USD',NULL,NULL,'2026-02-12 18:49:13.288273'),(11,1,7,'99002','ADDRESS_UPDATED','2 -> 4',NULL,NULL,'2026-02-12 21:55:06.361633'),(12,1,8,'1771530566','ORDER_CREATED','total=0.00 USD',NULL,NULL,'2026-02-19 19:49:27.555934'),(13,1,9,'1771600184','ORDER_CREATED','total=0.00 USD',NULL,NULL,'2026-02-20 15:09:44.697996'),(14,1,9,'1771600184','ADDRESS_UPDATED','2 -> 5',NULL,NULL,'2026-02-20 18:47:05.691562'),(15,1,10,'1771622461','ORDER_CREATED','total=0.00 USD',NULL,NULL,'2026-02-20 21:21:02.322564'),(16,1,10,'1771622461','ADDRESS_UPDATED','2 -> 5',NULL,NULL,'2026-02-20 21:22:23.204612'),(17,1,10,'1771622461','ADDRESS_UPDATED','5 -> 6',NULL,NULL,'2026-02-20 21:23:29.594378');
/*!40000 ALTER TABLE `sales_order_event` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sales_order_line`
--

DROP TABLE IF EXISTS `sales_order_line`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sales_order_line` (
  `order_line_id` bigint NOT NULL AUTO_INCREMENT,
  `tenant_id` bigint NOT NULL,
  `order_id` bigint NOT NULL,
  `line_no` int NOT NULL,
  `product_id` bigint NOT NULL,
  `sku` varchar(64) NOT NULL,
  `qty` int NOT NULL,
  `unit_price` decimal(12,2) NOT NULL,
  `line_total` decimal(12,2) NOT NULL,
  `fulfillment_status` enum('OPEN','ALLOCATED','SHIPPED','DELIVERED','CANCELLED') NOT NULL DEFAULT 'OPEN',
  PRIMARY KEY (`order_line_id`),
  UNIQUE KEY `ux_line` (`tenant_id`,`order_id`,`line_no`),
  KEY `ix_line_order` (`tenant_id`,`order_id`),
  KEY `fk_line_order` (`order_id`),
  KEY `fk_line_product` (`product_id`),
  CONSTRAINT `fk_line_order` FOREIGN KEY (`order_id`) REFERENCES `sales_order` (`order_id`),
  CONSTRAINT `fk_line_product` FOREIGN KEY (`product_id`) REFERENCES `product` (`product_id`),
  CONSTRAINT `fk_line_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `tenant` (`tenant_id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sales_order_line`
--

LOCK TABLES `sales_order_line` WRITE;
/*!40000 ALTER TABLE `sales_order_line` DISABLE KEYS */;
INSERT INTO `sales_order_line` VALUES (1,1,1,1,1,'SKU-RED-MUG',1,14.99,14.99,'DELIVERED'),(2,1,1,2,2,'SKU-BLK-TSHIRT-M',1,24.99,24.99,'DELIVERED'),(3,1,2,1,1,'SKU-RED-MUG',1,14.99,14.99,'SHIPPED');
/*!40000 ALTER TABLE `sales_order_line` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `shipment`
--

DROP TABLE IF EXISTS `shipment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `shipment` (
  `shipment_id` bigint NOT NULL AUTO_INCREMENT,
  `tenant_id` bigint NOT NULL,
  `order_id` bigint NOT NULL,
  `carrier` varchar(64) NOT NULL,
  `service_level` varchar(64) NOT NULL,
  `ship_status` enum('CREATED','LABEL_CREATED','IN_TRANSIT','OUT_FOR_DELIVERY','DELIVERED','EXCEPTION','RETURNED') NOT NULL,
  `ship_from_location` varchar(64) NOT NULL,
  `shipped_at` datetime DEFAULT NULL,
  `delivered_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`shipment_id`),
  KEY `ix_ship_order` (`tenant_id`,`order_id`),
  KEY `fk_ship_order` (`order_id`),
  CONSTRAINT `fk_ship_order` FOREIGN KEY (`order_id`) REFERENCES `sales_order` (`order_id`),
  CONSTRAINT `fk_ship_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `tenant` (`tenant_id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `shipment`
--

LOCK TABLES `shipment` WRITE;
/*!40000 ALTER TABLE `shipment` DISABLE KEYS */;
INSERT INTO `shipment` VALUES (1,1,1,'FedEx','Overnight','DELIVERED','CHI-DC','2026-02-01 18:10:00','2026-02-02 10:22:00','2026-02-03 11:30:18'),(2,1,2,'UPS','Ground','IN_TRANSIT','CHI-DC','2026-02-02 14:40:00',NULL,'2026-02-03 11:30:18');
/*!40000 ALTER TABLE `shipment` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `shipment_package`
--

DROP TABLE IF EXISTS `shipment_package`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `shipment_package` (
  `package_id` bigint NOT NULL AUTO_INCREMENT,
  `tenant_id` bigint NOT NULL,
  `shipment_id` bigint NOT NULL,
  `tracking_number` varchar(64) NOT NULL,
  `weight_oz` int DEFAULT NULL,
  PRIMARY KEY (`package_id`),
  UNIQUE KEY `ux_pkg_track` (`tenant_id`,`tracking_number`),
  KEY `ix_pkg_ship` (`tenant_id`,`shipment_id`),
  KEY `fk_pkg_ship` (`shipment_id`),
  CONSTRAINT `fk_pkg_ship` FOREIGN KEY (`shipment_id`) REFERENCES `shipment` (`shipment_id`),
  CONSTRAINT `fk_pkg_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `tenant` (`tenant_id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `shipment_package`
--

LOCK TABLES `shipment_package` WRITE;
/*!40000 ALTER TABLE `shipment_package` DISABLE KEYS */;
INSERT INTO `shipment_package` VALUES (1,1,1,'FDX123456789',32),(2,1,2,'1Z999AA10123456784',24);
/*!40000 ALTER TABLE `shipment_package` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `support_ticket`
--

DROP TABLE IF EXISTS `support_ticket`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `support_ticket` (
  `ticket_id` bigint NOT NULL AUTO_INCREMENT,
  `tenant_id` bigint NOT NULL,
  `ticket_number` varchar(32) NOT NULL,
  `customer_id` bigint NOT NULL,
  `order_id` bigint DEFAULT NULL,
  `category` enum('DELIVERY_ISSUE','REPLACEMENT','REFUND','ADDRESS_CHANGE','OTHER') NOT NULL,
  `priority` enum('LOW','NORMAL','HIGH','URGENT') NOT NULL DEFAULT 'NORMAL',
  `status` enum('OPEN','IN_PROGRESS','WAITING_CUSTOMER','RESOLVED','CLOSED') NOT NULL DEFAULT 'OPEN',
  `summary` varchar(255) NOT NULL,
  `created_by_user_id` bigint DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`ticket_id`),
  UNIQUE KEY `ux_ticket` (`tenant_id`,`ticket_number`),
  KEY `ix_ticket_order` (`tenant_id`,`order_id`),
  KEY `fk_ticket_customer` (`customer_id`),
  KEY `fk_ticket_order` (`order_id`),
  KEY `fk_ticket_user` (`created_by_user_id`),
  CONSTRAINT `fk_ticket_customer` FOREIGN KEY (`customer_id`) REFERENCES `customer` (`customer_id`),
  CONSTRAINT `fk_ticket_order` FOREIGN KEY (`order_id`) REFERENCES `sales_order` (`order_id`),
  CONSTRAINT `fk_ticket_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `tenant` (`tenant_id`),
  CONSTRAINT `fk_ticket_user` FOREIGN KEY (`created_by_user_id`) REFERENCES `app_user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `support_ticket`
--

LOCK TABLES `support_ticket` WRITE;
/*!40000 ALTER TABLE `support_ticket` DISABLE KEYS */;
/*!40000 ALTER TABLE `support_ticket` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `support_ticket_event`
--

DROP TABLE IF EXISTS `support_ticket_event`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `support_ticket_event` (
  `ticket_event_id` bigint NOT NULL AUTO_INCREMENT,
  `tenant_id` bigint NOT NULL,
  `ticket_id` bigint NOT NULL,
  `event_type` enum('NOTE','STATUS_CHANGE','CUSTOMER_MESSAGE','SYSTEM_ACTION') NOT NULL,
  `message` text NOT NULL,
  `created_by_user_id` bigint DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`ticket_event_id`),
  KEY `ix_ticket_evt` (`tenant_id`,`ticket_id`,`created_at`),
  KEY `fk_te_ticket` (`ticket_id`),
  KEY `fk_te_user` (`created_by_user_id`),
  CONSTRAINT `fk_te_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `tenant` (`tenant_id`),
  CONSTRAINT `fk_te_ticket` FOREIGN KEY (`ticket_id`) REFERENCES `support_ticket` (`ticket_id`),
  CONSTRAINT `fk_te_user` FOREIGN KEY (`created_by_user_id`) REFERENCES `app_user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `support_ticket_event`
--

LOCK TABLES `support_ticket_event` WRITE;
/*!40000 ALTER TABLE `support_ticket_event` DISABLE KEYS */;
/*!40000 ALTER TABLE `support_ticket_event` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tenant`
--

DROP TABLE IF EXISTS `tenant`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tenant` (
  `tenant_id` bigint NOT NULL AUTO_INCREMENT,
  `tenant_key` varchar(64) NOT NULL,
  `name` varchar(128) NOT NULL,
  `status` enum('ACTIVE','SUSPENDED') NOT NULL DEFAULT 'ACTIVE',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`tenant_id`),
  UNIQUE KEY `tenant_key` (`tenant_key`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tenant`
--

LOCK TABLES `tenant` WRITE;
/*!40000 ALTER TABLE `tenant` DISABLE KEYS */;
INSERT INTO `tenant` VALUES (1,'acme','Acme Retail','ACTIVE','2026-02-03 11:30:17');
/*!40000 ALTER TABLE `tenant` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tool_action_log`
--

DROP TABLE IF EXISTS `tool_action_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tool_action_log` (
  `action_log_id` bigint NOT NULL AUTO_INCREMENT,
  `tenant_id` bigint NOT NULL,
  `correlation_id` varchar(64) NOT NULL,
  `tool_name` varchar(128) NOT NULL,
  `request_json` json NOT NULL,
  `response_json` json DEFAULT NULL,
  `outcome` enum('OK','DENIED','ERROR') NOT NULL,
  `error_message` varchar(255) DEFAULT NULL,
  `created_by_user_id` bigint DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`action_log_id`),
  KEY `ix_action_corr` (`tenant_id`,`correlation_id`,`created_at`),
  KEY `fk_tal_user` (`created_by_user_id`),
  CONSTRAINT `fk_tal_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `tenant` (`tenant_id`),
  CONSTRAINT `fk_tal_user` FOREIGN KEY (`created_by_user_id`) REFERENCES `app_user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tool_action_log`
--

LOCK TABLES `tool_action_log` WRITE;
/*!40000 ALTER TABLE `tool_action_log` DISABLE KEYS */;
/*!40000 ALTER TABLE `tool_action_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tracking_event`
--

DROP TABLE IF EXISTS `tracking_event`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tracking_event` (
  `event_id` bigint NOT NULL AUTO_INCREMENT,
  `tenant_id` bigint NOT NULL,
  `package_id` bigint NOT NULL,
  `event_time` datetime NOT NULL,
  `status_code` varchar(32) NOT NULL,
  `description` varchar(255) NOT NULL,
  `city` varchar(128) DEFAULT NULL,
  `region` varchar(64) DEFAULT NULL,
  `country` char(2) DEFAULT NULL,
  PRIMARY KEY (`event_id`),
  KEY `ix_track_pkg_time` (`tenant_id`,`package_id`,`event_time`),
  KEY `fk_track_pkg` (`package_id`),
  CONSTRAINT `fk_track_pkg` FOREIGN KEY (`package_id`) REFERENCES `shipment_package` (`package_id`),
  CONSTRAINT `fk_track_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `tenant` (`tenant_id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tracking_event`
--

LOCK TABLES `tracking_event` WRITE;
/*!40000 ALTER TABLE `tracking_event` DISABLE KEYS */;
INSERT INTO `tracking_event` VALUES (1,1,1,'2026-02-01 18:20:00','LABEL_CREATED','Shipping label created','Chicago','IL','US'),(2,1,1,'2026-02-01 20:05:00','PICKED_UP','Package picked up','Chicago','IL','US'),(3,1,1,'2026-02-02 06:12:00','IN_TRANSIT','In transit to destination facility','Chicago','IL','US'),(4,1,1,'2026-02-02 08:45:00','OUT_FOR_DELIVERY','Out for delivery','Chicago','IL','US'),(5,1,1,'2026-02-02 10:22:00','DELIVERED','Delivered - left with reception','Chicago','IL','US');
/*!40000 ALTER TABLE `tracking_event` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-02-25 10:25:25
