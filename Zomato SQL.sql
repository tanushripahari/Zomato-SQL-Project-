 --- Zomato SQL Poject ----
--- 1. What is the total amount each customer spent on zomato?
SELECT S.userid, SUM(p.price) As Total_Amount_Spent from sales AS S join product As p on S.product_id = P.product_id GROUP BY
S.userid;

--- 2. How many days has each customer visited zomato?
SELECT userid, COUNT (DISTINCT created_date) AS Visited_Count from sales GROUP BY userid

-- 3. What was the first product purchased by each of the customer?
SELECT * from (
SELECT *,RANK() OVER(PARTITION by userid ORDER by created_date) as Ranking from sales) s where Ranking = 1

--- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?


SELECT userid, COUNT(product_id) As Purchased_count from sales where product_id = (
SELECT  product_id from sales group By product_id ORDER by COUNT(product_id) DESC LIMIT 1
) GROUP by userid


--- 5.  Which item was the most popular for each customer?
SELECT * FROm (
SELECT *,rank() over (PARTITION by userid ORDER  by product_count DESC) AS RANKING from(
SELECT userid , product_id , count(product_id) As product_count from sales group by userid, product_id order by count(product_id) DESC
) RANKING ) a where RANKING = 1


--- 6.which item was purchased first by customer after they become a member ?
SELECT * FROM (
  SELECT m.*,rank() over(partition by userid order by created_date) ranking from(
SELECT s.userid,s.created_date,s.product_id,g.gold_signup_date FROM sales As s INNER JOIN goldusers_signup AS g on s.userid=g.userid
and created_date >= gold_signup_date) m
) cus  where ranking = 1


--- 7. which item was purchased just before the customer became a member?
SELECT * FROM (
  SELECT m.*,rank() over(partition by userid order by created_date DESC) ranking from(
SELECT s.userid,s.created_date,s.product_id,g.gold_signup_date FROM sales As s INNER JOIN goldusers_signup AS g on s.userid=g.userid
and created_date <= gold_signup_date) m
) cus  where ranking = 1

--- 8. what is total orders and amount spent for each member before they become a member?

SELECT userid, COUNT(created_date) Order_purchased, SUM(price) total_amount_spent from
(SELECT b.*, c.price FROM
(SELECT s.userid,s.created_date,s.product_id,g.gold_signup_date FROM sales As s INNER JOIN goldusers_signup AS g on s.userid=g.userid
and created_date <= gold_signup_date) b INNER JOIN Product c ON b.product_id=c.product_id) u GROUP By userid

--- 9. If buying each product generates points for eg 5rs=2 zomato point and each product has different purchasing points for eg for p1 5rs=1 zomato point,for p2 10rs=zomato point and p3 5rs=1 zomato point 2rs =1zomato point, calculate points collected by each customer and for which product most points have been given till now.

SELECT r.*, (total_amount/ points) as Total_points_earned from (
SELECT h.*, case when product_id = 1 then 5
 when product_id = 2 then 2 when product_id = 3 then 5  else 0 end as points from
 (SELECT tn.userid, tn.product_id, sum(price) Total_amount FROM (
SELECT s.userid,l.product_id,l.price from sales s inner join product l on s.product_id=l.product_id
) tn GROUP by userid,product_id ) h ) r

-- calculate points collected by each customer and amount earned
 SELECT userid, sum(total_points_earned) as user_points, sum(total_points_earned) * 2.5 as Total_amount_earned  from (
 SELECT r.*, (total_amount/ points) as Total_points_earned from (
SELECT h.*, case when product_id = 1 then 5
 when product_id = 2 then 2 when product_id = 3 then 5  else 0 end as points from
 (SELECT tn.userid, tn.product_id, sum(price) Total_amount FROM (
SELECT s.userid,l.product_id,l.price from sales s inner join product l on s.product_id=l.product_id
) tn GROUP by userid,product_id ) h ) r ) u group by userid

--for which product most points have been given till now.
SELECT * from (
 SELECT kl.*, RANK() over(order by product_points DESC) as rnk from
 (SELECT product_id, sum(total_points_earned) product_points from (
 SELECT r.*, (total_amount/ points) as Total_points_earned from (
SELECT h.*, case when product_id = 1 then 5
 when product_id = 2 then 2 when product_id = 3 then 5  else 0 end as points from
 (SELECT tn.userid, tn.product_id, sum(price) Total_amount FROM (
SELECT s.userid,l.product_id,l.price from sales s inner join product l on s.product_id=l.product_id
) tn GROUP by userid,product_id ) h ) r ) u group by product_id) kl) e where rnk = 1
 

---10. In the first year after a customer joins the gold program (including the join date ) irrespective of what customer has purchased earn 5 zomato points for every 10rs spent who earned more more 1 or 3 what int earning in first yr ? 1zp = 2rs

SELECT t.*,pd.price * 0.5 from(
(
  SELECT s.userid,s.created_date,s.product_id,g.gold_signup_date FROM sales As s INNER JOIN goldusers_signup AS g on s.userid=g.userid
and created_date >= gold_signup_date and created_date <=  DATEADD(year,1,gold_signup_date)) t INNER JOIN product pd on t.product_id=pd.product_id
)

--> 11. Ranking all the transaction of the customers 


SELECT *, RANK() OVER(PARTITION BY userid ORDER BY created_date) AS RANKING  from sales

--> 12. Ranking all transaction for each member whenever they are zomato gold member for every non gold member transaction mark as na 

SELECT t.*, case when RANKING = 0 THEN 'NA' ELSE RANKING END AS RNK_TRANSACTION FROM (
select e.*, CAST((CASE WHEN gold_signup_date IS NULL THEN 0 ELSE RANK() OVER(PARTITION BY userid ORDER BY created_date DESC) END ) AS VARCHAR) AS RANKING FROM (
SELECT s.userid,s.created_date,s.product_id,g.gold_signup_date FROM sales As s LEFT JOIN goldusers_signup AS g on s.userid=g.userid
and created_date >= gold_signup_date) e) t
