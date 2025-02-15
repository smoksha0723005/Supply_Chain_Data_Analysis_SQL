-- ---------------------------DATA ANALYSIS-------------------------------------------------
-- Q1. WHO ARE THE MOST RELIABLE SUPPLIERS BASED ON ORDER FULFILMENT
select s.Name as supplier_name, count(o.OrderID) as completed_order
from orders o
join suppliers s 
on o.SupplierID = s.SupplierID
where o.Status like '%completed%'
group by s.Name
order by completed_order desc;

/* This result shows that all suppliers have completed one order each, indicating that there is even
distribution of orders with no dominant supplier, which may suggest equal supplier allocation or 
low repeat orders  */

-- Q2. WHICH ORDER STATUS IS THE MOST COMMON
select Status, count(OrderID) as status_count
from orders
group by Status
order by status_count desc;

/* The data showed that Cancelled orders are highest indicating potential issues in
order fulfillment or supplier reliability */

-- Q3. WHICH CATEGORY ARE IN THE HIGHEST DEMAND
select p.Category as category_name, count(OrderID) as total_sales
from orders o
join products p
on o.ProductID = p.ProductID
where o.Status like '%Completed%'
group by category_name
order by total_sales desc;

/* From this analysis we can see that the best selling category is Automative 
indicating higher sales */

-- Q4. WHICH CATEGORY IS RUNNING LOW IN STOCKS
select p.Name as product_name, 
	p.Category as category_name,
	i.Quantity as stock_left,
case
	when i.Quantity < 200 then 'Critical'
    when i.Quantity between 200 and 300 then 'Low'
    when i.Quantity between 300 and 400 then 'Moderate'
    else 'Sufficient'
end as stock_status
from inventory i
join products p
on i.ProductID = p.ProductID
order by i.Quantity asc;

-- Q5. HOW LONG DOES IT TAKE FOR ORDERS TO BE COMPLETED
select o.OrderID,
	   o.OrderDate,
       s.ShipmentDate,
       datediff(s.ShipmentDate, o.OrderDate) as processing_days
from orders o
join shipments s 
on o.OrderID = s.OrderID
where o.Status like '%Completed%'
order by processing_days desc;

/* All completed orders take exactly 10 days for fulfillment, indicating a 
consistent processing timeline. This suggests either a fixed shipping policy or an 
optimized but rigid fulfillment process with no flexibility based on demand. */

-- Q6. WHICH SHIPMENTS WERE DELAYED BEYOND THEIR ESTIMATED ARRIVAL DATE
select 
	s.ShipmentID,
    s.OrderID,
    s.ShipmentDate,
    s.EstimatedArrival,
    datediff(s.EstimatedArrival, s.ShipmentDate) as expected_delivery_days,
    case
		when s.EstimatedArrival < curdate() 
			and s.Status != 'Delivered'
		then 'Delayed'
		else 'On Time'
	end as shipment_status
    from shipments s
    join orders o on s.OrderID = o.OrderID
    order by shipment_status desc,
			expected_delivery_days asc;

-- Q7. WHICH PRODUCT CATEGORIES GENERATE THE MOST REVENUE
with revenue_data as (
	select
		p.Category as product_category,
        s.Name as supplier_name,
        o.OrderID,
        o.Quantity * p.Price as order_revenue
	from orders o
    join products p on o.ProductID = p.ProductID
    join suppliers s on o.SupplierID = s.SupplierID
    where o.Status like '%Completed%'
    )
    
select
	product_category,
    supplier_name,
    round(sum(order_revenue), 2) as total_revenue,
    rank() over (partition by product_category order by sum(order_revenue) desc) 
    as revenue_rank
from revenue_data
group by product_category, supplier_name
order by product_category, revenue_rank;

-- Q8. WHAT PERCENTAGE OF EACH SUPPLIERS ORDERS WERE CANCELED
with cancellation_data as (
	select
		s.Name as supplier_name,
        count(o.OrderID) as total_orders,
        sum(
			case
				when o.Status like '%Cancelled%' then 1
                else 0
                end) as cancelled_orders
	from orders o
    join suppliers s on o.SupplierID = s.SupplierID
    group by s.Name
	)
    
select
	supplier_name,
    total_orders,
    cancelled_orders,
    round((cancelled_orders / total_orders) * 100 , 2) as cancellation_rate,
    rank() over (order by cancelled_orders desc) as cancellation_rank
from cancellation_data
order by cancellation_rank;

-- Q9. WHICH PRODUCTS HAVE THE HIGHEST INVENTORY TURNOVER
select 
	p.Name as product_name,
    p.Category as product_category,
    i.Quantity as current_stock,
    sum(o.Quantity) as quantity_sold,
    round(sum(o.Quantity) / nullif(i.Quantity, 0), 2) as inventory_turnover_ratio,
    round(avg(datediff(s.ShipmentDate, o.OrderDate)), 2) as avg_days_to_ship
from inventory i 
join products p on i.ProductID = p.ProductID
join orders o on p.ProductID = o.ProductID
join shipments s on o.OrderID = s.OrderID
where o.Status like '%Completed%'
group by p.Name, p.Category, i.Quantity
order by inventory_turnover_ratio desc;

/* Products like Product 109 (Hardware) and Product 131 (Electronics) 
have high turnover and fast shipping, meaning they sell quickly 
and need frequent restocking. In contrast, slow-moving products 
like Product 306 (Automotive) and Product 326 (Electronics) 
take longer to sell and ship, 
indicating possible overstocking or supply chain delays.*/

-- ---------------------------------------END OF REPORT----------------------------------------





