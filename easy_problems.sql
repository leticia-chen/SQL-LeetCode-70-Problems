-- 511.Game Play Analysis I

-- Table: Activity

-- +--------------+---------+
-- | Column Name  | Type    |
-- +--------------+---------+
-- | player_id    | int     |
-- | device_id    | int     |
-- | event_date   | date    |
-- | games_played | int     |
-- +--------------+---------+
-- (player_id, event_date) is the primary key of this table.
-- This table shows the activity of players of some game.
-- Each row is a record of a player who logged in and played a number of games (possibly 0) before logging out on some day using some device.
-- 該表記錄了遊戲用戶的行為信息，主鍵為(player_id, event_date)的組合。每一行記錄每個遊戲用戶登錄情況以及玩的遊戲數(玩的遊戲可能是0)。

-- Write an SQL query that reports the first login date for each player.
-- 查詢每個用戶首次登陸的日期
-- 編寫一個SQL查詢，每個玩家的首次登錄日期。

-- The query result format is in the following example:

-- Activity table:
-- +-----------+-----------+------------+--------------+
-- | player_id | device_id | event_date | games_played |
-- +-----------+-----------+------------+--------------+
-- | 1         | 2         | 2016-03-01 | 5            |
-- | 1         | 2         | 2016-05-02 | 6            |
-- | 2         | 3         | 2017-06-25 | 1            |
-- | 3         | 1         | 2016-03-02 | 0            |
-- | 3         | 4         | 2018-07-03 | 5            |
-- +-----------+-----------+------------+--------------+

-- Result table:
-- +-----------+-------------+
-- | player_id | first_login |
-- +-----------+-------------+
-- | 1         | 2016-03-01  |
-- | 2         | 2017-06-25  |
-- | 3         | 2016-03-02  |
-- +-----------+-------------+

-- Solution
select player_id, min(event_date) as first_login
from Activity
group by player_id
order by player_id;


-----------------------------------------------------------------------------

-- 512.Game Play Analysis II

-- Write a SQL query that reports the device that is first logged in for each player.
-- 編寫一個SQL查詢，每個玩家首次登錄的設備

-- The query result format is in the following example:

-- Activity table:
-- +-----------+-----------+------------+--------------+
-- | player_id | device_id | event_date | games_played |
-- +-----------+-----------+------------+--------------+
-- | 1         | 2         | 2016-03-01 | 5            |
-- | 1         | 2         | 2016-05-02 | 6            |
-- | 2         | 3         | 2017-06-25 | 1            |
-- | 3         | 1         | 2016-03-02 | 0            |
-- | 3         | 4         | 2018-07-03 | 5            |
-- +-----------+-----------+------------+--------------+

-- Result table:
-- +-----------+-----------+
-- | player_id | device_id |
-- +-----------+-----------+
-- | 1         | 2         |
-- | 2         | 3         |
-- | 3         | 1         |
-- +-----------+-----------+

-- Solution 1
select player_id, device_id
from Activity
where (player_id, event_date)
in (
	select player_id, min(event_date)
    from Activity
    group by player_id
	)
order by player_id;

-- 解題說明:
-- 先找出每個玩家最早登入日期
-- 運用 RANK PARTITION 劃分 PLAYER_ID 並依 EVENT_DATE 排名
-- 最後查詢每位玩家排名第一的EVENT_DATE

-- Solution 2
WITH PLAYER_MIN_DATE AS (
  -- 先找出每個玩家最早登入日期
  SELECT PLAYER_ID, MIN(EVENT_DATE) MIN_EVENT_DATE
  FROM ACTIVITY GROUP BY PLAYER_ID
)
-- 在與原來的 ACTIVITY 資料表 JOIN 查詢出 DEVICE_ID
SELECT A.PLAYER_ID, A.DEVICE_ID, A.EVENT_DATE 
FROM ACTIVITY A INNER JOIN PLAYER_MIN_DATE P
ON A.PLAYER_ID = P.PLAYER_ID
AND A.EVENT_DATE = P.MIN_EVENT_DATE;

-- Solution 3
-- 運用 RANK PARTITION 劃分 PLAYER_ID 並依 EVENT_DATE 排序
WITH TABLE1 AS (
   SELECT PLAYER_ID, DEVICE_ID,
   RANK() OVER (
      PARTITION BY PLAYER_ID ORDER BY EVENT_DATE ASC
   ) AS RK
   FROM ACTIVITY
)
SELECT PLAYER_ID, DEVICE_ID
FROM TABLE1
WHERE RK = 1;

-- Solution 4
with T1 as (
	select player_id, device_id,
    row_number() over (partition by player_id order by event_date) as rk
    from Activity
)
select player_id, device_id
from T1
where rk=1;

-- Wrong Solution
-- 這個解法是錯誤的,因為player_id: 3會出現兩次,原因在於group by 1,2時
-- 這兩筆被認作不同
select player_id, device_id
from Activity
group by 1,2
having min(event_date)
order by 1


---------------------------------------------------------------------------------

-- 586.Customer Placing the Largest Number of Orders
-- 客戶下達最大數量的訂單

-- Query the customer_number from the orders table for the customer who has placed the largest number of orders.
-- 從訂單表中查詢 customer_number，以獲取已下達最大訂單數的客戶。

-- It is guaranteed that exactly one customer will have placed more orders than any other customer.
-- 可以確保恰好有一位客戶下的訂單比其他任何一位客戶都多。

-- The orders table is defined as follows:

-- | Column            | Type      |
-- |-------------------|-----------|
-- | order_number (PK) | int       |
-- | customer_number   | int       |
-- | order_date        | date      |
-- | required_date     | date      |
-- | shipped_date      | date      |
-- | status            | char(15)  |
-- | comment           | char(200) |

-- Sample Input
-- | order_number | customer_number | order_date | required_date | shipped_date | status | comment |
-- |--------------|-----------------|------------|---------------|--------------|--------|---------|
-- | 1            | 1               | 2017-04-09 | 2017-04-13    | 2017-04-12   | Closed |         |
-- | 2            | 2               | 2017-04-15 | 2017-04-20    | 2017-04-18   | Closed |         |
-- | 3            | 3               | 2017-04-16 | 2017-04-25    | 2017-04-20   | Closed |         |
-- | 4            | 3               | 2017-04-18 | 2017-04-28    | 2017-04-25   | Closed |         |

-- Sample Output
-- | customer_number |
-- |-----------------|
-- | 3               |

-- Solution 1
-- LIMIT 不能直接應用於一個未命名的子查詢,所以必須給子查詢取個別名
select customer_number
from (
	select customer_number, count(order_number) as order_count
	from orders
	group by customer_number
    order by order_count desc
) as t1
limit 1

-- Solution 2
with T1 as (
	select customer_number, count(order_number) as order_count
	from orders
	group by customer_number
)
select T1.customer_number
from T1
where order_count = (
	select max(order_count)
    from T1
)

-- Solution 3
-- 這裡不能在窗口函數裡用partition by,如果用partition by則是對每一個客戶做排名
with T1 as (
	select customer_number, count(order_number) order_count,
		rank() over (order by count(order_number)desc) as rk
    from orders
    group by customer_number
)
select T1.customer_number
from T1
where T1.rk=1

-- 錯誤寫法
-- having 只能對聚合函數的結果做條件,而非再次進行聚合運算
select customer_number, count(order_number) as order_count
from orders
group by customer_number
having max(order_count)

-----------------------------------------------------------------------------------

-- 603.Consecutive Available Seats
-- 連續空餘座位

-- Several friends at a cinema ticket office would like to reserve consecutive available seats.
-- 在電影院售票處幾個朋友想訂個"連續的可用座位"。
-- Can you help to query all the consecutive available seats order by the seat_id using the following cinema table?
-- 使用以下 CINEMA TABLE 通過 seat_id 查詢所有"連續可用"的電影院座位順序？

-- | seat_id | free |
-- |---------|------|
-- | 1       | 1    |
-- | 2       | 0    |
-- | 3       | 1    |
-- | 4       | 1    |
-- | 5       | 1    | 

-- Your query should return the following result for the sample case above.

-- | seat_id |
-- |---------|
-- | 3       |
-- | 4       |
-- | 5       |

-- Note:
-- The seat_id is an auto increment int, and free is bool ('1' means free, and '0' means occupied.).
-- SEAT_ID 是一個自動增量 int 和 free 是 boolean ('1'釋放,'0'佔據)
-- Consecutive available seats are more than 2(inclusive) seats consecutively available.
-- 連續可用座位數連續超過2個(含)座位。

-- Solution
-- 運用LAG查尋上一個FREE、LEAD查尋下一個FREE
-- 最後在查詢每個座位資料本身FREE為1的值且"上一個FREE"或"下一個FREE"為1的值
-- 即為查詢連續的可用座位
with FreeSeat as (
	select seat_id, free,
		lag(free) over (order by seat_id) as prevSeat,
        lead(free) over (order by seat_id) as nextSeat
	from cinema
)
select seat_id
from FreeSeat
where FreeSeat.free = 1
and (FreeSeat.prevSeat = 1 or FreeSeat.nextSeat = 1)
order by seat_id;

------------------------------------------------------------------------------------------

-- 607.Sales Person
-- Given three tables: SALESPERSON, COMPANY, ORDERS.
-- 給出三個表：銷售員、公司、訂單
-- Output all the names in the table salesperson, who didn’t have sales to company 'RED'.
-- 找出沒有向公司RED賣過東西的銷售員

-- Example
-- Input

-- Table: salesperson
-- The table salesperson holds the salesperson information. Every salesperson has a sales_id and a name.

-- +----------+------+--------+-----------------+-----------+
-- | sales_id | name | salary | commission_rate | hire_date |
-- +----------+------+--------+-----------------+-----------+
-- |   1      | John | 100000 |     6           | 4/1/2006  |
-- |   2      | Amy  | 120000 |     5           | 5/1/2010  |
-- |   3      | Mark | 65000  |     12          | 12/25/2008|
-- |   4      | Pam  | 25000  |     25          | 1/1/2005  |
-- |   5      | Alex | 50000  |     10          | 2/3/2007  |
-- +----------+------+--------+-----------------+-----------+


-- Table: company
-- The table company holds the company information. Every company has a com_id and a name.

-- +---------+--------+------------+
-- | com_id  |  name  |    city    |
-- +---------+--------+------------+
-- |   1     |  RED   |   Boston   |
-- |   2     | ORANGE |   New York |
-- |   3     | YELLOW |   Boston   |
-- |   4     | GREEN  |   Austin   |
-- +---------+--------+------------+


-- Table: orders
-- The table orders holds the sales record information, salesperson and customer company are represented by sales_id and com_id.

-- +----------+------------+---------+----------+--------+
-- | order_id | order_date | com_id  | sales_id | amount |
-- +----------+------------+---------+----------+--------+
-- | 1        |   1/1/2014 |    3    |    4     | 100000 |
-- | 2        |   2/1/2014 |    4    |    5     | 5000   |
-- | 3        |   3/1/2014 |    1    |    1     | 50000  |
-- | 4        |   4/1/2014 |    1    |    4     | 25000  |
-- +----------+----------+---------+----------+--------+

-- output

-- +------+
-- | name | 
-- +------+
-- | Amy  | 
-- | Mark | 
-- | Alex |
-- +------+

-- Explanation
-- According to order '3' and '4' in table orders, it is easy to tell only salesperson 'John' and 'Pam' have sales to company 'RED',
-- 根據表格訂單中的訂單 '3' 和 '4'，很容易知道僅銷售人員 "John" 和 "Pam" 對 "RED" 公司有銷售
-- so we need to output all the other names in the table salesperson.
-- 因此我們需要在表銷售人員中輸出所有其他銷售人員名稱

-- Solution 1
select name
from salesperson
where sales_id not in (
	select sales_id
	from orders
	where com_id in (
		select com_id
		from company
		where name = 'RED'
	)
);

-- Solution 2
SELECT s.name FROM SalesPerson AS s 
LEFT JOIN 
(
SELECT o.sales_id FROM Orders AS o LEFT JOIN Company AS c
ON o.com_id = c.com_id WHERE c.name = 'RED'
) AS t
ON s.sales_id = t.sales_id
WHERE t.sales_id IS NULL;


-- Wrong solution
-- 這裡用in,只會找出com_id=3,4的,而其對應的sales_id=4,5,但是sales_id=4是有RED訂單的
-- 而且sales_id=2,3並沒有出現在orders訂單中,但是RED並非他們的客戶
select name
from salesperson
where sales_id in (
	select sales_id
	from orders
	where com_id in (
		select com_id
		from company
		where name != 'RED'
	)
);

