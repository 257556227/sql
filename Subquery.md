###  [1978. 上级经理已离职的公司员工](https://leetcode.cn/problems/employees-whose-manager-left-the-company/)

```mysql
select employee_id from Employees 
where salary < 30000 and
manager_id not in (select employee_id from Employees)
order by employee_id ASC;
```

### [626. 换座位](https://leetcode.cn/problems/exchange-seats/)

奇数返回id+1的学生姓名，偶数返回id-1的学生姓名

若是最后一列且是奇数则返回该id对应的学生姓名

这三个条件用`case when when else`并列即可

学生姓名需要借助 inner join得到最后一位的id（count）

```mysql
select id,
(
    case
    	when id = c.last and mod(id, 2) = 1 then (select student from Seat where id = c.last)
        when mod(id, 2) = 1 then (select student from Seat where id = s.id+1)
    	else (select student from Seat where id = s.id-1) 
    end
) as student
from Seat s
inner join
(select count(*) as last from Seat) as c;
```

### [1321. 餐馆营业额变化增长](https://leetcode.cn/problems/restaurant-growth/)

1、纯用自连接去解决

① 首先找出一共有哪些日期有顾客访问`>= (SELECT min( visited_on ) FROM customer ) + 6`

② 其次将该表a，与customer表b全连接，连接条件为a表的visited_on比b表大不超过6天，即可以作为输出结果的这些天，一周内涉及到了哪些交易记录。`( SELECT DISTINCT visited_on FROM customer ) a JOIN customer b 
 	ON datediff( a.visited_on, b.visited_on ) BETWEEN 0 AND 6 `

③ 根据表a的这些日期分组，对其连接到的符合条件的表b的金额进行聚合计算，并根据表a日期升序排列（默认ASC）

```mysql
SELECT
	a.visited_on,
	sum( b.amount ) AS amount,
	round(sum( b.amount ) / 7, 2 ) AS average_amount 
FROM
	( SELECT DISTINCT visited_on FROM customer ) a JOIN customer b 
 	ON datediff( a.visited_on, b.visited_on ) BETWEEN 0 AND 6 
WHERE
	a.visited_on >= (SELECT min( visited_on ) FROM customer ) + 6 
GROUP BY
	a.visited_on
ORDER BY
  a.visited_on;
```

2. 利用窗口函数

```mysql
SELECT DISTINCT visited_on,
       sum_amount AS amount, 
       ROUND(sum_amount/7, 2) AS average_amount
FROM (
    SELECT visited_on, SUM(amount) OVER ( ORDER BY visited_on RANGE interval 6 day preceding  ) AS sum_amount 
    FROM Customer) t
-- 最后手动地从第7天开始
WHERE DATEDIFF(visited_on, (SELECT MIN(visited_on) FROM Customer)) >= 6;
```

### [1341. 电影评分](https://leetcode.cn/problems/movie-rating/)

在一个影评数据库中，我们需要找到两件事情：

评价电影数量最多的用户；
在2020年2月份平均评分最高的电影。
为了解决这个问题，我们需要编写两个子查询，然后使用UNION ALL将它们的结果合并在一起。

```mysql
(
select u.name as results
from MovieRating m
join Users u
on m.user_id = u.user_id
group by m.user_id
order by count(distinct movie_id) desc, name
limit 0,1
)
union all
(
select m.title as results
from MovieRating mr
join
Movies m
on mr.movie_id = m.movie_id
where created_at between '2020-02-01' and '2020-02-29'
group by m.movie_id
order by avg(mr.rating) desc, title
limit 0,1
);
```

### [602. 好友申请 II ：谁有最多的好友](https://leetcode.cn/problems/friend-requests-ii-who-has-the-most-friends/)

union all 将具有相同的数据类型，列的数量也必须相同的id合并成一列，再统计数量

```mysql
select id, count(id) num from 
(
    (select accepter_id id
    from RequestAccepted)
    union all
    (select requester_id id
    from RequestAccepted)
) u
group by id
order by num desc
limit 0,1;
```

### [585. 2016年的投资](https://leetcode.cn/problems/investments-in-2016/)

第一次自连接获取tiv_2015有相同值的pid

第二次自连接获取位置不同的pid

