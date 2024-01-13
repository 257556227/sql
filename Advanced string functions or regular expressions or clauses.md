## [1667. 修复表中的名字](https://leetcode.cn/problems/fix-names-in-a-table/)

```mysql
select user_id, CONCAT(UPPER(left(name, 1)), LOWER(SUBSTRING(name, 2))) as name
from Users
order by user_id
```

## [1527. 患某种疾病的患者](https://leetcode.cn/problems/patients-with-a-condition/)

题目要求 I 类糖尿病的代码总是包含前缀 DIAB1

而前缀存在分为2种：

1. I 类糖尿病位于第一个时: 以DIAB1开始，即CONDITIONS REGEXP '^DIAB1'
2. I 类糖尿病不是第一个时: 含有空格DIAB1，即CONDITIONS REGEXP '\sDIAB1'

用**正则表达式**来匹配这2种情况就行

位于第一个时，用 **^** 匹配输入字符串的开始位置，即`^DIAB1`
不是第一个时，又符合前缀所以它属于代码后段的首位，即前面有空格与代码首段隔开，用 **\s** 匹配一个被视为白空格的空格或字符；
但要注意的是：多数正则表达式实现使用**单个反斜杠转义特殊字符**，一遍能使用这些字符本身，但是MySQL要求两个反斜杠（MySQL自己解释一个，正则表达式库解释另一个），所以是`\\sDIAB1`

然后这2种情况只要满足一种即可，所以用 **|**
| 管道符号用于指定匹配字符串时要使用的替代模式；在由竖线分隔的一行模式中，竖线被解释为OR，匹配过程从最左侧的模式开始，在找到第一个匹配项时停止

```mysql
SELECT * FROM PATIENTS WHERE CONDITIONS REGEXP '^DIAB1|\\sDIAB1';
```

或者只用like

```mysql
select patient_id, patient_name, conditions
from patients
where conditions like 'DIAB1%' or conditions like '% DIAB1%';
```

亦或者用 substring_index

'DIAB1'前缀分两种，一种是最左边 前方无空格 如"DIAB100 MYOP"，以及前面有空格的前缀 如"ACNE DIAB100"，前面一种用`left(conditions, 5) = 'DIAB1'`，后一种则是需要使用`substring`以及`substring_index`

> left(str, length) 从左开始截取字符串，length 是截取长度。
> substring(str, begin, length) 从第start个字符开始截取字符串，length 不写默认为到末尾。
> substring_index（str,delim,count）
> 说明：substring_index（被截取字段，关键字，关键字出现的次数） 

`substring_index(conditions, 'DIAB1', 1)` 可以取得 'DIAB1' 之前的值

然后再采用`substring(str, -1, 1)`则可以取得空格；
当然，得先排除掉conditions=' '的情况

```mysql
select patient_id, patient_name, conditions
from Patients
where conditions != ' ' and 
(left(conditions, 5) = 'DIAB1' or substring(substring_index(conditions, 'DIAB1', 1), -1, 1) = ' ')
```

## [196. 删除重复的电子邮箱](https://leetcode.cn/problems/delete-duplicate-emails/) DELETE

```mysql
DELETE FROM Person
WHERE id NOT IN (
   SELECT id FROM (
       SELECT MIN(id) AS id FROM Person GROUP BY email
   ) AS u
);
```

```mysql
delete from Person
where id in (
    select id from(
        select p2.id from Person p1
        inner join Person p2
        on p1.id < p2.id 
        where p1.email = p2.email 
    ) t1
)
```

You can’t specify target table for update in FROM clause

不能先select出同一表中的某些值，再update这个表(在同一语句中)。 例如下面这个sql：

```mysql
delete from tbl where id in 
(
        select max(id) from tbl a where EXISTS
        (
            select 1 from tbl b where a.tac=b.tac group by tac HAVING count(1)>1
        )
        group by tac
)
```

改写成下面就行了：

```mysql
delete from tbl where id in 
(
    select a.id from 
    (
        select max(id) id from tbl a where EXISTS
        (
            select 1 from tbl b where a.tac=b.tac group by tac HAVING count(1)>1
        )
        group by tac
    ) a
)
```


就是将select出的结果再通过中间表select一遍，这样就规避了错误。注意，这个问题只出现于[mysql](http://lib.csdn.net/base/mysql)，mssql和[Oracle](http://lib.csdn.net/base/oracle)不会出现此问题。


## [176. 第二高的薪水](https://leetcode.cn/problems/second-highest-salary/)

```mysql
# 使用子查询找出最大的薪水记为a，然后再找出小于a的最大值就是第二高薪。
# select max(distinct salary) SecondHighestSalary
# from Employee
# where salary < (select max(distinct salary) from Employee)

# 使用limit和offset，降序排列再返回第二条记录可以得到第二大的值。
# limit n 子句表示查询结果返回前n条数据
# offset n 表示跳过x条语句
# limit y offset x 分句表示查询结果跳过 x 条数据，读取前 y 条数据
# select ifnull(
#     (select distinct salary
#     from Employee
#     order by salary desc
#     limit 1,1), null
# ) as SecondHighestSalary
# 判断空值的函数（ifnull）函数处理，sql语句返回空的情况

select ifnull((
    select salary
    from (
        select distinct salary, dense_rank() over(order by salary desc) ranks
        from Employee
    ) t
    where ranks = 2
), null
) as SecondHighestSalary
```

## [1484. 按日期分组销售产品](https://leetcode.cn/problems/group-sold-products-by-the-date/)

group_concat([distinct] 要连接的字段 [order by 排序字段] [separator '分隔符'])

另外，因为是“销售的不同产品的数量”所以要加distinct

```mysql
select
    sell_date,
    count(distinct product) num_sold,
    group_concat(
        distinct product
        order by product
        separator ','
    ) products
from 
    Activities
group by sell_date
order by sell_date
```

## [1327. 列出指定时间段内所有的下单产品](https://leetcode.cn/problems/list-the-products-ordered-in-a-period/)

```mysql
select p.product_name, sum(o.unit) unit
from Orders o inner join Products p
on o.product_id = p.product_id
where to_char(o.order_date, 'yyyy-mm') = '2020-02'
group by o.product_id
having sum(o.unit) >= 100
```

## [1517. 查找拥有有效邮箱的用户](https://leetcode.cn/problems/find-users-with-valid-e-mails/)

- ^：表示一个字符串或行的开头
- [a-z]：表示一个字符范围，匹配从 a 到 z 的任何字符。
- [0-9]：表示一个字符范围，匹配从 0 到 9 的任何字符。
- [a-zA-Z]：这个变量匹配从 a 到 z 或 A 到 Z 的任何字符。请注意，你可以在方括号内指定的字符范围的数量没有限制，您可以添加想要匹配的其他字符或范围。
- [^a-z]：这个变量匹配不在 a 到 z 范围内的任何字符。请注意，字符 ^ 用来否定字符范围，它在方括号内的含义与它的方括号外表示开始的含义不同。
- [a-z]*：表示一个字符范围，匹配从 a 到 z 的任何字符 0 次或多次。
- [a-z]+：表示一个字符范围，匹配从 a 到 z 的任何字符 1 次或多次。
- . ：匹配任意一个字符。
- \\. ：表示句号。请注意，反斜杠用于转义句点字符，因为句点字符在正则表达式中具有特殊含义。还要注意，在许多语言中，你需要转义反斜杠本身，因此需要使用双斜杠\\\\.。
- $：表示一个字符串或行的结尾。

```mysql
select * from Users
where mail REGEXP '^[a-zA-Z][a-zA-Z0-9_./-]*\\@leetcode\\.com$'
```