-- 這個方式, Pam也會出現
SELECT s.name
FROM salesperson s
LEFT JOIN orders o ON s.sales_id = o.sales_id
left JOIN company c ON o.com_id = c.com_id AND c.name = 'RED'
WHERE c.com_id IS NULL;

-------------------------------------------------------------------------------------

-- 610.Triangle Judgement

-- A pupil Tim gets homework to identify whether three line segments could possibly form a triangle.
-- 小學生蒂姆(Tim)進行作業，以確定三個線段是否可能形成三角形

-- However, this assignment is very heavy because there are hundreds of records to calculate.
-- 但是，此任務非常繁重，因為有數百條記錄需要計算

-- Could you help Tim by writing a query to judge whether these three sides can form a triangle, 
-- assuming table triangle holds the length of the three sides x, y and z.
-- 通過編寫查詢來判斷這三個邊是否可以形成三角形
-- 假設表格三角形包含x，y和z的三個邊的長度

-- | x  | y  | z  |
-- |----|----|----|
-- | 13 | 15 | 30 |
-- | 10 | 20 | 15 |

-- For the sample data above, your query should return the follow result:
-- | x  | y  | z  | triangle |
-- |----|----|----|----------|
-- | 13 | 15 | 30 | No       |
-- | 10 | 20 | 15 | Yes      |

-- Solution
-- 三角形成立的條件，兩邊之和大於第三邊
select x, y, z,
	case
		when x+y>z then 'Yes' 
        else 'No'
        end as triangle
from triangle

-----------------------------------------------------------------------------------------

-- 613.Shortest Distance in a Line

-- Table point holds the x coordinate of some points on x-axis in a plane, which are all integers.
-- 表格點保存平面中x軸上某些點的x坐標，它們都是整數。 

-- Write a query to find the shortest distance between two points in these points.
-- 編寫查詢以查找這些點中兩個點之間的最短距離

-- | x   |
-- |-----|
-- | -1  |
-- | 0   |
-- | 2   |
 

-- The shortest distance is '1' obviously, which is from point '-1' to '0'. So the output is as below:
-- 最短距離顯然是'1'，它是從點 '-1' 到 '0' 的距離。所以輸出如下：

-- | shortest|
-- |---------|
-- | 1       |
 

-- Note: Every point is unique, which means there is no duplicates in table point
-- 每個點都是唯一的，這意味著表點中沒有重複

-- Solution 1
with T as (
	select x,
		lead(x) over (order by x) as nextPoint
	from point
)
select min(nextPoint-x) shortest
from T

-- Solution 2
-- 子查詢如在from,一定要給別名
select min(nextPoint-x) shortest
from (
	select x,
		lead(x) over (order by x) as nextPoint
	from point
) T

--------------------------------------------------------------------------------------

-- 1050.Actors and Directors Who Cooperated At Least Three 
-- 合作過至少3次的演員和導演

-- Table: ActorDirector

-- +-------------+---------+
-- | Column Name | Type    |
-- +-------------+---------+
-- | actor_id    | int     |
-- | director_id | int     |
-- | timestamp   | int     |
-- +-------------+---------+
-- timestamp is the primary key column for this table.
 
-- Write a SQL query for a report that provides the pairs (actor_id, director_id)
-- where the actor have cooperated with the director at least 3 times.
-- 查詢合作至少3次的演員和導演

-- Example:

-- ActorDirector table:
-- +-------------+-------------+-------------+
-- | actor_id    | director_id | timestamp   |
-- +-------------+-------------+-------------+
-- | 1           | 1           | 0           |
-- | 1           | 1           | 1           |
-- | 1           | 1           | 2           |
-- | 1           | 2           | 3           |
-- | 1           | 2           | 4           |
-- | 2           | 1           | 5           |
-- | 2           | 1           | 6           |
-- +-------------+-------------+-------------+

-- Result table:
-- +-------------+-------------+
-- | actor_id    | director_id |
-- +-------------+-------------+
-- | 1           | 1           |
-- +-------------+-------------+
-- The only pair is (1, 1) where they cooperated exactly 3 times.
-- 唯一的一對是(1, 1)，他們恰好合作3次。


-- Solution 
-- 其實group by就是把欄位變成一組的概念
select actor_id, director_id
from ActorDirector
group by 1, 2
having count(*) >= 3;

--------------------------------------------------------------------------------------------

-- 1068.Product Sales Analysis I
-- 產品銷售分析I

-- Table: Sales

-- +-------------+-------+
-- | Column Name | Type  |
-- +-------------+-------+
-- | sale_id     | int   |
-- | product_id  | int   |
-- | year        | int   |
-- | quantity    | int   |
-- | price       | int   |
-- +-------------+-------+
-- (sale_id, year) is the primary key of this table.
-- product_id is a foreign key to Product table.
-- Note that the price is per unit.

-- Table: Product

-- +--------------+---------+
-- | Column Name  | Type    |
-- +--------------+---------+
-- | product_id   | int     |
-- | product_name | varchar |
-- +--------------+---------+
-- product_id is the primary key of this table.
 

-- Write an SQL query that reports all product names of the products 
-- in the Sales table along with their selling year and price.

-- For example:

-- Sales table:
-- +---------+------------+------+----------+-------+
-- | sale_id | product_id | year | quantity | price |
-- +---------+------------+------+----------+-------+ 
-- | 1       | 100        | 2008 | 10       | 5000  |
-- | 2       | 100        | 2009 | 12       | 5000  |
-- | 7       | 200        | 2011 | 15       | 9000  |
-- +---------+------------+------+----------+-------+

-- Product table:
-- +------------+--------------+
-- | product_id | product_name |
-- +------------+--------------+
-- | 100        | Nokia        |
-- | 200        | Apple        |
-- | 300        | Samsung      |
-- +------------+--------------+

-- Result table:
-- +--------------+-------+-------+
-- | product_name | year  | price |
-- +--------------+-------+-------+
-- | Nokia        | 2008  | 5000  |
-- | Nokia        | 2009  | 5000  |
-- | Apple        | 2011  | 9000  |
-- +--------------+-------+-------+

-- Solution 1
select p.product_name, s.year, s.price
from sales s, product p
where s.product_id = p.product_id

-- Solution 2
select p.product_name, s.year, s.price
from sales s 
join product p
on s.product_id = p.product_id

--------------------------------------------------------------------------------------

-- 1075.Project Employees I

-- Table: Project

-- +-------------+---------+
-- | Column Name | Type    |
-- +-------------+---------+
-- | project_id  | int     |
-- | employee_id | int     |
-- +-------------+---------+
-- (project_id, employee_id) is the primary key of this table.
-- employee_id is a foreign key to Employee table.
-- Table: Employee

-- +------------------+---------+
-- | Column Name      | Type    |
-- +------------------+---------+
-- | employee_id      | int     |
-- | name             | varchar |
-- | experience_years | int     |
-- +------------------+---------+
-- employee_id is the primary key of this table.
 

-- Write an SQL query that reports the average experience years 
-- of all the employees for each project, rounded to 2 digits.
-- 每個專案項目的所有員工的平均工作經驗年限，四捨五入到2位數字。

-- The query result format is in the following example:

-- Project table:
-- +-------------+-------------+
-- | project_id  | employee_id |
-- +-------------+-------------+
-- | 1           | 1           |
-- | 1           | 2           |
-- | 1           | 3           |
-- | 2           | 1           |
-- | 2           | 4           |
-- +-------------+-------------+

-- Employee table:
-- +-------------+--------+------------------+
-- | employee_id | name   | experience_years |
-- +-------------+--------+------------------+
-- | 1           | Khaled | 3                |
-- | 2           | Ali    | 2                |
-- | 3           | John   | 1                |
-- | 4           | Doe    | 2                |
-- +-------------+--------+------------------+

-- Result table:
-- +-------------+---------------+
-- | project_id  | average_years |
-- +-------------+---------------+
-- | 1           | 2.00          |
-- | 2           | 2.50          |
-- +-------------+---------------+
-- The average experience years for the first project is (3 + 2 + 1) / 3 = 2.00 
-- and for the second project is (3 + 2) / 2 = 2.50

-- Solution
select p.project_id, round(avg(e.experience_years), 2) average_years
from project p, employee e
where p.employee_id = e.employee_id
group by p.project_id;

----------------------------------------------------------------------------------------

-- 1076.Project Employees II

-- Table: Project

-- +-------------+---------+
-- | Column Name | Type    |
-- +-------------+---------+
-- | project_id  | int     |
-- | employee_id | int     |
-- +-------------+---------+
-- (project_id, employee_id) is the primary key of this table.
-- employee_id is a foreign key to Employee table.
-- Table: Employee

-- +------------------+---------+
-- | Column Name      | Type    |
-- +------------------+---------+
-- | employee_id      | int     |
-- | name             | varchar |
-- | experience_years | int     |
-- +------------------+---------+
-- employee_id is the primary key of this table.
 

-- Write an SQL query that reports all the projects that have the most employees.
-- 查詢擁有最多員工的專案項目

-- The query result format is in the following example:

-- Project table:
-- +-------------+-------------+
-- | project_id  | employee_id |
-- +-------------+-------------+
-- | 1           | 1           |
-- | 1           | 2           |
-- | 1           | 3           |
-- | 2           | 1           |
-- | 2           | 4           |
-- +-------------+-------------+

-- Employee table:
-- +-------------+--------+------------------+
-- | employee_id | name   | experience_years |
-- +-------------+--------+------------------+
-- | 1           | Khaled | 3                |
-- | 2           | Ali    | 2                |
-- | 3           | John   | 1                |
-- | 4           | Doe    | 2                |
-- +-------------+--------+------------------+

-- Result table:
-- +-------------+
-- | project_id  |
-- +-------------+
-- | 1           |
-- +-------------+
-- The first project has 3 employees while the second one has 2.
-- 第一個項目有3名員工，而第二個項目有2名員工

-- Solution 1
with T as (
	select project_id, employee_id, count(employee_id)
    from project
    group by 1, 2
    order by count(employee_id) desc
)
select project_id
from T
limit 1

-- Solution 2
with T as (
	select project_id, employee_id, 
    count(employee_id) over (partition by project_id order by employee_id) as cnt
    from project
    limit 1
)
select project_id
from T

-- Solution 3
-- LIMIT 不能在 CTE 中使用：LIMIT 應該在最外層查詢中使用，而不能在 CTE 中使用
-- 這裡必須用 group by,因為窗口函數裡面有聚合函數
with T as (
	select project_id, employee_id, 
    rank () over (partition by project_id order by count(employee_id) desc)
    from project
    group by 1,2
)
select project_id
from T
limit 1

-- Solution 4
-- 這裡窗口函數不一定要有 partition by 
select project_id
from (
	select project_id, 
    rank () over (order by count(employee_id) desc)
    from project
    group by 1
) as T
limit 1

-----------------------------------------------------------------------------------------

-- 1082.Sales Analysis I

-- Table: Product

-- +--------------+---------+
-- | Column Name  | Type    |
-- +--------------+---------+
-- | product_id   | int     |
-- | product_name | varchar |
-- | unit_price   | int     |
-- +--------------+---------+
-- product_id is the primary key of this table.

-- Table: Sales

-- +-------------+---------+
-- | Column Name | Type    |
-- +-------------+---------+
-- | seller_id   | int     |
-- | product_id  | int     |
-- | buyer_id    | int     |
-- | sale_date   | date    |
-- | quantity    | int     |
-- | price       | int     |
-- +------ ------+---------+
-- This table has no primary key, it can have repeated rows.
-- product_id is a foreign key to Product table.
 

-- Write an SQL query that reports the best seller by total sales price, If there is a tie, report them all.
-- 查詢"總銷售額"最高的員工，若有並列第一，需完整列出

-- The query result format is in the following example:

-- Product table:
-- +------------+--------------+------------+
-- | product_id | product_name | unit_price |
-- +------------+--------------+------------+
-- | 1          | S8           | 1000       |
-- | 2          | G4           | 800        |
-- | 3          | iPhone       | 1400       |
-- +------------+--------------+------------+

-- Sales table:
-- +-----------+------------+----------+------------+----------+-------+
-- | seller_id | product_id | buyer_id | sale_date  | quantity | price |
-- +-----------+------------+----------+------------+----------+-------+
-- | 1         | 1          | 1        | 2019-01-21 | 2        | 2000  |
-- | 1         | 2          | 2        | 2019-02-17 | 1        | 800   |
-- | 2         | 2          | 3        | 2019-06-02 | 1        | 800   |
-- | 3         | 3          | 4        | 2019-05-13 | 2        | 2800  |
-- +-----------+------------+----------+------------+----------+-------+

-- Result table:
-- +-------------+
-- | seller_id   |
-- +-------------+
-- | 1           |
-- | 3           |
-- +-------------+
-- Both sellers with id 1 and 3 sold products with the most total price of 2800.
-- 編號為1和3的賣方均以最高總價2800出售了產品

