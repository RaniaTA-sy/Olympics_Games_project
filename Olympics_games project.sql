----1.How many olympics games have been held?
select distinct count (games)total_olympics_games
from olympics_history

---2.	List down all Olympics games held so far.
select distinct games,city
from olympics_history
order by games,city

---3.	Mention the total no of nations who participated in each olympics game?
with t1 as(
	  select   oh.games,nr.region 
  from olympics_history oh
  join olympics_history_noc_regions nr  on oh.noc = nr.noc
  group by 1,2
  order by 1,2)
  select    games,count(*)as tot_countries
  from t1
  group by 1
  order by 2 desc
  
  ---4.	Which year saw the highest and lowest no of countries participating in olympics?
   with t1 as(
	  select   oh.games,nr.region 
      from olympics_history oh
     join olympics_history_noc_regions nr  on oh.noc = nr.noc
     group by 1,2
     order by 1,2),
 t2 as( select    games,count(*)as total_countries
        from t1
        group by 1
        order by 2 )
  select distinct
  concat(first_value(games)over(order by total_countries),
	 ' - ',first_value(total_countries)over(order by total_countries)) as lowest_countries,
 concat (first_value(games)over(order by total_countries),' - ',
			   first_value(total_countries)over(order by total_countries desc))as heighest_countries
				from t2
				group by games,total_countries
				
  
 ----- 5.Which nation has participated in all of the olympic games?
with total_games as(
	select count(distinct games)as total_games
   from olympics_history),
t2 as (
select oh.games,nr.region as countries
	from olympics_history oh
	join olympics_history_noc_regions nr   on oh.noc= nr.noc
	group by 1,2
	order by 1,2),
t3 as(
  select countries,count(*)num_of_participated 
	from t2
	group by countries)
select t3.* 
from t3
join total_games tg on tg.total_games = t3.num_of_participated 
order by countries

------6.Identify the sport which was played in all summer olympics.

with total_games as(
	select count(distinct games)total_games
     from olympics_history 
     where season='Summer'),
t2 as(
	select games,sport 
    from olympics_history
     where season = 'Summer'
     group by games,sport 
     order by games,sport ),
t3 as (
	select sport,count(*) num_of_games
	from t2
     group by sport)
select *
from t3
join total_games tg on tg.total_games = t3.num_of_games
order by sport


------7.Which Sports were just played only once in the olympics?
with t1 as (
	select distinct games,sport 
    from olympics_history),
t2 as(
	  select sport,count(*)as total_games
       from t1
       group by sport)
select   t2.*,t1.games
from t2
join t1 on t2.sport = t1.sport
where total_games =1
order by games

---8.Fetch the total no of sports played in each olympic games.

with t1 as (
	select distinct games,sport 
    from olympics_history
    group by games,sport),
t2 as(
   select  distinct sport,count(*)total_sport
   from t1 
   group by sport)
select t1.games,t2.total_sport
from t2 
join  t1 on t1.sport = t2.sport 
order by games

---9.Fetch details of the oldest athletes to win a gold medal.
with t1 as(
	select name,sex,height,weight,team,noc,games,year,season,city,sport,event,medal,
    cast(case when age = 'NA'then '0' else age end as int)as age
    from olympics_history
   where 
   Medal='Gold'),
t2 as(	select *,rank()over(order by age desc)as age_rnk
	from t1)
select t2.*
from t2
where age_rnk = 1

----10.	Fetch the top 5 athletes who have won the most gold medals.
with t1 as (
	select name,team,count(*)total_gold_medal
    from olympics_history
    where medal ='Gold'
    group by 1,2
    order by 3 desc),
t2 as (
    select *, dense_rank()over(order by total_gold_medal desc)as rnk
	from t1)
select name,team,total_gold_medal
	from t2 
	where rnk < 5

-----11.Fetch the top 5 athletes who have won the most medals (gold/silver/bronze).
with t1 as(
	select name,team,count(*)total_medals
    from olympics_history
   where medal in ('Gold','Bronze','Silver')
   group by 1,2
   order by 3 desc),
t2 as(
    select t1.*, dense_rank()over(order by total_medals desc)as Medal_rnk
	from t1)
select *   from t2  where Medal_rnk <5;

----12.	Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won.

with t1 as(
    select nr.region as country ,count(*)as total_medals
   from olympics_history  oh
   join olympics_history_noc_regions   nr
   on oh.noc = nr.noc
   where medal <> 'NA'
   group by nr.region  
   order by total_medals desc),
