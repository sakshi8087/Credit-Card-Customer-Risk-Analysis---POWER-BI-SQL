
--Data Cleaning 

select * from customer$;

select count(*) from customer$; -- 10,108 rows

--no duplicate client num
select client_num, count(*)
from customer$
group by client_num
having count(*) > 1;

--thereare no outliers
select min(customer_age) as min_age, max(customer_age) as max_age
from customer$;


select distinct gender from customer$; -- we have F and M we can update it to Female and Male

select distinct dependent_count  from customer$;

select distinct education_level from customer$;

select distinct marital_status from customer$;

select distinct state_cd from customer$;

select distinct car_owner, house_owner from customer$;

select distinct personal_loan from customer$;

select sum(case when personal_loan='yes' then 1 else 0 end)  as yes,
       sum(case when personal_loan='no' then 1 else 0 end) as no
from customer$;

select distinct contact from customer$;

select distinct customer_job from customer$;

select * from customer$
where income < 0; -- checking for negative income

select distinct cust_satisfaction_score from customer$;



select count(*)
from customer$ c
JOIN credit_card$ cc
ON c.client_num = cc.client_num

select * from credit_card$;

select count(*) from credit_card$;

select client_num, count(*)
from credit_card$
group by client_num
having count(*) > 1;


select distinct card_category from credit_card$;

select * from credit_card$
where annual_fees < 0 OR customer_acq_cost < 0 OR credit_limit < 0 OR total_revolving_bal < 0 OR total_trans_amt < 0 OR total_trans_vol < 0 OR avg_utilization_ratio < 0  OR interest_earned < 0 OR delinquent_acc < 0 ;

--update correct column name for use chip -> use_chip and exp type -> exp_type
exec sp_rename 'credit_card$.[Use Chip]','Use_chip', 'column';

exec sp_rename 'credit_card$.[Exp Type]', 'Exp_Type', 'Column';

--the data is already cleaned 


--Running total of transactions by week 

with cte as (select week_start_date, sum(total_trans_amt) as amount 
from credit_card$
group by week_start_date)

select week_start_date , sum(amount) over(order by week_start_date) from cte;

--Month-over-Month growth % 

with monthly_amt as (select year(week_start_date) as yr ,month(week_start_date) as mn,
       sum(total_trans_amt) as amt
from credit_card$
group by year(week_start_date) , month(week_start_date)
)
select yr, mn, round(amt,2) as monthly_amount,  
       lag(amt) over(order by yr,mn ) as prev,
       concat(round( (amt -  lag(amt) over(order by yr,mn )) * 100.0 /  nullif(lag(amt) over(order by yr,mn ),0), 2), '%') as mom_growth
from monthly_amt
order by mn, yr DESC;

--Week-Over-week

select datepart(week, week_start_date) as weeknumber
from credit_card$

select dateadd(week, datediff(week, 0 , week_start_date),0) as week_start_date
from credit_card$;

