/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, JOIN".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД WideWorldImporters можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

select 
	StockItemID, 
	StockItemName
from 
	Warehouse.StockItems
where 
	StockItemName like '%urgent%' 
	or StockItemName like 'Animal%'


/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

select 
	pSupp.SupplierID, 
	pSupp.SupplierName
from 
	Purchasing.Suppliers as pSupp
left join Purchasing.PurchaseOrders as pOrders on pSupp.SupplierID = pOrders.SupplierID
where 
	pOrders.PurchaseOrderID is null


select *
from Purchasing.PurchaseOrders

select *
from Purchasing.Suppliers


/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/

select 
	sOr.Quantity, 
	sOr.UnitPrice,*
from 
	Sales.Orders as sO
	left join Sales.OrderLines as sOr on sO.OrderID = sOr.OrderID
where 
	(sOr.UnitPrice > 100 or sOr.Quantity > 20)  
	and  sOr.PickingCompletedWhen is not null



select distinct
     so.OrderID,
	 convert(varchar, so.OrderDate, 104) as 'Дата заказа' 
    ,case
      when month(so.OrderDate) = 1 then N'Январь'
      when month(so.OrderDate) = 2 then N'Февраль'
      when month(so.OrderDate) = 3 then N'Март'
      when month(so.OrderDate) = 4 then N'Апрель'
      when month(so.OrderDate) = 5 then N'Май'
      when month(so.OrderDate) = 6 then N'Июнь'
      when month(so.OrderDate) = 7 then N'Июль'
      when month(so.OrderDate) = 8 then N'Август'
      when month(so.OrderDate) = 9 then N'Сентябрь'
      when month(so.OrderDate) = 10 then N'Октябрь'
      when month(so.OrderDate) = 11 then N'Ноябрь'
      when month(so.OrderDate) = 12 then N'Декабрь'
      end as 'Месяц'
    ,case
      when month(so.OrderDate) in (1, 2, 3) then 1
      when month(so.OrderDate) in (4, 5, 6) then 2
      when month(so.OrderDate) in (7, 8, 9) then 3
      when month(so.OrderDate) in (10, 11, 12)  then 4
      end as 'Квартал'
    ,case
      when month(so.OrderDate) in (1, 2, 3, 4) then 1
      when month(so.OrderDate) in (5, 6, 7, 8) then 2
      when month(so.OrderDate) in (9, 10, 11, 12)  then 3
      end as 'Треть года'
	,sC.CustomerName  as 'Имя заказчика'
from 
    Sales.Orders so
    inner join Sales.OrderLines as sOL on so.OrderID = sOL.OrderID
    inner join Sales.Customers as sC on sO.CustomerID = sC.CustomerID
where
    (sOL.UnitPrice > 100 or sOL.Quantity > 20)  
	and  sOL.PickingCompletedWhen is not null
order by
     [Квартал],
     [Треть года],
     [Дата заказа]
	offset 1000 rows fetch next 100 rows only
	go



select*
from Sales.Orders

select*
from Sales.OrderLines

select*
from Sales.Customers

/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/
select*
from 
	Purchasing.PurchaseOrders as PuPO
	inner join Application.DeliveryMethods as ApDM on PuPO.DeliveryMethodID = ApDM.DeliveryMethodID
	left join Purchasing.Suppliers as PuSup on PuPO.SupplierID = PuSup.SupplierID
where 
	PuPO.ExpectedDeliveryDate BETWEEN '20130101' and '20130131'
	and PuPO.IsOrderFinalized = 1
	and ApDM.DeliveryMethodName in ('Air Freight', 'Refrigerated Air Freight')
	order by
	PuPO.ExpectedDeliveryDate



 select 
	 ApDM.DeliveryMethodName,
	 PuPO.OrderDate,
	 PuPO.ExpectedDeliveryDate, 
	 PuSup.SupplierName,  
	 ApPe.FullName, 
	 ApPe.PersonID --ContactPerson не нашёл, методом поиска так же не принесло никаких результатов!
from 
	Purchasing.PurchaseOrders as PuPO
	inner join Application.DeliveryMethods as ApDM on PuPO.DeliveryMethodID = ApDM.DeliveryMethodID
	left join Purchasing.Suppliers as PuSup on PuPO.SupplierID = PuSup.SupplierID
	left join Application.People as ApPe on PuPO.ContactPersonID =ApPe.PersonID

 SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE COLUMN_NAME = 'ContactPersonID'  --имя контактного лица принимавшего заказ (ContactPerson) нет такого атрибута

select*
from Purchasing.Suppliers

select*
from Purchasing.PurchaseOrders

select*
from Application.People

select*
from Application.DeliveryMethods

/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/
 SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE COLUMN_NAME = 'SalespersonPerson'

 select top 10 SaCu.CustomerName,*
  from Sales.Orders as SaOr
   inner join Sales.Customers as SaCu on SaOr.CustomerID = SaCu.CustomerID
   order by SaOr.OrderDate desc
   --не смог найти имя сотрудника который оформил заказ

  select*
 from Sales.Orders

   select*
 from Sales.Customers

    select*
 from Application.People

     select*
 from Application.People_Archive 
/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/
	declare @SINa nvarchar(100) = 'Chocolate frogs 250g', @SIID int;
	set  @SIID = (select StockItemID 
							from Warehouse.StockItems 
							where StockItemName = @SINa)
select distinct 
	SaCu.CustomerID, 
	SaCu.CustomerName, 
	SaCu.PhoneNumber
from 
	Warehouse.StockItems as WaSI
	inner join Sales.OrderLines as SaOL on WaSI.StockItemID = SaOL.StockItemID
	inner join Sales.Orders as SaOr on SaOL.OrderID = SaOr.OrderID
	inner join Sales.Customers as SaCu on SaCu.CustomerID = SaOr.CustomerID
where  
	WaSI.StockItemID = @SIID



select*
from Warehouse.StockItems

select*
from Sales.Customers

  select*
 from Sales.Orders

select*
from Sales.OrderLines
