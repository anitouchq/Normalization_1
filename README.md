# Лабораторная работа № 1. Нормализация данных в БД

## Цель работы

Изучить избыточность данных и аномалии вставки, обновления и удаления. Преобразовать исходную таблицу продаж к третьей нормальной форме (3NF), перенести данные без потерь и проверить результат.

## Используемые инструменты

- Visual Studio Code;
- Git Bash / Docker CLI;
- Docker;
- MySQL 8.0.46;
- Git и GitHub.

## 1. Исходная база данных

Исходный дамп относится к базе данных `sales_norm` и содержит таблицу `sales_unnormalized`. В каждой строке записана одна позиция продажи. Данные о продаже и клиенте повторяются для каждой товарной позиции.

Подключаемся к базе:

```sql
USE sales_norm;
SHOW TABLES;
DESCRIBE sales_unnormalized;
```

Структура исходной таблицы:

| Поле | Тип | Назначение |
|---|---|---|
| `sale_id` | INT | Номер продажи |
| `sale_date` | DATE | Дата продажи |
| `client_id` | INT | Код клиента |
| `client_name` | VARCHAR(100) | Имя клиента |
| `client_city` | VARCHAR(100) | Город клиента |
| `product_id` | INT | Код товара |
| `product_name` | VARCHAR(100) | Название товара |
| `unit_price` | DECIMAL(10,2) | Цена единицы товара |
| `quantity` | INT | Количество |

Первичный ключ исходной таблицы составной: `(sale_id, product_id)`.

Проверим исходные записи:

```sql
SELECT *
FROM sales_unnormalized
ORDER BY sale_id, product_id;
```

В предоставленном дампе содержится 10 строк, 6 продаж, 3 клиента и 5 товаров.

## 2. Анализ функциональных зависимостей

Для исходных данных определяются следующие функциональные зависимости:

- `sale_id → sale_date, client_id` — номер продажи определяет дату и клиента;
- `client_id → client_name, client_city` — код клиента определяет его имя и город;
- `product_id → product_name, unit_price` — код товара определяет название и цену;
- `(sale_id, product_id) → quantity` — количество определяется конкретной товарной позицией в продаже.

Составной ключ исходной таблицы — `(sale_id, product_id)`: одна продажа может содержать несколько товаров, а один товар может встречаться в разных продажах.

### Первая нормальная форма (1NF)

Каждое поле содержит одно атомарное значение, а каждая строка описывает одну товарную позицию. Поэтому табличная структура соответствует 1NF. При этом сведения о продаже и клиенте многократно повторяются.

### Вторая нормальная форма (2NF)

Все неключевые атрибуты должны полностью зависеть от всего составного ключа. В исходной таблице это условие нарушено:

- `sale_date` и `client_id` зависят только от `sale_id`;
- `product_name` и `unit_price` зависят только от `product_id`;
- `quantity` зависит от всей пары `(sale_id, product_id)`.

Это частичные зависимости от составного ключа.

### Третья нормальная форма (3NF)

Кроме требований 2NF, неключевые атрибуты не должны транзитивно зависеть от ключа. Например, имя и город клиента определяются через `client_id`, а не непосредственно через номер продажи. Сведения о клиентах и товарах необходимо вынести в отдельные таблицы.

## 3. Аномалии исходной таблицы

### Аномалия обновления

Если клиент изменит город, необходимо исправить все строки этого клиента. Пропуск хотя бы одной строки приведёт к противоречивым данным.

Безопасная демонстрация с отменой изменений:

```sql
START TRANSACTION;

UPDATE sales_unnormalized
SET client_city = 'Тестовый город'
WHERE client_id = 101
LIMIT 1;

SELECT sale_id, client_id, client_name, client_city
FROM sales_unnormalized
WHERE client_id = 101;

ROLLBACK;
```

### Аномалия удаления

Если удалить все товарные позиции единственной продажи клиента 102, из таблицы исчезнут и сведения, по которым можно было узнать имя и город этого клиента.

```sql
START TRANSACTION;

DELETE FROM sales_unnormalized
WHERE sale_id IN (
    SELECT sale_id
    FROM (
        SELECT sale_id
        FROM sales_unnormalized
        WHERE client_id = 102
    ) AS client_sales
);

SELECT DISTINCT client_id, client_name, client_city
FROM sales_unnormalized
WHERE client_id = 102;

ROLLBACK;
```

