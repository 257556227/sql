[620. 有趣的电影](https://leetcode.cn/problems/not-boring-movies/)

```mysql
select * from cinema
where id & 1 = 1 and description != 'boring'
order by rating desc;
```

[1251. 平均售价](https://leetcode.cn/problems/average-selling-price/)

```mysql
select p.product_id, IFNULL(ROUND(SUM(u.units * p.price) / SUM(u.units), 2), 0) as average_price  
from Prices p
left join UnitsSold u
on p.product_id = u.product_id and u.purchase_date between p.start_date and p.end_date
group by p.product_id
```

