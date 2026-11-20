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

- `sale_date`, `client_id`, `client_name` и `client_city` определяются через `sale_id` (имя и город — через `client_id`);
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
SET client_city = 'Сочи'
WHERE sale_id = 5001 AND product_id = 201;

SELECT sale_id, client_id, client_name, client_city
FROM sales_unnormalized
WHERE client_id = 101;

ROLLBACK;
```

### Аномалия удаления

В журнале действий удалялись продажи `5004` и `5006`, обе принадлежат клиенту `103`. После удаления всех строк этого клиента его имя и город исчезают из исходной таблицы.

```sql
START TRANSACTION;

DELETE FROM sales_unnormalized
WHERE sale_id IN (5004, 5006);

SELECT DISTINCT client_id, client_name, client_city
FROM sales_unnormalized;

ROLLBACK;
```

Транзакция отменяет удаление, поэтому исходные данные восстанавливаются.

### Аномалия вставки

Исходная таблица требует значения для всех полей, включая `sale_id`, `product_id`, дату и количество. Поэтому отдельного клиента без продажи и товарной позиции добавить нельзя.

В логе зафиксирована попытка:

```sql
INSERT INTO sales_unnormalized (client_id, client_name, client_city)
VALUES (104, 'Козлов Дмитрий', 'Екатеринбург');
```

Она не может выполниться успешно: обязательные поля `sale_id`, `sale_date`, `product_id`, `product_name`, `unit_price` и `quantity` не указаны и не имеют значений по умолчанию. Это и демонстрирует аномалию вставки. В нормализованной схеме такого клиента можно добавить отдельно в таблицу `clients`.

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

Расчётные значения по данным исходного SQL-дампа (их следует подтвердить выполнением запроса):

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

Расчётный результат для клиента 101 по данным дампа — **37 000.00**.

В ходе зафиксированной сессии после переноса и проверочных запросов исходная таблица `sales_unnormalized` была удалена (команда `DROP TABLE` отражена в логе). Перед таким действием обязательно сохраните исходный дамп. В репозитории он находится в `dumps/before_normalization.sql`.

## 7. Дампы и журнал действий

В репозитории приложены оба SQL-файла:

- [`dumps/before_normalization.sql`](dumps/before_normalization.sql) — исходная таблица `sales_unnormalized` с 10 строками.
- [`dumps/after_normalization.sql`](dumps/after_normalization.sql) — четыре нормализованные таблицы с перенесёнными данными.

Журнал действий MySQL за 20.11.2026: [`logs/session.log`](logs/session.log). В нём отражены создание исходной таблицы, демонстрация аномалий, создание и заполнение нормализованных таблиц, проверочные запросы и удаление исходной таблицы.

**Примечание по проверке:** в логе оба запроса подсчёта содержат `COUNT()` без аргумента. Это ошибка в запросах журнала; корректная форма подсчёта строк — `COUNT(*)`. Поэтому ожидаемые значения в разделе 6 рассчитаны по дампам, но вывод о совпадении результатов нужно подтвердить повторным выполнением исправленных запросов.

## 8. Материалы выполнения

Скриншоты выполнения лабораторной работы:

<img width="1012" height="287" alt="Скриншот 1" src="https://github.com/user-attachments/assets/17159986-089a-4661-8e94-4dcb67a848ed" />
<img width="222" height="148" alt="Скриншот 2" src="https://github.com/user-attachments/assets/2d41c0d2-f64e-478b-8eed-97854d7e949a" />
<img width="302" height="197" alt="Скриншот 3" src="https://github.com/user-attachments/assets/add5a513-4fb5-489e-bb4d-6f085d232eca" />
<img width="311" height="175" alt="Скриншот 4" src="https://github.com/user-attachments/assets/ec206137-5bf7-4b69-b288-ef9598f7095f" />
<img width="398" height="230" alt="Скриншот 5" src="https://github.com/user-attachments/assets/83d443d7-d844-429f-aaf9-8591e4ebeeba" />
<img width="391" height="252" alt="Скриншот 6" src="https://github.com/user-attachments/assets/6f7b6d2f-32b9-4189-949c-a1b6aed751b7" />
<img width="355" height="297" alt="Скриншот 7" src="https://github.com/user-attachments/assets/8879d1ad-4841-4b14-9c93-024d4228c6a3" />
<img width="407" height="227" alt="Скриншот 8" src="https://github.com/user-attachments/assets/c89574d6-7873-42e6-88f4-829f9e921cd4" />
<img width="508" height="412" alt="Скриншот 9" src="https://github.com/user-attachments/assets/e1e37c1f-48a1-4744-87f7-a34129b2f8c1" />
<img width="872" height="257" alt="Скриншот 10" src="https://github.com/user-attachments/assets/dec67d96-5bcf-4774-b004-c6076606de59" />



## 9. Вывод

В ходе работы исходная таблица продаж была проанализирована с точки зрения функциональных зависимостей и нормальных форм. Повторяющиеся сведения о клиентах и товарах являются причиной избыточности и аномалий обновления, вставки и удаления.

Для устранения этих проблем данные разделяются на четыре связанные таблицы: справочник клиентов, справочник товаров, заголовки продаж и товарные позиции. Корректность переноса проверяется сравнением количества записей, общей стоимости продаж и просмотром объединённых данных.

**Итог:** структура разделена на четыре связанные таблицы. Данные дампов дают 10 товарных позиций, 3 клиентов, 5 товаров и 6 продаж; расчётная общая стоимость — 80 000.00, сумма покупок клиента 101 — 37 000.00.
