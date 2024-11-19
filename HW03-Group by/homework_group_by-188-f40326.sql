/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, GROUP BY, HAVING".

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
1. Посчитать среднюю цену товара, общую сумму продажи по месяцам.
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

select
	 month(AsCT.TransactionDate) as [Месяц]
	,sum(AsCT.TransactionAmount) as [Общая сумма]
	,avg(SaOr.UnitPrice) as [Средняя стоимость товара]
from
	Sales.Invoices as SaIn
	inner join Sales.CustomerTransactions as AsCT ON SaIn.InvoiceID = AsCT.InvoiceID
	inner join Sales.OrderLines as SaOr ON SaIn.OrderID = SaOr.OrderID
group by month(AsCT.TransactionDate)
order by [Месяц] asc;

select * 
from Sales.Invoices

select * 
from Sales.CustomerTransactions

select * 
from Sales.OrderLines

/*
2. Отобразить все месяцы, где общая сумма продаж превысила 4 600 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

select
	year(SaIn.InvoiceDate) as [Год],
	month(SaIn.InvoiceDate) as [Месяц],
	sum(SaIL.UnitPrice * SaIL.Quantity) as SumSales
FROM Sales.Invoices as SaIn
	INNER JOIN Sales.InvoiceLines as SaIL on SaIL.InvoiceID = SaIn.InvoiceID
group by
	year(SaIn.InvoiceDate),
	month(SaIn.InvoiceDate)
having sum(SaIL.UnitPrice * SaIL.Quantity) > 4600000
order by [Год]

select * 
from Sales.Invoices

select * 
from Sales.InvoiceLines

/*
3. Вывести сумму продаж, дату первой продажи
и количество проданного по месяцам, по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году,  месяцу, товару.

Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи
* Количество проданного

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

select
	year(SaIn.InvoiceDate) as [Год продажи],
	month(SaIn.InvoiceDate) as [Месяц продажи],
	WaSI.StockItemName as [Наименование товара],
	sum(SaIL.UnitPrice * SaIL.Quantity) as [Сумма продаж],
	min(SaIn.InvoiceDate) as [Дата первой продажи],
	sum(SaIL.Quantity) as [Количество проданного]
from
	Sales.Invoices as SaIn
	INNER JOIN Sales.InvoiceLines as SaIL on SaIL.InvoiceID = SaIn.InvoiceID
	INNER JOIN Warehouse.StockItems as WaSI on WaSI.StockItemID = SaIL.StockItemID
group by
	year(SaIn.InvoiceDate),
	month(SaIn.InvoiceDate),
	WaSI.StockItemName
having sum(SaIL.Quantity) < 50

select *
from Sales.Invoices

select* 
from Sales.InvoiceLines

select*
from Warehouse.StockItems
-- ---------------------------------------------------------------------------
-- Опционально
-- ---------------------------------------------------------------------------
/*
Написать запросы 2-3 так, чтобы если в каком-то месяце не было продаж,
то этот месяц также отображался бы в результатах, но там были нули.
*/
