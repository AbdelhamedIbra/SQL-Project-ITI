
--Inserte 

create or alter proc insert_employee 
    @EmpId int, 
    @EmpName varchar(150), 
    @title varchar(150), 
    @city varchar(150),
    @country varchar(150),
    @superId int
as
begin
--check if the Employee exists 
    if not exists  (select * from employees where EmployeeId = @EmpId)
    begin
        insert into employees
        ( 
            employeeId, 
            EmployeeName, 
            title, 
            city,
            country,
            superId
        )
        values
        (
            @EmpId,
            @EmpName,
            @title,
            @city,
            @country,
            @superId
        )

        print 'User inserted successfully.';
    end 
    else
    begin
        print 'User with EmpId ' +@EmpId + ' already exists.';
    end
end


insert_employee  
    @EmpId = 11,
    @EmpName = 'Mohammed Khalaf',
    @title = 'Data Analyst',
    @city = 'Samalout',
    @country = 'Egypt',
    @superId = 9


	--Update

create or alter proc Update_data
    @EmpId int,
    @EmpName varchar(150),
    @title varchar(150),
    @city varchar(150),
    @country varchar(150),
    @superID int
as
begin
    if exists (select * from employees$ e where e.employeeID = @EmpId)
    begin
	--update refrences
	    update employees$
        set superId = @superID
        where superId = @EmpId

        update employees
        set
            employeeID = @EmpId,
            employeeName = @EmpName,
            title = @title,
            city = @city,
            country = @country,
            superId = @superID
        where
            employeeID = @EmpId;
    end
    else
    begin
        print 'User with EmpId ' + @EmpId  + ' does not exist.'
    end
end



EXEC Update_data
    @EmpId = 1,
    @EmpName = 'Mohammed Khalaf',
    @title = 'Data analyst',
    @city = 'Samalout',
    @country = 'Egypt',
    @superId = 8
		



--CUSTOMER DISTRIBUTION
--count customers per CITY OR COUNTRY

create or alter proc customer_count
	@type varchar(50)
as
		if @type ='city'
		select city,count(*) as 'Customer_count'
		from customers
		group by city
		order by count(*)  desc
		
	else if @type= 'country'
		select country,count(*) as 'Customer_count'
		from customers
		group by country
		order by count(*)  desc
	

customer_count @type='City'


--count customers per SPECIFIED CITY OR COUNTRY
create or alter proc customers_count_spec

	@type varchar(50),
	@city_country varchar(50)
	as
	begin
	if @type ='city'
		select city,count(*) as 'Customer_count'
		from [dbo].[customers]
		group by city
		having city=@city_country
	else if @type= 'country'
		select country,count(*) as 'Customer_count'
		from [dbo].[customers]
		group by country
		having country= @city_country

		end

customers_count_spec @type='country',@city_country='mexico'

---------------------------------------------------------------





-----------------------------------------------------------
--PRUDCTS

--Extract Month and Year from ORDER DATE
Alter table orders add order_Month  varchar(50)
Alter table orders add order_Year  varchar(50)

select * from order_details
select * from orders


update orders 
set order_Month = FORMAT (CONVERT(DATE, orderdate),'MM-yy')
update orders 
set order_Year = FORMAT (CONVERT(DATE, orderdate),'yyyy')

select Order_Month
from orders

--count total cost per Order
--Total cost (product price X Quantity )- discount = Gross Revenue
--

Alter table order_details add Total_Cost  money

update order_details 
set Total_cost=(unitprice-(unitprice*discount))*quantity

select * from orders

--------------------------------------------------------------
--Total cost---Gross Revenue
select  sum (Total_Cost) as Gross_revenue
from order_details

--------------------------------------------------------------
--total sales per month
create or alter proc Total_sales_month 
@month varchar(10)
as

	select sum(od.Total_cost) 
	from order_details od
	join orders o
	on o.orderID=od.orderid
	where order_month =@month
	

Total_sales_month @month='09-14'
-----------------------------------------------------

--selecting top n months in sales

create or alter proc top_month @n int
as

	select top (@n) order_month ,sum(od.Total_cost) as sales
	from order_details od
	join orders o 
	on o.orderID=od.orderID
	group by order_month 
	order by sum(od.Total_cost) 

top_month @n =3

----------------------------------

--Trendy products