-- Solution 1
select seller_id
from sales
group by seller_id
having sum(price) = (
	select max(a.total)
    from (
		select sum(price) as total
		from SALES
		group by seller_id
		) a
) 

-- Solution 2
select seller_id
from (
	select seller_id, 
		rank() over(order by sum(price) desc) as rk
	from sales
    group by 1
) t
where t.rk = 1;

-- Solution 3
with rk as (
	select seller_id,
		rank() over(order by sum(price) desc) as price_rk
	from SALES
    group by 1
)
select seller_id
from rk
where price_rk = 1;

-- Solution 4
with rk as (
	select seller_id, sum(price) total
    from sales
    group by 1
)
select seller_id
from rk
where total = (select max(total) from rk);

------------------------------------------------------------------------------------------

-- 1083.Sales Analysis II

-- Table: Product

-- +--------------+---------+
-- | Column Name  | Type    |
-- +--------------+---------+
-- | product_id   | int     |
-- | product_name | varchar |
-- | unit_price   | int     |
-- +--------------+---------+
-- product_id is the primary key of this table.
-- Table: Sales

-- +-------------+---------+
-- | Column Name | Type    |
-- +-------------+---------+
-- | seller_id   | int     |
-- | product_id  | int     |
-- | buyer_id    | int     |
-- | sale_date   | date    |
-- | quantity    | int     |
-- | price       | int     |
-- +------ ------+---------+
-- This table has no primary key, it can have repeated rows.
-- product_id is a foreign key to Product table.
 

-- Write an SQL query that reports the buyers who have bought 'S8' but not 'iPhone'.
-- 已購買S8但未購買iPhone的買家
-- Note that S8 and iPhone are products present in the Product table.

-- The query result format is in the following example:

-- Product table:
-- +------------+--------------+------------+
-- | product_id | product_name | unit_price |
-- +------------+--------------+------------+
-- | 1          | S8           | 1000       |
-- | 2          | G4           | 800        |
-- | 3          | iPhone       | 1400       |
-- +------------+--------------+------------+

-- Sales table:
-- +-----------+------------+----------+------------+----------+-------+
-- | seller_id | product_id | buyer_id | sale_date  | quantity | price |
-- +-----------+------------+----------+------------+----------+-------+
-- | 1         | 1          | 1        | 2019-01-21 | 2        | 2000  |
-- | 1         | 2          | 2        | 2019-02-17 | 1        | 800   |
-- | 2         | 1          | 3        | 2019-06-02 | 1        | 800   |
-- | 3         | 3          | 3        | 2019-05-13 | 2        | 2800  |
-- +-----------+------------+----------+------------+----------+-------+

-- Result table:
-- +-------------+
-- | buyer_id    |
-- +-------------+
-- | 1           |
-- +-------------+
-- The buyer with id 1 bought an S8 but didn't buy an iPhone. The buyer with id 3 bought both.
-- ID為1的買家購買了S8但沒有購買的iPhone。編號為3的買家同時購買了兩者。

-- Solution 1
with buyer_s8 as (
	select distinct buyer_id
	from sales
	where product_id = (
		select product_id
		from product
		where product_name = "S8"
	)
),
buyer_iphone as (
	select distinct buyer_id
    from sales
    where product_id = (
		select product_id
		from product
		where product_name = "iPhone"
	)
)
select buyer_id
from buyer_s8
where buyer_id not in (
	select buyer_id
    from buyer_iphone
) 

-- Solution 2:
SELECT DISTINCT s1.buyer_id
FROM Sales s1
JOIN Product p1 ON s1.product_id = p1.product_id
LEFT JOIN Sales s2 ON s1.buyer_id = s2.buyer_id
                  AND s2.product_id = (SELECT product_id FROM Product WHERE product_name = 'iPhone')
WHERE p1.product_name = 'S8'
  AND s2.buyer_id IS NULL;

要了解這個 SQL 查詢的每個步驟產生的結果，我們需要詳細分析每個子查詢和JOIN是如何進行的。以下是詳細的分步解釋：

### 1. 主要查詢

```sql
SELECT DISTINCT s1.buyer_id
FROM Sales s1
JOIN Product p1 ON s1.product_id = p1.product_id
LEFT JOIN Sales s2 ON s1.buyer_id = s2.buyer_id
                  AND s2.product_id = (SELECT product_id FROM Product WHERE product_name = 'iPhone')
WHERE p1.product_name = 'S8'
  AND s2.buyer_id IS NULL;
```

### 2. FROM 和 JOIN 步驟

-- 首先，我們來看 FROM 和 JOIN 步驟如何形成臨時表：

#### Step 1: FROM Sales s1

-- 從 `Sales` 表選取所有資料，取別名為 `s1`。

| s1.seller_id | s1.product_id | s1.buyer_id | s1.sale_date | s1.quantity | s1.price |
|--------------|----------------|-------------|--------------|-------------|----------|
| 1            | 1              | 1           | 2019-01-21   | 2           | 2000     |
| 1            | 2              | 2           | 2019-02-17   | 1           | 800      |
| 2            | 1              | 3           | 2019-06-02   | 1           | 800      |
| 3            | 3              | 3           | 2019-05-13   | 2           | 2800     |

#### Step 2: JOIN Product p1 ON s1.product_id = p1.product_id

-- 將 `Sales` 表中的 `product_id` 與 `Product` 表中的 `product_id` 進行 JOIN：

| s1.seller_id | s1.product_id | s1.buyer_id | s1.sale_date | s1.quantity | s1.price | p1.product_name | p1.unit_price |
|--------------|----------------|-------------|--------------|-------------|----------|-----------------|---------------|
| 1            | 1              | 1           | 2019-01-21   | 2           | 2000     | S8              | 1000          |
| 1            | 2              | 2           | 2019-02-17   | 1           | 800      | G4              | 800           |
| 2            | 1              | 3           | 2019-06-02   | 1           | 800      | S8              | 1000          |
| 3            | 3              | 3           | 2019-05-13   | 2           | 2800     | iPhone          | 1400          |

#### Step 3: LEFT JOIN Sales s2 ON s1.buyer_id = s2.buyer_id AND s2.product_id = (SELECT product_id FROM Product WHERE product_name = 'iPhone')

這步將 `s1` 表與 `Sales` 表進行 LEFT JOIN，條件是 `buyer_id` 相等且 `product_id` 是 iPhone 的 id：

-- 1. 首先，內部子查詢 `(SELECT product_id FROM Product WHERE product_name = 'iPhone')` 返回 `product_id = 3`。
-- 2. 然後，LEFT JOIN 的結果如下：

| s1.seller_id | s1.product_id | s1.buyer_id | s1.sale_date | s1.quantity | s1.price | p1.product_name | p1.unit_price | s2.seller_id | s2.product_id | s2.buyer_id | s2.sale_date | s2.quantity | s2.price |
|--------------|----------------|-------------|--------------|-------------|----------|-----------------|---------------|--------------|----------------|-------------|--------------|-------------|----------|
| 1            | 1              | 1           | 2019-01-21   | 2           | 2000     | S8              | 1000          | NULL         | NULL           | NULL        | NULL         | NULL        | NULL     |
| 1            | 2              | 2           | 2019-02-17   | 1           | 800      | G4              | 800           | NULL         | NULL           | NULL        | NULL         | NULL        | NULL     |
| 2            | 1              | 3           | 2019-06-02   | 1           | 800      | S8              | 1000          | 3            | 3              | 3           | 2019-05-13   | 2           | 2800     |
| 3            | 3              | 3           | 2019-05-13   | 2           | 2800     | iPhone          | 1400          | 3            | 3              | 3           | 2019-05-13   | 2           | 2800     |

### 3. WHERE 篩選條件

-- 接下來，應用 WHERE 篩選條件 `p1.product_name = 'S8' AND s2.buyer_id IS NULL`：

| s1.seller_id | s1.product_id | s1.buyer_id | s1.sale_date | s1.quantity | s1.price | p1.product_name | p1.unit_price | s2.seller_id | s2.product_id | s2.buyer_id | s2.sale_date | s2.quantity | s2.price |
|--------------|----------------|-------------|--------------|-------------|----------|-----------------|---------------|--------------|----------------|-------------|--------------|-------------|----------|
| 1            | 1              | 1           | 2019-01-21   | 2           | 2000     | S8              | 1000          | NULL         | NULL           | NULL        | NULL         | NULL        | NULL     |

### 4. SELECT DISTINCT s1.buyer_id

最終，選擇 `buyer_id` 並去重：

| buyer_id |
|----------|
| 1        |

所以，結果是 `buyer_id = 1`，這是正確的答案，因為 `buyer_id = 1` 買了 S8 但沒有買 iPhone。

SELECT distinct s1.*, p1.*
FROM Sales s1
JOIN Product p1 ON s1.product_id = p1.product_id
LEFT JOIN Sales s2 ON s1.buyer_id = s2.buyer_id
				AND s2.product_id = (SELECT product_id FROM Product WHERE product_name = 'iPhone')


-- Solution 3:
-- 在這段 SQL 查詢中，NOT EXISTS 子查詢用來排除那些同時購買了 'iPhone' 和 'S8' 的買家。
-- 子查詢的結果決定了主要查詢中的每個 BUYER_ID 是否包含在最終結果中。
SELECT DISTINCT S1.PRODUCT_ID, S1.BUYER_ID, P.PRODUCT_NAME
FROM SALES S1 JOIN PRODUCT P
ON S1.PRODUCT_ID = P.PRODUCT_ID
WHERE P.PRODUCT_NAME = 'S8'
AND NOT EXISTS (
  SELECT S.BUYER_ID
  FROM SALES S JOIN PRODUCT P
  ON S.PRODUCT_ID = P.PRODUCT_ID
  WHERE P.PRODUCT_NAME = 'iPhone'
  AND S1.BUYER_ID = S.BUYER_ID
);
-- 1. 首先，主查詢選擇所有購買了 'S8' 的買家：
-- 這將返回：
1.PRODUCT_ID	S1.BUYER_ID	P.PRODUCT_NAME
1	1	S8
1	3	S8
-- 2. 內部子查詢和判斷：
-- 對於每個從主查詢返回的 S1.BUYER_ID，內部子查詢檢查該買家是否購買了 'iPhone'。
-- 檢查 S1.BUYER_ID = 1 是否購買了 'iPhone'：
SELECT S.BUYER_ID
FROM SALES S 
JOIN PRODUCT P ON S.PRODUCT_ID = P.PRODUCT_ID
WHERE P.PRODUCT_NAME = 'iPhone'
AND 1 = S.BUYER_ID
-- 此查詢沒有返回任何記錄，因為 BUYER_ID = 1 沒有購買 'iPhone'。
-- 這意味著 NOT EXISTS 判斷為 True，所以 BUYER_ID = 1 被包括在最終結果中。
-- 檢查 S1.BUYER_ID = 3 是否購買了 'iPhone'：
SELECT S.BUYER_ID
FROM SALES S 
JOIN PRODUCT P ON S.PRODUCT_ID = P.PRODUCT_ID
WHERE P.PRODUCT_NAME = 'iPhone'
AND 3 = S.BUYER_ID
-- 此查詢返回了一條記錄，因為 BUYER_ID = 3 購買了 'iPhone'。
-- 這意味著 NOT EXISTS 判斷為 False，所以 BUYER_ID = 3 被排除在最終結果之外。
-- 3. 最終結果：
-- 只有 BUYER_ID = 1 通過了 NOT EXISTS 的檢查：

-- Solution 4:
SELECT DISTINCT A.BUYER_ID
FROM SALES A JOIN PRODUCT B
ON A.PRODUCT_ID = B.PRODUCT_ID
WHERE 
A.BUYER_ID IN (
	SELECT A.BUYER_ID 
	FROM SALES A 
	JOIN PRODUCT B ON A.PRODUCT_ID = B.PRODUCT_ID 
	WHERE B.PRODUCT_NAME = 'S8') 
AND
A.BUYER_ID NOT IN (
	SELECT A.BUYER_ID 
	FROM SALES A 
	JOIN PRODUCT B ON A.PRODUCT_ID = B.PRODUCT_ID 
	WHERE B.PRODUCT_NAME = 'iPhone');

-------------------------------------------------------------------------------------------------------------

-- 1084.Sales Analysis III

-- Table: Product

-- +--------------+---------+
-- | Column Name  | Type    |
-- +--------------+---------+
-- | product_id   | int     |
-- | product_name | varchar |
-- | unit_price   | int     |
-- +--------------+---------+
-- product_id is the primary key of this table.
-- Table: Sales