### Аномалия вставки

Нельзя добавить клиента или товар как самостоятельную сущность: исходная таблица предназначена для хранения товарных позиций продаж. Для добавления клиента без продажи пришлось бы создавать неполную строку либо использовать фиктивные значения.

В нормализованной схеме клиент и товар смогут существовать независимо от продаж.

## 4. Проектирование схемы в 3NF

Разделим исходные данные на четыре таблицы:

| Таблица | Назначение | Ключи |
|---|---|---|
| `clients` | Справочник клиентов | `client_id` — PK |
| `products` | Справочник товаров | `product_id` — PK |
| `sales` | Заголовки продаж | `sale_id` — PK, `client_id` — FK |
| `sale_items` | Товарные позиции продаж | `(sale_id, product_id)` — PK, оба поля — FK |

Связи:

- один клиент может совершить несколько продаж;
- каждая продажа относится к одному клиенту;
- одна продажа может содержать несколько товаров;
- один товар может входить в разные продажи.

### Создание таблиц

Выполним SQL в базе `sales_norm`:

```sql
CREATE TABLE clients (
    client_id   INT PRIMARY KEY,
    client_name VARCHAR(100) NOT NULL,
    client_city VARCHAR(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE products (
    product_id   INT PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    unit_price   DECIMAL(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE sales (
    sale_id   INT PRIMARY KEY,
    sale_date DATE NOT NULL,
    client_id INT NOT NULL,
    CONSTRAINT fk_sales_client
        FOREIGN KEY (client_id)
        REFERENCES clients(client_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE sale_items (
    sale_id    INT NOT NULL,
    product_id INT NOT NULL,
    quantity   INT NOT NULL,
    PRIMARY KEY (sale_id, product_id),
    CONSTRAINT fk_items_sale
        FOREIGN KEY (sale_id)
        REFERENCES sales(sale_id),
    CONSTRAINT fk_items_product
        FOREIGN KEY (product_id)
        REFERENCES products(product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

Теперь клиентские и товарные сведения хранятся отдельно. Внешние ключи обеспечивают ссылочную целостность, а составной первичный ключ `sale_items` запрещает повтор одной и той же товарной позиции в рамках продажи.

## 5. Перенос данных

Сначала заполним справочники и заголовки продаж, после них — таблицу товарных позиций:

```sql
INSERT INTO clients (client_id, client_name, client_city)
SELECT DISTINCT client_id, client_name, client_city
FROM sales_unnormalized;

INSERT INTO products (product_id, product_name, unit_price)
SELECT DISTINCT product_id, product_name, unit_price
FROM sales_unnormalized;

INSERT INTO sales (sale_id, sale_date, client_id)
SELECT DISTINCT sale_id, sale_date, client_id
FROM sales_unnormalized;

INSERT INTO sale_items (sale_id, product_id, quantity)
SELECT sale_id, product_id, quantity
FROM sales_unnormalized;
```

Если таблицы уже заполнены, повторный запуск этих команд приведёт к конфликтам первичных ключей. Для повторного тестирования очистите только созданные нормализованные таблицы в правильном порядке:

```sql
DELETE FROM sale_items;
DELETE FROM sales;
DELETE FROM products;
DELETE FROM clients;
```

После очистки можно повторить перенос.

## 6. Проверка результата

### Количество записей

```sql
SELECT 'sales_unnormalized' AS table_name, COUNT(*) AS row_count
FROM sales_unnormalized
UNION ALL
SELECT 'clients', COUNT(*) FROM clients
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'sales', COUNT(*) FROM sales
UNION ALL
SELECT 'sale_items', COUNT(*) FROM sale_items;
```

Ожидаемые значения для предоставленного дампа:

| Таблица | Количество |
|---|---:|
| `sales_unnormalized` | 10 |
| `clients` | 3 |
| `products` | 5 |
| `sales` | 6 |
| `sale_items` | 10 |

### Сравнение общей стоимости

До нормализации:

```sql
SELECT SUM(unit_price * quantity) AS total_before
FROM sales_unnormalized;
```

После нормализации:

```sql
SELECT SUM(p.unit_price * si.quantity) AS total_after
FROM sale_items AS si
JOIN products AS p
    ON p.product_id = si.product_id;
