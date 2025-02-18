/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "06 - Оконные функции".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters
/*
1. Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года 
(в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
Выведите: id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом

Пример:
-------------+----------------------------
Дата продажи | Нарастающий итог по месяцу
-------------+----------------------------
 2015-01-29   | 4801725.31
 2015-01-30	 | 4801725.31
 2015-01-31	 | 4801725.31
 2015-02-01	 | 9626342.98
 2015-02-02	 | 9626342.98
 2015-02-03	 | 9626342.98
Продажи можно взять из таблицы Invoices.
Нарастающий итог должен быть без оконной функции.
*/

set statistics time, io on
go

WITH Inv AS (
	SELECT 
		InvoiceID,
		SUM(Quantity * UnitPrice) InvSum
	FROM 
		Sales.InvoiceLines
	GROUP BY 
		InvoiceID
),
MonthAmount AS (
	SELECT 
		EOMONTH(InvoiceDate) endm, 
		SUM(InvSum) MonthSum
	FROM 
		Sales.Invoices
		JOIN Inv 
			ON Inv.InvoiceID = Invoices.InvoiceID
	WHERE InvoiceDate >= '2015-01-01'
	GROUP BY EOMONTH(InvoiceDate)
),
MonthAmountCumulative AS (
	SELECT 
		a.endm,
		SUM(b.MonthSum) AS MonthSum
	FROM 
		MonthAmount a
		JOIN MonthAmount b ON b.endm <= a.endm
	GROUP BY a.endm
)

SELECT 
	Invoices.InvoiceID, 
	Customers.CustomerName, 
	Invoices.InvoiceDate, 
	Inv.InvSum,
	mac.MonthSum
FROM 
	Sales.Invoices
	JOIN Inv ON Inv.InvoiceID = Invoices.InvoiceID
	JOIN Sales.Customers ON Customers.CustomerID = Invoices.CustomerID
	JOIN MonthAmountCumulative as mac ON mac.endm = EOMONTH(Invoices.InvoiceDate)
;

/*
2. Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.
   Сравните производительность запросов 1 и 2 с помощью set statistics time, io on
*/
-- Для предыдущего запроса
-- Время работы SQL Server:
--   Время ЦП = 125 мс, затраченное время = 283 мс.

-- Для запроса ниже
-- Время работы SQL Server:
--  Время ЦП = 47 мс, затраченное время = 2204 мс. 

WITH Inv AS (
	SELECT 
		InvoiceID,
		SUM(Quantity * UnitPrice) InvSum
	FROM 
		Sales.InvoiceLines
	GROUP BY 
		InvoiceID
)

SELECT 
	Invoices.InvoiceID, 
	Customers.CustomerName, 
	Invoices.InvoiceDate, 
	Inv.InvSum,
	SUM(Inv.InvSum) OVER(ORDER BY EOMONTH(Invoices.InvoiceDate)) CumulativeSum
FROM 
	Sales.Invoices
	JOIN Inv ON Inv.InvoiceID = Invoices.InvoiceID
	JOIN Sales.Customers ON Customers.CustomerID = Invoices.CustomerID
WHERE InvoiceDate >= '2015-01-01'
;

/*
3. Вывести список 2х самых популярных продуктов (по количеству проданных) 
в каждом месяце за 2016 год (по 2 самых популярных продукта в каждом месяце).
*/

WITH miq AS (
	SELECT
		[EndMonth] = EOMONTH(Invoices.InvoiceDate),
		StockItems.StockItemName,
		[MonthQty] = SUM(InvoiceLines.Quantity) ,
		[RowNumber] = ROW_NUMBER() OVER (PARTITION BY EOMONTH(Invoices.InvoiceDate) ORDER BY SUM(InvoiceLines.Quantity) DESC)
	FROM 
		Sales.InvoiceLines
		JOIN Warehouse.StockItems ON InvoiceLines.StockItemID = StockItems.StockItemID
		JOIN Sales.Invoices ON InvoiceLines.InvoiceID = Invoices.InvoiceID
	WHERE Invoices.InvoiceDate BETWEEN '2016-01-01' AND '2016-12-31'
	GROUP BY 
		EOMONTH(Invoices.InvoiceDate), 
		StockItems.StockItemName
	)