t2 as(
   select *,dense_rank()over(order by total_medals desc) as rnk
	from t1) 	
select *
	from t2
where rnk <5;
	

---13.	List down total gold, silver and broze medals won by each country.
create extension tablefunc;
	
	select country,
	coalesce(bronze,0) as bronze,
	coalesce(gold,0) as gold,
	coalesce(silver,0)as silver
	from crosstab(
	'select nr.region as country,oh.medal,count(*)total_medals
    from olympics_history oh
    join olympics_history_noc_regions nr   on nr.noc = oh.noc
    where medal <>''NA''
    group by country,medal
    order by country,medal',
    'values(''Bronze''),(''Gold''),(''Silver'')')
as final_result (country varchar,bronze bigint,Gold bigint, Silver bigint)
order by gold  desc ,Silver desc,Bronze desc 

----14.	List down total gold, silver and broze medals won by each country corresponding to each olympic games.

select left(games,strpos(games,'-')-1)as games,
right(games,length(games)-strpos(games,'-')) as country,
coalesce(bronze,0)as bronze,
coalesce(gold,0)as gold,
coalesce(silver,0)as silver
 FROM CROSSTAB('SELECT concat(games, '' - '', nr.region) as games
                , medal
                , count(1) as total_medals
                FROM olympics_history oh
                JOIN olympics_history_noc_regions nr ON nr.noc = oh.noc
                where medal <> ''NA''
                GROUP BY games,nr.region,medal
                order BY games,medal',
            'values (''Bronze''), (''Gold''), (''Silver'')')
    AS FINAL_RESULT(games text, bronze bigint, gold bigint, silver bigint)

---15.Identify which country won the most gold,most silver and most bronze medals in each olympic games.

with t1 as(
	select left(games,strpos(games,'-')-1)as games,
   right(games,length(games)-strpos(games,'-')) as country,
   coalesce(bronze,0)as bronze,
   coalesce(gold,0)as gold,
   coalesce(silver,0)as silver
   FROM CROSSTAB('SELECT concat(games, '' - '', nr.region) as games
                , medal
                , count(1) as total_medals
                FROM olympics_history oh
                JOIN olympics_history_noc_regions nr ON nr.noc = oh.noc
                where medal <> ''NA''
                GROUP BY games,nr.region,medal
                order BY games,medal',
            'values (''Bronze''), (''Gold''), (''Silver'')')
    AS FINAL_RESULT(games text, bronze bigint, gold bigint, silver bigint))	
	select   distinct games,
	concat (first_value(country) over(partition by games order by gold desc),' - ',
			first_value(gold)over(partition by games order by gold desc))as Max_gold,
	concat (first_value(country) over(partition by games order by silver desc),' - ',
			first_value(silver)over(partition by games order by silver desc))as Max_silver,
	concat (first_value(country) over(partition by games order by bronze desc),' - ',
			first_value(bronze)over(partition by games order by bronze desc))as Max_bronze
	from t1
	order by games
	
----16.	Which countries have never won gold medal but have won silver/bronze medals?

select * from (
    	SELECT country, coalesce(gold,0) as gold, coalesce(silver,0) as silver, coalesce(bronze,0) as bronze
    	FROM CROSSTAB('SELECT nr.region as country
    					, medal, count(1) as total_medals
    					FROM OLYMPICS_HISTORY oh
    					JOIN OLYMPICS_HISTORY_NOC_REGIONS nr ON nr.noc=oh.noc
    					where medal <> ''NA''
    					GROUP BY nr.region,medal order BY nr.region,medal',
                    'values (''Bronze''), (''Gold''), (''Silver'')')
    		AS FINAL_RESULT(country varchar,
    		bronze bigint, gold bigint, silver bigint)) 
           where gold = 0 and (silver > 0 or bronze > 0)
           order by gold desc , silver desc , bronze desc 
	
----17.	In which Sport/event, India has won highest medals.
with t1 as(
	select  sport,count(*)total_medals
    from olympics_history 
    where medal <> 'NA' and team= 'India'
    group by sport
    order by 2 desc),
t2 as(
select *,rank() over(order by total_medals desc)as medal_rnk
	from t1)
  select * 
  from t2 
  where medal_rnk =1
  
  ---18.Break down all olympic games where india won medal for Hockey and how many medals in each olympic games.
  select games,sport,team,count(*) total_medal
  from olympics_history
  where medal<>'NA' and team = 'India' 
  and sport ='Hockey'
  group by 1,2,3
  order by 4 desc