-- +-------------+---------+
-- | Column Name | Type    |
-- +-------------+---------+
-- | seller_id   | int     |
-- | product_id  | int     |
-- | buyer_id    | int     |
-- | sale_date   | date    |
-- | quantity    | int     |
-- | price       | int     |
-- +------ ------+---------+
-- This table has no primary key, it can have repeated rows.
-- product_id is a foreign key to Product table.
 

-- Write an SQL query that reports the products that were only sold in spring 2019.
-- 僅在2019年春季銷售的產品
-- That is, between 2019-01-01 and 2019-03-31 inclusive.
-- 在 '2019-01-01' 和 '2019-03-31' 之間

-- The query result format is in the following example:

-- Product table:
-- +------------+--------------+------------+
-- | product_id | product_name | unit_price |
-- +------------+--------------+------------+
-- | 1          | S8           | 1000       |
-- | 2          | G4           | 800        |
-- | 3          | iPhone       | 1400       |
-- +------------+--------------+------------+

-- Sales table:
-- +-----------+------------+----------+------------+----------+-------+
-- | seller_id | product_id | buyer_id | sale_date  | quantity | price |
-- +-----------+------------+----------+------------+----------+-------+
-- | 1         | 1          | 1        | 2019-01-21 | 2        | 2000  |
-- | 1         | 2          | 2        | 2019-02-17 | 1        | 800   |
-- | 2         | 2          | 3        | 2019-06-02 | 1        | 800   |
-- | 3         | 3          | 4        | 2019-05-13 | 2        | 2800  |
-- +-----------+------------+----------+------------+----------+-------+

-- Result table:
-- +-------------+--------------+
-- | product_id  | product_name |
-- +-------------+--------------+
-- | 1           | S8           |
-- +-------------+--------------+
-- The product with id 1 was only sold in spring 2019 while the other two were sold after.
-- ID為1的產品'僅在'2019年春季銷售，而其他兩個則在之後銷售

-- solution
-- 產品只能在春季銷售,同樣產品不能在其他季節銷售
select s.product_id, p.product_name
from sales s join product p
on s.product_id = p.product_id
where s.product_id in (
	select product_id
    from sales
	where sale_date between '2019-01-01' and '2019-03-31')
and s.product_id not in (
	select product_id
    from sales
    where sale_date < '2019-01-01' or sale_date > '2019-03-31');

-- Solution
-- Oracle
SELECT S1.PRODUCT_ID, P.PRODUCT_NAME, S1.SALE_DATE 
FROM SALES S1 JOIN PRODUCT P 
ON S1.PRODUCT_ID = P.PRODUCT_ID
WHERE SALE_DATE BETWEEN '2019-01-01' AND '2019-03-31'
AND NOT EXISTS (
  SELECT S.PRODUCT_ID
  FROM SALES S
  WHERE SALE_DATE　NOT BETWEEN '2019-01-01' AND '2019-03-31'
  AND S1.PRODUCT_ID = S.PRODUCT_ID
);

-------------------------------------------------------------------------------------------

-- 1113.Reported Posts

-- Table: Actions

-- +---------------+---------+
-- | Column Name   | Type    |
-- +---------------+---------+
-- | user_id       | int     |
-- | post_id       | int     |
-- | action_date   | date    | 
-- | action        | enum    |
-- | extra         | varchar |
-- +---------------+---------+
-- There is no primary key for this table, it may have duplicate rows.
-- The action column is an ENUM type of ('view', 'like', 'reaction', 'comment', 'report', 'share').
-- The extra column has optional information about the action such as a reason for report or a type of reaction.
-- 下表中沒有主鍵，因此可能有重複行。action 列可能的值為(查看、喜歡、反應、評論、報告、分享)
-- extra 列不是必須的，包含有關操作的可選信息，例如報告原因或反應類型。
 
-- Write an SQL query that "reports" the number of posts reported 'yesterday' for each report reason. Assume today is '2019-07-05'.
-- 查詢每種報告理由在昨天的報告數量，需要篩除重複 'post_id' 的重複報告

-- The query result format is in the following example:

-- Actions table:
-- +---------+---------+-------------+--------+--------+
-- | user_id | post_id | action_date | action | extra  |
-- +---------+---------+-------------+--------+--------+
-- | 1       | 1       | 2019-07-01  | view   | null   |
-- | 1       | 1       | 2019-07-01  | like   | null   |
-- | 1       | 1       | 2019-07-01  | share  | null   |
-- | 2       | 4       | 2019-07-04  | view   | null   |
-- | 2       | 4       | 2019-07-04  | report | spam   |
-- | 3       | 4       | 2019-07-04  | view   | null   |
-- | 3       | 4       | 2019-07-04  | report | spam   |
-- | 4       | 3       | 2019-07-02  | view   | null   |
-- | 4       | 3       | 2019-07-02  | report | spam   |
-- | 5       | 2       | 2019-07-04  | view   | null   |
-- | 5       | 2       | 2019-07-04  | report | racism |
-- | 5       | 5       | 2019-07-04  | view   | null   |
-- | 5       | 5       | 2019-07-04  | report | racism |
-- +---------+---------+-------------+--------+--------+

-- spam 垃圾郵件
-- racism 種族主義
-- Result table:
-- +---------------+--------------+
-- | report_reason | report_count |
-- +---------------+--------------+
-- | spam          | 1            |
-- | racism        | 2            |
-- +---------------+--------------+ 
-- Note that we only care about report reasons with non zero number of reports.
-- 我們只關心報告數量不為零的報告原因

-- Solution 1
select a.extra as report_reason, count(distinct a.post_id) as report_count
from (
	select distinct * from actions
) a
-- where action_date = curdate() - INTERVAL 1 day
where action_date = date_sub("2019-07-05", interval 1 day)
and action = 'report'
and extra is not null
group by 1

-- Solution
-- Oracle
SELECT EXTRA "REPORT_REASON", COUNT(DISTINCT POST_ID) "REPORT_COUNT"
FROM ACTIONS
WHERE ACTION = 'report'
AND ACTION_DATE = (TO_DATE('2019-07-05','YYYY-MM-DD') - 1)
GROUP BY EXTRA;

---------------------------------------------------------------------------------------------

-- 1141.User Activity for the Past 30 Days I
-- 使用者過去30天的活動紀錄

-- Table: Activity

-- +---------------+---------+
-- | Column Name   | Type    |
-- +---------------+---------+
-- | user_id       | int     |
-- | session_id    | int     |
-- | activity_date | date    |
-- | activity_type | enum    |
-- +---------------+---------+
-- There is no primary key for this table, it may have duplicate rows.
-- The activity_type column is an ENUM of type ('open_session', 'end_session', 'scroll_down', 'send_message').
-- The table shows the user activities for a social media website.
-- 使用者在網路社交媒體上的活動資料
-- Note that each session belongs to exactly one user.
 

-- Write an SQL query to find the daily active user count for a period of 30 days ending '2019-07-27' inclusively.
-- 截至2019年7月27日（含）的30天期間的每日活躍用戶數
-- A user was active on some day if he/she made at least one activity on that day.

-- The query result format is in the following example:

-- Activity table:
-- +---------+------------+---------------+---------------+
-- | user_id | session_id | activity_date | activity_type |
-- +---------+------------+---------------+---------------+
-- | 1       | 1          | 2019-07-20    | open_session  |
-- | 1       | 1          | 2019-07-20    | scroll_down   |
-- | 1       | 1          | 2019-07-20    | end_session   |
-- | 2       | 4          | 2019-07-20    | open_session  |
-- | 2       | 4          | 2019-07-21    | send_message  |
-- | 2       | 4          | 2019-07-21    | end_session   |
-- | 3       | 2          | 2019-07-21    | open_session  |
-- | 3       | 2          | 2019-07-21    | send_message  |
-- | 3       | 2          | 2019-07-21    | end_session   |
-- | 4       | 3          | 2019-06-25    | open_session  |
-- | 4       | 3          | 2019-06-25    | end_session   |
-- +---------+------------+---------------+---------------+

-- Result table:
-- +------------+--------------+ 
-- | day        | active_users |
-- +------------+--------------+ 
-- | 2019-07-20 | 2            |
-- | 2019-07-21 | 2            |
-- +------------+--------------+ 
-- Note that we do not care about days with zero active users.

-- Solution 1
select activity_date as day, count(distinct user_id) as active_users
from activity
where activity_date 
	between date_sub('2019-07-27', interval 29 day)
    and '2019-07-27'
group by 1


-- Oracle
SELECT (TO_DATE('2019-07-27','YYYY-MM-DD') - 29) FROM DUAL;

SELECT ACTIVITY_DATE AS DAY, COUNT(DISTINCT USER_ID) AS ACTIVE_USERS
FROM ACTIVITY
WHERE ACTIVITY_DATE BETWEEN (TO_DATE('2019-07-27','YYYY-MM-DD') - 29) AND '2019-07-27'
GROUP BY ACTIVITY_DATE;

---------------------------------------------------------------------------------------------

-- 1148.Article Views I 文章瀏覽

-- Table: Views

-- +---------------+---------+
-- | Column Name   | Type    |
-- +---------------+---------+
-- | article_id    | int     |
-- | author_id     | int     |
-- | viewer_id     | int     |
-- | view_date     | date    |
-- +---------------+---------+
-- There is no primary key for this table, it may have duplicate rows.
-- Each row of this table indicates that some viewer viewed an article (written by some author) on some date. 
-- 表格的每一行表示某位觀看者在某個日期觀看了某位作者撰寫的文章
-- Note that equal author_id and viewer_id indicate the same person.

-- Write an SQL query to find all the authors that viewed at least one of their own articles,
-- 查找所有查看過至少一篇自己的文章的作者
-- sorted in ascending order by their id.
-- 作者編號升幕排序
-- The query result format is in the following example:

-- Views table:
-- +------------+-----------+-----------+------------+
-- | article_id | author_id | viewer_id | view_date  |
-- +------------+-----------+-----------+------------+
-- | 1          | 3         | 5         | 2019-08-01 |
-- | 1          | 3         | 6         | 2019-08-02 |
-- | 2          | 7         | 7         | 2019-08-01 |
-- | 2          | 7         | 6         | 2019-08-02 |
-- | 4          | 7         | 1         | 2019-07-22 |
-- | 3          | 4         | 4         | 2019-07-21 |
-- | 3          | 4         | 4         | 2019-07-21 |
-- +------------+-----------+-----------+------------+

-- Result table:
-- +------+
-- | id   |
-- +------+
-- | 4    |
-- | 7    |
-- +------+

-- Solution 1
-- where viewer_id in (author_id) 的寫法並不能達到預期效果
-- 因為 author_id 不是一個列表或子查詢的結果，而是一個單一值。
select distinct author_id as id
from views
where viewer_id in (select distinct author_id from views)
order by author_id;

-- Solution 2
select distinct author_id as id
from views
where viewer_id = author_id
order by author_id;

--------------------------------------------------------------------------------------------

-- 1173.Immediate Food Delivery I 即時食品外送

-- Table: Delivery

-- +-----------------------------+---------+
-- | Column Name                 | Type    |
-- +-----------------------------+---------+
-- | delivery_id                 | int     |
-- | customer_id                 | int     |
-- | order_date                  | date    |
-- | customer_pref_delivery_date | date    |
-- +-----------------------------+---------+
-- customer_pref_delivery_date 顧客預期交貨日期

-- delivery_id is the primary key of this table.
-- The table holds information about food delivery to customers that make orders 
-- 該表包含有關向訂購客戶交付食物的信息
-- at some date and specify a preferred delivery date (on the same order date or after it).
-- 在某個日期並指定首選的交貨日期(在同一訂單日期或之後)

-- If the "preferred delivery date" of the customer is the same as the "order date"
-- then the order is called immediate otherwise it's called scheduled.
-- 如果客戶的首選交貨日期與訂單日期相同，則該訂單稱為"即時訂單"，否則稱為"計劃訂單"

-- Write an SQL query to find the percentage of immediate orders in the table, rounded to 2 decimal places.
-- 在表格中找到"即時訂單"所佔的百分比(四捨五入到小數點後兩位)

-- The query result format is in the following example:

-- Delivery table:
-- +-------------+-------------+------------+-----------------------------+
-- | delivery_id | customer_id | order_date | customer_pref_delivery_date |
-- +-------------+-------------+------------+-----------------------------+
-- | 1           | 1           | 2019-08-01 | 2019-08-02                  |
-- | 2           | 5           | 2019-08-02 | 2019-08-02                  |
-- | 3           | 1           | 2019-08-11 | 2019-08-11                  |
-- | 4           | 3           | 2019-08-24 | 2019-08-26                  |
-- | 5           | 4           | 2019-08-21 | 2019-08-22                  |
-- | 6           | 2           | 2019-08-11 | 2019-08-13                  |
-- +-------------+-------------+------------+-----------------------------+

