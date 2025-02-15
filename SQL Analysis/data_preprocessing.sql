create database supply_chain_db;

-- --------------------------SUPPLY CHAIN SQL ANALYSIS-----------------------------------
select *
from inventory;

select *
from orders;

select *
from products;

select *
from shipments;

select *
from suppliers;

-- --------------------------------------DATA CLEANING--------------------------------------
-- CHECKING NULL VALUES IN EACH TABLE

select 'suppliers' as table_name,
	count(*) as null_count
from suppliers
where Name = ""
	or Location = ""
    or Contact = ""
union all
select 'products',
	count(*) 
from products
where Name = ""
	or Category = "" 
    or Price = ""
union all
select 'inventory',
	count(*) 
from inventory
where Quantity = ""
	or WarehouseLocation = ""
union all
select 'orders',
	count(*) 
from orders
where OrderDate = ""
	or Quantity = ""
    or Status = ""
union all
select 'shipments',
	count(*) 
from shipments
where ShipmentDate = ""
	or EstimatedArrival = "" 
    or Status = "";

-- CONVERTING EMPTY STRINGS TO NULL
update suppliers
set Name = null
where Name = '';

update orders
set OrderDate = null
where OrderDate = '';

update orders
set Quantity = null
where Quantity = '';

update orders 
set Status = null
where Status = '';

update shipments 
set ShipmentDate = null 
where ShipmentDate = '';

update shipments 
set EstimatedArrival = null where EstimatedArrival = '';

update shipments 
set Status = null where Status = '';

-- HANDLING NULL VALUES
update suppliers 
set Name = 'Unknown Supplier' 
where Name is null;

SET @max_order_date = (SELECT MAX(OrderDate) FROM orders);

UPDATE orders 
SET OrderDate = @max_order_date 
WHERE OrderDate IS null;

SET @avg_quantity = (SELECT ROUND(AVG(Quantity)) FROM orders WHERE Quantity IS NOT null);

UPDATE orders 
SET Quantity = @avg_quantity 
WHERE Quantity IS null;

UPDATE orders 
SET Status = 'Pending' 
WHERE Status IS null;

UPDATE shipments 
SET ShipmentDate = (SELECT DATE_ADD(OrderDate, INTERVAL 2 DAY) FROM orders WHERE orders.OrderID = shipments.OrderID) 
WHERE ShipmentDate IS null;

UPDATE shipments 
SET EstimatedArrival = (SELECT DATE_ADD(ShipmentDate, INTERVAL 5 DAY)) 
WHERE EstimatedArrival IS null;

UPDATE shipments 
SET Status = 'In Transit' 
WHERE Status IS null;

-- CHECKING FOR DUPLICATE VALUES
select Name, Location, count(*) as dc
from suppliers
group by Name, Location
having count(*) > 1;

SELECT ProductID, Name, COUNT(*) AS dc
FROM products
GROUP BY ProductID, Name
HAVING COUNT(*) > 1;

SELECT ProductID, WarehouseLocation, COUNT(*) AS dc
FROM inventory
GROUP BY ProductID, WarehouseLocation
HAVING COUNT(*) > 1;

SELECT OrderID, ProductID, SupplierID, OrderDate, COUNT(*) AS DuplicateCount
FROM orders
GROUP BY OrderID, ProductID, SupplierID, OrderDate
HAVING COUNT(*) > 1;

SELECT OrderID, ShipmentDate, COUNT(*) AS DuplicateCount
FROM shipments
GROUP BY OrderID, ShipmentDate
HAVING COUNT(*) > 1;

-- REMOVING DUPLICATE VALUES
CREATE TEMPORARY TABLE temp_suppliers AS 
select min(SupplierID)
from suppliers
group by Name, Location;

DELETE FROM suppliers 
WHERE SupplierID NOT IN (SELECT SupplierID FROM temp_suppliers);

DROP TEMPORARY TABLE IF EXISTS temp_suppliers;