```

Для исходного набора данных ожидаемая общая стоимость — **80 000.00**. Значения до и после нормализации должны совпасть.

### Сверка строк после переноса

```sql
SELECT
    s.sale_id,
    s.sale_date,
    c.client_id,
    c.client_name,
    c.client_city,
    p.product_id,
    p.product_name,
    p.unit_price,
    si.quantity
FROM sale_items AS si
JOIN sales AS s
    ON s.sale_id = si.sale_id
JOIN clients AS c
    ON c.client_id = s.client_id
JOIN products AS p
    ON p.product_id = si.product_id
ORDER BY s.sale_id, p.product_id;
```

### Пример аналитического запроса

Рассчитаем общую стоимость покупок клиента с кодом 101:

```sql
SELECT
    c.client_id,
    c.client_name,
    SUM(p.unit_price * si.quantity) AS total_spent
FROM clients AS c
JOIN sales AS s
    ON s.client_id = c.client_id
JOIN sale_items AS si
    ON si.sale_id = s.sale_id
JOIN products AS p
    ON p.product_id = si.product_id
WHERE c.client_id = 101
GROUP BY c.client_id, c.client_name;
```

Ожидаемый результат для клиента 101 — **37 000.00**.

### Дополнительная проверка ссылочной целостности

Попробуем добавить товарную позицию с несуществующим товаром. Запрос должен завершиться ошибкой внешнего ключа:

```sql
INSERT INTO sale_items (sale_id, product_id, quantity)
VALUES (5001, 999, 1);
```

Не добавляйте такую строку в рабочую базу: это отрицательный тест ограничения.

В ходе зафиксированной сессии после переноса и проверочных запросов исходная таблица `sales_unnormalized` была удалена (команда `DROP TABLE` отражена в логе). Перед таким действием обязательно сохраните исходный дамп. В репозитории он находится в `dumps/before_normalization.sql`.

## 7. Дампы и журнал действий

В репозитории будут храниться дамп исходного состояния, дамп после нормализации, лог и скриншоты. Дамп, предоставленный для этой работы, относится к базе `sales_norm` и таблице `sales_unnormalized`.

Пример экспорта из Docker-контейнера (замените имя контейнера и пользователя на свои):

```bash
mkdir -p dumps logs screenshots

# Исходное состояние — до создания нормализованных таблиц
docker exec <container_name> mysqldump -u<mysql_user> -p sales_norm > dumps/before_normalization.sql

# После создания и заполнения нормализованных таблиц
docker exec <container_name> mysqldump -u<mysql_user> -p sales_norm > dumps/after_normalization.sql
```

Пароль вводится в ответ на запрос mysqldump. Не записывайте пароль в README, команды лога или репозиторий.

Фактический лог MySQL за сессию 20.11.2026 добавлен в репозиторий: [`logs/session.log`](logs/session.log). В нём сохранены команды создания исходной таблицы, демонстрации аномалий, создания и заполнения нормализованных таблиц, проверок и удаления исходной таблицы.

## 8. Материалы выполнения

Добавьте собственные скриншоты в каталог `screenshots/`:

- [ ] Подключение к MySQL в Docker.
- [ ] Просмотр исходной таблицы `sales_unnormalized`.
- [ ] Демонстрация аномалий.
- [ ] Создание таблиц `clients`, `products`, `sales`, `sale_items`.
- [ ] Перенос данных.
- [ ] Проверка количества строк.
- [ ] Сравнение общей стоимости до и после.
- [ ] Выполнение аналитического запроса.

Добавьте дампы:

- [ ] `dumps/before_normalization.sql`;
- [ ] `dumps/after_normalization.sql`.

Добавьте лог:

- [x] [`logs/session.log`](logs/session.log) — предоставленный лог фактической сессии MySQL.

## 9. Вывод

В ходе работы исходная таблица продаж была проанализирована с точки зрения функциональных зависимостей и нормальных форм. Повторяющиеся сведения о клиентах и товарах являются причиной избыточности и аномалий обновления, вставки и удаления.

Для устранения этих проблем данные разделяются на четыре связанные таблицы: справочник клиентов, справочник товаров, заголовки продаж и товарные позиции. Корректность переноса проверяется сравнением количества записей, общей стоимости продаж и просмотром объединённых данных.

**Перед сдачей выполните все запросы самостоятельно и приложите реальные скриншоты, дампы и лог. Числовые результаты в README являются ожидаемыми для предоставленного дампа и должны быть подтверждены выполнением SQL.**