SELECT 
	[MonthName] = FORMAT([EndMonth], 'MMMM', 'Ru-ru'),
	[StockItemName],
	[MonthQty]
FROM miq
WHERE [RowNumber] <= 2
ORDER BY 
	[EndMonth], 
	[RowNumber]
;


/*
4. Функции одним запросом
Посчитайте по таблице товаров (в вывод также должен попасть ид товара, название, брэнд и цена):
* пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
* посчитайте общее количество товаров и выведете полем в этом же запросе
* посчитайте общее количество товаров в зависимости от первой буквы названия товара
* отобразите следующий id товара исходя из того, что порядок отображения товаров по имени 
* предыдущий ид товара с тем же порядком отображения (по имени)
* названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
* сформируйте 30 групп товаров по полю вес товара на 1 шт

Для этой задачи НЕ нужно писать аналог без аналитических функций.
*/

SELECT 
	StockItemID, 
	StockItemName, 
	Brand, 
	UnitPrice,
	ROW_NUMBER() OVER(PARTITION BY LEFT(StockItemName, 1) ORDER BY StockItemName) rn,
	COUNT(*) OVER() CommonCount,
	COUNT(*) OVER(PARTITION BY LEFT(StockItemName, 1)) FirstSymbolCount,
	LEAD(StockItemID) OVER(ORDER BY StockItemName) NextItemID,
	LAG(StockItemID) OVER(ORDER BY StockItemName) PrevItemID,
	LAG(StockItemName, 2, 'No items') OVER(ORDER BY StockItemName) PrevPrevItemName,
	NTILE(30) OVER(ORDER BY TypicalWeightPerUnit) WeightGroup
FROM 
	Warehouse.StockItems
ORDER BY 
	StockItemName
;

/*
5. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал.
   В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки.
*/

SELECT TOP(1) WITH TIES 
	People.PersonID, 
	People.FullName, 
	Customers.CustomerID, 
	Customers.CustomerName, 
	Invoices.InvoiceDate, 
	SUM(InvoiceLines.Quantity * InvoiceLines.UnitPrice) OVER(PARTITION BY Invoices.InvoiceID) InvoiceTotal
FROM 
	Sales.Invoices
	INNER JOIN Sales.InvoiceLines ON InvoiceLines.InvoiceID = Invoices.InvoiceID
	INNER JOIN Application.People ON People.PersonID = Invoices.SalespersonPersonID 
	INNER JOIN Sales.Customers ON Customers.CustomerID = Invoices.CustomerID
ORDER BY 
	ROW_NUMBER() OVER(PARTITION BY Invoices.SalespersonPersonID ORDER BY InvoiceDate DESC)
;


/*
6. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

WITH temp AS (
	SELECT 
		Customers.CustomerID,
		Customers.CustomerName,
		StockItemID,
		UnitPrice,
		Invoices.InvoiceDate, Invoices.InvoiceID,
		DENSE_RANK() OVER(PARTITION BY Customers.CustomerID ORDER BY UnitPrice DESC) DensRank
	FROM 
		Sales.Invoices
		JOIN Sales.InvoiceLines ON InvoiceLines.InvoiceID = Invoices.InvoiceID
		JOIN Sales.Customers ON Customers.CustomerID = Invoices.CustomerID)

SELECT DISTINCT
	CustomerID,
	CustomerName,
	StockItemID,
	UnitPrice,
	InvoiceDate 
FROM 
	temp
WHERE DensRank <= 2

Опционально можете для каждого запроса без оконных функций сделать вариант запросов с оконными функциями и сравнить их производительность. 