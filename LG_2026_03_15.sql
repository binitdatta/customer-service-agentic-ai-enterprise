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
) ENGINE=InnoDB AUTO_INCREMENT=22 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `address`
--

LOCK TABLES `address` WRITE;
/*!40000 ALTER TABLE `address` DISABLE KEYS */;
INSERT INTO `address` VALUES (1,1,1,'Ava Patel','1020 W Addison St','Apt 12B','Chicago','IL','60613','US',1,'2026-02-03 11:30:18'),(2,1,1,'Ava Patel','401 N Michigan Ave','Ste 900','Chicago','IL','60611','US',1,'2026-02-03 11:30:18'),(3,1,2,'Noah Kim','55 E Monroe St',NULL,'Chicago','IL','60603','US',1,'2026-02-03 11:30:18'),(4,1,1,'Ava Patel','123 Main St',NULL,'Naperville','IL','60540','US',0,'2026-02-12 18:03:18'),(5,1,NULL,NULL,'200 Lake Shore Dr',NULL,'Chicago','IL','60611','US',0,'2026-02-20 18:47:05'),(6,1,1,NULL,'1200 MBK Drive',NULL,'Chicago','IL','60611','US',0,'2026-02-20 21:23:29'),(7,1,NULL,NULL,'1200 S Michigan Ave',NULL,'Chicago','IL','60605','US',0,'2026-03-05 13:08:52'),(8,1,NULL,NULL,'401 N Michigan Ave',NULL,'Chicago','IL','60611','US',0,'2026-03-05 13:12:47'),(9,1,1,NULL,'420 N LG Ave',NULL,'Chicago','IL','60623','US',0,'2026-03-05 13:32:21'),(10,1,2,NULL,'10 Main St',NULL,'Naperville','IL','60540','US',0,'2026-03-05 14:56:02'),(11,1,2,NULL,'1 Apple Park Way',NULL,'Cupertino','CA','95014','US',0,'2026-03-05 15:12:54'),(12,1,2,NULL,'200 W Adams St',NULL,'Chicago','IL','60606','US',0,'2026-03-05 15:13:58'),(13,1,1,NULL,'500 W Madison St Suite 1000',NULL,'Chicago','IL','60661','US',0,'2026-03-05 15:19:53'),(14,1,2,NULL,'233 S Wacker Dr',NULL,'Chicago','IL','60606','US',0,'2026-03-06 11:39:34'),(15,1,1,NULL,'875 N Michigan Ave',NULL,'Chicago','IL','60611','US',0,'2026-03-06 11:39:59'),(16,1,2,NULL,'100 W Randolph St',NULL,'Chicago','IL','60601','US',0,'2026-03-13 03:05:50'),(17,1,NULL,NULL,'23875 N Michigan Ave',NULL,'Chicago','IL','60611','US',0,'2026-03-14 13:24:55'),(18,1,NULL,NULL,'24233 S Wacker Dr',NULL,'Chicago','IL','60606','US',0,'2026-03-14 13:26:20'),(19,1,NULL,NULL,'10292 S Dearborn St',NULL,'Chicago','IL','60603','US',0,'2026-03-14 13:26:58'),(20,1,NULL,NULL,'10099 W Randolph St',NULL,'Chicago','IL','60601','US',0,'2026-03-14 13:29:57'),(21,1,NULL,NULL,'1 Martin Place',NULL,'Sydney','NSW','2000','AU',0,'2026-03-14 16:34:44');
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
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `customer`
--

LOCK TABLES `customer` WRITE;
/*!40000 ALTER TABLE `customer` DISABLE KEYS */;
INSERT INTO `customer` VALUES (1,1,'CUST-1001','Ava','Patel','ava.patel@example.com','+1-312-555-0101','ACTIVE','2026-02-03 11:30:18'),(2,1,'CUST-1002','Noah','Kim','noah.kim@example.com','+1-773-555-0199','ACTIVE','2026-02-03 11:30:18'),(3,1,'CUST-1003','Sofia','Reyes','sofia.reyes@example.com','+1-213-555-0310','ACTIVE','2026-01-10 15:00:00'),(4,1,'CUST-1004','Marcus','Webb','marcus.webb@example.com','+1-617-555-0441','ACTIVE','2026-01-15 16:30:00'),(5,1,'CUST-1005','Priya','Nair','priya.nair@example.com','+1-415-555-0552','ACTIVE','2026-01-20 20:00:00'),(6,1,'CUST-1006','Daniel','Okafor','daniel.okafor@example.com','+1-832-555-0663','BLOCKED','2026-01-25 22:45:00');
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
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `idempotency_key`
--

