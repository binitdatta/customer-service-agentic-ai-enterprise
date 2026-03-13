-- =============================================================================
-- seed_catalog_v2.sql
-- Adds realistic test data to make the CS workflow system end-to-end testable.
--
-- Adds:
--   4 customers   (CUST-1003 … CUST-1006)
--   8 addresses   (2 per new customer, varied US cities)
--  13 products    (product_id 3 … 15, varied categories and prices)
--  10 orders      (order_id 11 … 20, every status covered, real totals)
--  20 order lines (2–3 lines per order, referencing new product IDs)
--
-- Safe to run on a clean dump of LG_20260225.sql (after that schema loads).
-- Uses INSERT IGNORE so re-running is harmless.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- CUSTOMERS  (customer_id 3 … 6)
-- ---------------------------------------------------------------------------
INSERT IGNORE INTO `customer`
  (customer_id, tenant_id, customer_ref, first_name, last_name, email, phone, status, created_at)
VALUES
  (3, 1, 'CUST-1003', 'Sofia',   'Reyes',   'sofia.reyes@example.com',   '+1-213-555-0310', 'ACTIVE',  '2026-01-10 09:00:00'),
  (4, 1, 'CUST-1004', 'Marcus',  'Webb',    'marcus.webb@example.com',   '+1-617-555-0441', 'ACTIVE',  '2026-01-15 10:30:00'),
  (5, 1, 'CUST-1005', 'Priya',   'Nair',    'priya.nair@example.com',    '+1-415-555-0552', 'ACTIVE',  '2026-01-20 14:00:00'),
  (6, 1, 'CUST-1006', 'Daniel',  'Okafor',  'daniel.okafor@example.com', '+1-832-555-0663', 'BLOCKED', '2026-01-25 16:45:00');

-- ---------------------------------------------------------------------------
-- ADDRESSES  (address_id 7 … 14)
-- Two addresses per new customer so address-update tests have somewhere to go.
-- ---------------------------------------------------------------------------
INSERT IGNORE INTO `address`
  (address_id, tenant_id, customer_id, name_line, line1, line2, city, region, postal_code, country, is_validated, created_at)
VALUES
  -- Sofia Reyes — Los Angeles
  ( 7, 1, 3, 'Sofia Reyes',  '3800 W 6th St',       'Apt 204',  'Los Angeles',  'CA', '90020', 'US', 1, '2026-01-10 09:05:00'),
  ( 8, 1, 3, 'Sofia Reyes',  '925 N La Brea Ave',   NULL,        'West Hollywood','CA', '90038', 'US', 1, '2026-01-10 09:10:00'),
  -- Marcus Webb — Boston
  ( 9, 1, 4, 'Marcus Webb',  '210 Tremont St',       'Unit 5F',  'Boston',       'MA', '02116', 'US', 1, '2026-01-15 10:35:00'),
  (10, 1, 4, 'Marcus Webb',  '88 Broad St',          NULL,        'Boston',       'MA', '02110', 'US', 1, '2026-01-15 10:40:00'),
  -- Priya Nair — San Francisco
  (11, 1, 5, 'Priya Nair',   '560 Divisadero St',   'Apt 3',    'San Francisco', 'CA', '94117', 'US', 1, '2026-01-20 14:05:00'),
  (12, 1, 5, 'Priya Nair',   '1 Ferry Building',    'Stall 32',  'San Francisco', 'CA', '94111', 'US', 1, '2026-01-20 14:10:00'),
  -- Daniel Okafor — Houston
  (13, 1, 6, 'Daniel Okafor','4200 Westheimer Rd',   'Suite 110','Houston',       'TX', '77027', 'US', 1, '2026-01-25 16:50:00'),
  (14, 1, 6, 'Daniel Okafor','2200 Post Oak Blvd',   NULL,        'Houston',       'TX', '77056', 'US', 0, '2026-01-25 17:00:00');

-- ---------------------------------------------------------------------------
-- PRODUCTS  (product_id 3 … 15)
-- SKU convention: SKU-<CATEGORY>-<DESCRIPTOR>
-- ---------------------------------------------------------------------------
INSERT IGNORE INTO `product`
  (product_id, tenant_id, sku, name, is_active, created_at)