-- Result table:
-- +----------------------+
-- | immediate_percentage |
-- +----------------------+
-- | 33.33                |
-- +----------------------+
-- The orders with delivery id 2 and 3 are immediate while the others are scheduled.
-- 交貨ID為2和3的訂單是"即時訂單"的，而其他的則是"計劃訂單"

-- Solution 1
with a as (
	select count(delivery_id) as immediate
    from delivery
    where order_date = customer_pref_delivery_date
),
b as (
	select count(delivery_id) as scheduler
    from delivery
)
select round(a.immediate/b.scheduler*100, 2) as immediate_percentage
from a, b;

-- Solution 2
select round(a.immediate/b.scheduler*100, 2) as immediate_percentage
from (
	select count(delivery_id) as immediate
    from delivery
    where order_date = customer_pref_delivery_date
) a,
	(
    select count(delivery_id) as scheduler
    from delivery
    )b

-- Wrong Solution
-- 這樣寫變成cross join, 答案會是1,但是這裡又無法再用where a.column = b.column
-- 這種情形,其實在寫一個CTE即可解決
with a as (
	select delivery_id
    from delivery
    where order_date = customer_pref_delivery_date
)
select round(count(a.delivery_id)/count(b.delivery_id)*100, 2) as immediate_percentage
from delivery b, a

----------------------------------------------------------------------------------------------

-- 1251.Average Selling Price

-- Table: Prices

-- +---------------+---------+
-- | Column Name   | Type    |
-- +---------------+---------+
-- | product_id    | int     |
-- | start_date    | date    |
-- | end_date      | date    |
-- | price         | int     |
-- +---------------+---------+
-- (product_id, start_date, end_date) is the primary key for this table.
-- Each row of this table indicates the price of the product_id in the period from start_date to end_date.
-- 該表的每一行指示從 start_date 到 end_date 期間 product_id 的價格
-- For each product_id there will be no two overlapping periods.
-- 對於每個 product_id，將沒有兩個重疊的時間段
-- That means there will be no two intersecting periods for the same product_id.
-- 這意味著同一 product_id 不會有兩個相交的時間段

-- Table: UnitsSold(已售)

-- +---------------+---------+
-- | Column Name   | Type    |
-- +---------------+---------+
-- | product_id    | int     |
-- | purchase_date | date    | 購買日
-- | units         | int     | 購買單位
-- +---------------+---------+
-- There is no primary key for this table, it may contain duplicates.
-- Each row of this table indicates the date, units and product_id of each product sold.
-- 該表的每一行均指示每種已售產品的日期，購買單位和 product_id

-- Write an SQL query to find the average selling price for each product.
-- 計算每個產品的平均售價
-- average_price should be rounded to 2 decimal places.
-- average_price 應該四捨五入到小數點後兩位
-- The query result format is in the following example:

-- Prices table:
-- +------------+------------+------------+--------+
-- | product_id | start_date | end_date   | price  |
-- +------------+------------+------------+--------+
-- | 1          | 2019-02-17 | 2019-02-28 | 5      |
-- | 1          | 2019-03-01 | 2019-03-22 | 20     |
-- | 2          | 2019-02-01 | 2019-02-20 | 15     |
-- | 2          | 2019-02-21 | 2019-03-31 | 30     |
-- +------------+------------+------------+--------+
 
-- UnitsSold table:
-- +------------+---------------+-------+
-- | product_id | purchase_date | units |
-- +------------+---------------+-------+
-- | 1          | 2019-02-25    | 100   |
-- | 1          | 2019-03-01    | 15    |
-- | 2          | 2019-02-10    | 200   |
-- | 2          | 2019-03-22    | 30    |
-- +------------+---------------+-------+

-- Result table:
-- +------------+---------------+
-- | product_id | average_price |
-- +------------+---------------+
-- | 1          | 6.96          |
-- | 2          | 16.96         |
-- +------------+---------------+  
-- Average selling price = Total Price of Product / Number of products sold.
-- Average selling price for product 1 = ((100 * $5) + (15 * $20)) / 115 = 6.96
-- 100 + 15 = 115
-- Average selling price for product 2 = ((200 * $15) + (30 * $30)) / 230 = 16.96
-- 200 + 30 = 230


-- Solution 1
select t.product_id, round(sum(t.subTotal)/sum(t.units), 2) average_price
	from (
		select p.product_id, p.start_date, p.end_date, u.units, (p.price*u.units) subTotal
		from prices p, unitssold u
		where p.product_id = u.product_id
		and u.purchase_date between p.start_date and p.end_date
	) t
	group by t.product_id



-- Solution 2
with t1 as (
	select p.product_id, p.start_date, p.end_date, u.units, (p.price*u.units) subTotal
	from prices p, unitssold u
	where p.product_id = u.product_id
	and u.purchase_date between p.start_date and p.end_date
)
select product_id, round(sum(subTotal)/sum(units), 2) average_price
from t1
group by 1

-----------------------------------------------------------------------------------------------

-- 1280.Students and Examinations 學生與考試

-- Table: Students
-- +---------------+---------+
-- | Column Name   | Type    |
-- +---------------+---------+
-- | student_id    | int     |
-- | student_name  | varchar |
-- +---------------+---------+
-- student_id is the primary key for this table.
-- Each row of this table contains the ID and the name of one student in the school.
 

-- Table: Subjects
-- +--------------+---------+
-- | Column Name  | Type    |
-- +--------------+---------+
-- | subject_name | varchar |
-- +--------------+---------+
-- subject_name is the primary key for this table.
-- Each row of this table contains the name of one subject in the school.
 

-- Table: Examinations
-- +--------------+---------+
-- | Column Name  | Type    |
-- +--------------+---------+
-- | student_id   | int     |
-- | subject_name | varchar |
-- +--------------+---------+
-- There is no primary key for this table. It may contain duplicates.
-- Each student from the Students table takes every course from Subjects table.
-- 每個學生都可以從"課程"表中選擇每個課程
-- Each row of this table indicates that a student with ID student_id attended the exam of subject_name.
-- 每一行表示ID為 Student_id 的學生參加了 subject_name 的考試

-- Write an SQL query to find the number of times each student attended each exam.
-- 查找每個學生參加每項考試的次數

-- Order the result table by student_id and subject_name.
-- 按 student_id 和 subject_name 排序

-- The query result format is in the following example:

-- Students table:
-- +------------+--------------+
-- | student_id | student_name |
-- +------------+--------------+
-- | 1          | Alice        |
-- | 2          | Bob          |
-- | 13         | John         |
-- | 6          | Alex         |
-- +------------+--------------+

-- Subjects table:
-- +--------------+
-- | subject_name |
-- +--------------+
-- | Math         |
-- | Physics      |
-- | Programming  |
-- +--------------+

-- Examinations table:
-- +------------+--------------+
-- | student_id | subject_name |
-- +------------+--------------+
-- | 1          | Math         |
-- | 1          | Physics      |
-- | 1          | Programming  |
-- | 2          | Programming  |
-- | 1          | Physics      |
-- | 1          | Math         |
-- | 13         | Math         |
-- | 13         | Programming  |
-- | 13         | Physics      |
-- | 2          | Math         |
-- | 1          | Math         |
-- +------------+--------------+

-- Result table:
-- +------------+--------------+--------------+----------------+
-- | student_id | student_name | subject_name | attended_exams |
-- +------------+--------------+--------------+----------------+
-- | 1          | Alice        | Math         | 3              |
-- | 1          | Alice        | Physics      | 2              |
-- | 1          | Alice        | Programming  | 1              |
-- | 2          | Bob          | Math         | 1              |
-- | 2          | Bob          | Physics      | 0              |
-- | 2          | Bob          | Programming  | 1              |
-- | 6          | Alex         | Math         | 0              |
-- | 6          | Alex         | Physics      | 0              |
-- | 6          | Alex         | Programming  | 0              |
-- | 13         | John         | Math         | 1              |
-- | 13         | John         | Physics      | 1              |
-- | 13         | John         | Programming  | 1              |
-- +------------+--------------+--------------+----------------+

-- The result table should contain all students and all subjects.
-- 結果表應包含所有學生和所有學科
-- Alice attended Math exam 3 times, Physics exam 2 times and Programming exam 1 time.
-- 愛麗絲（Alice）參加了3次數學考試，2次物理考試和1次編程考試。
-- Bob attended Math exam 1 time, Programming exam 1 time and didn't attend the Physics exam.
-- 鮑勃（Bob）參加了1次數學考試，1次參加了編程考試，並且沒有參加物理考試。
-- Alex didn't attend any exam.
-- 亞歷克斯沒有參加任何考試。
-- John attended Math exam 1 time, Physics exam 1 time and Programming exam 1 time.
-- 約翰參加數學考試1次，物理1考試時間和考試的編程1次。

-- Solution 1
select a.student_id, a.student_name, a.subject_name, ifnull(b.attended_exams, 0)
from 
	(select student_id, student_name, subject_name
	from students, subjects
	order by 1, 3) a
left join
	(select student_id, subject_name, count(subject_name) attended_exams
	from examinations
	group by 1,2) b
on a.student_id = b.student_id
and a.subject_name = b.subject_name
order by 1, 3

-- Solution 2
with a as (
	select student_id, student_name, subject_name
	from students, subjects
	order by 1, 3
),
b as (
	select student_id, subject_name, count(subject_name) attended_exams
	from examinations
	group by 1,2
)
select a.student_id, a.student_name, a.subject_name, coalesce(b.attended_exams, 0)
from a left join b
on a.student_id = b.student_id
and a.subject_name = b.subject_name
order by 1, 3


-- Wrong Solution
-- 這裡少了and a.subject_name = b.subject_name
select a.student_id, a.student_name, a.subject_name, ifnull(b.attended_exams, 0)
from 
	(select student_id, student_name, subject_name
	from students, subjects
	order by 1, 3) a
left join
	(select student_id, subject_name, count(subject_name) attended_exams
	from examinations
	group by 1,2) b
on a.student_id = b.student_id
order by 1, 3
-- 因為兩個子查詢產生的臨時表分別為:
-- a:
student_id | student_name | subject_name
----------------------------------------
1          | Alice        | Math
1          | Alice        | Physics
1          | Alice        | Programming
2          | Bob          | Math
2          | Bob          | Physics
2          | Bob          | Programming
6          | Alex         | Math
6          | Alex         | Physics
6          | Alex         | Programming
13         | John         | Math
13         | John         | Physics
13         | John         | Programming
-- b:
student_id | subject_name | attended_exams
------------------------------------------
1          | Math         | 3
1          | Physics      | 2
1          | Programming  | 1
2          | Math         | 1
2          | Programming  | 1
13         | Math         | 1
13         | Physics      | 1
13         | Programming  | 1

-- left join時,以 sutudent_id=1為例,b表有三筆,而當只有以sutudent_id做連結時,
-- a表的的第一筆sutudent_id=1就必須把b表的三筆都連結進去,因為b表的三筆的student_id都是1
-- 所以必須有第二個連結條件subject_name

--------------------------------------------------------------------------------------------

-- 1294.Weather Type in Each Country 不同國家的天氣類型

-- Table: Countries
-- +---------------+---------+
-- | Column Name   | Type    |
-- +---------------+---------+
-- | country_id    | int     |
-- | country_name  | varchar |
-- +---------------+---------+
-- country_id is the primary key for this table.
-- Each row of this table contains the ID and the name of one country.
 

-- Table: Weather
-- +---------------+---------+
-- | Column Name   | Type    |
-- +---------------+---------+
-- | country_id    | int     |
-- | weather_state | varchar |
-- | day           | date    |
-- +---------------+---------+
-- (country_id, day) is the primary key for this table.
-- Each row of this table indicates the weather state in a country for one day.
-- 此表的每一行表示一個國家一天的天氣狀況 

-- Write an SQL query to find the type of weather in each country for November 2019.
-- 查找每個國家在2019年11月的天氣類型

-- The type of weather is Cold if the "average" 'weather_state' is less than or equal 15,
-- 如果平均 weather_state 小於或等於 15，則天氣類型為 'Cold'
-- Hot if the average weather_state is greater than or equal 25 and Warm otherwise.
-- 如果平均 weather_state 大於或等於 25，則天氣類型為 'Hot'
-- Return result table in any order.

-- The query result format is in the following example:

-- Countries table:
-- +------------+--------------+
-- | country_id | country_name |
-- +------------+--------------+
-- | 2          | USA          |
-- | 3          | Australia    |
-- | 7          | Peru         |
-- | 5          | China        |
-- | 8          | Morocco      |
-- | 9          | Spain        |
-- +------------+--------------+

