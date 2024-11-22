/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "03 - Подзапросы, CTE, временные таблицы".

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
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/

select*
from Application.People

select*
from Sales.Invoices

--1) через вложенный запрос

select DISTINCT ApPe. PersonID, FullName 
from Application.People as ApPe
where  ApPe.IsSalesperson = 1 and not exists 
		(select *
		from Sales.Invoices as SaIn
		where SaIn.SalespersonPersonID = ApPe.PersonID 
		and SaIn.InvoiceDate = '2015-07-04')

--  2) через WITH (для производных таблиц)

; with InvoicesCTE AS (
		select SalespersonPersonID
		from Sales.Invoices as SaIn
		where SaIn.InvoiceDate = '2015-07-04')
	select PersonID, FullName
	from Application.People as ApPe
	where ApPe.IsSalesperson = 1 and 
		(ApPe.PersonID not in (
							   select SalespersonPersonID 
							   from InvoicesCTE)
							  )
									

/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/
select*
from Warehouse.StockItems

--  1) через вложенный запрос

declare @MinPrice decimal(18,2) = (select min(UnitPrice) from Warehouse.StockItems)
select StockItemID, StockItemName, UnitPrice
from Warehouse.StockItems
where UnitPrice = @MinPrice

--  2) через WITH (для производных таблиц)

; with mp (MinPrice) AS (
						select min(UnitPrice)
						from Warehouse.StockItems
						)
	select StockItemID, StockItemName, UnitPrice
	from Warehouse.StockItems
	where UnitPrice IN (
						select MinPrice
						from mp
					   )
						


/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/
select*
from Sales.CustomerTransactions

--  1) через вложенный запрос

select*
from Sales.Customers as SaCo
where SaCo.CustomerID IN (select top (5) CustomerID
						  from Sales.CustomerTransactions
						  order by TransactionAmount desc)

--  2) через WITH (для производных таблиц)

;with ma (CustomerID) as (
						  select top (5) CustomerID
						  from Sales.CustomerTransactions
						  order by TransactionAmount desc
						  )
select SaCu.*
from Sales.Customers as SaCu
where CustomerID in (
					select CustomerID
					from ma
					)


/*
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID).
*/
select*
from Application.DeliveryMethods

SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE COLUMN_NAME = 'CityID'

--  1) через вложенный запрос

select
	SaOr.DeliveryCityID,
	ApCi.CityName,
	ISNULL(ApPe.FullName, 'Unknown') as PickerName
from
	(select distinct SaCu.DeliveryCityID, SaOr.PickedByPersonID
		from Sales.Orders as SaOr
		join Sales.Customers as SaCu on SaCu.CustomerID = SaOr.CustomerID
		where SaOr.OrderId in (
							  select OrderId 
							  from (
									select distinct OrderID
									from Sales.OrderLines
									where StockItemID in (
														 select StockItemID 
														 from (
															  select top (3) with ties StockItemID
															  from Warehouse.StockItems
															  order by UnitPrice desc
															  ) as Items
														 )
									) as OrderIds
							  )
	) as SaOr	
	inner join Application.Cities as ApCi
		on ApCi.CityId = SaOr.DeliveryCityID
	left join Application.People as ApPe 
		on ApPe.PersonID = SaOr.PickedByPersonID
;


--  2) через WITH (для производных таблиц)

WITH Items (StockItemID) as (
	select top (3) with ties StockItemID
	from Warehouse.StockItems
	order by UnitPrice desc
), 
	OrderIds (OrderId) as (
	select distinct OrderID
	from Sales.OrderLines
	where StockItemID in (select StockItemID from Items)
), 
	SaOr (CityID, PickerId) as (
	select distinct SaCu.DeliveryCityID, SaOr.PickedByPersonID
	from 
		Sales.Orders as SaOr
		join Sales.Customers as SaCu
			on SaCu.CustomerID = SaOr.CustomerID
	where SaOr.OrderId IN (select OrderId from OrderIds)
)

SELECT 
	SaOr.CityID,
	ApCi.CityName,
	ISNULL(p.FullName, 'Unknown') as PickerName
FROM 
	SaOr
	INNER JOIN Application.Cities as ApCi
		on ApCi.CityId = SaOr.CityID
	LEFT JOIN Application.People p 
		on p.PersonID = SaOr.PickerId
;
-- ---------------------------------------------------------------------------
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса, 
-- так и в сторону упрощения плана\ускорения. 
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. 
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). 
-- Напишите ваши рассуждения по поводу оптимизации. 

-- 5. Объясните, что делает и оптимизируйте запрос

SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	(SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice, 
	(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
			FROM Sales.Orders
			WHERE Orders.PickingCompletedWhen IS NOT NULL	
				AND Orders.OrderId = Invoices.OrderId)	
	) AS TotalSummForPickedItems
FROM Sales.Invoices 
	JOIN
	(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC

-- --

TODO: напишите здесь свое решение