VALUES
  -- Drinkware
  ( 3, 1, 'SKU-MUG-BLUE-16OZ',     'Ceramic Mug - Cobalt Blue 16oz',         1, '2026-01-01 08:00:00'),
  ( 4, 1, 'SKU-TUMBLR-SS-20OZ',    'Stainless Steel Tumbler 20oz',            1, '2026-01-01 08:00:00'),
  ( 5, 1, 'SKU-GLASS-PINT-SET4',   'Pint Glass Set of 4',                     1, '2026-01-01 08:00:00'),
  -- Apparel
  ( 6, 1, 'SKU-TSHIRT-WHT-S',      'T-Shirt - White - Small',                 1, '2026-01-01 08:00:00'),
  ( 7, 1, 'SKU-TSHIRT-WHT-L',      'T-Shirt - White - Large',                 1, '2026-01-01 08:00:00'),
  ( 8, 1, 'SKU-HOODIE-GRY-M',      'Pullover Hoodie - Grey - Medium',         1, '2026-01-01 08:00:00'),
  ( 9, 1, 'SKU-HOODIE-GRY-XL',     'Pullover Hoodie - Grey - XL',             1, '2026-01-01 08:00:00'),
  -- Home & Desk
  (10, 1, 'SKU-NOTEBOOK-A5',       'Hardcover Notebook A5 - Dot Grid',        1, '2026-01-01 08:00:00'),
  (11, 1, 'SKU-DESK-LAMP-USB',     'LED Desk Lamp with USB Charging Port',    1, '2026-01-01 08:00:00'),
  (12, 1, 'SKU-CANDLE-SOY-8OZ',    'Soy Wax Candle - Cedarwood 8oz',          1, '2026-01-01 08:00:00'),
  -- Electronics Accessories
  (13, 1, 'SKU-CABLE-USBC-2M',     'USB-C Braided Cable 2m',                  1, '2026-01-01 08:00:00'),
  (14, 1, 'SKU-CHARGER-PD30W',     'USB-C PD 30W Wall Charger',               1, '2026-01-01 08:00:00'),
  -- Discontinued (tests inactive-SKU rejection)
  (15, 1, 'SKU-POSTER-RETRO-A2',   'Retro Travel Poster A2 - Discontinued',   0, '2026-01-01 08:00:00');

-- ---------------------------------------------------------------------------
-- ORDERS  (order_id 11 … 20)
-- Covers every status, varied customers, realistic totals.
-- Each order references a validated address from the block above.
-- ---------------------------------------------------------------------------
INSERT IGNORE INTO `sales_order`
  (order_id, tenant_id, order_number, customer_id, bill_to_address_id, ship_to_address_id,
   order_status, currency, order_total, created_at, updated_at)
VALUES
  -- Sofia Reyes orders
  (11, 1, 'ORD-2001', 3, 7,  7,  'DELIVERED',  'USD',  62.97, '2026-01-11 10:00:00', '2026-01-18 14:00:00'),
  (12, 1, 'ORD-2002', 3, 7,  8,  'SHIPPED',    'USD',  45.98, '2026-01-22 11:00:00', '2026-01-25 09:00:00'),
  -- Marcus Webb orders
  (13, 1, 'ORD-2003', 4, 9,  9,  'PAID',       'USD',  90.97, '2026-02-01 09:00:00', '2026-02-01 09:30:00'),
  (14, 1, 'ORD-2004', 4, 9,  10, 'FULFILLING', 'USD', 101.96, '2026-02-10 15:00:00', '2026-02-11 08:00:00'),
  (15, 1, 'ORD-2005', 4, 9,  9,  'CANCELLED',  'USD',  29.98, '2026-02-12 12:00:00', '2026-02-12 12:45:00'),
  -- Priya Nair orders
  (16, 1, 'ORD-2006', 5, 11, 11, 'CREATED',    'USD',  77.98, '2026-02-20 16:00:00', '2026-02-20 16:00:00'),
  (17, 1, 'ORD-2007', 5, 11, 12, 'DELIVERED',  'USD', 109.98, '2026-01-28 10:00:00', '2026-02-05 12:00:00'),
  -- Daniel Okafor orders (BLOCKED customer — good for rejection testing)
  (18, 1, 'ORD-2008', 6, 13, 13, 'CLOSED',     'USD',  39.98, '2026-01-26 09:00:00', '2026-02-02 10:00:00'),
  -- Mixed-customer orders for grid/filter testing
  (19, 1, 'ORD-2009', 3, 7,  7,  'SHIPPED',    'USD',  49.99, '2026-02-22 14:00:00', '2026-02-23 08:00:00'),
  (20, 1, 'ORD-2010', 5, 11, 11, 'PAID',       'USD',  58.97, '2026-02-25 10:00:00', '2026-02-25 10:30:00');