LOCK TABLES `idempotency_key` WRITE;
/*!40000 ALTER TABLE `idempotency_key` DISABLE KEYS */;
INSERT INTO `idempotency_key` VALUES (1,1,'order_create','f744e02c-2164-4dca-8e3e-b0bcf0c16ab0','49feab4a565ade812b7aa5c6eaaf1f60871d827720b6237c55714f70185c7a33','{\"lines\": [{\"qty\": 1, \"sku\": \"SKU-RED-MUG\", \"line_no\": 1, \"line_total\": \"19.99\", \"product_id\": 1, \"unit_price\": \"19.99\", \"fulfillment_status\": \"OPEN\"}, {\"qty\": 2, \"sku\": \"SKU-BLK-TSHIRT-M\", \"line_no\": 2, \"line_total\": \"59.98\", \"product_id\": 2, \"unit_price\": \"29.99\", \"fulfillment_status\": \"OPEN\"}], \"status\": \"CREATED\", \"currency\": \"USD\", \"order_id\": 70, \"tenant_id\": 1, \"customer_id\": 1, \"order_total\": \"79.97\", \"order_number\": \"3371103454\", \"bill_to_address_id\": null, \"ship_to_address_id\": 9}','SUCCEEDED','2026-03-13 08:05:04','2026-03-13 08:05:04'),(2,1,'order_create','40ec42d1-3502-4d9c-b794-ec17e7766f92','1178c3b4f1ddbafabd98adb47dbe2bff253bcb63e9ca10a0ea8f03805d94712c','{\"lines\": [{\"qty\": 2, \"sku\": \"SKU-RED-MUG\", \"line_no\": 1, \"line_total\": \"39.98\", \"product_id\": 1, \"unit_price\": \"19.99\", \"fulfillment_status\": \"OPEN\"}, {\"qty\": 1, \"sku\": \"SKU-BLK-TSHIRT-M\", \"line_no\": 2, \"line_total\": \"29.99\", \"product_id\": 2, \"unit_price\": \"29.99\", \"fulfillment_status\": \"OPEN\"}], \"status\": \"CREATED\", \"currency\": \"USD\", \"order_id\": 71, \"tenant_id\": 1, \"customer_id\": 2, \"order_total\": \"69.97\", \"order_number\": \"3371150261\", \"bill_to_address_id\": null, \"ship_to_address_id\": 16}','SUCCEEDED','2026-03-13 08:05:50','2026-03-13 08:05:50'),(3,1,'order_create','e3b30f17-62ea-4ca3-bcea-db28b18b0bda','b0c2d2dd5a0961f1ce33ef6af045023f16844cd982d0749c83149cb82780979f','{\"lines\": [{\"qty\": 3, \"sku\": \"SKU-BLK-TSHIRT-M\", \"line_no\": 1, \"line_total\": \"89.97\", \"product_id\": 2, \"unit_price\": \"29.99\", \"fulfillment_status\": \"OPEN\"}], \"status\": \"CREATED\", \"currency\": \"USD\", \"order_id\": 72, \"tenant_id\": 1, \"customer_id\": 3, \"order_total\": \"89.97\", \"order_number\": \"3371174256\", \"bill_to_address_id\": null, \"ship_to_address_id\": 14}','SUCCEEDED','2026-03-13 08:06:15','2026-03-13 08:06:15'),(4,1,'order_create','6a5a9a48-0a2f-4563-978d-eb85c0006039','cedcb95576ce4c81befc8ef2a2f77c2bea10522915b8dd7e9a95718dec22d6f0','{\"lines\": [{\"qty\": 5, \"sku\": \"SKU-RED-MUG\", \"line_no\": 1, \"line_total\": \"99.95\", \"product_id\": 1, \"unit_price\": \"19.99\", \"fulfillment_status\": \"OPEN\"}], \"status\": \"CREATED\", \"currency\": \"USD\", \"order_id\": 73, \"tenant_id\": 1, \"customer_id\": 1, \"order_total\": \"99.95\", \"order_number\": \"3371189495\", \"bill_to_address_id\": null, \"ship_to_address_id\": 9}','SUCCEEDED','2026-03-13 08:06:30','2026-03-13 08:06:30'),(5,1,'order_create','ed7a9e95-494d-45ec-bdd6-24174a2596ed','51dadf115951d428dad2f219b3bf21a355b280548e9905ab091a9d05cc9991d0','{\"lines\": [{\"qty\": 2, \"sku\": \"SKU-RED-MUG\", \"line_no\": 1, \"line_total\": \"39.98\", \"product_id\": 1, \"unit_price\": \"19.99\", \"fulfillment_status\": \"OPEN\"}, {\"qty\": 1, \"sku\": \"SKU-BLK-TSHIRT-M\", \"line_no\": 2, \"line_total\": \"29.99\", \"product_id\": 2, \"unit_price\": \"29.99\", \"fulfillment_status\": \"OPEN\"}], \"status\": \"CREATED\", \"currency\": \"USD\", \"order_id\": 74, \"tenant_id\": 1, \"customer_id\": 2, \"order_total\": \"69.97\", \"order_number\": \"3371202203\", \"bill_to_address_id\": null, \"ship_to_address_id\": 15}','SUCCEEDED','2026-03-13 08:06:42','2026-03-13 08:06:42'),(6,1,'order_create','63f9f34c-8d48-482e-ae68-aeb57b986ad8','87c665874e30d49277c7b75fa679b2192eb3ec26a9a851a027d18f4bcc8c3af3',NULL,'FAILED','2026-03-13 08:12:14','2026-03-13 08:12:14'),(7,1,'order_create','a856e42d-72e4-4076-af35-d34073da26fd','6998b35bc635d60737d290f6c7e0c63c7ea4ae4bf9a0eb81f4ff75aecaae6134','{\"lines\": [{\"qty\": 1, \"sku\": \"SKU-BLK-TSHIRT-M\", \"line_no\": 1, \"line_total\": \"29.99\", \"product_id\": 2, \"unit_price\": \"29.99\", \"fulfillment_status\": \"OPEN\"}], \"status\": \"CREATED\", \"currency\": \"USD\", \"order_id\": 76, \"tenant_id\": 1, \"customer_id\": 2, \"order_total\": \"29.99\", \"order_number\": \"3371565018\", \"bill_to_address_id\": null, \"ship_to_address_id\": 14}','SUCCEEDED','2026-03-13 08:12:45','2026-03-13 08:12:45'),(8,1,'order_create','9c351524-a761-4259-b600-513eb6d6807a','890d4db3a39dacd8ac6ff31a8023398ce330cb481cf67b19a5ed9087609d2ff3','{\"lines\": [{\"qty\": 1, \"sku\": \"SKU-RED-MUG\", \"line_no\": 1, \"line_total\": \"19.99\", \"product_id\": 1, \"unit_price\": \"19.99\", \"fulfillment_status\": \"OPEN\"}, {\"qty\": 2, \"sku\": \"SKU-BLK-TSHIRT-M\", \"line_no\": 2, \"line_total\": \"59.98\", \"product_id\": 2, \"unit_price\": \"29.99\", \"fulfillment_status\": \"OPEN\"}], \"status\": \"CREATED\", \"currency\": \"USD\", \"order_id\": 77, \"tenant_id\": 1, \"customer_id\": 1, \"order_total\": \"79.97\", \"order_number\": \"3424354220\", \"bill_to_address_id\": null, \"ship_to_address_id\": 9}','SUCCEEDED','2026-03-13 22:52:34','2026-03-13 22:52:34'),(9,1,'order_create','20781dc1-5e35-4d70-be66-b92f3b660b9d','991884da737d3b57d33fd5ceb0d51ebeac5f57948578cae4ec7ef6b0d3a47fac','{\"lines\": [{\"qty\": 1, \"sku\": \"SKU-RED-MUG\", \"line_no\": 1, \"line_total\": \"19.99\", \"product_id\": 1, \"unit_price\": \"19.99\", \"fulfillment_status\": \"OPEN\"}, {\"qty\": 2, \"sku\": \"SKU-BLK-TSHIRT-M\", \"line_no\": 2, \"line_total\": \"59.98\", \"product_id\": 2, \"unit_price\": \"29.99\", \"fulfillment_status\": \"OPEN\"}], \"status\": \"CREATED\", \"currency\": \"USD\", \"order_id\": 78, \"tenant_id\": 1, \"customer_id\": 1, \"order_total\": \"79.97\", \"order_number\": \"3424381892\", \"bill_to_address_id\": null, \"ship_to_address_id\": 9}','SUCCEEDED','2026-03-13 22:53:02','2026-03-13 22:53:02'),(10,1,'order_create','d1240c88-2767-42e0-82c7-ac05ecd87694','328191a62ce68240608c4af19b54f328d9fbd70c0c34b4b199ff9662c143625a','{\"lines\": [{\"qty\": 2, \"sku\": \"SKU-RED-MUG\", \"line_no\": 1, \"line_total\": \"39.98\", \"product_id\": 1, \"unit_price\": \"19.99\", \"fulfillment_status\": \"OPEN\"}, {\"qty\": 1, \"sku\": \"SKU-BLK-TSHIRT-M\", \"line_no\": 2, \"line_total\": \"29.99\", \"product_id\": 2, \"unit_price\": \"29.99\", \"fulfillment_status\": \"OPEN\"}], \"status\": \"CREATED\", \"currency\": \"USD\", \"order_id\": 79, \"tenant_id\": 1, \"customer_id\": 2, \"order_total\": \"69.97\", \"order_number\": \"3424418434\", \"bill_to_address_id\": null, \"ship_to_address_id\": 16}','SUCCEEDED','2026-03-13 22:53:39','2026-03-13 22:53:39'),(11,1,'order_create','3196aae2-cf62-4aa6-a150-17bbab519436','5a07130717c3757d662cbe6f1bc2a041c8739997f8f0296c5b7f88b55185652c','{\"lines\": [{\"qty\": 3, \"sku\": \"SKU-BLK-TSHIRT-M\", \"line_no\": 1, \"line_total\": \"89.97\", \"product_id\": 2, \"unit_price\": \"29.99\", \"fulfillment_status\": \"OPEN\"}], \"status\": \"CREATED\", \"currency\": \"USD\", \"order_id\": 80, \"tenant_id\": 1, \"customer_id\": 3, \"order_total\": \"89.97\", \"order_number\": \"3424461526\", \"bill_to_address_id\": null, \"ship_to_address_id\": 14}','SUCCEEDED','2026-03-13 22:54:22','2026-03-13 22:54:22'),(12,1,'order_create','1db73967-92ce-4b3b-9f9b-e152e157cd53','c21b5424b99f027561031b0b33868dfe66a9672c83b41a14df2e822d444fe255','{\"lines\": [{\"qty\": 5, \"sku\": \"SKU-RED-MUG\", \"line_no\": 1, \"line_total\": \"99.95\", \"product_id\": 1, \"unit_price\": \"19.99\", \"fulfillment_status\": \"OPEN\"}], \"status\": \"CREATED\", \"currency\": \"USD\", \"order_id\": 81, \"tenant_id\": 1, \"customer_id\": 1, \"order_total\": \"99.95\", \"order_number\": \"3424483453\", \"bill_to_address_id\": null, \"ship_to_address_id\": 9}','SUCCEEDED','2026-03-13 22:54:43','2026-03-13 22:54:44'),(13,1,'order_create','54e353f3-742f-42c4-beae-96c5de547405','10c4a71e40f9f5c031b7cfc519ba7ded4a90deefaf66c3ca121c807f501668b3','{\"lines\": [{\"qty\": 2, \"sku\": \"SKU-RED-MUG\", \"line_no\": 1, \"line_total\": \"39.98\", \"product_id\": 1, \"unit_price\": \"19.99\", \"fulfillment_status\": \"OPEN\"}, {\"qty\": 1, \"sku\": \"SKU-BLK-TSHIRT-M\", \"line_no\": 2, \"line_total\": \"29.99\", \"product_id\": 2, \"unit_price\": \"29.99\", \"fulfillment_status\": \"OPEN\"}], \"status\": \"CREATED\", \"currency\": \"USD\", \"order_id\": 82, \"tenant_id\": 1, \"customer_id\": 2, \"order_total\": \"69.97\", \"order_number\": \"3424520171\", \"bill_to_address_id\": null, \"ship_to_address_id\": 15}','SUCCEEDED','2026-03-13 22:55:20','2026-03-13 22:55:20'),(14,1,'order_create','8033513f-d153-4f02-8cc0-c04ef952884f','9a449fc99d1e5c848903b359d8c904055cd151a31095a7f7bfd2e7f9895011a0','{\"lines\": [{\"qty\": 1, \"sku\": \"SKU-RED-MUG\", \"line_no\": 1, \"line_total\": \"19.99\", \"product_id\": 1, \"unit_price\": \"19.99\", \"fulfillment_status\": \"OPEN\"}], \"status\": \"CREATED\", \"currency\": \"USD\", \"order_id\": 83, \"tenant_id\": 1, \"customer_id\": 1, \"order_total\": \"19.99\", \"order_number\": \"3425865543\", \"bill_to_address_id\": null, \"ship_to_address_id\": 10}','SUCCEEDED','2026-03-13 23:17:46','2026-03-13 23:17:46'),(15,1,'order_create','a5438932-574d-4bef-8383-c0993e35b33a','948d2888df2c165619bae40d0abb1caf00796b92bf097c45c50f24b27bcddbe4',NULL,'FAILED','2026-03-13 23:19:31','2026-03-13 23:19:32'),(16,1,'order_create','8ad9b1bd-bfb8-4bd1-ab31-cddf9034a941','e58bc4ccfc6a853e86141d2f41fc8a839cb84b8da471bc6ef874e88cb3fa567f',NULL,'FAILED','2026-03-13 23:21:20','2026-03-13 23:21:20'),(17,1,'order_create','846c4be3-a59a-4465-b344-7b746bbce550','26929caeb075d47e5db9f46081342ac9691db9c186164c2989bec08ca04a72b2','{\"lines\": [{\"qty\": 3, \"sku\": \"SKU-BLK-MD-TEE\", \"line_no\": 1, \"line_total\": \"59.97\", \"product_id\": 16, \"unit_price\": \"19.99\", \"fulfillment_status\": \"OPEN\"}], \"status\": \"CREATED\", \"currency\": \"USD\", \"order_id\": 86, \"tenant_id\": 1, \"customer_id\": 1, \"order_total\": \"59.97\", \"order_number\": \"3428593792\", \"bill_to_address_id\": null, \"ship_to_address_id\": 9}','SUCCEEDED','2026-03-14 00:03:14','2026-03-14 00:03:14'),(18,1,'order_create','89ffb2f5-a3bf-4240-8f5e-18a70bb8e11d','d2c6e6965d45d807eea05d03b2a138980806c819bd86532c9da3d1cfa11a7b69','{\"lines\": [{\"qty\": 3, \"sku\": \"SKU-BLK-MD-TEE\", \"line_no\": 1, \"line_total\": \"59.97\", \"product_id\": 16, \"unit_price\": \"19.99\", \"fulfillment_status\": \"OPEN\"}], \"status\": \"CREATED\", \"currency\": \"USD\", \"order_id\": 87, \"tenant_id\": 1, \"customer_id\": 1, \"order_total\": \"59.97\", \"order_number\": \"3428622826\", \"bill_to_address_id\": null, \"ship_to_address_id\": 9}','SUCCEEDED','2026-03-14 00:03:43','2026-03-14 00:03:43'),(19,1,'order_create','087396af-fd0b-49f6-ad00-15e34c82921f','931b4dabecd05b4af12f4d38ef284978c2212d3ab477f88fa5ff40a82a958c29',NULL,'FAILED','2026-03-14 00:04:49','2026-03-14 00:04:49'),(20,1,'order_create','97f8b54f-c759-440e-98bd-769245f217ab','6f922be3ca5708d7981253afcf4145ed2c348dcd5a74fa0145834ae112c25c87','{\"lines\": [{\"qty\": 1, \"sku\": \"SKU-BLK-TSHIRT-M\", \"line_no\": 1, \"line_total\": \"29.99\", \"product_id\": 2, \"unit_price\": \"29.99\", \"fulfillment_status\": \"OPEN\"}], \"status\": \"CREATED\", \"currency\": \"USD\", \"order_id\": 89, \"tenant_id\": 1, \"customer_id\": 2, \"order_total\": \"29.99\", \"order_number\": \"3428732716\", \"bill_to_address_id\": null, \"ship_to_address_id\": 14}','SUCCEEDED','2026-03-14 00:05:33','2026-03-14 00:05:33');
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
  `unit_price` decimal(12,2) NOT NULL DEFAULT '0.00',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`product_id`),
  UNIQUE KEY `ux_product_tenant_sku` (`tenant_id`,`sku`),
  CONSTRAINT `fk_product_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `tenant` (`tenant_id`)
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `product`
--

LOCK TABLES `product` WRITE;
/*!40000 ALTER TABLE `product` DISABLE KEYS */;
INSERT INTO `product` VALUES (1,1,'SKU-RED-MUG','Ceramic Mug - Red',19.99,1,'2026-02-03 11:30:18'),(2,1,'SKU-BLK-TSHIRT-M','T-Shirt - Black - Medium',29.99,1,'2026-02-03 11:30:18'),(3,1,'SKU-MUG-BLUE-16OZ','Ceramic Mug - Cobalt Blue 16oz',0.00,1,'2026-01-01 14:00:00'),(4,1,'SKU-TUMBLR-SS-20OZ','Stainless Steel Tumbler 20oz',0.00,1,'2026-01-01 14:00:00'),(5,1,'SKU-GLASS-PINT-SET4','Pint Glass Set of 4',0.00,1,'2026-01-01 14:00:00'),(6,1,'SKU-TSHIRT-WHT-S','T-Shirt - White - Small',0.00,1,'2026-01-01 14:00:00'),(7,1,'SKU-TSHIRT-WHT-L','T-Shirt - White - Large',0.00,1,'2026-01-01 14:00:00'),(8,1,'SKU-HOODIE-GRY-M','Pullover Hoodie - Grey - Medium',0.00,1,'2026-01-01 14:00:00'),(9,1,'SKU-HOODIE-GRY-XL','Pullover Hoodie - Grey - XL',0.00,1,'2026-01-01 14:00:00'),(10,1,'SKU-NOTEBOOK-A5','Hardcover Notebook A5 - Dot Grid',0.00,1,'2026-01-01 14:00:00'),(11,1,'SKU-DESK-LAMP-USB','LED Desk Lamp with USB Charging Port',0.00,1,'2026-01-01 14:00:00'),(12,1,'SKU-CANDLE-SOY-8OZ','Soy Wax Candle - Cedarwood 8oz',0.00,1,'2026-01-01 14:00:00'),(13,1,'SKU-CABLE-USBC-2M','USB-C Braided Cable 2m',0.00,1,'2026-01-01 14:00:00'),(14,1,'SKU-CHARGER-PD30W','USB-C PD 30W Wall Charger',0.00,1,'2026-01-01 14:00:00'),(15,1,'SKU-POSTER-RETRO-A2','Retro Travel Poster A2 - Discontinued',0.00,0,'2026-01-01 14:00:00'),(16,1,'SKU-BLK-MD-TEE','Black Medium Tshirt',19.99,1,'2026-03-13 18:57:43');
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
) ENGINE=InnoDB AUTO_INCREMENT=90 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sales_order`
--

