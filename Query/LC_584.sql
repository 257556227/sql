SELECT name 
 FROM customer 
WHERE referee_id <> 2
UNION ALL
SELECT name 
 FROM customer 
WHERE referee_id IS NULL