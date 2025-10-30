use case_studies;
SELECT * FROM case_studies.`session 4 - swiggy_cleaned`;

rename table `session 4 - swiggy_cleaned` to swiggy;

select * from swiggy;

select 
	sum(case when hotel_name = '' then 1 else 0 end) as hotel_name,
    sum(case when rating='' then 1 else 0 end) as rating,
    sum(case when time_minutes='' then 1 else 0 end) as time_minutes,
    sum(case when food_type='' then 1 else 0 end) as food_type,
    sum(case when location='' then 1 else 0 end) as location,
    sum(case when offer_above = '' then 1 else 0 end) as offer_above,
    sum(case when offer_percentage='' then 1 else 0 end) as offer_percentage
	from swiggy;
    
--

/* Automation to write above code for the case if data have more than 20 columns. Here we are going to learn schemas,
group concate, concate, prepare, execute, etc. */
-- delimiter // 
-- create procedure count_blank_rows()
-- begin
-- 		select group_concat(
-- 					concat('sum(case when`', column_name, '`='''' Then 1 else 0 end) as `', column_name ,'`')
-- 				) into @sql 
-- 				from information_schema.columns  where table_name= 'swiggy';
-- 		set @sql = concat('select ', @sql, ' from swiggy');

-- 		prepare smt from @sql;
-- 		execute smt;
-- 		deallocate prepare smt;
-- end 
-- // 
-- delimiter;

# call count_blank_rows()
		 
 -- selecting all column names of table 
 -- select column_name from information_schema.columns where table_name = 'swiggy';
 
 -- Group Concat -> it concates the  o/p of concat function.
 
 select count(rating) from swiggy where rating like '%mins%';
 
 -- shifting values from rating to time_minutes.
 
 create table clean as 
 select * from swiggy where rating like '%mins%';
 
 create table cleaned
 select *, substring(rating,1,2) as 'rat' from clean;
 
 update swiggy as s 
 inner join cleaned as c
 on s.hotel_name = c.hotel_name
 set s.time_minutes = c.rat;
 
 drop table clean;
 drop table cleaned; 
 
-- cleaning for ('-') type of values in time_minutes columns 
create table cleaned as
select * from swiggy where time_minutes like '%-%';

select * from cleaned;

create table clean as 
SELECT 
  hotel_name,
  time_minutes,
  SUBSTRING_INDEX(time_minutes, '-', 1) AS rat1,
  SUBSTRING_INDEX(time_minutes, '-', -1) AS rat2
FROM cleaned;

select * from clean;

update swiggy s 
inner join clean c
on s.hotel_name = c.hotel_name 
set s.time_minutes = ((c.rat1 + c.rat2)/2);


-- Cleaning rating columns
select rating from swiggy where rating like '%mins%';
select * from swiggy;

create table cleaning_rating as
select location, round(avg(rating),2) as 'avg_rating' from swiggy 
where rating not like '%mins%'
group by location;

update swiggy s 
inner join cleaning_rating c 
on s.location  = c.location 
set s.rating = c.avg_rating
where s.rating like '%mins%';

select hotel_name, rating,location from swiggy where rating like '%mins%';

set @average_rating = (select round(avg(rating),2) from swiggy where rating not like '%mins%');
select @average_rating;

SET @avg_rating = (
  SELECT ROUND(AVG(CAST(rating AS DECIMAL(4,2))), 2)
  FROM swiggy
  WHERE rating NOT LIKE '%mins%'
);
select @avg_rating;

update swiggy 
set rating = @avg_rating
where rating like '%mins%';

-- In Location column there are several values that are similar to one area like Kandiwali(E), kandiwali East. so we have to update all values as Kandiwali East/West. 

select distinct(location) from swiggy where location like '%Kandivali%';
select location, count(location) from swiggy
group by location;

update swiggy
set location = 'Kandivali East'
where location like '%East%';

update swiggy
set location = 'Kandivali West'
where location like '%West%';

update swiggy
set location = 'Kandivali East'
where location like '%E%';

update swiggy
set location = 'Kandivali West'
where location like '%W%';

--------------------------------------------------------
-- Cleaning food_type column. as data is not normalized here. we have to clean this columns to get the answers clearly.
select * from 
(
select *, substring_index( substring_index(food_type ,',',numbers.n),',', -1) as 'food'
from  swiggy
	join
	(
		select 1+a.N + b.N*10 as n from 
		(
			(
			SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 
			UNION ALL SELECT 8 UNION ALL SELECT 9) a
			cross join 
			(
			SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 
			UNION ALL SELECT 8 UNION ALL SELECT 9)b
		)
	)  as numbers 
    on  char_length(food_type)  - char_length(replace(food_type ,',','')) >= numbers.n-1
)a;

