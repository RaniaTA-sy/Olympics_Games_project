# Olympics_Games_project
Analysis project Made by pgAdmin 4 'SQL'
## table of contents
- [Project Overview](#project-overview)
- [Data Sources](#data-sources)
- [Tools](#tools)	
- [Data Cleaning Preparation](#data-cleaning-preparation)
- [Data Analysis](#data-analysis)
- [Recommendations](#recommendations) 


## Project Overview

This repository offers a comprehensive, PostgreSQL-based analysis of the Olympic Games, encompassing all Games from their inception to the present. 
It includes 20 SQL queries that extract insights on participation, nations, sports, and medal tallies, such as country participation by year,
top medal lists, most successful nations, and sport-specific medal trends. The data model supports year-wise breakdowns, country-level medal summaries,
and event-level analyses, with clear, reproducible queries and explanations.

## Data Sources
 Famous Painting Data: The primary dataset used in the analysis consists of "athlete_events.csv", 
 "athlete_events_data_dictionary.csv", "country_definitions.csv", and "country_definitions_data_dictionary.csv". 
 ### Tools 
- pgAdmin4: Cleansing process 
-[download here](http://micrsoft.com)
- pgAdmin4: Make the analysis project

### Data Cleaning Preparation
  We performed the following tasks: 
  1- data loading and inception
  2-Check the quality of the data for each table.

###  Data Analysis
 includes requirements and SQL syntax for each question.    
Questions:
use olympics_games 

1) How many Olympic Games have been held?
   
```sql
select distinct count (games)total_olympics_games
from olympics_history
'''

3) List down all Olympic Games held so far.

    ```sql
select distinct games,city
from olympics_history
order by games,city
```

5) Mention the total no of nations that participated in each Olympic game?

```sql
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
```
 
  6) Which year saw the highest and lowest no of countries participating in the Olympics?
  
  ```sql
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
```	

7) Which nation has participated in all of the Olympic Games?

```sql
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
```

8) Identify the sport which was played in all summer Olympics.

```sql
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
```


9) Which Sports were just played only once in the Olympics?

```sql
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
```

10) Find the total no of sports played in each Olympic Games.

```sql
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
```

9) Find details of the oldest athletes to win a gold medal.

```sql
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
```
10) Find the top 5 athletes who have won the most gold medals.

```sql
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
```
11) Find the top 5 athletes who have won the most medals (gold/silver/bronze).

```sql
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
```

12) Find the top 5 most successful countries in the Olympics. Success is defined by no of medals won.

```sql
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
```
	
13) List down the total gold, silver and bronze medals won by each country.

```sql
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
```

14) List down the total gold, silver and bronze medals won by each country corresponding to each Olympic Games.

```sql
select left(games,strpos(games,'-')-1)as games,
right(games,length(games)-strpos(games,'-')) as country,
coalesce(bronze,0)as bronze,
coalesce(gold,0)as gold,
coalesce(silver,0)as silver
 FROM CROSSTAB('SELECT concat(games, '' - '', nr.region) as games
                , medal , count(1) as total_medals
                FROM olympics_history oh
                JOIN olympics_history_noc_regions nr ON nr.noc = oh.noc
                where medal <> ''NA''
                GROUP BY games,nr.region,medal
                order BY games,medal',
            'values (''Bronze''), (''Gold''), (''Silver'')')
    AS FINAL_RESULT(games text, bronze bigint, gold bigint, silver bigint)
```

15) Identify which country won the most gold, silver and bronze medals in each Olympic Games.

```sql
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
                JOIN olympics_history_noc_regions nr 
                ON nr.noc = oh.noc
                where medal <> ''NA''
                GROUP BY games,nr.region,medal
                order BY games,medal',
            'values (''Bronze''), (''Gold''), (''Silver'')')
    AS FINAL_RESULT(games text, bronze bigint, gold bigint, silver bigint))	
	select   distinct games,
	concat (first_value(country) over(partition by games order by gold desc),' - ',
	first_value(gold)over(partition by games order by gold desc))as   Max_gold,
	concat (first_value(country) over(partition by games order by silver desc),' - ',
	first_value(silver)over(partition by games order by silver desc))as Max_silver,
	concat (first_value(country) over(partition by games order by bronze desc),' - ',
first_value(bronze)over(partition by games order by bronze desc))as Max_bronze
	from t1
	order by games
```

16) Which countries have never won a gold medal but have won silver/bronze medals?

```sql
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
```

17) In which Sport/event has India won the highest medals?

```sql
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
```
  18) Break down all Olympic Games where India won medals for Hockey and how many medals in each Olympic Games.

```sql
  select games,sport,team,count(*) total_medal
  from olympics_history
  where medal<>'NA' and team = 'India' 
  and sport ='Hockey'
  group by 1,2,3
  order by 4 desc
```
## Recommendations 
1. Improve special training and psychological conditioning for players engaged in the most injury or failure-prone events.
2. Review the performance reports for September and October to identify skill deficiencies and adjust training plans accordingly.
3. Develop expert programs for sports with a growing level of competition to enhance tactics and skills.
4. Encourage synchronisation among coaches, sports scientists, and nutritionists for improved athlete preparation and recovery.
5. Emphasis should be placed on seeking out and developing young talent early, giving them support and competitions to hone their skills before the Olympics.
6. Encourage international exposure for the players through regular participation in world championships and friendly matches in order to develop confidence and resilience.
