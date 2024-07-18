-- Question Set 1


--/////////////////////////////////////////////////


/* Q1: Retrieve the total number of orders placed. */

SELECT COUNT(DISTINCT order_id) AS total_orders
FROM orders;


/* Q2: Calculate the total revenue generated from pizza sales. */

SELECT SUM(total_amount) AS total_revenue
FROM orders;


/* Q3: Identify the highest-priced pizza. */

SELECT pizza_id, price
FROM pizzas
WHERE price = (SELECT MAX(price) FROM pizzas);


/* Q4: Identify the most common pizza size ordered. */

SELECT size, COUNT(*) AS order_count
FROM pizzas
GROUP BY size
ORDER BY order_count DESC
LIMIT 1;


/* Q5: List the top 5 most ordered pizza types along with their quantities. */

SELECT pizza_type, COUNT(*) AS order_count
FROM pizzas
GROUP BY pizza_type
ORDER BY order_count DESC
LIMIT 5;


-- Question Set 2


--/////////////////////////////////////////////////


/* Q1: Join the necessary tables to find the total quantity of each pizza category
ordered. */ 

SELECT p.pizza_type, SUM(po.quantity) AS total_quantity
FROM pizzas p
INNER JOIN pizza_orders po ON p.pizza_id = po.pizza_id
INNER JOIN orders o ON po.order_id = o.order_id
GROUP BY p.pizza_type
ORDER BY total_quantity DESC;


/* Q2: Determine the distribution of orders by hour of the day. */


SELECT
    SUBSTRING(time FROM 1 FOR 2) AS order_hour,
    COUNT(*) AS order_count
FROM
    orders
GROUP BY
    order_hour
ORDER BY
    order_hour;
    
    

/*Q3: Join relevant tables to find the category-wise distribution of pizzas. */

 
SELECT
    c.category,
    COUNT(distinct po.order_id) AS order_count, -- in any case order_id is unique
    SUM(po.quantity) AS total_quantity
FROM
    pizza_types c
JOIN
    pizzas p ON c.pizza_type_id = p.pizza_type_id
INNER JOIN
    order_details po ON p.pizza_id = po.pizza_id
inner join 
	orders o on po.order_id = o.order_id
GROUP BY
    c.category
ORDER BY
    c.category, total_quantity DESC;
 




/* Q4 Group the orders by date and calculate the average number of pizzas
ordered per day. */

SELECT
    order_date,
    round(AVG(quantity)) AS avg_pizzas_per_day
FROM (
    SELECT
        DATE(date) AS order_date,
        SUM(quantity) AS quantity
    FROM
        orders
        JOIN order_details ON orders.order_id = order_details.order_id
    GROUP BY
        DATE(date)
) AS daily_pizza_orders
GROUP BY
    order_date
ORDER BY
    order_date;


                
/* Q5: Determine the top 3 most ordered pizza types based on revenue. */


SELECT
    p.pizza_type_id,
    COUNT(po.order_id) AS total_orders,
    SUM(po.quantity * p.price) AS total_revenue
FROM
    pizzas p
JOIN
    order_details po ON p.pizza_id = po.pizza_id
GROUP BY
    p.pizza_type_id
ORDER BY
    total_revenue DESC
LIMIT 3;


-- Question Set 3


--/////////////////////////////////////////////////


/* Q1: Calculate the percentage contribution of each pizza type to total revenue. */


SELECT
	DISTINCT
    p.pizza_type_id,
    round(SUM(po.quantity * p.price) OVER (partition by p.pizza_type_id) * 100 / SUM(po.quantity * p.price) over ()) AS pizza_percentage
FROM
    pizzas p
JOIN
    order_details po ON p.pizza_id = po.pizza_id
ORDER BY
    pizza_percentage DESC;
                       
 
 
 /* Q2: Analyze the cumulative revenue generated over time. */
 
 
 SELECT
    o.date,
    SUM(od.quantity * pizzas.price) AS daily_revenue,
    SUM(SUM(od.quantity * pizzas.price)) OVER (ORDER BY o.date) AS cumulative_revenue
FROM
	pizzas
inner join 
    order_details od on pizzas.pizza_id = od.pizza_id
JOIN
    orders o ON od.order_id = o.order_id
GROUP BY
    o.date
ORDER BY
    o.date;
 
 
 
 
 /* Q3: Calculate the 3-month moving average of monthly revenue. */
 
 
 WITH MonthlyRevenue AS (
    SELECT
        LEFT(o.date, 7) AS month,
        SUM(od.quantity * pizzas.price) AS monthly_revenue
    FROM
        orders o
    INNER JOIN
        order_details od ON o.order_id = od.order_id
  	INNER JOIN
  		pizzas ON OD.pizza_id = pizzas.pizza_id
    GROUP BY
        LEFT(o.date, 7)
    ORDER BY
       LEFT(o.date, 7)
)

