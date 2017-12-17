-- MySQL dump 10.16  Distrib 10.1.28-MariaDB, for Linux (x86_64)
--
-- Host: localhost    Database: trading
-- ------------------------------------------------------
-- Server version	10.1.28-MariaDB

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `bot_logs`
--

DROP TABLE IF EXISTS `bot_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `bot_logs` (
  `date` datetime DEFAULT NULL,
  `type` tinytext COLLATE utf8mb4_unicode_ci,
  `info` text COLLATE utf8mb4_unicode_ci
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `bot_trading`
--

DROP TABLE IF EXISTS `bot_trading`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `bot_trading` (
  `ord_uuid` char(50) NOT NULL,
  `name` tinytext,
  `ppu` decimal(10,8) DEFAULT NULL,
  `quant` decimal(13,8) DEFAULT NULL,
  `bought_at` datetime DEFAULT NULL,
  `s_ppu` decimal(13,8) DEFAULT NULL,
  `finished` int(11) DEFAULT '0',
  `bot_sold_at` datetime DEFAULT NULL,
  PRIMARY KEY (`ord_uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `config`
--

DROP TABLE IF EXISTS `config`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `config` (
  `name` char(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `value` tinytext COLLATE utf8mb4_unicode_ci,
  `descr` text COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `hst_btc_rates`
--

DROP TABLE IF EXISTS `hst_btc_rates`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `hst_btc_rates` (
  `name` char(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ask` decimal(10,8) DEFAULT NULL,
  `bid` decimal(10,8) DEFAULT NULL,
  `date` datetime DEFAULT NULL,
  KEY `hst_rates_date_idx` (`date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `hst_eth_rates`
--

DROP TABLE IF EXISTS `hst_eth_rates`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `hst_eth_rates` (
  `name` char(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ask` decimal(10,8) DEFAULT NULL,
  `bid` decimal(10,8) DEFAULT NULL,
  `date` datetime DEFAULT NULL,
  KEY `hst_rates_date_idx` (`date`),
  KEY `hst_rates_name_idx` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `hst_usdt_rates`
--

DROP TABLE IF EXISTS `hst_usdt_rates`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `hst_usdt_rates` (
  `name` char(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `last` decimal(13,8) DEFAULT NULL,
  `bid` decimal(13,8) DEFAULT NULL,
  `ask` decimal(13,8) DEFAULT NULL,
  `date` datetime DEFAULT NULL,
  `b_orders` smallint(6) DEFAULT NULL,
  `s_orders` smallint(6) DEFAULT NULL,
  KEY `hst_rates_date_idx` (`date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `markets`
--

DROP TABLE IF EXISTS `markets`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `markets` (
  `id` smallint(6) NOT NULL AUTO_INCREMENT,
  `name` tinytext COLLATE utf8mb4_unicode_ci,
  `High` decimal(12,8) DEFAULT NULL,
  `Low` decimal(12,8) DEFAULT NULL,
  `Volume` double DEFAULT NULL,
  `Last` decimal(12,8) DEFAULT NULL,
  `BaseVolume` double DEFAULT NULL,
  `TimeStamp` datetime DEFAULT NULL,
  `Bid` decimal(12,8) DEFAULT NULL,
  `Ask` decimal(12,8) DEFAULT NULL,
  `OpenBuyOrders` int(11) DEFAULT NULL,
  `OpenSellOrders` int(11) DEFAULT NULL,
  `PrevDay` decimal(12,8) DEFAULT NULL,
  `Created` datetime DEFAULT NULL,
  KEY `id` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=271 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `my_balances`
--

DROP TABLE IF EXISTS `my_balances`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `my_balances` (
  `pid` tinyint(4) DEFAULT '2',
  `currency` char(7) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Balance` decimal(13,8) DEFAULT NULL,
  `Available` decimal(13,8) DEFAULT NULL,
  `Pending` decimal(13,8) DEFAULT NULL,
  `CryptoAddress` tinytext COLLATE utf8mb4_unicode_ci
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `my_hst_orders`
--

DROP TABLE IF EXISTS `my_hst_orders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `my_hst_orders` (
  `pid` tinyint(4) DEFAULT '2',
  `OrderUuid` tinytext COLLATE utf8mb4_unicode_ci,
  `Exchange` char(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `TimeStamp` datetime DEFAULT NULL,
  `OrderType` char(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Limit` decimal(10,8) DEFAULT NULL,
  `Quantity` decimal(15,8) DEFAULT NULL,
  `QuantityRemaining` decimal(15,8) DEFAULT NULL,
  `Commission` decimal(10,8) DEFAULT NULL,
  `Price` decimal(10,8) DEFAULT NULL,
  `PricePerUnit` decimal(10,8) DEFAULT NULL,
  `IsConditional` bit(1) DEFAULT NULL,
  `Condition` bit(1) DEFAULT NULL,
  `ConditionTarget` tinytext COLLATE utf8mb4_unicode_ci,
  `ImmediateOrCancel` bit(1) DEFAULT NULL,
  `Closed` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `my_open_orders`
--

DROP TABLE IF EXISTS `my_open_orders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `my_open_orders` (
  `pid` tinyint(4) DEFAULT '2',
  `Uuid` tinytext COLLATE utf8mb4_unicode_ci,
  `OrderUuid` tinytext COLLATE utf8mb4_unicode_ci,
  `Exchange` char(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `OrderType` char(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Quantity` decimal(15,8) DEFAULT NULL,
  `QuantityRemaining` decimal(15,8) DEFAULT NULL,
  `CommissionPaid` decimal(10,8) DEFAULT NULL,
  `Limit` decimal(10,8) DEFAULT NULL,
  `Price` decimal(10,8) DEFAULT NULL,
  `PricePerUnit` decimal(10,8) DEFAULT NULL,
  `Opened` datetime DEFAULT NULL,
  `Closed` datetime DEFAULT NULL,
  `ImmediateOrCancel` bit(1) DEFAULT NULL,
  `IsConditional` bit(1) DEFAULT NULL,
  `CancelInitiated` bit(1) DEFAULT NULL,
  `Condition` tinytext COLLATE utf8mb4_unicode_ci,
  `ConditionTarget` tinyint(4) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `my_ticks`
--

DROP TABLE IF EXISTS `my_ticks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `my_ticks` (
  `name` char(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `last` decimal(13,8) DEFAULT NULL,
  `ask` decimal(13,8) DEFAULT NULL,
  `bid` decimal(13,8) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `my_trade_pairs`
--

DROP TABLE IF EXISTS `my_trade_pairs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `my_trade_pairs` (
  `pid` tinyint(4) NOT NULL DEFAULT '2',
  `name` char(15) NOT NULL,
  `step` decimal(13,8) DEFAULT NULL,
  `operation_amount` decimal(13,8) DEFAULT '0.00000000',
  `start_buy_price` decimal(13,8) DEFAULT NULL,
  `start_sell_price` decimal(13,8) DEFAULT NULL,
  `traded` bit(1) DEFAULT b'1',
  `sell_factor` smallint(6) DEFAULT '105',
  PRIMARY KEY (`pid`,`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `my_trading`
--

DROP TABLE IF EXISTS `my_trading`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `my_trading` (
  `pid` tinyint(4) DEFAULT '2',
  `name` char(12) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ord_uuid` tinytext COLLATE utf8mb4_unicode_ci,
  `type` tinytext COLLATE utf8mb4_unicode_ci,
  `quantity` decimal(13,8) DEFAULT NULL,
  `ppu` decimal(13,8) DEFAULT NULL,
  `bought_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `order_volumes`
--

DROP TABLE IF EXISTS `order_volumes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `order_volumes` (
  `name` tinytext COLLATE utf8mb4_unicode_ci,
  `date` datetime DEFAULT NULL,
  `count` smallint(6) DEFAULT NULL,
  `vol` decimal(13,8) DEFAULT NULL,
  `type` tinytext COLLATE utf8mb4_unicode_ci,
  KEY `date` (`date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `simul_trades`
--

DROP TABLE IF EXISTS `simul_trades`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `simul_trades` (
  `pid` tinyint(4) DEFAULT NULL,
  `pair` char(12) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `quantity` decimal(13,8) DEFAULT NULL,
  `ppu` decimal(13,8) DEFAULT NULL,
  `buy_time` datetime DEFAULT NULL,
  `track` decimal(13,8) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `stat_market_volumes`
--

DROP TABLE IF EXISTS `stat_market_volumes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `stat_market_volumes` (
  `name` tinytext COLLATE utf8mb4_unicode_ci NOT NULL,
  `enabled` tinyint(4) DEFAULT NULL,
  `last_rised_at` datetime DEFAULT NULL,
  `last_checked_at` datetime DEFAULT NULL,
  `last_rise` tinytext COLLATE utf8mb4_unicode_ci,
  `vol10` double DEFAULT NULL,
  `vol20` double DEFAULT NULL,
  `vol30` double DEFAULT NULL,
  `vol60` double DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `token_notes`
--

DROP TABLE IF EXISTS `token_notes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `token_notes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `date` datetime DEFAULT NULL,
  `sym` tinytext COLLATE utf8mb4_unicode_ci,
  `note` text COLLATE utf8mb4_unicode_ci,
  `priority` tinytext COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `tprofiles`
--

DROP TABLE IF EXISTS `tprofiles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tprofiles` (
  `pid` int(11) DEFAULT NULL,
  `name` char(12) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `check` tinyint(4) DEFAULT NULL,
  `group` tinyint(4) DEFAULT '0',
  `enabled` tinyint(4) DEFAULT '1',
  `pumped` tinyint(4) DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `traders`
--

DROP TABLE IF EXISTS `traders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `traders` (
  `id` int(11) DEFAULT NULL,
  `name` tinytext COLLATE utf8mb4_unicode_ci,
  `full_name` tinytext COLLATE utf8mb4_unicode_ci,
  `description` tinytext COLLATE utf8mb4_unicode_ci,
  `created_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2017-12-17 19:29:41