-- ---------------------------------------------------------------------------
-- ORDER LINES  (order_line_id 4 … 23)
-- Prices match realistic retail; line_total = qty * unit_price.
-- order_total on each sales_order above is the sum of its lines.
-- ---------------------------------------------------------------------------
INSERT IGNORE INTO `sales_order_line`
  (order_line_id, tenant_id, order_id, line_no, product_id, sku, qty, unit_price, line_total, fulfillment_status)
VALUES
  -- ORD-2001  (order_id 11)  total = 62.97
  ( 4, 1, 11, 1,  3, 'SKU-MUG-BLUE-16OZ',   2, 16.99,  33.98, 'DELIVERED'),
  ( 5, 1, 11, 2,  4, 'SKU-TUMBLR-SS-20OZ',  1, 28.99,  28.99, 'DELIVERED'),

  -- ORD-2002  (order_id 12)  total = 44.98
  ( 6, 1, 12, 1,  6, 'SKU-TSHIRT-WHT-S',    1, 22.99,  22.99, 'SHIPPED'),
  ( 7, 1, 12, 2,  7, 'SKU-TSHIRT-WHT-L',    1, 22.99,  22.99, 'SHIPPED'),   -- size swap candidate

  -- ORD-2003  (order_id 13)  total = 89.99
  ( 8, 1, 13, 1, 11, 'SKU-DESK-LAMP-USB',   1, 49.99,  49.99, 'ALLOCATED'),
  ( 9, 1, 13, 2, 14, 'SKU-CHARGER-PD30W',   1, 22.99,  22.99, 'ALLOCATED'),
  (10, 1, 13, 3, 13, 'SKU-CABLE-USBC-2M',   1, 17.99,  17.99, 'OPEN'),      -- partial allocation

  -- ORD-2004  (order_id 14)  total = 54.97
  -- ORD-2004  (order_id 14)  total = 101.96  (hoodie + notebook + 2× candle)
  (11, 1, 14, 1,  8, 'SKU-HOODIE-GRY-M',    1, 54.99,  54.99, 'SHIPPED'),
  (12, 1, 14, 2, 10, 'SKU-NOTEBOOK-A5',      1, 16.99,  16.99, 'SHIPPED'),
  (13, 1, 14, 3, 12, 'SKU-CANDLE-SOY-8OZ',   2, 14.99,  29.98, 'OPEN'),

  -- ORD-2005  (order_id 15) CANCELLED  total = 29.99
  (15, 1, 15, 1, 12, 'SKU-CANDLE-SOY-8OZ',   2, 14.99,  29.98, 'CANCELLED'),

  -- ORD-2006  (order_id 16) CREATED  total = 77.97
  (16, 1, 16, 1,  8, 'SKU-HOODIE-GRY-M',    1, 54.99,  54.99, 'OPEN'),
  (17, 1, 16, 2,  5, 'SKU-GLASS-PINT-SET4', 1, 22.99,  22.99, 'OPEN'),

  -- ORD-2007  (order_id 17) DELIVERED  total = 114.96
  (18, 1, 17, 1, 11, 'SKU-DESK-LAMP-USB',   1, 49.99,  49.99, 'DELIVERED'),
  (19, 1, 17, 2,  9, 'SKU-HOODIE-GRY-XL',   1, 59.99,  59.99, 'DELIVERED'),

  -- ORD-2008  (order_id 18) CLOSED  total = 39.98
  (20, 1, 18, 1,  3, 'SKU-MUG-BLUE-16OZ',   1, 16.99,  16.99, 'DELIVERED'),
  (21, 1, 18, 2,  4, 'SKU-TUMBLR-SS-20OZ',  1, 22.99,  22.99, 'DELIVERED'),

  -- ORD-2009  (order_id 19) SHIPPED  total = 49.99
  (22, 1, 19, 1, 11, 'SKU-DESK-LAMP-USB',   1, 49.99,  49.99, 'SHIPPED'),

  -- ORD-2010  (order_id 20) PAID  total = 67.97
  (23, 1, 20, 1, 13, 'SKU-CABLE-USBC-2M',   2, 17.99,  35.98, 'OPEN'),
  (24, 1, 20, 2, 14, 'SKU-CHARGER-PD30W',   1, 22.99,  22.99, 'OPEN');