SELECT
    month,
    monthly_revenue,
    AVG(monthly_revenue) OVER (
        ORDER BY month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS three_month_moving_avg
FROM
    MonthlyRevenue;
 
 

/* Q4: Rank customers based on the total amount they have spent. */

-- No customer table ????????????????????????



/* Q5: Calculate the percentile rank of each pizza type based on the total quantity
sold. */



SELECT
    p.pizza_type_id,
    SUM(od.quantity) AS total_quantity_sold,
    PERCENT_RANK() OVER (ORDER BY SUM(od.quantity)) AS percentile_rank
FROM
    orders o
JOIN
    order_details od ON o.order_id = od.order_id
JOIN
    pizzas p ON od.pizza_id = p.pizza_id
GROUP BY
    p.pizza_type_id
ORDER BY
    percentile_rank;




/* Q6: Determine the top 3 most ordered pizza types based on revenue for each
pizza category. */


WITH PizzaRevenue AS (
    SELECT
        p.pizza_type_id,
  		SUM(od.quantity * p.price) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY p.pizza_type_id ORDER BY SUM(od.quantity * P.price) DESC) AS rn
    FROM
        orders o
    JOIN
        order_details od ON o.order_id = od.order_id
    JOIN
        pizzas p ON od.pizza_id = p.pizza_id
    GROUP BY
        p.pizza_type_id
  ORDER BY
    total_revenue DESC
)

SELECT
    pizza_type_id,
    total_revenue
FROM
    PizzaRevenue
LIMIT 3




/* Q7: Compare each month's revenue to the previous month's revenue. */


WITH MonthlyRevenue AS (
    SELECT
         LEFT(o.date, 7) AS month,
        SUM(od.quantity * pizzas.price) AS monthly_revenue
    FROM
        orders o
    JOIN
        order_details od ON o.order_id = od.order_id
  	inner JOIN 
  		pizzas on od.pizza_id = pizzas.pizza_id
    GROUP BY
         LEFT(o.date, 7)
    ORDER BY
         LEFT(o.date, 7)
)

SELECT
    month,
    monthly_revenue,
    LAG(monthly_revenue) OVER (ORDER BY month) AS previous_month_revenue,
    monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY month) AS revenue_difference
FROM
    MonthlyRevenue;





-- Question Set 4


--/////////////////////////////////////////////////


/* Q1: Determine the average, minimum, and maximum order value per customer,
and identify the top 5 customers with the highest average order value. */

-- No customer table ?????????????




/* Q2: Calculate the total revenue and the average revenue per pizza type over
each month. */



WITH MonthlyPizzaRevenue AS (
    SELECT
        DATE_TRUNC('month', o.date::date) AS month,
        p.pizza_type_id,
        SUM(od.quantity * p.price) AS total_revenue,
        AVG(od.quantity * p.price) AS average_revenue
    FROM
        orders o
    JOIN
        order_details od ON o.order_id = od.order_id
    JOIN
        pizzas p ON od.pizza_id = p.pizza_id
    GROUP BY
        DATE_TRUNC('month', o.date::date), p.pizza_type_id
    ORDER BY
        DATE_TRUNC('month', o.date::date), p.pizza_type_id
)

SELECT
    month,
    pizza_type_id,
    total_revenue,
    average_revenue
FROM
    MonthlyPizzaRevenue
ORDER BY
    month,
    pizza_type_id;




/* Q3: Identify the top 3 pizza types in terms of quantity ordered within each city
and the respective revenue generated by these pizza types. */

-- No CITY DATA?????





/* Q4: Determine the monthly cumulative revenue and the moving average of the
monthly revenue over a 3-month window. */

WITH MonthlyRevenue AS (
    SELECT
        DATE_TRUNC('month', o.date::date) AS month,
        SUM(od.quantity * p.price) AS monthly_revenue
    FROM
        orders o
    JOIN
        order_details od ON o.order_id = od.order_id
    JOIN
        pizzas p ON od.pizza_id = p.pizza_id
    GROUP BY
        DATE_TRUNC('month', o.date::date)
    ORDER BY
        DATE_TRUNC('month', o.date::date)
)

SELECT
    month,
    monthly_revenue,
    SUM(monthly_revenue) OVER (ORDER BY month) AS cumulative_revenue,
    AVG(monthly_revenue) OVER (
        ORDER BY month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS moving_average_revenue
FROM
    MonthlyRevenue
ORDER BY
    month;




/* Q5: Identify potential data quality issues by finding orders where the total price
is significantly different from the sum of the line item prices (e.g.,
differences greater than 5%). */

-- what does total_price mean? where does it come?

/* Q6: Optimize the performance of a query that retrieves the total number of pizzas sold per customer 
by using appropriate indexing and query restructuring. */ 

-- where does customer data come?

