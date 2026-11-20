-- MySQL 8.0.46
-- База данных: sales_norm
-- Состояние до нормализации

CREATE DATABASE IF NOT EXISTS `sales_norm`;
USE `sales_norm`;

DROP TABLE IF EXISTS `sales_unnormalized`;

CREATE TABLE `sales_unnormalized` (
  `sale_id` INT NOT NULL,
  `sale_date` DATE NOT NULL,
  `client_id` INT NOT NULL,
  `client_name` VARCHAR(100) NOT NULL,
  `client_city` VARCHAR(100) NOT NULL,
  `product_id` INT NOT NULL,
  `product_name` VARCHAR(100) NOT NULL,
  `unit_price` DECIMAL(10,2) NOT NULL,
  `quantity` INT NOT NULL,
  PRIMARY KEY (`sale_id`, `product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `sales_unnormalized`
(`sale_id`, `sale_date`, `client_id`, `client_name`, `client_city`, `product_id`, `product_name`, `unit_price`, `quantity`)
VALUES
(5001, '2026-11-20', 101, 'Иванов Иван', 'Москва', 201, 'Монитор', 15000.00, 2),
(5001, '2026-11-20', 101, 'Иванов Иван', 'Москва', 202, 'Клавиатура', 2000.00, 1),
(5002, '2026-11-20', 102, 'Петрова Мария', 'Санкт-Петербург', 203, 'Мышь', 1000.00, 3),
(5002, '2026-11-20', 102, 'Петрова Мария', 'Санкт-Петербург', 204, 'Наушники', 3500.00, 1),
(5003, '2026-11-20', 101, 'Иванов Иван', 'Москва', 205, 'Колонки', 2500.00, 2),
(5004, '2026-11-20', 103, 'Сидоров Алексей', 'Казань', 202, 'Клавиатура', 2000.00, 5),
(5004, '2026-11-20', 103, 'Сидоров Алексей', 'Казань', 203, 'Мышь', 1000.00, 2),
(5005, '2026-11-20', 102, 'Петрова Мария', 'Санкт-Петербург', 201, 'Монитор', 15000.00, 1),
(5006, '2026-11-20', 103, 'Сидоров Алексей', 'Казань', 204, 'Наушники', 3500.00, 2),
(5006, '2026-11-20', 103, 'Сидоров Алексей', 'Казань', 205, 'Колонки', 2500.00, 1);