-- Weather table:
-- +------------+---------------+------------+
-- | country_id | weather_state | day        |
-- +------------+---------------+------------+
-- | 2          | 15            | 2019-11-01 |
-- | 2          | 12            | 2019-10-28 |
-- | 2          | 12            | 2019-10-27 |
-- | 3          | -2            | 2019-11-10 |
-- | 3          | 0             | 2019-11-11 |
-- | 3          | 3             | 2019-11-12 |
-- | 5          | 16            | 2019-11-07 |
-- | 5          | 18            | 2019-11-09 |
-- | 5          | 21            | 2019-11-23 |
-- | 7          | 25            | 2019-11-28 |
-- | 7          | 22            | 2019-12-01 |
-- | 7          | 20            | 2019-12-02 |
-- | 8          | 25            | 2019-11-05 |
-- | 8          | 27            | 2019-11-15 |
-- | 8          | 31            | 2019-11-25 |
-- | 9          | 7             | 2019-10-23 |
-- | 9          | 3             | 2019-12-23 |
-- +------------+---------------+------------+

-- Result table:
-- +--------------+--------------+
-- | country_name | weather_type |
-- +--------------+--------------+
-- | USA          | Cold         |
-- | Austraila    | Cold         |
-- | Peru         | Hot          |
-- | China        | Warm         |
-- | Morocco      | Hot          |
-- +--------------+--------------+

-- Average weather_state in USA in November is (15) / 1 = 15 so weather type is 'Cold'.
-- 美國11月的平均天氣狀態為（15）/ 1 = 15，因此天氣類型為'Cold'
-- Average weather_state in Austraila in November is (-2 + 0 + 3) / 3 = 0.333 so weather type is 'Cold'.
-- 11月在澳大利亞的平均天氣狀態為（-2 + 0 + 3）/ 3 = 0.333，因此天氣類型為'Cold'
-- Average weather_state in Peru in November is (25) / 1 = 25 so weather type is 'Hot'.
-- 秘魯在11月的平均weather_state為（25）/ 1 = 25，因此天氣類型為'Hot'
-- Average weather_state in China in November is (16 + 18 + 21) / 3 = 18.333 so weather type is 'Warm'.
-- 11月中國的平均天氣狀態為（16 + 18 + 21）/ 3 = 18.333，因此天氣類型為'Warm'
-- Average weather_state in Morocco in November is (25 + 27 + 31) / 3 = 27.667 so weather type is 'Hot'.
-- 摩洛哥11月的平均weather_state為（25 + 27 + 31）/ 3 = 27.667，因此天氣類型為'Hot'
-- We know nothing about average weather_state in Spain in November
-- 我們對11月份西班牙的平均天氣狀況一無所知
-- so we don't include it in the result table. 
-- 因此我們不將其包括在結果表中。

-- Solution
select c.country_name,
	case when avg(w.weather_state) <= 15 then 'Cold'
		when avg(w.weather_state) >= 25 then 'Hot'
	else 'Warm'
    end as weather_type
from weather w
left join countries c on w.country_id = c.country_id
where month(w.day) = 11
group by 1


-- Solution
-- Oracle
-- 判斷每個國家的天氣類型，其中溫度小於等於15，為'Cold'，溫度大於等於25，為'Hot'，其他溫度區間為'Warm'
SELECT C.COUNTRY_NAME,
CASE WHEN AVG(W.WEATHER_STATE) <= 15 THEN 'Cold'
     WHEN AVG(W.WEATHER_STATE) >= 25 THEN 'Hot'
     ELSE 'Warm'
     END AS WEATHER_TYPE,
     TRUNC(W.DAY, 'MONTH') "November 2019"
FROM WEATHER W JOIN COUNTRIES C
ON W.COUNTRY_ID = C.COUNTRY_ID
WHERE TRUNC(W.DAY, 'MONTH') = '2019-11-01' -- MONTH(月捨去)
GROUP BY C.COUNTRY_NAME, TRUNC(W.DAY, 'MONTH');

-----------------------------------------------------------------------------------------------

-- 1303.Find the Team Size 查詢團隊人數

-- Table: Employee
-- +---------------+---------+
-- | Column Name   | Type    |
-- +---------------+---------+
-- | employee_id   | int     |
-- | team_id       | int     |
-- +---------------+---------+
-- employee_id is the primary key for this table.
-- Each row of this table contains the ID of each employee and their respective team.
-- 每一行包含每個員工及其各自團隊的ID
-- Write an SQL query to find the team size of each of the employees.
-- 查找每個員工的團隊規模

-- Return result table in any order.

-- The query result format is in the following example:

-- Employee Table:
-- +-------------+------------+
-- | employee_id | team_id    |
-- +-------------+------------+
-- |     1       |     8      |
-- |     2       |     8      |
-- |     3       |     8      |
-- |     4       |     7      |
-- |     5       |     9      |
-- |     6       |     9      |
-- +-------------+------------+

-- Result table:
-- +-------------+------------+
-- | employee_id | team_size  |
-- +-------------+------------+
-- |     1       |     3      |
-- |     2       |     3      |
-- |     3       |     3      |
-- |     4       |     1      |
-- |     5       |     2      |
-- |     6       |     2      |
-- +-------------+------------+
-- Employees with Id 1,2,3 are part of a team with team_id = 8.
-- ID為 1,2,3 員工是與 TEAM_ID = 8 團隊的一部分
-- Employees with Id 4 is part of a team with team_id = 7.
-- 與ID 4 員工與 TEAM_ID = 7 團隊的一部分。
-- Employees with Id 5,6 are part of a team with team_id = 9.
-- 用編號 5,6 員工與 TEAM_ID = 9 團隊的一部分。

-- Solution 1
select e.employee_id, t.team_size
from employee e, (
	select team_id, count(team_id) as team_size
	from employee
	group by 1) t
where e.team_id = t.team_id

-- Solution 2
select e.employee_id, t.team_size
from employee e join
	(select team_id, count(team_id) as team_size
	from employee
	group by 1) t
on e.team_id = t.team_id


with a as (
	select team_id, count(team_id) as team_size
	from employee
	group by 1
)
select e.employee_id, a.team_size
from employee e, a
where e.team_id = a.team_id

----------------------------------------------------------------------------------------------

-- 1322.Ads Performance 廣告成效統計

-- Table: Ads
-- +---------------+---------+
-- | Column Name   | Type    |
-- +---------------+---------+
-- | ad_id         | int     |
-- | user_id       | int     |
-- | action        | enum    |
-- +---------------+---------+
-- (ad_id, user_id) is the primary key for this table.
-- Each row of this table contains the ID of an Ad, the ID of a user and the action taken by this user regarding this Ad.
-- 每一行都包含一個廣告的ID，一個用戶的ID以及該用戶對該廣告所採取的操作
-- The action column is an ENUM type of ('Clicked', 'Viewed', 'Ignored').
-- 操作列是ENUM類型（'單擊','查看','忽略'）

-- A company is running Ads and wants to calculate the performance of each Ad.
-- 一家公司正在投放廣告，並希望計算每個廣告的效果

-- Performance of the Ad is measured using Click-Through Rate (CTR) where:
-- 使用則（CTR）衡量廣告的效果，其中
-- CTR = (Ad total clicks / Ad total clicks + Ad total views) * 100

-- Write an SQL query to find the ctr of each Ad.
-- 編寫SQL查詢以找到每個廣告的點擊率

-- Round ctr to 2 decimal points.
-- 將ctr舍入到2個小數點
-- Order the result table by ctr in descending order and by ad_id in ascending order in case of a tie.
-- 按照 "ctr 降序" 對結果進行排序，在點擊率相同的情況下，則按 "ad_id按升序" 對結果表進行排序

-- The query result format is in the following example:

-- Ads table:
-- +-------+---------+---------+
-- | ad_id | user_id | action  |
-- +-------+---------+---------+
-- | 1     | 1       | Clicked |
-- | 2     | 2       | Clicked |
-- | 3     | 3       | Viewed  |
-- | 5     | 5       | Ignored |
-- | 1     | 7       | Ignored |
-- | 2     | 7       | Viewed  |
-- | 3     | 5       | Clicked |
-- | 1     | 4       | Viewed  |
-- | 2     | 11      | Viewed  |
-- | 1     | 2       | Clicked |
-- +-------+---------+---------+

-- Result table:
-- +-------+-------+
-- | ad_id | ctr   |
-- +-------+-------+
-- | 1     | 66.67 |
-- | 3     | 50.00 |
-- | 2     | 33.33 |
-- | 5     | 0.00  |
-- +-------+-------+

-- for ad_id = 1, ctr = (2/(2+1)) * 100 = 66.67
-- for ad_id = 2, ctr = (1/(1+2)) * 100 = 33.33
-- for ad_id = 3, ctr = (1/(1+1)) * 100 = 50.00
-- for ad_id = 5, ctr = 0.00, Note that ad_id = 5 has no clicks or views.
-- 請注意 ad_id = 5 沒有點擊或觀看次數。
-- Note that we don't care about Ignored Ads.
-- Result table is ordered by the ctr. in case of a tie we order them by ad_id

-- Solution 1
select a.ad_id, round(ifnull((b.clicked_count/c.count_sum)*100, 0), 2) as ctr
from ads a 
	left join
		(select ad_id, count(action) clicked_count
		from ads
		where action = 'Clicked' and action != 'Ignored'
		group by 1) b
    on a.ad_id = b.ad_id
    left join 
		(select ad_id, count(action) count_sum
		from ads
		where action != 'Ignored'
		group by 1) c
	on b.ad_id = c.ad_id
group by 1
order by 2 desc,1

-- Solution 2
with a1 as (
	select ad_id,
		sum(case when action in ('Clicked')
        then 1 else 0 end) as clicked
	from ads
    group by 1
),
a2 as (
	select ad_id,
		sum(case when action in ('Clicked', 'Viewed')
		then 1 else 0 end) as clicked
    from ads
    group by 1
)
select t.ad_id, round(ifnull((a1.clicked/a2.clicked)*100, 0), 2) as ctr
from ads t left join a1
on t.ad_id = a1.ad_id
left join a2
on a1.ad_id = a2.ad_id
group by 1
order by 2 desc, 1


-- Solution
-- Oracle
WITH T1 AS(
  -- 計算每一個AD的"點擊數"加總
  SELECT AD_ID, 
	SUM(CASE WHEN ACTION IN ('Clicked') THEN 1 ELSE 0 END) AS CLICKED
  FROM ADS
  GROUP BY AD_ID
),
T2 AS (
  -- 計算每一個AD的"點擊數"及"查看"的加總
  SELECT AD_ID,
	SUM(CASE WHEN ACTION IN ('Clicked','Viewed') THEN 1 ELSE 0 END) AS TOTAL
  FROM ADS
  GROUP BY AD_ID
)
SELECT T1.AD_ID, 
	NVL(ROUND(CLICKED / NULLIF(TOTAL, 0) * 100, 2), 0) AS CTR
FROM T1 JOIN T2
ON T1.AD_ID = T2.AD_ID
ORDER BY CTR DESC, AD_ID;

-- 語法為「NULLIF ( expression-1 , expression-2 )」
-- 當 expression-1 的值與 expression-2 的值相同時，便會回傳 NULL，其他的就會如實的回傳 expression-1

---------------------------------------------------------------------------------------------

-- 1327.List the Products Ordered in a Period 列出期間內訂購的產品

-- Table: Products
-- +------------------+---------+
-- | Column Name      | Type    |
-- +------------------+---------+
-- | product_id       | int     |
-- | product_name     | varchar |
-- | product_category | varchar |
-- +------------------+---------+
-- product_id is the primary key for this table.
-- This table contains data about the company's products.

-- Table: Orders
-- +---------------+---------+
-- | Column Name   | Type    |
-- +---------------+---------+
-- | product_id    | int     |
-- | order_date    | date    |
-- | unit          | int     |
-- +---------------+---------+
-- There is no primary key for this table. It may have duplicate rows.
-- product_id is a foreign key to Products table.
-- unit is the number of products ordered in order_date.

-- Write an SQL query to get the names of products with "greater than or equal to 100 units"
-- ordered in "February 2020" and their amount.
-- 查詢以獲取"2020年2月"訂購的"大於或等於100"個產品的'產品名稱及其數量'

-- Return result table in any order.

-- The query result format is in the following example: 

-- Products table:
-- +-------------+-----------------------+------------------+
-- | product_id  | product_name          | product_category |
-- +-------------+-----------------------+------------------+
-- | 1           | Leetcode Solutions    | Book             |
-- | 2           | Jewels of Stringology | Book             |
-- | 3           | HP                    | Laptop           |
-- | 4           | Lenovo                | Laptop           |
-- | 5           | Leetcode Kit          | T-shirt          |
-- +-------------+-----------------------+------------------+