create or alter proc trendy_product 
@n int, 
@analysis varchar(20)
as
	if @analysis ='Less'
		select *
		from (
		select 
		rank() over (order by sum(od.Total_cost) asc) AS Salesrank,
		p.ProductID,
        p.ProductName,
        sum(od.Total_cost) AS Totalsales 
   
		from products p
		join order_details od
		on od.productID=p.productID
		group by p.ProductID,p.ProductName
		) as rank_view

		where rank_view.Salesrank <=@n

	else if @analysis ='Most'
		select * from
		(select p.ProductID,
            p.ProductName,
            sum(od.Total_cost) as TotalSales,
            rank() over (order by sum(od.Total_cost) desc) as Salesrank
			from products p
			join order_details od
			on od.productID=p.productID
			group by p.ProductID,p.ProductName
			 ) as rank_view
			where rank_view.Salesrank <= @n

trendy_product @n=4 ,@analysis='Most'


--Top trendy products--count

declare @n int=4
select top(@n) p.ProductID,
            p.ProductName,
            sum(od.quantity ) as Total_quantity
			from products p
			join order_details od
			on od.productID=p.productID
			group by p.ProductID,p.ProductName
			order by total_quantity desc
 
 











--Revenue per product
/*
select
	p.productName,
	od.unitPrice,
    p.unitPrice AS CurrentUnitPrice,
    sum(quantity) as total_quantity
    ,max(p.unitPrice - od.unitPrice)  as margin_unit
from
    order_details od
JOIN
    products p on od.productID = p.productID
group by p.productName,p.unitPrice,od.unitPrice
order by margin_unit desc
*/
-------------------------------------------------------
select avg(Total_Cost)
from order_details
----------
--total Dealing with customer over time
select c.companyname ,sum(o.Total_Cost) as Total_dealnig  
from order_details o join orders ord
on o.orderID=ord.orderID
join customers c
on ord.customerID=c.customerID
group by c.companyName
order by Total_dealnig desc

--------------------------------------------------------
--Trendy products per Month


--sales per montg
with monthsales AS (
    select
        od.productID,
		p.productName,
        o.Order_Month AS sale_month,
        sum(od.quantity) AS total_quantity
    from
        orders o
    join
        order_details od on o.orderid = od.orderid
	join products p on p.productID= od.productID
    group by
        od.productID, o.Order_Month,p.productName
),
RankedSales as (
    select
        productID,
		productname,
        sale_month,
        total_quantity,
        row_number() OVER (partition by sale_month order by total_quantity desc) as ranking
    from
        monthsales
)
select 
    r.productID,
    p.productName,
    r.sale_month,
    r.total_quantity
from
    RankedSales r
join
    products p ON p.productid = r.productID
where
    r.ranking = 1



	
---------------------------------------------------
---------------------------
--AVG shipping time per shipping country
select sh.companyName,avg( datediff(day,o.shippedDate,o.requiredDate)) as AVG_Ship_Time
,avg(o.freight) as AVG_ship_cost
from orders o
join shippers sh
on sh.shipperID=o.shipperID
group by sh.companyName

--	AVG SHipping time, cost per city
select c.city,avg( datediff(day,o.shippedDate,o.requiredDate)) as AVG_Ship_Time
,avg(o.freight) as AVG_ship_cost
from orders o
join customers c
on c.customerID=o.customerID
group by c.city
order by AVG_ship_cost

------------------------------------------------------------------

--List products in each category
--Category

select 
(case when c.categoryName='Beverages' then p.productName end)as Beverages,
(case when c.categoryName='Condiments' then p.productName end)as Condiments,
(case when c.categoryName='Confections' then p.productName end)as Confections,
(case when c.categoryName='Dairy Products' then p.productName end)as Dairy_Products,
(case when c.categoryName='Grains & Cereals' then p.productName end)as Grains_Cereals,
(case when c.categoryName='Meat & Poultry' then p.productName end)as Meat_Poultry,
(case when c.categoryName='Seafood' then p.productName end)as  Seafood

from products p
join categories c
on p.categoryID=c.categoryID
--where c.categoryName is not null
order by c.categoryName 



------------------------------------------------------------
--trading with companies over 3 years ÍÌã ÇáÊÚÇãá ãÚ ßá ÔÑßÉ Úáì ãÏÇÑ Çá 3 ÓäæÇÊ


select  *
from (
    select  c.companyName ,sum(od.Total_Cost)as totalCost,o.Order_year
    from orders o
    join customers c on c.customerID = o.customerID
	join order_details od
	on od.orderID=o.orderID
	group by c.companyName,o.Order_year
	--order by totalCost desc
) as Sourcetable


pivot (
    sum (totalCost) for Order_year IN ([2013], [2014], [2015])
) as Pivottable
order by [2015]desc,[2014]desc,[2013]desc



---------------------------------------------------








