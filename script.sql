-- Таблица Скидка
CREATE TABLE Скидка (
    ID SERIAL PRIMARY KEY,
    Название VARCHAR(100) NOT NULL UNIQUE,
    Описание TEXT,
    Дата_Начала DATE NOT NULL,
    Дата_Окончания DATE NOT NULL,
    Процент_Скидки DECIMAL(5, 2) NOT NULL
);

-- Таблица Место
CREATE TABLE Место (
    ID SERIAL PRIMARY KEY,
    Адрес VARCHAR(255) NOT NULL
);

-- Таблица Единицы измерения
CREATE TABLE Единицы_Измерения (
    Категория VARCHAR(50) PRIMARY KEY,
    Единица_Измерения VARCHAR(20) NOT NULL
);

-- Таблица Склад
CREATE TABLE Склад (
    ID SERIAL PRIMARY KEY,
    Объем_Склада DECIMAL(10, 2) NOT NULL,
    ID_Места INT NOT NULL,
    CONSTRAINT fk_место_склад FOREIGN KEY (ID_Места) REFERENCES Место(ID) ON DELETE CASCADE
);

-- Таблица Магазин
CREATE TABLE Магазин (
    ID SERIAL PRIMARY KEY,
    Номер_Полки VARCHAR(20) NOT NULL,
    ID_Места INT NOT NULL,
    CONSTRAINT fk_место_магазин FOREIGN KEY (ID_Места) REFERENCES Место(ID) ON DELETE CASCADE
);

-- Таблица Товар
CREATE TABLE Товар (
    ID SERIAL PRIMARY KEY,
    Название VARCHAR(100) NOT NULL,
    Описание TEXT,
    Категория VARCHAR(50) NOT NULL,
    Цена DECIMAL(10, 2) NOT NULL,
    Количество_На_Месте INT NOT NULL,
    ID_Скидки INT,
    ID_Места INT,
    CONSTRAINT fk_скидка FOREIGN KEY (ID_Скидки) REFERENCES Скидка(ID) ON DELETE SET NULL,
    CONSTRAINT fk_место FOREIGN KEY (ID_Места) REFERENCES Место(ID) ON DELETE CASCADE,
    CONSTRAINT fk_единица_измерения FOREIGN KEY (Категория) REFERENCES Единицы_Измерения(Категория) ON DELETE CASCADE
);

-- Таблица Сотрудники
CREATE TABLE Сотрудники (
    ID SERIAL PRIMARY KEY,
    Номер_Паспорта VARCHAR(10) NOT NULL UNIQUE,
    ФИО VARCHAR(100) NOT NULL,
    Должность VARCHAR(50),
    Дата_Принятия_На_Работу DATE NOT NULL,
    Заработная_Плата DECIMAL(10, 2) NOT NULL,
    Контактный_Телефон VARCHAR(15) NOT NULL UNIQUE,
    Дата_Рождения DATE NOT NULL
);

-- Таблица Продажа
CREATE TABLE Продажа (
    ID SERIAL PRIMARY KEY,
    Номер_Чека VARCHAR(20) NOT NULL UNIQUE,
    Дата_Продажи DATE NOT NULL,
    Время_Продажи TIME NOT NULL,
    Итоговая_Сумма DECIMAL(10, 2) NOT NULL,
    Способ_Оплаты VARCHAR(20),
    ID_Сотрудника INT NOT NULL,
    CONSTRAINT fk_сотрудник FOREIGN KEY (ID_Сотрудника) REFERENCES Сотрудники(ID) ON DELETE CASCADE
);

-- Таблица Поставка
CREATE TABLE Поставка (
    ID SERIAL PRIMARY KEY,
    Дата_Поставки DATE NOT NULL,
    Номер_Поставщика VARCHAR(20) NOT NULL,
    ID_Места INT NOT NULL,
    CONSTRAINT fk_место FOREIGN KEY (ID_Места) REFERENCES Место(ID) ON DELETE CASCADE
);

-- Таблица Заказ у поставщика
CREATE TABLE Заказ_У_Поставщика (
    ID_Товара INT NOT NULL,
    ID_Поставки INT NOT NULL,
    Количество_Товара INT NOT NULL,
    PRIMARY KEY (ID_Товара, ID_Поставки),
    CONSTRAINT fk_товар FOREIGN KEY (ID_Товара) REFERENCES Товар(ID) ON DELETE CASCADE,
    CONSTRAINT fk_поставка FOREIGN KEY (ID_Поставки) REFERENCES Поставка(ID) ON DELETE CASCADE
);

-- Таблица Покупка
CREATE TABLE Покупка (
    ID_Товара INT NOT NULL,
    ID_Продажи INT NOT NULL,
    Количество_Товара INT NOT NULL,
    PRIMARY KEY (ID_Товара, ID_Продажи),
    CONSTRAINT fk_товар FOREIGN KEY (ID_Товара) REFERENCES Товар(ID) ON DELETE CASCADE,
    CONSTRAINT fk_продажа FOREIGN KEY (ID_Продажи) REFERENCES Продажа(ID) ON DELETE CASCADE
);
CREATE OR REPLACE FUNCTION get_tovars_with_discounts()
RETURNS TABLE (Название TEXT, Процент_Скидки NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT Товар.Название, Скидка.Процент_Скидки
    FROM Товар
    JOIN Скидка ON Товар.ID_Скидки = Скидка.ID;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_employee_by_check(номер_чека TEXT)
RETURNS TABLE (ФИО TEXT, Контактный_Телефон TEXT) AS $$
BEGIN
    RETURN QUERY
    SELECT Сотрудники.ФИО, Сотрудники.Контактный_Телефон
    FROM Сотрудники
    JOIN Продажа ON Сотрудники.ID = Продажа.ID_Сотрудника
    WHERE Продажа.Номер_Чека = номер_чека;
END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION get_tovars_in_warehouse(адрес TEXT)
RETURNS TABLE (Название TEXT, Количество_На_Месте INT) AS $$
BEGIN
    RETURN QUERY
    SELECT Товар.Название, Товар.Количество_На_Месте
    FROM Товар
    JOIN Место ON Товар.ID_Места = Место.ID
    WHERE Место.Адрес = адрес;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_employees_with_salary_above_average()
RETURNS TABLE (ФИО TEXT, Заработная_Плата NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT ФИО, Заработная_Плата
    FROM Сотрудники
    WHERE Заработная_Плата > (SELECT AVG(Заработная_Плата) FROM Сотрудники);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_tovars_with_active_discount(дата DATE)
RETURNS TABLE (Название TEXT, ID INT) AS $$
BEGIN
    RETURN QUERY
    SELECT Товар.Название, Товар.ID
    FROM Товар
    JOIN Скидка ON Товар.ID_Скидки = Скидка.ID
    WHERE Скидка.Дата_Начала = дата;
END;
$$ LANGUAGE plpgsql;