--week date jan 1 2023(week 1) , jan 9 2023 (week 2)
--(datediff(day, '19000101', week_start_date) -- 19000101- monday, and week start date result in 46,222 days have passed since 1 Jan 1990
--% 7 -- modulo operator, it resturns the remainder after division, why divide by 7 because one week contains 7 days which result in 2 -- which tell us wednesday is 2 days after monday 
--why -(negative) 2 -- because we want to go backwards from wed to monday 
--day - we are adding or substracting days -2= substract 2 days and week start date as staring date 
--then cast as date 
with weekly_data as (select  dateadd(day, - (datediff(day, '19000101', week_start_date) % 7), cast(week_start_date as date)) as week_start,
       sum(total_trans_amt) as amt
from credit_card$
group by dateadd(day, - (datediff(day, '19000101', week_start_date) % 7), cast(week_start_date as date)) 
)
,wow as(
select week_start,
       amt,
       lag(amt) over(order by week_start) as prev_week_sales
from weekly_data
)
select week_start,
       amt,
       prev_week_sales,
       round((amt - prev_week_sales) * 100.0 / nullif(prev_week_sales,0),2) as wow_growth_perc
from wow
order by week_start;


with w as (select week_start_date, sum(total_trans_amt) as amt
            from credit_card$ group by week_start_date)

select week_start_date, amt,
       lag(amt) over(order by week_start_date) as prev_week,
       round((amt - lag(amt) over(order by week_start_date)) * 100.0 / nullif(lag(amt) over(order by week_start_date),0),2) as wow_ct
from w order by week_start_date;

-- 4 - week moving average


with weekly as (select week_start_date,
       sum(total_trans_amt) as total_amt,
       avg(credit_limit) as avg_limit
from credit_card$
group by week_start_date)

select week_start_date,
       total_amt,
       avg(total_amt) over(order by week_start_date rows between 3 preceding and current row) as ma4_amt,
       avg_limit,
       avg(avg_limit) over(order by week_start_date rows between 3 preceding and current row)as ma4_limit
from weekly
order by week_start_date;



--Headline KPS and CAC ratio

select * from credit_card$

select sum(total_trans_amt) as total_transaction_amount,
       sum(total_trans_vol) as total_transaction_volume,
       avg(credit_limit) as avg_credit_limit,
       count(client_num) as no_of_clients,
       concat(round(sum(customer_acq_cost) * 100.0 / sum(total_trans_amt),2), '%') as CAC_ratio
from credit_card$;

--Intyerest earned as % of revolving balance

select 
       round(sum(interest_earned) * 100.0 / nullif(sum(total_revolving_bal),0),2) as per
from credit_card$;

select top 10 
       client_num,
       round(sum(interest_earned) * 100.0 / nullif(sum(total_revolving_bal),0),2) as per
from credit_card$
group by client_num
order by per DESC;


--Utilization: average and high utilization clients - why heavy use of the limit is an early sign of stress

select
       round(avg(avg_utilization_ratio)* 100,2) as average,
       sum(case when avg_utilization_ratio > 0.80 then 1 else 0 end) as clients_above
from credit_card$
order by average;

select top 6 
       client_num,
       round(avg(avg_utilization_ratio)* 100,2) as average
from credit_card$
Group by client_num
order by average DESC;


--Top 5 clients by spend
select * from customer$

select top 5 c.client_num,
       cc.card_category,
       c.customer_job,
       cc.total_trans_amt 
from credit_card$ cc
JOIN customer$ c ON c.client_num = cc.client_num
order by cc.total_trans_amt DESC;




--churn indicator : no activity in the last 6 months

with cutoff as (select dateadd(month, -6 , max(week_start_date)) as cut_date from credit_card$)


select client_num,
       week_start_date,
       case when week_start_date > cut_date then 'Active' else 'Inactive' end as status
from credit_card$ cross JOIN cutoff;

--summary count for above
with cutoff as (select dateadd(month, -6 , max(week_start_date)) as cut_date from credit_card$)

select case when week_start_date > cut_date then 'Active' else 'Inactive' end as status,
       count(*) as clients
from credit_card$ cross join cutoff
group by  case when week_start_date > cut_date then 'Active' else 'Inactive' end ;



--delinquency rate - the direct measure of credit quality

select card_category,
       round(sum(case when delinquent_acc > 0 then 1 else 0 end) * 100.0 / count(distinct client_num),2) as delinquency_rate
from credit_card$
group by card_category;

--High credit exposure clients - flags clients using almost all of thier limit while carring large unpaid balance

select client_num, case when total_revolving_bal > 0.9 * credit_limit and avg_utilization_ratio > 0.80 then 'Heavy_risk' else 'low_risk' end as risk_category
from credit_card$;

select count(client_num) as no_of_clients,
       sum(case when total_revolving_bal > 0.9 * credit_limit and avg_utilization_ratio > 0.80 then 1 else 0 end) as Heavy_risk
from credit_card$;

--composite credit risk score
--is one number that combines several separate warning signs about a customer
--so you can rank customers by risk instead of checking each signal on its own

with thr as (select distinct 
       PERCENTILE_CONT(0.75) within group (order by total_revolving_bal) over() as p75, -- which column to sort and take percentile of -- over() with empty buckets means the window is the whole table every row recives the same answer and no rows are collapsed
       PERCENTILE_CONT(0.50) within group (order by total_revolving_bal) over() as p50
from credit_card$),
scored as (
select cc.client_num,
       case when avg_utilization_ratio > 0.80 then 2
            when avg_utilization_ratio >= 0.50 then 1 else 0 end
      +case when delinquent_acc > 0 then 1 else 0 end
      +case when total_revolving_bal >= p75 then 2
            when total_revolving_bal >= p50 then 1 else 0 end as risk_score
from credit_card$ cc cross join thr)

select risk_score,
       case when risk_score >=5 then 'High Risk'
            when risk_score >=3 then 'Medium Risk'
            else 'Low Risk' end as risk_category,
        count(*) as clients
from scored
group by risk_score
order by risk_score;





--satisfcation and credit limit by segment

--(a) satisfaction by card_category 

select cc.card_category,
       round(avg(c.cust_satisfaction_Score * 1.0),3) as avg_sat,
       count(*) as clients
from credit_card$ cc
JOIN customer$ c on c.client_num = cc.client_num
group by cc.card_category
order by avg_sat DESC;


--(b) credit limit by personal loan_status


select c.personal_loan,
       round(avg(cc.credit_limit),0) as avg_credit_limit,
       count(*) as clients
from credit_card$ cc
JOIN customer$ c on c.client_num = cc.client_num
group by c.personal_loan;

--personal loan penetration and profile

 --headline
 select count(*) as total_clients,
        sum(case when personal_loan='yes' then 1 else 0 end) as loan_clients,
        round(sum(case when personal_loan='yes' then 1 else 0 end)* 100.0 / count(*) ,2) as penetration_ct
from customer$;

--profile : change the grouping column for each 

select customer_job,
       count(*) as loan_clients,
       round(count(*) * 100.0/ sum(count(*)) over(),2) as pct_of_loan_clients
from customer$
where personal_loan='yes'
group by customer_job
order by loan_clients DESC;

--education_level

select education_level,
       count(*) as loan_clients,
       round(count(*) * 100.0/ sum(count(*)) over(),2) as pct_of_loan_clients
from customer$
where personal_loan='yes'
group by education_level
order by loan_clients DESC;

--house_owner
select house_owner,
       count(*) as loan_clients,
       round(count(*) * 100.0/ sum(count(*)) over(),2) as pct_of_loan_clients
from customer$
where personal_loan='yes'
group by house_owner
order by loan_clients DESC;

--age
select case when customer_age < 30 then 'Under 30'
            when customer_age < 40 then '30-39'
            when customer_age < 50 then '40-49'
            when customer_age < 60 then '50-59'
            else '60+' end as age_band,
       count(*) as loan_clients
from customer$
where personal_loan = 'yes'
group by case when customer_age < 30 then 'Under 30'
              when customer_age < 40 then '30-39'
              when customer_age < 50 then '40-49'
              when customer_age < 60 then '50-59'
              else '60+' end
order by min(customer_age);


--count(*) is the number of loan clients in the job
--sum(count(*)) over() wrapped around the group result. it adds up all those counts across all jobs which is 1,286
select round(count(*) * 100.0/ sum(count(*)) over(),2) as pct_of_loan_clients


--why cross join used with thr and cutoff
--cross join pairs every row of one table with every row of the other