LOCK TABLES `sales_order` WRITE;
/*!40000 ALTER TABLE `sales_order` DISABLE KEYS */;
INSERT INTO `sales_order` VALUES (1,1,'88421',1,1,2,'DELIVERED','USD',39.98,'2026-02-03 11:30:18','2026-02-03 11:30:18'),(2,1,'88422',2,3,3,'SHIPPED','USD',14.99,'2026-02-03 11:30:18','2026-02-03 11:30:18'),(4,1,'91001',1,NULL,3,'DELIVERED','USD',129.99,'2026-02-06 19:42:55','2026-02-06 20:30:24'),(5,1,'91001-R1',1,NULL,3,'CREATED','USD',0.00,'2026-02-06 20:39:58','2026-02-06 20:39:58'),(6,1,'99001',1,1,2,'CREATED','USD',0.00,'2026-02-13 00:41:12','2026-02-13 00:41:12'),(7,1,'99002',1,1,4,'CREATED','USD',0.00,'2026-02-13 00:49:13','2026-02-13 03:55:06'),(8,1,'1771530566',1,1,2,'CREATED','USD',0.00,'2026-02-20 01:49:27','2026-02-20 01:49:27'),(9,1,'1771600184',1,1,5,'CREATED','USD',0.00,'2026-02-20 21:09:44','2026-02-21 00:47:06'),(10,1,'1771622461',1,1,6,'CREATED','USD',0.00,'2026-02-21 03:21:02','2026-02-21 03:23:30'),(11,1,'1772464659',1,1,2,'CREATED','USD',0.00,'2026-03-02 21:17:40','2026-03-02 21:17:40'),(12,1,'1772477136',1,1,2,'CREATED','USD',0.00,'2026-03-03 00:45:37','2026-03-03 00:45:37'),(13,1,'ORD-2003',4,9,9,'PAID','USD',90.97,'2026-02-01 15:00:00','2026-02-01 15:30:00'),(14,1,'ORD-2004',4,9,10,'FULFILLING','USD',101.96,'2026-02-10 21:00:00','2026-02-11 14:00:00'),(15,1,'ORD-2005',4,9,9,'CANCELLED','USD',29.98,'2026-02-12 18:00:00','2026-02-12 18:45:00'),(16,1,'ORD-2006',5,11,11,'CREATED','USD',77.98,'2026-02-20 22:00:00','2026-02-20 22:00:00'),(17,1,'ORD-2007',5,11,12,'DELIVERED','USD',109.98,'2026-01-28 16:00:00','2026-02-05 18:00:00'),(18,1,'ORD-2008',6,13,13,'CLOSED','USD',39.98,'2026-01-26 15:00:00','2026-02-02 16:00:00'),(19,1,'90010',1,NULL,5,'CREATED','USD',69.97,'2026-03-03 18:10:10','2026-03-03 12:10:10'),(20,1,'90012',1,NULL,5,'CREATED','USD',69.97,'2026-03-03 18:23:56','2026-03-03 12:23:56'),(21,1,'90014',1,NULL,6,'SHIPPED','USD',19.99,'2026-03-03 18:24:23','2026-03-03 20:02:17'),(22,1,'90015',1,NULL,5,'CANCELLED','USD',19.99,'2026-03-03 20:18:53','2026-03-03 22:48:09'),(23,1,'90016',1,NULL,5,'FULFILLING','USD',19.99,'2026-03-03 23:24:57','2026-03-03 23:30:16'),(24,1,'90016-R1',1,NULL,5,'CREATED','USD',0.00,'2026-03-03 23:33:53','2026-03-03 23:33:53'),(25,1,'60611',1,NULL,8,'CREATED','USD',79.97,'2026-03-05 19:12:47','2026-03-05 13:12:47'),(26,1,'2717457409',1,NULL,8,'CREATED','USD',79.97,'2026-03-05 19:30:57','2026-03-05 13:30:57'),(27,1,'2717541677',1,NULL,9,'CREATED','USD',79.97,'2026-03-05 19:32:22','2026-03-05 13:32:21'),(28,1,'2722562336',2,NULL,10,'CREATED','USD',49.98,'2026-03-05 20:56:02','2026-03-05 14:56:02'),(29,1,'2722963675',1,NULL,9,'CREATED','USD',79.97,'2026-03-05 21:02:44','2026-03-05 15:02:43'),(30,1,'2723059590',1,NULL,9,'CREATED','USD',79.97,'2026-03-05 21:04:20','2026-03-05 15:04:19'),(31,1,'2723142684',2,NULL,10,'CREATED','USD',49.98,'2026-03-05 21:05:43','2026-03-05 15:05:42'),(32,1,'2723305115',1,NULL,7,'CREATED','USD',109.96,'2026-03-05 21:08:25','2026-03-05 15:08:25'),(33,1,'2723574810',2,NULL,11,'CREATED','USD',29.99,'2026-03-05 21:12:55','2026-03-05 15:12:54'),(34,1,'2723638689',2,NULL,12,'CREATED','USD',79.96,'2026-03-05 21:13:59','2026-03-05 15:13:58'),(35,1,'2723993206',1,NULL,13,'CREATED','USD',39.98,'2026-03-05 21:19:53','2026-03-05 15:19:53'),(36,1,'2724429877',1,NULL,8,'CREATED','USD',79.97,'2026-03-05 21:27:10','2026-03-05 15:27:09'),(37,1,'2724488969',1,NULL,9,'CREATED','USD',79.97,'2026-03-05 21:28:09','2026-03-05 15:28:09'),(38,1,'2724507296',1,NULL,7,'CREATED','USD',109.96,'2026-03-05 21:28:27','2026-03-05 15:28:27'),(39,1,'2724517352',2,NULL,10,'CREATED','USD',49.98,'2026-03-05 21:28:37','2026-03-05 15:28:37'),(40,1,'2724532086',2,NULL,11,'CREATED','USD',29.99,'2026-03-05 21:28:52','2026-03-05 15:28:52'),(41,1,'2724542595',2,NULL,12,'CREATED','USD',79.96,'2026-03-05 21:29:03','2026-03-05 15:29:02'),(42,1,'2724552246',1,NULL,13,'CREATED','USD',39.98,'2026-03-05 21:29:12','2026-03-05 15:29:12'),(43,1,'2724561457',1,NULL,8,'CREATED','USD',79.97,'2026-03-05 21:29:21','2026-03-05 15:29:21'),(44,1,'2796926369',1,NULL,9,'CREATED','USD',79.97,'2026-03-06 17:35:26','2026-03-06 11:35:26'),(45,1,'2797021165',1,NULL,7,'CREATED','USD',109.96,'2026-03-06 17:37:01','2026-03-06 11:37:01'),(46,1,'2797048290',2,NULL,10,'CREATED','USD',49.98,'2026-03-06 17:37:28','2026-03-06 11:37:28'),(47,1,'2797068996',2,NULL,11,'CREATED','USD',29.99,'2026-03-06 17:37:49','2026-03-06 11:37:49'),(48,1,'2797084472',2,NULL,12,'CREATED','USD',79.96,'2026-03-06 17:38:04','2026-03-06 11:38:04'),(49,1,'2797102688',1,NULL,13,'CANCELLED','USD',39.98,'2026-03-06 17:38:23','2026-03-06 18:02:15'),(50,1,'2797140678',1,NULL,8,'CREATED','USD',79.97,'2026-03-06 17:39:01','2026-03-06 11:39:00'),(51,1,'2797160970',1,NULL,3,'CREATED','USD',59.98,'2026-03-06 17:39:21','2026-03-06 11:39:20'),(52,1,'2797174520',2,NULL,15,'CREATED','USD',59.97,'2026-03-06 17:39:35','2026-03-06 18:01:40'),(53,1,'2797199048',1,NULL,15,'CLOSED','USD',49.98,'2026-03-06 17:39:59','2026-03-06 17:57:00'),(54,1,'88421-R1',1,1,2,'CREATED','USD',0.00,'2026-03-06 18:06:01','2026-03-06 18:06:01'),(55,1,'88421-R2',1,1,2,'CREATED','USD',0.00,'2026-03-06 18:06:30','2026-03-06 18:06:30'),(56,1,'88421-R3',1,1,2,'CREATED','USD',0.00,'2026-03-06 18:06:51','2026-03-06 18:06:51'),(57,1,'88421-R4',1,1,2,'CREATED','USD',0.00,'2026-03-06 18:07:10','2026-03-06 18:07:10'),(58,1,'88421-R5',1,1,2,'CREATED','USD',0.00,'2026-03-06 18:07:31','2026-03-06 18:07:31'),(59,1,'88421-R6',1,1,2,'CREATED','USD',0.00,'2026-03-06 18:07:48','2026-03-06 18:07:48'),(60,1,'2801195608',1,NULL,14,'CANCELLED','USD',39.98,'2026-03-06 18:46:36','2026-03-06 18:49:24'),(61,1,'2801210414',2,NULL,10,'CANCELLED','USD',29.99,'2026-03-06 18:46:50','2026-03-06 18:48:02'),(62,1,'2801336413',1,NULL,3,'CREATED','USD',79.97,'2026-03-06 18:48:56','2026-03-06 12:48:56'),(63,1,'2812828607',1,NULL,9,'CREATED','USD',79.97,'2026-03-06 22:00:29','2026-03-06 16:00:28'),(64,1,'2812855381',2,NULL,10,'DELIVERED','USD',19.99,'2026-03-06 22:00:55','2026-03-06 22:45:36'),(65,1,'2812868945',1,NULL,7,'CREATED','USD',89.97,'2026-03-06 22:01:09','2026-03-06 16:01:09'),(66,1,'2812934138',1,NULL,7,'CREATED','USD',89.97,'2026-03-06 22:02:14','2026-03-06 16:02:14'),(67,1,'2813322226',2,NULL,12,'CREATED','USD',79.96,'2026-03-06 22:08:42','2026-03-06 16:08:42'),(68,1,'2814117579',1,NULL,9,'CANCELLED','USD',19.99,'2026-03-06 22:21:58','2026-03-06 22:23:22'),(69,1,'2812855381-R1',2,NULL,10,'CREATED','USD',0.00,'2026-03-06 22:45:48','2026-03-06 22:45:48'),(70,1,'3371103454',1,NULL,9,'CREATED','USD',79.97,'2026-03-13 08:05:04','2026-03-13 03:05:03'),(71,1,'3371150261',2,NULL,16,'CREATED','USD',69.97,'2026-03-13 08:05:50','2026-03-13 03:05:50'),(72,1,'3371174256',3,NULL,14,'CANCELLED','USD',89.97,'2026-03-13 08:06:15','2026-03-14 18:22:05'),(73,1,'3371189495',1,NULL,20,'CREATED','USD',99.95,'2026-03-13 08:06:30','2026-03-14 18:29:57'),(74,1,'3371202203',2,NULL,15,'CREATED','USD',69.97,'2026-03-13 08:06:42','2026-03-13 03:06:42'),(76,1,'3371565018',2,NULL,14,'CREATED','USD',29.99,'2026-03-13 08:12:45','2026-03-13 03:12:45'),(77,1,'3424354220',1,NULL,9,'CREATED','USD',79.97,'2026-03-13 22:52:34','2026-03-13 17:52:34'),(78,1,'3424381892',1,NULL,9,'CREATED','USD',79.97,'2026-03-13 22:53:02','2026-03-13 17:53:02'),(79,1,'3424418434',2,NULL,16,'CREATED','USD',69.97,'2026-03-13 22:53:39','2026-03-13 17:53:38'),(80,1,'3424461526',3,NULL,14,'CREATED','USD',89.97,'2026-03-13 22:54:22','2026-03-13 17:54:21'),(81,1,'3424483453',1,NULL,9,'CREATED','USD',99.95,'2026-03-13 22:54:43','2026-03-13 17:54:43'),(82,1,'3424520171',2,NULL,15,'CREATED','USD',69.97,'2026-03-13 22:55:20','2026-03-13 17:55:20'),(83,1,'3425865543',1,NULL,10,'CREATED','USD',19.99,'2026-03-13 23:17:46','2026-03-13 18:17:45'),(86,1,'3428593792',1,NULL,9,'CREATED','USD',59.97,'2026-03-14 00:03:14','2026-03-13 19:03:13'),(87,1,'3428622826',1,NULL,21,'CREATED','USD',59.97,'2026-03-14 00:03:43','2026-03-14 21:34:45'),(89,1,'3428732716',2,NULL,14,'CREATED','USD',29.99,'2026-03-14 00:05:33','2026-03-13 19:05:32');
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
) ENGINE=InnoDB AUTO_INCREMENT=152 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sales_order_event`
--

LOCK TABLES `sales_order_event` WRITE;
/*!40000 ALTER TABLE `sales_order_event` DISABLE KEYS */;
INSERT INTO `sales_order_event` VALUES (1,1,4,'91001','ORDER_CREATED','total=129.99 USD','4f1eb95d-5e11-4737-b442-260b960899fa','alice','2026-02-06 13:42:55.387141'),(2,1,4,'91001','ADDRESS_UPDATED','2 -> 3','4f1eb95d-5e11-4737-b442-260b960899fa','alice','2026-02-06 13:54:49.629341'),(3,1,4,'91001','STATUS_UPDATED','CREATED -> PAID; source=OPS_TOOL; notes=manual status correction','4f1eb95d-5e11-4737-b442-260b960899fa','alice','2026-02-06 14:18:42.475030'),(4,1,4,'91001','STATUS_UPDATED','PAID -> FULFILLING; source=OPS_TOOL; notes=manual status correction','4f1eb95d-5e11-4737-b442-260b960899fa','alice','2026-02-06 14:22:07.891339'),(5,1,4,'91001','STATUS_UPDATED','FULFILLING -> SHIPPED; source=OPS_TOOL; notes=manual status correction','4f1eb95d-5e11-4737-b442-260b960899fa','alice','2026-02-06 14:29:52.845384'),(6,1,4,'91001','STATUS_UPDATED','SHIPPED -> DELIVERED; source=OPS_TOOL; notes=manual status correction','4f1eb95d-5e11-4737-b442-260b960899fa','alice','2026-02-06 14:30:24.125597'),(7,1,4,'91001','REPLACEMENT_REQUESTED','replacement=91001-R1; ship_speed=STANDARD','4f1eb95d-5e11-4737-b442-260b960899fa','alice','2026-02-06 14:39:58.412773'),(8,1,5,'91001-R1','REPLACEMENT_CREATED','original=91001; ship_speed=STANDARD','4f1eb95d-5e11-4737-b442-260b960899fa','alice','2026-02-06 14:39:58.418180'),(9,1,6,'99001','ORDER_CREATED','total=0.00 USD',NULL,NULL,'2026-02-12 18:41:12.546189'),(10,1,7,'99002','ORDER_CREATED','total=0.00 USD',NULL,NULL,'2026-02-12 18:49:13.288273'),(11,1,7,'99002','ADDRESS_UPDATED','2 -> 4',NULL,NULL,'2026-02-12 21:55:06.361633'),(12,1,8,'1771530566','ORDER_CREATED','total=0.00 USD',NULL,NULL,'2026-02-19 19:49:27.555934'),(13,1,9,'1771600184','ORDER_CREATED','total=0.00 USD',NULL,NULL,'2026-02-20 15:09:44.697996'),(14,1,9,'1771600184','ADDRESS_UPDATED','2 -> 5',NULL,NULL,'2026-02-20 18:47:05.691562'),(15,1,10,'1771622461','ORDER_CREATED','total=0.00 USD',NULL,NULL,'2026-02-20 21:21:02.322564'),(16,1,10,'1771622461','ADDRESS_UPDATED','2 -> 5',NULL,NULL,'2026-02-20 21:22:23.204612'),(17,1,10,'1771622461','ADDRESS_UPDATED','5 -> 6',NULL,NULL,'2026-02-20 21:23:29.594378'),(18,1,11,'1772464659','ORDER_CREATED','total=0.00 USD',NULL,NULL,'2026-03-02 15:17:39.873697'),(19,1,12,'1772477136','ORDER_CREATED','total=0.00 USD',NULL,NULL,'2026-03-02 18:45:36.958720'),(21,1,19,'90010','ORDER_CREATED','total=69.97 USD; lines=2',NULL,NULL,'2026-03-03 12:10:10.108831'),(22,1,20,'90012','ORDER_CREATED','total=69.97 USD; lines=2',NULL,NULL,'2026-03-03 12:23:56.392123'),(23,1,21,'90014','ORDER_CREATED','total=19.99 USD; lines=1',NULL,NULL,'2026-03-03 12:24:23.477720'),(24,1,21,'90014','ADDRESS_UPDATED','5 -> 6',NULL,NULL,'2026-03-03 13:29:29.472948'),(25,1,21,'90014','STATUS_UPDATED','CREATED -> PAID; source=CSR_UI; notes=manual status correction',NULL,NULL,'2026-03-03 14:00:00.265273'),(26,1,21,'90014','STATUS_UPDATED','PAID -> FULFILLING; source=CSR_UI; notes=manual status correction',NULL,NULL,'2026-03-03 14:01:23.048423'),(27,1,21,'90014','STATUS_UPDATED','FULFILLING -> SHIPPED; source=CSR_UI; notes=manual status correction',NULL,NULL,'2026-03-03 14:02:17.103261'),(28,1,22,'90015','ORDER_CREATED','total=19.99 USD; lines=1',NULL,NULL,'2026-03-03 14:18:53.239856'),(29,1,22,'90015','ORDER_CANCELLED','reason=Customer requested cancellation; notes=None',NULL,NULL,'2026-03-03 16:48:09.332842'),(30,1,23,'90016','ORDER_CREATED','total=19.99 USD; lines=1',NULL,NULL,'2026-03-03 17:24:57.250193'),(31,1,23,'90016','STATUS_UPDATED','CREATED -> PAID; source=PAYMENTS; notes=test: marking paid to allow replacement flow',NULL,NULL,'2026-03-03 17:28:48.047873'),(32,1,23,'90016','STATUS_UPDATED','PAID -> FULFILLING; source=OPS_TOOL; notes=test: advancing to fulfilling',NULL,NULL,'2026-03-03 17:30:15.735768'),(33,1,23,'90016','REPLACEMENT_REQUESTED','replacement=90016-R1; ship_speed=STANDARD',NULL,NULL,'2026-03-03 17:33:53.471792'),(34,1,24,'90016-R1','REPLACEMENT_CREATED','original=90016; ship_speed=STANDARD',NULL,NULL,'2026-03-03 17:33:53.473754'),(35,1,25,'60611','ORDER_CREATED','total=79.97 USD; lines=2',NULL,NULL,'2026-03-05 13:12:47.433798'),(36,1,26,'2717457409','ORDER_CREATED','total=79.97 USD; lines=2',NULL,NULL,'2026-03-05 13:30:57.485089'),(37,1,27,'2717541677','ORDER_CREATED','total=79.97 USD; lines=2',NULL,NULL,'2026-03-05 13:32:21.709115'),(38,1,28,'2722562336','ORDER_CREATED','total=49.98 USD; lines=2',NULL,NULL,'2026-03-05 14:56:02.396201'),(39,1,29,'2722963675','ORDER_CREATED','total=79.97 USD; lines=2',NULL,NULL,'2026-03-05 15:02:43.716777'),(40,1,30,'2723059590','ORDER_CREATED','total=79.97 USD; lines=2',NULL,NULL,'2026-03-05 15:04:19.616080'),(41,1,31,'2723142684','ORDER_CREATED','total=49.98 USD; lines=2',NULL,NULL,'2026-03-05 15:05:42.713474'),(42,1,32,'2723305115','ORDER_CREATED','total=109.96 USD; lines=2',NULL,NULL,'2026-03-05 15:08:25.183723'),(43,1,33,'2723574810','ORDER_CREATED','total=29.99 USD; lines=1',NULL,NULL,'2026-03-05 15:12:54.851642'),(44,1,34,'2723638689','ORDER_CREATED','total=79.96 USD; lines=1',NULL,NULL,'2026-03-05 15:13:58.714676'),(45,1,35,'2723993206','ORDER_CREATED','total=39.98 USD; lines=1',NULL,NULL,'2026-03-05 15:19:53.262959'),(46,1,36,'2724429877','ORDER_CREATED','total=79.97 USD; lines=2',NULL,NULL,'2026-03-05 15:27:09.929445'),(47,1,37,'2724488969','ORDER_CREATED','total=79.97 USD; lines=2',NULL,NULL,'2026-03-05 15:28:09.014704'),(48,1,38,'2724507296','ORDER_CREATED','total=109.96 USD; lines=2',NULL,NULL,'2026-03-05 15:28:27.340053'),(49,1,39,'2724517352','ORDER_CREATED','total=49.98 USD; lines=2',NULL,NULL,'2026-03-05 15:28:37.384887'),(50,1,40,'2724532086','ORDER_CREATED','total=29.99 USD; lines=1',NULL,NULL,'2026-03-05 15:28:52.118711'),(51,1,41,'2724542595','ORDER_CREATED','total=79.96 USD; lines=1',NULL,NULL,'2026-03-05 15:29:02.615607'),(52,1,42,'2724552246','ORDER_CREATED','total=39.98 USD; lines=1',NULL,NULL,'2026-03-05 15:29:12.267954'),(53,1,43,'2724561457','ORDER_CREATED','total=79.97 USD; lines=2',NULL,NULL,'2026-03-05 15:29:21.487412'),(54,1,44,'2796926369','ORDER_CREATED','total=79.97 USD; lines=2',NULL,NULL,'2026-03-06 11:35:26.617236'),(55,1,45,'2797021165','ORDER_CREATED','total=109.96 USD; lines=2',NULL,NULL,'2026-03-06 11:37:01.220951'),(56,1,46,'2797048290','ORDER_CREATED','total=49.98 USD; lines=2',NULL,NULL,'2026-03-06 11:37:28.316451'),(57,1,47,'2797068996','ORDER_CREATED','total=29.99 USD; lines=1',NULL,NULL,'2026-03-06 11:37:49.030924'),(58,1,48,'2797084472','ORDER_CREATED','total=79.96 USD; lines=1',NULL,NULL,'2026-03-06 11:38:04.493949'),(59,1,49,'2797102688','ORDER_CREATED','total=39.98 USD; lines=1',NULL,NULL,'2026-03-06 11:38:22.712925'),(60,1,50,'2797140678','ORDER_CREATED','total=79.97 USD; lines=2',NULL,NULL,'2026-03-06 11:39:00.716619'),(61,1,51,'2797160970','ORDER_CREATED','total=59.98 USD; lines=1',NULL,NULL,'2026-03-06 11:39:20.995812'),(62,1,52,'2797174520','ORDER_CREATED','total=59.97 USD; lines=1',NULL,NULL,'2026-03-06 11:39:34.535391'),(63,1,53,'2797199048','ORDER_CREATED','total=49.98 USD; lines=2',NULL,NULL,'2026-03-06 11:39:59.080352'),(64,1,53,'2797199048','STATUS_UPDATED','CREATED -> PAID; source=OPS_TOOL; notes=None',NULL,NULL,'2026-03-06 11:55:18.387804'),(65,1,53,'2797199048','STATUS_UPDATED','PAID -> FULFILLING; source=OPS_TOOL; notes=None',NULL,NULL,'2026-03-06 11:55:46.618662'),(66,1,53,'2797199048','STATUS_UPDATED','FULFILLING -> SHIPPED; source=DRIVER_APP; notes=picked up by carrier',NULL,NULL,'2026-03-06 11:56:08.519131'),(67,1,53,'2797199048','STATUS_UPDATED','SHIPPED -> DELIVERED; source=DRIVER_APP; notes=left at front door',NULL,NULL,'2026-03-06 11:56:37.544501'),(68,1,53,'2797199048','STATUS_UPDATED','DELIVERED -> CLOSED; source=SUPPORT_AGENT; notes=confirmed by customer',NULL,NULL,'2026-03-06 11:57:00.028952'),(69,1,52,'2797174520','ADDRESS_UPDATED','14 -> 7',NULL,NULL,'2026-03-06 11:58:41.609356'),(70,1,52,'2797174520','ADDRESS_UPDATED','7 -> 10',NULL,NULL,'2026-03-06 11:59:24.186294'),(71,1,52,'2797174520','ADDRESS_UPDATED','10 -> 12',NULL,NULL,'2026-03-06 11:59:52.440600'),(72,1,52,'2797174520','ADDRESS_UPDATED','12 -> 8',NULL,NULL,'2026-03-06 12:00:55.286295'),(73,1,52,'2797174520','ADDRESS_UPDATED','8 -> 3',NULL,NULL,'2026-03-06 12:01:19.912789'),(74,1,52,'2797174520','ADDRESS_UPDATED','3 -> 15',NULL,NULL,'2026-03-06 12:01:40.166525'),(75,1,49,'2797102688','ORDER_CANCELLED','reason=customer request; notes=changed mind',NULL,NULL,'2026-03-06 12:02:15.288693'),(76,1,1,'88421','REPLACEMENT_REQUESTED','replacement=88421-R1; ship_speed=OVERNIGHT',NULL,NULL,'2026-03-06 12:06:01.248581'),(77,1,54,'88421-R1','REPLACEMENT_CREATED','original=88421; ship_speed=OVERNIGHT',NULL,NULL,'2026-03-06 12:06:01.256862'),(78,1,1,'88421','REPLACEMENT_REQUESTED','replacement=88421-R2; ship_speed=EXPEDITED',NULL,NULL,'2026-03-06 12:06:30.101230'),(79,1,55,'88421-R2','REPLACEMENT_CREATED','original=88421; ship_speed=EXPEDITED',NULL,NULL,'2026-03-06 12:06:30.101580'),(80,1,1,'88421','REPLACEMENT_REQUESTED','replacement=88421-R3; ship_speed=STANDARD',NULL,NULL,'2026-03-06 12:06:50.539825'),(81,1,56,'88421-R3','REPLACEMENT_CREATED','original=88421; ship_speed=STANDARD',NULL,NULL,'2026-03-06 12:06:50.542965'),(82,1,1,'88421','REPLACEMENT_REQUESTED','replacement=88421-R4; ship_speed=STANDARD',NULL,NULL,'2026-03-06 12:07:10.064877'),(83,1,57,'88421-R4','REPLACEMENT_CREATED','original=88421; ship_speed=STANDARD',NULL,NULL,'2026-03-06 12:07:10.065233'),(84,1,1,'88421','REPLACEMENT_REQUESTED','replacement=88421-R5; ship_speed=OVERNIGHT',NULL,NULL,'2026-03-06 12:07:31.111141'),(85,1,58,'88421-R5','REPLACEMENT_CREATED','original=88421; ship_speed=OVERNIGHT',NULL,NULL,'2026-03-06 12:07:31.111649'),(86,1,1,'88421','REPLACEMENT_REQUESTED','replacement=88421-R6; ship_speed=EXPEDITED',NULL,NULL,'2026-03-06 12:07:48.199272'),(87,1,59,'88421-R6','REPLACEMENT_CREATED','original=88421; ship_speed=EXPEDITED',NULL,NULL,'2026-03-06 12:07:48.200276'),(88,1,60,'2801195608','ORDER_CREATED','total=39.98 USD; lines=1',NULL,NULL,'2026-03-06 12:46:35.697052'),(89,1,61,'2801210414','ORDER_CREATED','total=29.99 USD; lines=1',NULL,NULL,'2026-03-06 12:46:50.453599'),(90,1,61,'2801210414','ORDER_CANCELLED','reason=buyer\'s remorse; notes=Customer called and wants out',NULL,NULL,'2026-03-06 12:48:02.360201'),(91,1,60,'2801195608','ADDRESS_UPDATED','9 -> 14',NULL,NULL,'2026-03-06 12:48:28.131866'),(92,1,62,'2801336413','ORDER_CREATED','total=79.97 USD; lines=2',NULL,NULL,'2026-03-06 12:48:56.475192'),(93,1,60,'2801195608','ORDER_CANCELLED','reason=dupe order, customer confirmed; notes=None',NULL,NULL,'2026-03-06 12:49:23.896648'),(94,1,63,'2812828607','ORDER_CREATED','total=79.97 USD; lines=2',NULL,NULL,'2026-03-06 16:00:28.680689'),(95,1,64,'2812855381','ORDER_CREATED','total=19.99 USD; lines=1',NULL,NULL,'2026-03-06 16:00:55.406073'),(96,1,65,'2812868945','ORDER_CREATED','total=89.97 USD; lines=1',NULL,NULL,'2026-03-06 16:01:09.135508'),(97,1,66,'2812934138','ORDER_CREATED','total=89.97 USD; lines=1',NULL,NULL,'2026-03-06 16:02:14.165477'),(98,1,67,'2813322226','ORDER_CREATED','total=79.96 USD; lines=1',NULL,NULL,'2026-03-06 16:08:42.265442'),(99,1,68,'2814117579','ORDER_CREATED','total=19.99 USD; lines=1',NULL,NULL,'2026-03-06 16:21:57.771403'),(100,1,68,'2814117579','ORDER_CANCELLED','reason=duplicate order; notes=None',NULL,NULL,'2026-03-06 16:23:21.576646'),(101,1,64,'2812855381','STATUS_UPDATED','CREATED -> PAID; source=OPS_TOOL; notes=None',NULL,NULL,'2026-03-06 16:45:00.816525'),(102,1,64,'2812855381','STATUS_UPDATED','PAID -> FULFILLING; source=OPS_TOOL; notes=None',NULL,NULL,'2026-03-06 16:45:12.903003'),(103,1,64,'2812855381','STATUS_UPDATED','FULFILLING -> SHIPPED; source=OPS_TOOL; notes=None',NULL,NULL,'2026-03-06 16:45:26.057746'),(104,1,64,'2812855381','STATUS_UPDATED','SHIPPED -> DELIVERED; source=OPS_TOOL; notes=None',NULL,NULL,'2026-03-06 16:45:36.025581'),(105,1,64,'2812855381','REPLACEMENT_REQUESTED','replacement=2812855381-R1; ship_speed=EXPEDITED',NULL,NULL,'2026-03-06 16:45:48.013055'),(106,1,69,'2812855381-R1','REPLACEMENT_CREATED','original=2812855381; ship_speed=EXPEDITED',NULL,NULL,'2026-03-06 16:45:48.013956'),(107,1,11,'ORD-2001','ORDER_CREATED','total=62.97 USD',NULL,'seed','2026-01-11 10:00:01.000000'),(108,1,11,'ORD-2001','STATUS_UPDATED','CREATED -> DELIVERED; source=OPS_TOOL',NULL,'seed','2026-01-18 14:00:01.000000'),(109,1,12,'ORD-2002','ORDER_CREATED','total=44.98 USD',NULL,'seed','2026-01-22 11:00:01.000000'),(110,1,12,'ORD-2002','STATUS_UPDATED','CREATED -> SHIPPED; source=OPS_TOOL',NULL,'seed','2026-01-25 09:00:01.000000'),(111,1,13,'ORD-2003','ORDER_CREATED','total=89.99 USD',NULL,'seed','2026-02-01 09:00:01.000000'),(112,1,13,'ORD-2003','STATUS_UPDATED','CREATED -> PAID; source=OPS_TOOL',NULL,'seed','2026-02-01 09:30:01.000000'),(113,1,14,'ORD-2004','ORDER_CREATED','total=101.96 USD',NULL,'seed','2026-02-10 15:00:01.000000'),(114,1,14,'ORD-2004','STATUS_UPDATED','CREATED -> PAID; source=OPS_TOOL',NULL,'seed','2026-02-10 15:30:01.000000'),(115,1,14,'ORD-2004','STATUS_UPDATED','PAID -> FULFILLING; source=OPS_TOOL',NULL,'seed','2026-02-11 08:00:01.000000'),(116,1,15,'ORD-2005','ORDER_CREATED','total=29.99 USD',NULL,'seed','2026-02-12 12:00:01.000000'),(117,1,15,'ORD-2005','ORDER_CANCELLED','reason=customer request',NULL,'seed','2026-02-12 12:45:01.000000'),(118,1,16,'ORD-2006','ORDER_CREATED','total=77.97 USD',NULL,'seed','2026-02-20 16:00:01.000000'),(119,1,17,'ORD-2007','ORDER_CREATED','total=114.96 USD',NULL,'seed','2026-01-28 10:00:01.000000'),(120,1,17,'ORD-2007','STATUS_UPDATED','CREATED -> DELIVERED; source=OPS_TOOL',NULL,'seed','2026-02-05 12:00:01.000000'),(121,1,18,'ORD-2008','ORDER_CREATED','total=39.98 USD',NULL,'seed','2026-01-26 09:00:01.000000'),(122,1,18,'ORD-2008','STATUS_UPDATED','CREATED -> CLOSED; source=OPS_TOOL',NULL,'seed','2026-02-02 10:00:01.000000'),(123,1,19,'ORD-2009','ORDER_CREATED','total=49.99 USD',NULL,'seed','2026-02-22 14:00:01.000000'),(124,1,19,'ORD-2009','STATUS_UPDATED','CREATED -> SHIPPED; source=OPS_TOOL',NULL,'seed','2026-02-23 08:00:01.000000'),(125,1,20,'ORD-2010','ORDER_CREATED','total=67.97 USD',NULL,'seed','2026-02-25 10:00:01.000000'),(126,1,20,'ORD-2010','STATUS_UPDATED','CREATED -> PAID; source=OPS_TOOL',NULL,'seed','2026-02-25 10:30:01.000000'),(127,1,70,'3371103454','ORDER_CREATED','total=79.97 USD; lines=2',NULL,NULL,'2026-03-13 03:05:03.679047'),(128,1,71,'3371150261','ORDER_CREATED','total=69.97 USD; lines=2',NULL,NULL,'2026-03-13 03:05:50.305285'),(129,1,72,'3371174256','ORDER_CREATED','total=89.97 USD; lines=1',NULL,NULL,'2026-03-13 03:06:14.535360'),(130,1,73,'3371189495','ORDER_CREATED','total=99.95 USD; lines=1',NULL,NULL,'2026-03-13 03:06:29.532518'),(131,1,74,'3371202203','ORDER_CREATED','total=69.97 USD; lines=2',NULL,NULL,'2026-03-13 03:06:42.238182'),(132,1,76,'3371565018','ORDER_CREATED','total=29.99 USD; lines=1',NULL,NULL,'2026-03-13 03:12:45.086744'),(133,1,77,'3424354220','ORDER_CREATED','total=79.97 USD; lines=2',NULL,NULL,'2026-03-13 17:52:34.425237'),(134,1,78,'3424381892','ORDER_CREATED','total=79.97 USD; lines=2',NULL,NULL,'2026-03-13 17:53:02.025806'),(135,1,79,'3424418434','ORDER_CREATED','total=69.97 USD; lines=2',NULL,NULL,'2026-03-13 17:53:38.560211'),(136,1,80,'3424461526','ORDER_CREATED','total=89.97 USD; lines=1',NULL,NULL,'2026-03-13 17:54:21.554591'),(137,1,81,'3424483453','ORDER_CREATED','total=99.95 USD; lines=1',NULL,NULL,'2026-03-13 17:54:43.503664'),(138,1,82,'3424520171','ORDER_CREATED','total=69.97 USD; lines=2',NULL,NULL,'2026-03-13 17:55:20.196184'),(139,1,83,'3425865543','ORDER_CREATED','total=19.99 USD; lines=1',NULL,NULL,'2026-03-13 18:17:45.706015'),(140,1,86,'3428593792','ORDER_CREATED','total=59.97 USD; lines=1',NULL,NULL,'2026-03-13 19:03:13.937254'),(141,1,87,'3428622826','ORDER_CREATED','total=59.97 USD; lines=1',NULL,NULL,'2026-03-13 19:03:42.853706'),(142,1,89,'3428732716','ORDER_CREATED','total=29.99 USD; lines=1',NULL,NULL,'2026-03-13 19:05:32.782174'),(143,1,72,'3371174256','ORDER_CANCELLED','reason=Per Customer Request; notes=None',NULL,NULL,'2026-03-14 13:22:05.507911'),(144,1,73,'3371189495','ADDRESS_UPDATED','9 -> 5',NULL,NULL,'2026-03-14 13:23:26.619424'),(145,1,73,'3371189495','ADDRESS_UPDATED','5 -> 12',NULL,NULL,'2026-03-14 13:23:58.146011'),(146,1,73,'3371189495','ADDRESS_UPDATED','12 -> 3',NULL,NULL,'2026-03-14 13:24:23.833644'),(147,1,73,'3371189495','ADDRESS_UPDATED','3 -> 17',NULL,NULL,'2026-03-14 13:24:55.778875'),(148,1,73,'3371189495','ADDRESS_UPDATED','17 -> 18',NULL,NULL,'2026-03-14 13:26:20.797929'),(149,1,73,'3371189495','ADDRESS_UPDATED','18 -> 19',NULL,NULL,'2026-03-14 13:26:58.815398'),(150,1,73,'3371189495','ADDRESS_UPDATED','19 -> 20',NULL,NULL,'2026-03-14 13:29:57.116690'),(151,1,87,'3428622826','ADDRESS_UPDATED','9 -> 21',NULL,NULL,'2026-03-14 16:34:44.971180');
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
) ENGINE=InnoDB AUTO_INCREMENT=94 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sales_order_line`
--