-- ---------------------------------------------------------------------------
-- SALES_ORDER_EVENTS  — one creation event per new order so the timeline
-- endpoint returns something for each new order out of the box.
-- ---------------------------------------------------------------------------
INSERT IGNORE INTO `sales_order_event`
  (tenant_id, order_id, order_number, event_type, message, actor_sub, actor_username, created_at)
VALUES
  (1, 11, 'ORD-2001', 'ORDER_CREATED',    'total=62.97 USD',  NULL, 'seed', '2026-01-11 10:00:01'),
  (1, 11, 'ORD-2001', 'STATUS_UPDATED',   'CREATED -> DELIVERED; source=OPS_TOOL', NULL, 'seed', '2026-01-18 14:00:01'),
  (1, 12, 'ORD-2002', 'ORDER_CREATED',    'total=44.98 USD',  NULL, 'seed', '2026-01-22 11:00:01'),
  (1, 12, 'ORD-2002', 'STATUS_UPDATED',   'CREATED -> SHIPPED; source=OPS_TOOL',   NULL, 'seed', '2026-01-25 09:00:01'),
  (1, 13, 'ORD-2003', 'ORDER_CREATED',    'total=89.99 USD',  NULL, 'seed', '2026-02-01 09:00:01'),
  (1, 13, 'ORD-2003', 'STATUS_UPDATED',   'CREATED -> PAID; source=OPS_TOOL',      NULL, 'seed', '2026-02-01 09:30:01'),
  (1, 14, 'ORD-2004', 'ORDER_CREATED',    'total=101.96 USD',  NULL, 'seed', '2026-02-10 15:00:01'),
  (1, 14, 'ORD-2004', 'STATUS_UPDATED',   'CREATED -> PAID; source=OPS_TOOL',      NULL, 'seed', '2026-02-10 15:30:01'),
  (1, 14, 'ORD-2004', 'STATUS_UPDATED',   'PAID -> FULFILLING; source=OPS_TOOL',   NULL, 'seed', '2026-02-11 08:00:01'),
  (1, 15, 'ORD-2005', 'ORDER_CREATED',    'total=29.99 USD',  NULL, 'seed', '2026-02-12 12:00:01'),
  (1, 15, 'ORD-2005', 'ORDER_CANCELLED',  'reason=customer request',               NULL, 'seed', '2026-02-12 12:45:01'),
  (1, 16, 'ORD-2006', 'ORDER_CREATED',    'total=77.97 USD',  NULL, 'seed', '2026-02-20 16:00:01'),
  (1, 17, 'ORD-2007', 'ORDER_CREATED',    'total=114.96 USD', NULL, 'seed', '2026-01-28 10:00:01'),
  (1, 17, 'ORD-2007', 'STATUS_UPDATED',   'CREATED -> DELIVERED; source=OPS_TOOL', NULL, 'seed', '2026-02-05 12:00:01'),
  (1, 18, 'ORD-2008', 'ORDER_CREATED',    'total=39.98 USD',  NULL, 'seed', '2026-01-26 09:00:01'),
  (1, 18, 'ORD-2008', 'STATUS_UPDATED',   'CREATED -> CLOSED; source=OPS_TOOL',    NULL, 'seed', '2026-02-02 10:00:01'),
  (1, 19, 'ORD-2009', 'ORDER_CREATED',    'total=49.99 USD',  NULL, 'seed', '2026-02-22 14:00:01'),
  (1, 19, 'ORD-2009', 'STATUS_UPDATED',   'CREATED -> SHIPPED; source=OPS_TOOL',   NULL, 'seed', '2026-02-23 08:00:01'),
  (1, 20, 'ORD-2010', 'ORDER_CREATED',    'total=67.97 USD',  NULL, 'seed', '2026-02-25 10:00:01'),
  (1, 20, 'ORD-2010', 'STATUS_UPDATED',   'CREATED -> PAID; source=OPS_TOOL',      NULL, 'seed', '2026-02-25 10:30:01');

-- ---------------------------------------------------------------------------
-- AUTO_INCREMENT resets — keeps sequences clean after INSERT IGNORE
-- ---------------------------------------------------------------------------
ALTER TABLE `customer`        AUTO_INCREMENT = 7;
ALTER TABLE `address`         AUTO_INCREMENT = 15;
ALTER TABLE `product`         AUTO_INCREMENT = 16;
ALTER TABLE `sales_order`     AUTO_INCREMENT = 21;
ALTER TABLE `sales_order_line` AUTO_INCREMENT = 25;