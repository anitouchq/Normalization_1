-- MySQL 8.0.46
-- База данных: sales_norm
-- Состояние после нормализации (3НФ)

CREATE DATABASE IF NOT EXISTS `sales_norm`;
USE `sales_norm`;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS `sale_items`;
DROP TABLE IF EXISTS `sales`;
DROP TABLE IF EXISTS `products`;
DROP TABLE IF EXISTS `clients`;
SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE `clients` (
  `client_id` INT NOT NULL,
  `client_name` VARCHAR(100) NOT NULL,
  `client_city` VARCHAR(100) NOT NULL,
  PRIMARY KEY (`client_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `products` (
  `product_id` INT NOT NULL,
  `product_name` VARCHAR(100) NOT NULL,
  `unit_price` DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `sales` (
  `sale_id` INT NOT NULL,
  `sale_date` DATE NOT NULL,
  `client_id` INT NOT NULL,
  PRIMARY KEY (`sale_id`),
  KEY `idx_sales_client_id` (`client_id`),
  CONSTRAINT `fk_sales_clients`
    FOREIGN KEY (`client_id`) REFERENCES `clients` (`client_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `sale_items` (
  `sale_id` INT NOT NULL,
  `product_id` INT NOT NULL,
  `quantity` INT NOT NULL,
  PRIMARY KEY (`sale_id`, `product_id`),
  KEY `idx_sale_items_product_id` (`product_id`),
  CONSTRAINT `fk_sale_items_sales`
    FOREIGN KEY (`sale_id`) REFERENCES `sales` (`sale_id`),
  CONSTRAINT `fk_sale_items_products`
    FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `clients` (`client_id`, `client_name`, `client_city`) VALUES
(101, 'Иванов Иван', 'Москва'),
(102, 'Петрова Мария', 'Санкт-Петербург'),
(103, 'Сидоров Алексей', 'Казань');

INSERT INTO `products` (`product_id`, `product_name`, `unit_price`) VALUES
(201, 'Монитор', 15000.00),
(202, 'Клавиатура', 2000.00),
(203, 'Мышь', 1000.00),
(204, 'Наушники', 3500.00),
(205, 'Колонки', 2500.00);

INSERT INTO `sales` (`sale_id`, `sale_date`, `client_id`) VALUES
(5001, '2026-11-20', 101),
(5002, '2026-11-20', 102),
(5003, '2026-11-20', 101),
(5004, '2026-11-20', 103),
(5005, '2026-11-20', 102),
(5006, '2026-11-20', 103);

INSERT INTO `sale_items` (`sale_id`, `product_id`, `quantity`) VALUES
(5001, 201, 2),
(5001, 202, 1),
(5002, 203, 3),
(5002, 204, 1),
(5003, 205, 2),
(5004, 202, 5),
(5004, 203, 2),
(5005, 201, 1),
(5006, 204, 2),
(5006, 205, 1);