-- Orders table:
-- +--------------+--------------+----------+
-- | product_id   | order_date   | unit     |
-- +--------------+--------------+----------+
-- | 1            | 2020-02-05   | 60       |
-- | 1            | 2020-02-10   | 70       |
-- | 2            | 2020-01-18   | 30       |
-- | 2            | 2020-02-11   | 80       |
-- | 3            | 2020-02-17   | 2        |
-- | 3            | 2020-02-24   | 3        |
-- | 4            | 2020-03-01   | 20       |
-- | 4            | 2020-03-04   | 30       |
-- | 4            | 2020-03-04   | 60       |
-- | 5            | 2020-02-25   | 50       |
-- | 5            | 2020-02-27   | 50       |
-- | 5            | 2020-03-01   | 50       |
-- +--------------+--------------+----------+

-- Result table:
-- +--------------------+---------+
-- | product_name       | unit    |
-- +--------------------+---------+
-- | Leetcode Solutions | 130     |
-- | Leetcode Kit       | 100     |
-- +--------------------+---------+

-- Products with product_id = 1 is ordered in February a total of (60 + 70) = 130.
-- Products with product_id = 2 is ordered in February a total of 80.
-- Products with product_id = 3 is ordered in February a total of (2 + 3) = 5.
-- Products with product_id = 4 was not ordered in February 2020.
-- Products with product_id = 5 is ordered in February a total of (50 + 50) = 100.

-- Solution
select t.product_name, sum(t.unit) unit
from (
	select p.product_id, p.product_name, o.order_date, o.unit
	from orders o left join products p
	on p.product_id = o.product_id
) t
where month(t.order_date) = 2
group by 1
having unit >= 100;

-- Solution
-- Oracle
SELECT P.PRODUCT_NAME, SUM(UNIT) "UNIT"
FROM ORDERS O JOIN PRODUCTS P
ON O.PRODUCT_ID = P.PRODUCT_ID
WHERE TRUNC(ORDER_DATE, 'MONTH') = '2020-02-01'
GROUP BY P.PRODUCT_NAME
HAVING SUM(UNIT) >= 100
ORDER BY "UNIT" DESC;

----------------------------------------------------------------------------------------------

-- 1350.Students With Invalid Departments 已不存在的科系中的學生

-- Table: Departments
-- +---------------+---------+
-- | Column Name   | Type    |
-- +---------------+---------+
-- | id            | int     |
-- | name          | varchar |
-- +---------------+---------+
-- id is the primary key of this table.
-- The table has information about the id of each department of a university.


-- Table: Students
-- +---------------+---------+
-- | Column Name   | Type    |
-- +---------------+---------+
-- | id            | int     |
-- | name          | varchar |
-- | department_id | int     |
-- +---------------+---------+
-- id is the primary key of this table.
-- The table has information about the id of each student at a university and the id of the department he/she studies at.

-- Write an SQL query to find the id and the name of all students who are enrolled in departments that no longer exists.
-- 查找已不存在的系中所有已註冊學生的ID和名稱。

-- Return the result table in any order.

-- The query result format is in the following example:

-- Departments table:
-- +------+--------------------------+
-- | id   | name                     |
-- +------+--------------------------+
-- | 1    | Electrical Engineering   |
-- | 7    | Computer Engineering     |
-- | 13   | Bussiness Administration |
-- +------+--------------------------+

-- Students table:
-- +------+----------+---------------+
-- | id   | name     | department_id |
-- +------+----------+---------------+
-- | 23   | Alice    | 1             |
-- | 1    | Bob      | 7             |
-- | 5    | Jennifer | 13            |
-- | 2    | John     | 14            |
-- | 4    | Jasmine  | 77            |
-- | 3    | Steve    | 74            |
-- | 6    | Luis     | 1             |
-- | 8    | Jonathan | 7             |
-- | 7    | Daiana   | 33            |
-- | 11   | Madelynn | 1             |
-- +------+----------+---------------+


-- Result table:
-- +------+----------+
-- | id   | name     |
-- +------+----------+
-- | 2    | John     |
-- | 7    | Daiana   |
-- | 4    | Jasmine  |
-- | 3    | Steve    |
-- +------+----------+

-- John, Daiana戴安娜, Steve and Jasmine are enrolled(註冊) in departments 14, 33, 74 and 77 respectively(分別).
-- department 14, 33, 74 and 77 doesn't exist in the Departments table.


select s.id, s.name
from students s left join departments d
on s.department_id = d.id
where s.department_id not in (select id from departments)


-- Wrong Solution
-- 這樣是inner join, 只取有交集的欄,所以會沒有答案
-- 應該用left join, 這樣沒有交集的會是null
select s.id, s.name
from students s, departments d
where s.department_id = d.id
and s.department_id not in (select id from departments)

-------------------------------------------------------------------------------------------

-- 1378.Replace Employee ID With The Unique Identifier
-- 用唯一的識別替換員工ID

-- Table: Employees
-- +---------------+---------+
-- | Column Name   | Type    |
-- +---------------+---------+
-- | id            | int     |
-- | name          | varchar |
-- +---------------+---------+
-- id is the primary key for this table.
-- Each row of this table contains the id and the name of an employee in a company.

-- Table: EmployeeUNI
-- +---------------+---------+
-- | Column Name   | Type    |
-- +---------------+---------+
-- | id            | int     |
-- | unique_id     | int     |
-- +---------------+---------+
-- (id, unique_id) is the primary key for this table.
-- Each row of this table contains the id and the corresponding unique id of an employee in the company.

-- Write an SQL query to show the unique ID of each user, If a user doesn't have a unique ID replace just show null.
-- Return the result table in any order.
-- 查詢以顯示每個用戶的unique ID，如果用戶沒有unique ID，則替換為null，以任何順序返回結果表。

-- Employees table:
-- +----+----------+
-- | id | name     |
-- +----+----------+
-- | 1  | Alice    |
-- | 7  | Bob      |
-- | 11 | Meir     |
-- | 90 | Winston  |
-- | 3  | Jonathan |
-- +----+----------+


-- EmployeeUNI table:
-- +----+-----------+
-- | id | unique_id |
-- +----+-----------+
-- | 3  | 1         |
-- | 11 | 2         |
-- | 90 | 3         |
-- +----+-----------+

-- The query result format is in the following example:
-- +-----------+----------+
-- | unique_id | name     |
-- +-----------+----------+
-- | null      | Alice    |
-- | null      | Bob      |
-- | 2         | Meir     |
-- | 3         | Winston  |
-- | 1         | Jonathan |
-- +-----------+----------+
-- Alice and Bob don't have a unique ID, We will show null instead.
-- The unique ID of Meir is 2.
-- The unique ID of Winston is 3.
-- The unique ID of Jonathan is 1.


select uni.unique_id, e.name
from employees e left join employeeuni uni
on e.id = uni.id

----------------------------------------------------------------------------------------

-- 1407.Top Travellers

-- Table: Users
-- +---------------+---------+
-- | Column Name   | Type    |
-- +---------------+---------+
-- | id            | int     |
-- | name          | varchar |
-- +---------------+---------+
-- id is the primary key for this table.
-- name is the name of the user. 


-- Table: Rides
-- +---------------+---------+
-- | Column Name   | Type    |
-- +---------------+---------+
-- | id            | int     |
-- | user_id       | int     |
-- | distance      | int     |
-- +---------------+---------+
-- id is the primary key for this table.
-- user_id is the id of the user who travelled the distance "distance".
-- user_id 用戶編號，distance 是該用戶行駛的距離


-- Write an SQL query to report the distance travelled by each user.

-- Return the result table ordered by travelled_distance in descending order, 
-- if two or more users travelled the same distance, order them by their name in ascending order.

-- 查詢以報告每個用戶的行進距離，查詢結果按 travelled_distance 降序排列，如果兩個或多個用戶旅行相同的距離，請按其名稱(name) 升序排列。

-- The query result format is in the following example. 

-- Users table:
-- +------+-----------+
-- | id   | name      |
-- +------+-----------+
-- | 1    | Alice     |
-- | 2    | Bob       |
-- | 3    | Alex      |
-- | 4    | Donald    |
-- | 7    | Lee       |
-- | 13   | Jonathan  |
-- | 19   | Elvis     |
-- +------+-----------+
  
  
-- Rides table:
-- +------+----------+----------+
-- | id   | user_id  | distance |
-- +------+----------+----------+
-- | 1    | 1        | 120      |
-- | 2    | 2        | 317      |
-- | 3    | 3        | 222      |
-- | 4    | 7        | 100      |
-- | 5    | 13       | 312      |
-- | 6    | 19       | 50       |
-- | 7    | 7        | 120      |
-- | 8    | 19       | 400      |
-- | 9    | 7        | 230      |
-- +------+----------+----------+


-- Result table:
-- +----------+--------------------+
-- | name     | travelled_distance |
-- +----------+--------------------+
-- | Elvis    | 450                |
-- | Lee      | 450                |
-- | Bob      | 317                |
-- | Jonathan | 312                |
-- | Alex     | 222                |
-- | Alice    | 120                |
-- | Donald   | 0                  |
-- +----------+--------------------+

-- Elvis and Lee travelled 450 miles, Elvis is the top traveller as his name is alphabetically smaller than Lee.
-- Bob, Jonathan, Alex and Alice have only one ride and we just order them by the total distances of the ride.
-- Donald didn't have any rides, the distance travelled by him is 0.
-- Elvis和Lee走了450英里，Elvis是排名最高的旅行者，因為他的名字順序靠前。
-- Bob，Jonathan，Alex和Alice都只有一次旅行，我們只是按照總距離對他們進行排序。
-- Donald沒有旅行，他的行進距離是0。


-- Solution
select u.name, ifnull(sum(r.distance), 0) as travlled_distance
from users u left join rides r
on u.id = r.user_id
group by 1
order by 2 desc, 1


-- Solution
-- Oracle
SELECT U.NAME,
	NVL(SUM(R.DISTANCE), 0) AS TRAVELLED_DISTANCE 
FROM USERS U LEFT JOIN RIDES R
ON R.USER_ID = U.ID
GROUP BY NAME
ORDER BY TRAVELLED_DISTANCE DESC, NAME;

--------------------------------------------------------------------------------------------

-- 1484.Group Sold Products By The Date

-- Table Activities:
-- +-------------+---------+
-- | Column Name | Type    |
-- +-------------+---------+
-- | sell_date   | date    |
-- | product     | varchar |
-- +-------------+---------+
-- There is no primary key for this table, it may contains duplicates.
-- Each row of this table contains the product name and the date it was sold in a market.
-- 該表的每一行都包含產品名稱和在市場上出售的日期。

-- Write an SQL query to find for each date, the number of "distinct products" 'sold' and their 'names'.
-- 查找每個日期，所售"不同產品"的'數量'及其'名稱'

-- The sold-products names for each date should be sorted lexicographically. 
-- 每個日期的已售產品名稱應按字典順序排序

-- Return the result table ordered by sell_date.
-- 返回按Sell_date排序的結果

-- The query result format is in the following example.

-- Activities table:
-- +------------+-------------+
-- | sell_date  | product     |
-- +------------+-------------+
-- | 2020-05-30 | Headphone   |
-- | 2020-06-01 | Pencil      |
-- | 2020-06-02 | Mask        |
-- | 2020-05-30 | Basketball  |
-- | 2020-06-01 | Bible       |
-- | 2020-06-02 | Mask        |
-- | 2020-05-30 | T-Shirt     |
-- +------------+-------------+

-- Result table:
-- +------------+----------+------------------------------+
-- | sell_date  | num_sold | products                     |
-- +------------+----------+------------------------------+
-- | 2020-05-30 | 3        | Basketball,Headphone,T-shirt |
-- | 2020-06-01 | 2        | Bible,Pencil                 |
-- | 2020-06-02 | 1        | Mask                         |
-- +------------+----------+------------------------------+
-- For 2020-05-30, Sold items were (Headphone, Basketball, T-shirt), we sort them lexicographically and separate them by comma.
-- 我們按字典順序對它們進行排序，並用逗號分隔它們。
-- For 2020-06-01, Sold items were (Pencil, Bible), we sort them lexicographically and separate them by comma.
-- For 2020-06-02, Sold item is (Mask), we just return it.


-- Solution
select sell_date, count(distinct product) as num_sold,
		group_concat(distinct product) as products
from activities
group by 1
order by 1


-- Solution
-- Oracle 19c and later
SELECT SELL_DATE, COUNT(DISTINCT PRODUCT) NUM_SOLD,
	LISTAGG(DISTINCT PRODUCT, ',') WITHIN GROUP (ORDER BY PRODUCT)
FROM　ACTIVITIES
GROUP BY SELL_DATE
ORDER BY SELL_DATE;