```mysql
select round(sum(distinct i1.tiv_2016), 2) tiv_2016
from Insurance i1
inner join
Insurance i2
on i1.tiv_2015 = i2.tiv_2015
where i1.pid <> i2.pid and i1.pid not in(
    select distinct i1.pid
    from Insurance i1
    inner join
    Insurance i2
    on i1.pid <> i2.pid and i1.lon = i2.lon and i1.lat = i2.lat
);
```

也可以用`GROUP BY` 和 `COUNT`

检查每一个 **TIV_2015** 是否是唯一的，如果不是唯一的且同时坐标是唯一的，那么这条记录就符合题目要求。应该被统计到答案中。

```mysql
SELECT
    ROUND(SUM(insurance.TIV_2016), 2) AS TIV_2016
FROM
    insurance
WHERE
    insurance.TIV_2015 IN
    (
      SELECT
        TIV_2015
      FROM
        insurance
      GROUP BY TIV_2015
      HAVING COUNT(*) > 1 #巧妙将tiv相同变成count>1
    )
    AND CONCAT(LAT, LON) IN #concat两个作为一个条件
    (
      SELECT
        CONCAT(LAT, LON)
      FROM
        insurance
      GROUP BY LAT , LON
      HAVING COUNT(*) = 1 #同理，只有1个则cnt=1
    )
;
```

注意：这两条要求**需要不分顺序同时满足**，所以如果你想要先用规则 1 来筛选一遍数据，然后再用规则 2 来筛选，会得到错误的结果。

### [185. 部门工资前三高的所有员工](https://leetcode.cn/problems/department-top-three-salaries/)

找出公司里前 3 高的薪水，意思是不超过三个值比这些值大

-- 解题的核心是两表自关联，算出工资比自己高的人有几个，工资比自己高的人数为0，自己就是第一名

-- 工资比自己高的人有一个，自己是第二名，工资比自己高的人有两个自己就是第三名，所以取比自己工资高的人小于3就是取的前三名的人

```mysql
SELECT e1.Salary 
FROM Employee AS e1
WHERE 3 > 
		(SELECT  count(DISTINCT e2.Salary) 
		 FROM	Employee AS e2 
	 	 WHERE	e1.Salary < e2.Salary 	AND e1.DepartmentId = e2.DepartmentId) ;
```

举个栗子：
当 e1 = e2 = [4,5,6,7,8]

e1.Salary = 4，e2.Salary 可以取值 [5,6,7,8]，count(DISTINCT e2.Salary) = 4

e1.Salary = 5，e2.Salary 可以取值 [6,7,8]，count(DISTINCT e2.Salary) = 3

e1.Salary = 6，e2.Salary 可以取值 [7,8]，count(DISTINCT e2.Salary) = 2

e1.Salary = 7，e2.Salary 可以取值 [8]，count(DISTINCT e2.Salary) = 1

e1.Salary = 8，e2.Salary 可以取值 []，count(DISTINCT e2.Salary) = 0

最后 3 > count(DISTINCT e2.Salary)，所以 e1.Salary 可取值为 [6,7,8]，即集合前 3 高的薪水

再把表 Department 和表 Employee 连接，获得各个部门工资前三高的员工。

```mysql
SELECT
	Department.NAME AS Department, --取部门名称
	e1.NAME AS Employee, --取员工姓名
	e1.Salary AS Salary --取工资值
FROM
	Employee AS e1,Department --合并两张表
WHERE
	e1.DepartmentId = Department.Id --合并条件

--从这里开始是筛选部门前三高的工资
--筛选方法：从e2表里寻找在相同部门中比自身(e1表)更高的工资(值)，像这样的工资(值)一共不超过3个（即只有0,1,2个）

	AND 3 > --不超过3个（即只有0,1,2个）
            (SELECT  count( DISTINCT e2.Salary ) --像这样的工资(值)一共
             FROM Employee AS e2 --从e2表里寻找
             WHERE e1.Salary < e2.Salary --比自身(e1表)更高的工资(值)
             AND e1.DepartmentId = e2.DepartmentId) --在相同部门中

--筛选完成

ORDER BY Department.NAME,Salary DESC; --根据部门、工资值倒序排序
```

或者开窗函数

```mysql
select Department, Employee, Salary
from (
    select d.name Department, ee.name Employee, ee.salary Salary, dense_rank() over(partition by departmentId order by salary desc) ranks
    from Employee ee
    left join Department d
    on ee.departmentId = d.id
) t
where ranks <= 3
```