-- DROPPPING DUPLICATE VALUES FROM INVENTORY TABLE
CREATE temporary table temp_inventory as
SELECT MIN(InventoryID) 
FROM inventory 
GROUP BY ProductID, WarehouseLocation;

DELETE FROM inventory
WHERE InventoryID NOT IN (SELECT InventoryID FROM temp_inventory);

DROP TEMPORARY TABLE IF EXISTS temp_inventory;

-- DROPPING DUPLICATE VALUES FROM SHIPMENT TABLE
CREATE temporary table temp_shipment as
SELECT MIN(ShipmentID) 
FROM shipments
GROUP BY OrderID, ShipmentDate;

DELETE FROM shipments
WHERE ShipmentID NOT IN (SELECT ShipmentID FROM temp_shipment);

DROP TEMPORARY TABLE IF EXISTS temp_shipment;



-- FIXING DUBPLICATE IDs BY ASSIGNING UNIQUE VALUES
SET @new_id = (SELECT MAX(SupplierID) FROM suppliers) + 1;
UPDATE suppliers 
SET SupplierID = @new_id 
WHERE SupplierID IN (
    SELECT SupplierID FROM ( 
        SELECT SupplierID FROM suppliers 
        GROUP BY SupplierID 
        HAVING COUNT(*) > 1 
    ) temp
)
LIMIT 1;

SET @new_id = (SELECT MAX(ProductID) FROM products) + 1;
UPDATE products 
SET ProductID = @new_id 
WHERE ProductID IN (
    SELECT ProductID FROM ( 
        SELECT ProductID FROM products 
        GROUP BY ProductID 
        HAVING COUNT(*) > 1 
    ) temp
)
LIMIT 1;

SET @new_id = (SELECT MAX(InventoryID) FROM inventory) + 1;
UPDATE inventory 
SET InventoryID = @new_id 
WHERE InventoryID IN (
    SELECT InventoryID FROM ( 
        SELECT InventoryID FROM inventory 
        GROUP BY InventoryID 
        HAVING COUNT(*) > 1 
    ) temp
)
LIMIT 1;

SET @new_id = (SELECT MAX(OrderID) FROM orders) + 1;
UPDATE orders 
SET OrderID = @new_id 
WHERE OrderID IN (
    SELECT OrderID FROM ( 
        SELECT OrderID FROM orders 
        GROUP BY OrderID 
        HAVING COUNT(*) > 1 
    ) temp
)
LIMIT 1;

SET @new_id = (SELECT MAX(ShipmentID) FROM shipments) + 1;
UPDATE shipments 
SET ShipmentID = @new_id 
WHERE ShipmentID IN (
    SELECT ShipmentID FROM ( 
        SELECT ShipmentID FROM shipments 
        GROUP BY ShipmentID 
        HAVING COUNT(*) > 1 
    ) temp
)
LIMIT 1;

-- REPLACING NULL VALUES WITH UNIQUE IDs
SET @new_id = (SELECT MAX(SupplierID) FROM suppliers) + 1;

UPDATE suppliers 
SET SupplierID = @new_id 
WHERE SupplierID IS null;

-- ADDING PRIMARY KEYS TO THE ALL TABLE
ALTER TABLE suppliers ADD PRIMARY KEY (SupplierID);
ALTER TABLE products ADD PRIMARY KEY (ProductID);
ALTER TABLE inventory ADD PRIMARY KEY (InventoryID);
ALTER TABLE orders ADD PRIMARY KEY (OrderID);
ALTER TABLE shipments ADD PRIMARY KEY (ShipmentID);

-- ----------------------------------------------------DATA STANDARIZATION -------------------------------------------------------------------------------------------------
select distinct location
from suppliers;

-- FIXING LOCATION DATA
update suppliers
set location = replace(location,'-',','); 

-- STANDARIZING PRODUCT CATEGORIES
select distinct Category
from products;

update products
set Category = "Manufacturing"
where Category in ('Mfg.','Manufacturing');

















































    