-- Oracle 18c and earlier
WITH SELL_DATE_ACT AS (
  SELECT DISTINCT SELL_DATE, PRODUCT
  FROM　ACTIVITIES  
  ORDER BY SELL_DATE, PRODUCT
)
SELECT SELL_DATE, COUNT(PRODUCT) NUM_SOLD,
	LISTAGG(PRODUCT, ',') WITHIN GROUP (ORDER BY PRODUCT) 
FROM　SELL_DATE_ACT
GROUP BY SELL_DATE
ORDER BY SELL_DATE;

--------------------------------------------------------------------------------------------

-- 1495.Friendly Movies Streamed Last Month 上個月播放的兒童電影

-- Table: TVProgram
-- +---------------+---------+
-- | Column Name   | Type    |
-- +---------------+---------+
-- | program_date  | date    |
-- | content_id    | int     |
-- | channel       | varchar |
-- +---------------+---------+
-- (program_date, content_id) is the primary key for this table.
-- This table contains information of the programs on the TV.
-- content_id is the id of the program on some channels on the TV.


-- Table: Content
-- +---------------+---------+
-- | Column Name   | Type    |
-- +---------------+---------+
-- | content_id    | int     |
-- | title         | varchar |
-- | Kids_content  | enum    |
-- | content_type  | varchar |
-- +---------------+---------+
-- content_id is the primary key for this table.
-- Kids_content is an enum that takes one of the values ('Y', 'N') 
-- where:'Y' means is content for kids otherwise 'N' is not content for kids.
-- 'Y'表示內容適合小孩，'N'表示內容不適合小孩
-- content_type is the category of the content as movies, series, etc.
-- content_type 是內容的類別，例如電影，連續劇等


-- Write an SQL query to report the "distinct titles" of the 'kid-friendly' movies streamed in 'June 2020'.
-- 查詢以2020年6月播放的兒童電影的不同標題

-- Return the result table in any order.

-- TVProgram table:
-- +--------------------+--------------+-------------+
-- | program_date       | content_id   | channel     |
-- +--------------------+--------------+-------------+
-- | 2020-06-10 08:00   | 1            | LC-Channel  |
-- | 2020-05-11 12:00   | 2            | LC-Channel  |
-- | 2020-05-12 12:00   | 3            | LC-Channel  |
-- | 2020-05-13 14:00   | 4            | Disney Ch   |
-- | 2020-06-18 14:00   | 4            | Disney Ch   |
-- | 2020-07-15 16:00   | 5            | Disney Ch   |
-- +--------------------+--------------+-------------+


-- Content table:
-- Series(系列)
-- +------------+----------------+---------------+---------------+
-- | content_id | title          | Kids_content  | content_type  |
-- +------------+----------------+---------------+---------------+
-- | 1          | Leetcode Movie | N             | Movies        |
-- | 2          | Alg. for Kids  | Y             | Series        |
-- | 3          | Database Sols  | N             | Series        |
-- | 4          | Aladdin        | Y             | Movies        |
-- | 5          | Cinderella     | Y             | Movies        |
-- +------------+----------------+---------------+---------------+

-- The query result format is in the following example. 
-- Result table:
-- +--------------+
-- | title        |
-- +--------------+
-- | Aladdin      |
-- +--------------+
-- "Leetcode Movie" is not a content for kids.
-- "Leetcode Movie" 不是兒童內容
-- "Alg. for Kids" is not a movie.
-- "Alg. for Kids" 不是電影。
-- "Database Sols" is not a movie
-- "Database Sols" 不是電影
-- "Alladin" is a movie, content for kids and was streamed in June 2020.
-- "阿拉丁" 是一部兒童的電影，於 2020 年 6 月播出
-- "Cinderella" was not streamed in June 2020.
-- "灰姑娘" 於 2020 年 6 月未播出。


select C.title
from TVProgram T, Content C
where T.content_id = C.content_id
and C.Kids_content = "Y"
and C.content_type = "Movies"
and month(T.program_date) = 6;


-- Solution
-- Oracle
SELECT DISTINCT C.TITLE, TRUNC(PROGRAM_DATE, 'MONTH') TRUNC_MONTH
FROM CONTENT C JOIN TVPROGRAM T
ON C.CONTENT_ID = T.CONTENT_ID
WHERE KIDS_CONTENT = 'Y' AND CONTENT_TYPE = 'Movies'
AND TRUNC(PROGRAM_DATE, 'MONTH') = '2020-06-01';

----------------------------------------------------------------------------------------------

-- 1511.Customer Order Frequency

--  Table: Customers
--  +---------------+---------+
--  | Column Name   | Type    |
--  +---------------+---------+
--  | customer_id   | int     |
--  | name          | varchar |
--  | country       | varchar |
--  +---------------+---------+
--  customer_id is the primary key for this table.
--  This table contains information of the customers in the company.
--  
--  Table: Product
--  +---------------+---------+
--  | Column Name   | Type    |
--  +---------------+---------+
--  | product_id    | int     |
--  | description   | varchar |
--  | price         | int     |
--  +---------------+---------+
--  product_id is the primary key for this table.
--  This table contains information of the products in the company.
--  price is the product cost.
--  
--  
--  
--  Table: Orders
--  +---------------+---------+
--  | Column Name   | Type    |
--  +---------------+---------+
--  | order_id      | int     |
--  | customer_id   | int     |
--  | product_id    | int     |
--  | order_date    | date    |
--  | quantity      | int     |
--  +---------------+---------+
--  order_id is the primary key for this table.
--  This table contains information on customer orders.
--  customer_id is the id of the customer who bought "quantity" products with id "product_id".
--  customer_id 是購買了 ID 為 "product_id" 的 "數量" 產品的客戶的 ID
--  Order_date is the date in format ('YYYY-MM-DD') when the order was shipped.
--  Order_date 是訂單出貨時格式 ('YYYY-MM-DD') 的日期。

-- Write an SQL query to report the customer_id and customer_name of customers who have spent at least $100 in each month of June and July 2020.
-- 2020年 6月 和 7月 的每個月至少花費 100 美元的客戶的 customer_id 和 customer_name

--  Return the result table in any order.

--  The query result format is in the following example.
--  Customers
--  +--------------+-----------+-------------+
--  | customer_id  | name      | country     |
--  +--------------+-----------+-------------+
--  | 1            | Winston   | USA         |
--  | 2            | Jonathan  | Peru        |
--  | 3            | Moustafa  | Egypt       |
--  +--------------+-----------+-------------+

--  Product
--  +--------------+-------------+-------------+
--  | product_id   | description | price       |
--  +--------------+-------------+-------------+
--  | 10           | LC Phone    | 300         |
--  | 20           | LC T-Shirt  | 10          |
--  | 30           | LC Book     | 45          |
--  | 40           | LC Keychain | 2           |
--  +--------------+-------------+-------------+

--  Orders
--  +--------------+-------------+-------------+-------------+-----------+
--  | order_id     | customer_id | product_id  | order_date  | quantity  |
--  +--------------+-------------+-------------+-------------+-----------+
--  | 1            | 1           | 10          | 2020-06-10  | 1         |
--  | 2            | 1           | 20          | 2020-07-01  | 1         |
--  | 3            | 1           | 30          | 2020-07-08  | 2         |
--  | 4            | 2           | 10          | 2020-06-15  | 2         |
--  | 5            | 2           | 40          | 2020-07-01  | 10        |
--  | 6            | 3           | 20          | 2020-06-24  | 2         |
--  | 7            | 3           | 30          | 2020-06-25  | 2         |
--  | 9            | 3           | 30          | 2020-05-08  | 3         |
--  +--------------+-------------+-------------+-------------+-----------+

--  Result table:
--  +--------------+------------+
--  | customer_id  | name       |  
--  +--------------+------------+
--  | 1            | Winston    |
--  +--------------+------------+ 
--  Winston spent $300 (300 * 1) in June and $100 ( 10 * 1 + 45 * 2) in July 2020.
--  Jonathan spent $600 (300 * 2) in June and $20 ( 2 * 10) in July 2020.
--  Moustafa spent $110 (10 * 2 + 45 * 2) in June and $0 in July 2020.


-- Solution
-- 這題將符合條件的customer_id按月先篩選出,然後再篩選同時有出現在6,7月的customer_id
-- 如果先將6,7月的join成一個表格,那在之後用customer_id做group by時(因為要sum金額)
-- 會將6,7月的都group by 一起
select customer_id, name
from customers
where customer_id in (
	select o.customer_id
	from orders o left join product p
	on o.product_id = p.product_id
	where month(o.order_date) = 6
	group by o.customer_id
	having sum(o.quantity*p.price) >= 100)
and customer_id in (
	select o.customer_id
	from orders o left join product p
	on o.product_id = p.product_id
	where month(o.order_date) = 7
	group by o.customer_id
	having sum(o.quantity*p.price) >= 100)

---------------------------------------------------------------------------------------------

-- 1517.Find Users With Valid E-Mails

--  Table: Users
--  +---------------+---------+
--  | Column Name   | Type    |
--  +---------------+---------+
--  | user_id       | int     |
--  | name          | varchar |
--  | mail          | varchar |
--  +---------------+---------+
--  user_id is the primary key for this table.
--  This table contains information of the users signed up in a website. Some e-mails are invalid.
-- 此表包含在網站上註冊的用戶的信息。一些電子郵件無效。

--  Write an SQL query to find the users who have valid emails.
-- 查找擁有有效電子郵件的用戶
  
-- A valid e-mail has a "prefix name" and a "domain" where:
-- The prefix name is a string that may contain letters (upper or lower case), digits, 
-- 前綴名稱是一個"字符串"，可能包含字母（大寫或小寫）、數字、
-- underscore '_', period '.' and/ or dash '-'. The prefix name must start with a letter.
-- 下劃線'_'、句點'.'和/ 或 破折號'-'。前綴名稱必須以字母開頭
-- The domain is '@leetcode.com'.
-- 網域是 '@leetcode.com'

-- Return the result table in any order.
 
--  The query result format is in the following example.
--  Users
--  +---------+-----------+-------------------------+
--  | user_id | name      | mail                    |
--  +---------+-----------+-------------------------+
--  | 1       | Winston   | winston@leetcode.com    |
--  | 2       | Jonathan  | jonathanisgreat         |
--  | 3       | Annabelle | bella-@leetcode.com     |
--  | 4       | Sally     | sally.come@leetcode.com |
--  | 5       | Marwan    | quarz#2020@leetcode.com |
--  | 6       | David     | david69@gmail.com       |
--  | 7       | Shapiro   | .shapo@leetcode.com     |
--  +---------+-----------+-------------------------+


--  Result table:
--  +---------+-----------+-------------------------+
--  | user_id | name      | mail                    |
--  +---------+-----------+-------------------------+
--  | 1       | Winston   | winston@leetcode.com    |
--  | 3       | Annabelle | bella-@leetcode.com     |
--  | 4       | Sally     | sally.come@leetcode.com |
--  +---------+-----------+-------------------------+

-- The mail of user 2 doesn't have a domain.
-- 用戶2的郵件沒有網域
-- The mail of user 5 has # sign which is not allowed.
-- 用戶5的郵件帶有＃號，這是不允許的
-- The mail of user 6 doesn't have leetcode domain.
-- 用戶6的郵件沒有 leetcode 網域
-- The mail of user 7 starts with a period.
-- 用戶7的郵件以句點開頭


-- Solution
-- ^：表示字符串的開始。
-- [a-zA-Z]+：匹配一個或多個字母（大寫或小寫）。[a-zA-Z] 表示字母範圍，+ 表示至少出現一次。
-- [a-zA-Z0-9_\\./\\-]{0,}：匹配任意長度的字母、數字、下劃線（_）、點（.）、斜杠（/）或連字符（-）。{0,} 表示可以出現零次或多次。
-- @leetcode\\.com：匹配字符串 @leetcode.com。因為點（.）在正則表達式中有特殊含義，所以需要使用反斜杠（\\）進行轉義，變成 \\.com。
-- $：表示字符串的結束。
select * from users
where mail regexp'^[a-zA-Z]+[a-zA-Z0-9_./-]{0,}@leetcode\\.com$'

-- Solution
-- Oracle
-- 語法規則：https://docs.oracle.com/cd/B19306_01/B14251_01/adfns_regexp.htm
SELECT * FROM USERS
WHERE REGEXP_LIKE(MAIL, '^[A-Za-z]+[A-Za-z0-9_./-]*@leetcode.com$');

-- MySQL
-- 語法規則：https://www.runoob.com/mysql/mysql-regexp.html
--  ^ 表示開頭
--  + 符合一個或多個,不包括空值
--  * 符合零個或多個
--  [] 表示集合裡的任意一個
--  \\ 用於轉譯特殊字符
--  a{m,n} 符合 m 到 n 個 a，左側不寫為0，右側不寫為任意
--  $ 表示以什麼為結尾