LOCK TABLES `sales_order_line` WRITE;
/*!40000 ALTER TABLE `sales_order_line` DISABLE KEYS */;
INSERT INTO `sales_order_line` VALUES (1,1,1,1,1,'SKU-RED-MUG',1,14.99,14.99,'DELIVERED'),(2,1,1,2,2,'SKU-BLK-TSHIRT-M',1,24.99,24.99,'DELIVERED'),(3,1,2,1,1,'SKU-RED-MUG',1,14.99,14.99,'SHIPPED'),(4,1,11,1,3,'SKU-MUG-BLUE-16OZ',2,16.99,33.98,'DELIVERED'),(5,1,11,2,4,'SKU-TUMBLR-SS-20OZ',1,28.99,28.99,'DELIVERED'),(6,1,19,1,1,'SKU-RED-MUG',2,19.99,39.98,'OPEN'),(7,1,19,2,2,'SKU-BLK-TSHIRT-M',1,29.99,29.99,'OPEN'),(8,1,20,1,1,'SKU-RED-MUG',2,19.99,39.98,'OPEN'),(9,1,20,2,2,'SKU-BLK-TSHIRT-M',1,29.99,29.99,'OPEN'),(10,1,21,1,1,'SKU-RED-MUG',1,19.99,19.99,'OPEN'),(11,1,22,1,1,'SKU-RED-MUG',1,19.99,19.99,'OPEN'),(12,1,23,1,1,'SKU-RED-MUG',1,19.99,19.99,'OPEN'),(13,1,25,1,1,'SKU-RED-MUG',1,19.99,19.99,'OPEN'),(14,1,25,2,2,'SKU-BLK-TSHIRT-M',2,29.99,59.98,'OPEN'),(15,1,26,1,1,'SKU-RED-MUG',1,19.99,19.99,'OPEN'),(16,1,26,2,2,'SKU-BLK-TSHIRT-M',2,29.99,59.98,'OPEN'),(17,1,27,1,1,'SKU-RED-MUG',1,19.99,19.99,'OPEN'),(18,1,27,2,2,'SKU-BLK-TSHIRT-M',2,29.99,59.98,'OPEN'),(19,1,28,1,1,'SKU-RED-MUG',1,19.99,19.99,'OPEN'),(20,1,28,2,2,'SKU-BLK-TSHIRT-M',1,29.99,29.99,'OPEN'),(21,1,29,1,1,'SKU-RED-MUG',1,19.99,19.99,'OPEN'),(22,1,29,2,2,'SKU-BLK-TSHIRT-M',2,29.99,59.98,'OPEN'),(23,1,30,1,1,'SKU-RED-MUG',1,19.99,19.99,'OPEN'),(24,1,30,2,2,'SKU-BLK-TSHIRT-M',2,29.99,59.98,'OPEN'),(25,1,31,1,1,'SKU-RED-MUG',1,19.99,19.99,'OPEN'),(26,1,31,2,2,'SKU-BLK-TSHIRT-M',1,29.99,29.99,'OPEN'),(27,1,32,1,1,'SKU-RED-MUG',1,19.99,19.99,'OPEN'),(28,1,32,2,2,'SKU-BLK-TSHIRT-M',3,29.99,89.97,'OPEN'),(29,1,33,1,2,'SKU-BLK-TSHIRT-M',1,29.99,29.99,'OPEN'),(30,1,34,1,1,'SKU-RED-MUG',4,19.99,79.96,'OPEN'),(31,1,35,1,1,'SKU-RED-MUG',2,19.99,39.98,'OPEN'),(32,1,36,1,1,'SKU-RED-MUG',1,19.99,19.99,'OPEN'),(33,1,36,2,2,'SKU-BLK-TSHIRT-M',2,29.99,59.98,'OPEN'),(34,1,37,1,1,'SKU-RED-MUG',1,19.99,19.99,'OPEN'),(35,1,37,2,2,'SKU-BLK-TSHIRT-M',2,29.99,59.98,'OPEN'),(36,1,38,1,1,'SKU-RED-MUG',1,19.99,19.99,'OPEN'),(37,1,38,2,2,'SKU-BLK-TSHIRT-M',3,29.99,89.97,'OPEN'),(38,1,39,1,1,'SKU-RED-MUG',1,19.99,19.99,'OPEN'),(39,1,39,2,2,'SKU-BLK-TSHIRT-M',1,29.99,29.99,'OPEN'),(40,1,40,1,2,'SKU-BLK-TSHIRT-M',1,29.99,29.99,'OPEN'),(41,1,41,1,1,'SKU-RED-MUG',4,19.99,79.96,'OPEN'),(42,1,42,1,1,'SKU-RED-MUG',2,19.99,39.98,'OPEN'),(43,1,43,1,1,'SKU-RED-MUG',1,19.99,19.99,'OPEN'),(44,1,43,2,2,'SKU-BLK-TSHIRT-M',2,29.99,59.98,'OPEN'),(45,1,44,1,1,'SKU-RED-MUG',1,19.99,19.99,'OPEN'),(46,1,44,2,2,'SKU-BLK-TSHIRT-M',2,29.99,59.98,'OPEN'),(47,1,45,1,1,'SKU-RED-MUG',1,19.99,19.99,'OPEN'),(48,1,45,2,2,'SKU-BLK-TSHIRT-M',3,29.99,89.97,'OPEN'),(49,1,46,1,1,'SKU-RED-MUG',1,19.99,19.99,'OPEN'),(50,1,46,2,2,'SKU-BLK-TSHIRT-M',1,29.99,29.99,'OPEN'),(51,1,47,1,2,'SKU-BLK-TSHIRT-M',1,29.99,29.99,'OPEN'),(52,1,48,1,1,'SKU-RED-MUG',4,19.99,79.96,'OPEN'),(53,1,49,1,1,'SKU-RED-MUG',2,19.99,39.98,'OPEN'),(54,1,50,1,1,'SKU-RED-MUG',1,19.99,19.99,'OPEN'),(55,1,50,2,2,'SKU-BLK-TSHIRT-M',2,29.99,59.98,'OPEN'),(56,1,51,1,2,'SKU-BLK-TSHIRT-M',2,29.99,59.98,'OPEN'),(57,1,52,1,1,'SKU-RED-MUG',3,19.99,59.97,'OPEN'),(58,1,53,1,1,'SKU-RED-MUG',1,19.99,19.99,'OPEN'),(59,1,53,2,2,'SKU-BLK-TSHIRT-M',1,29.99,29.99,'OPEN'),(60,1,60,1,1,'SKU-RED-MUG',2,19.99,39.98,'OPEN'),(61,1,61,1,2,'SKU-BLK-TSHIRT-M',1,29.99,29.99,'OPEN'),(62,1,62,1,1,'SKU-RED-MUG',1,19.99,19.99,'OPEN'),(63,1,62,2,2,'SKU-BLK-TSHIRT-M',2,29.99,59.98,'OPEN'),(64,1,63,1,1,'SKU-RED-MUG',1,19.99,19.99,'OPEN'),(65,1,63,2,2,'SKU-BLK-TSHIRT-M',2,29.99,59.98,'OPEN'),(66,1,64,1,1,'SKU-RED-MUG',1,19.99,19.99,'OPEN'),(67,1,65,1,2,'SKU-BLK-TSHIRT-M',3,29.99,89.97,'OPEN'),(68,1,66,1,2,'SKU-BLK-TSHIRT-M',3,29.99,89.97,'OPEN'),(69,1,67,1,1,'SKU-RED-MUG',4,19.99,79.96,'OPEN'),(70,1,68,1,1,'SKU-RED-MUG',1,19.99,19.99,'OPEN'),(71,1,70,1,1,'SKU-RED-MUG',1,19.99,19.99,'OPEN'),(72,1,70,2,2,'SKU-BLK-TSHIRT-M',2,29.99,59.98,'OPEN'),(73,1,71,1,1,'SKU-RED-MUG',2,19.99,39.98,'OPEN'),(74,1,71,2,2,'SKU-BLK-TSHIRT-M',1,29.99,29.99,'OPEN'),(75,1,72,1,2,'SKU-BLK-TSHIRT-M',3,29.99,89.97,'OPEN'),(76,1,73,1,1,'SKU-RED-MUG',5,19.99,99.95,'OPEN'),(77,1,74,1,1,'SKU-RED-MUG',2,19.99,39.98,'OPEN'),(78,1,74,2,2,'SKU-BLK-TSHIRT-M',1,29.99,29.99,'OPEN'),(79,1,76,1,2,'SKU-BLK-TSHIRT-M',1,29.99,29.99,'OPEN'),(80,1,77,1,1,'SKU-RED-MUG',1,19.99,19.99,'OPEN'),(81,1,77,2,2,'SKU-BLK-TSHIRT-M',2,29.99,59.98,'OPEN'),(82,1,78,1,1,'SKU-RED-MUG',1,19.99,19.99,'OPEN'),(83,1,78,2,2,'SKU-BLK-TSHIRT-M',2,29.99,59.98,'OPEN'),(84,1,79,1,1,'SKU-RED-MUG',2,19.99,39.98,'OPEN'),(85,1,79,2,2,'SKU-BLK-TSHIRT-M',1,29.99,29.99,'OPEN'),(86,1,80,1,2,'SKU-BLK-TSHIRT-M',3,29.99,89.97,'OPEN'),(87,1,81,1,1,'SKU-RED-MUG',5,19.99,99.95,'OPEN'),(88,1,82,1,1,'SKU-RED-MUG',2,19.99,39.98,'OPEN'),(89,1,82,2,2,'SKU-BLK-TSHIRT-M',1,29.99,29.99,'OPEN'),(90,1,83,1,1,'SKU-RED-MUG',1,19.99,19.99,'OPEN'),(91,1,86,1,16,'SKU-BLK-MD-TEE',3,19.99,59.97,'OPEN'),(92,1,87,1,16,'SKU-BLK-MD-TEE',3,19.99,59.97,'OPEN'),(93,1,89,1,2,'SKU-BLK-TSHIRT-M',1,29.99,29.99,'OPEN');
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

-- Dump completed on 2026-03-15  7:52:52
