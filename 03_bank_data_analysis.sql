DROP TABLE bank_loans;

CREATE TABLE bank_loans (
    loan_id VARCHAR(50),
    customer_id VARCHAR(50),
    loan_status VARCHAR(50),
    current_loan_amount VARCHAR(20),
    term VARCHAR(20),
    credit_score VARCHAR(20),
    annual_income VARCHAR(20),
    years_in_current_job VARCHAR(20),
    home_ownership VARCHAR(30),
    purpose VARCHAR(50),
    monthly_debt VARCHAR(20),
    years_of_credit_history VARCHAR(20),
    months_since_last_delinquent VARCHAR(30),
    number_of_open_accounts VARCHAR(20),
    number_of_credit_problems VARCHAR(20),
    current_credit_balance VARCHAR(20),
    maximum_open_credit VARCHAR(20),
    bankruptcies VARCHAR(20),
    tax_liens VARCHAR(20)
);
--1)How many loans do we have and what's the overall default rate?
Select count(*) as total_loans,
sum(case when loan_status='Fully Paid' then 1 else 0 end) as good_loans,
sum(case when loan_status='Charged Off' then 1 else 0 end) as bad_loans,
round(100.0 * sum(case when loan_status ='Charged Off' then 1 else 0 end)/count(*),2) as default_rate_pct
from bank_loans
where loan_status is not null;


-- 2) What is split between good and bad loans, and how much money is tied up in each?
select loan_status, count(*) as total_loans,
round(100.0* count(*)/sum(count(*)) over(),2) AS percentage,
sum(cast(current_loan_amount AS BIGINT)) AS total_amount
FROM bank_loans
WHERE loan_status IS NOT NULL
GROUP BY loan_status
ORDER BY total_loans DESC;

--3) Which loan purposes have the highest default rate?
select purpose, 
count(*) as total_loans,
sum(case when loan_status = 'Charged Off' then 1 else 0 end) as defaults,
round(100.0 * sum(case when loan_status = 'Charged Off' then 1 else 0 end)/count(*),2) as default_rate_pct
FROM bank_loans 
where loan_status is not null
and purpose is not null
group by purpose 
order by default_rate_pct DESC;

--4) Do customers who rent, own, or have a mortgage default more often?
select home_ownership, 
count(*) as total_loans,
sum(case when loan_status = 'Charged Off'then 1 else 0 end) as defaults,
round(100.0 * sum(case when loan_status = 'Charged Off' then 1 else 0 end)/count(*),2) as default_rate_pct
FROM bank_loans 
where loan_status is not null
and home_ownership is not null
group by home_ownership
order by default_rate_pct desc;

--5) Which loan term (Short vs Long) has a higher default rate?
select
term,
count(*) as total_loans,
sum(case when loan_status = 'Charged Off' then 1 else 0 end) as defaults,
round(100.0 * sum(case when loan_status = 'Charged Off' then 1 else 0 end) / count(*), 2) as default_rate_pct
from bank_loans
where loan_status is not null
and term is not null
group by term
order by default_rate_pct desc;


--Q6) Does job stability affect loan default rate?
select years_in_current_job,
count(*) as total_loans,
sum(case when loan_status = 'Charged Off' then 1 else 0 end) as defaults,
round(100.0 * sum(case when loan_status = 'Charged Off' then 1 else 0 end) / count(*), 2) as default_rate_pct
from bank_loans
where loan_status is not null
and years_in_current_job is not null
group by years_in_current_job
order by default_rate_pct desc;

--Q7) Do customers with lower credit scores default more often?
select 
case
when cast(nullif(credit_score,' ')as float)>=750 then 'Excellent'
when cast(nullif(credit_score,' ')as float)>=700 then 'Good'
when cast(nullif(credit_score,' ')as float)>=650 then 'Fair'
when cast(nullif(credit_score,' ')as float)>=600 then 'Poor'
else 'Unknown'
end as credit_score_band,
count(*) as total_loans,
sum(case when loan_status = 'Charged Off' then 1 else 0 end) as defaults,
round(100.0 * sum(case when loan_status = 'Charged Off' then 1 else 0 end) / count(*), 2) as default_rate_pct
from bank_loans
where loan_status is not null
group by credit_score_band
order by default_rate_pct desc;

--8) Loan Volume & Default by credit score band + term combined
select term,
case
when cast(nullif(credit_score,' ')as float)>=750 then 'Excellent'
when cast(nullif(credit_score,' ')as float)>=700 then 'Good'
when cast(nullif(credit_score,' ')as float)>=650 then 'Fair'
when cast(nullif(credit_score,' ')as float)>=600 then 'Poor'
else 'Unknown'
end as credit_score_band,
count(*) as total_loans,
sum(case when loan_status = 'Charged Off' then 1 else 0 end) as defaults,
round(100.0 * sum(case when loan_status = 'Charged Off' then 1 else 0 end) / count(*), 2) as default_rate_pct
from bank_loans
where loan_status is not null
group by term, credit_score_band
order by default_rate_pct desc;

--9) Which loan purposes account for the most money lent by the bank?
select purpose,
count(*) as total_loans,
sum(cast(current_loan_amount as bigint)) as total_funded_amount,
round(100.0*sum(cast(current_loan_amount as bigint))/sum(sum(cast(current_loan_amount as bigint)))over(),2) as pct_of_total
from bank_loans
where loan_status is not null
and purpose is not null
and current_loan_amount != '9999999'
group by purpose
order by total_funded_amount desc;

--10) What ia the typical profile of a customer who defaults vs one who fully pays?
select
loan_status,
count(*) as total_loans,
round(avg(cast(nullif(credit_score,' ')as float))::numeric,0) as avg_credit_score,
round(avg(cast(nullif(annual_income,' ')as float))::numeric,0) as avg_annual_income,
round(avg(cast(nullif(monthly_debt,' ')as float))::numeric,0) as avg_monthly_debt
from bank_loans
where loan_status is not null
group by loan_status
order by avg_credit_score desc;

--11) Do customers with bankruptcies or tax liens default more often?
select 
case
when cast(nullif(nullif(bankruptcies,' '), 'NA')as float) > 0 then 'Has Bankruptcy'
else 'No Bankruptcy'
end as bankruptcy_status,
count(*) as total_loans,
sum(case when loan_status = 'Charged Off' then 1 else 0 end) as defaults,
round(100.0 * sum(case when loan_status = 'Charged Off' then 1 else 0 end) / count(*), 2) as default_rate_pct
from bank_loans
where loan_status is not null
group by bankruptcy_status
order by default_rate_pct desc;

--12) Do customers with tax liens default more often?
select 
case 
when cast(nullif(nullif(tax_liens,' '),'NA')as float)>0 then 'Has Tax Lien'
else 'No Tax Lien'
end as tax_lien_status,
count(*) as total_loans,
sum(case when loan_status = 'Charged Off' then 1 else 0 end) as defaults,
round(100.0 * sum(case when loan_status = 'Charged Off' then 1 else 0 end) / count(*), 2) as default_rate_pct
from bank_loans
where loan_status is not null
group by tax_lien_status
order by default_rate_pct desc;

--13) Which loan purpose is costing the bank the most money in defaults?
select purpose,
count(*) as total_loans,
sum(case when loan_status = 'Charged Off' then 1 else 0 end) as defaults,
sum(cast(current_loan_amount as bigint)) as total_funded_amount
from bank_loans
where loan_status is not null
and purpose is not null
and current_loan_amount != '9999999'
group by purpose 
order by total_funded_amount desc;

--14) Do customers with more credit problems default more often?

select 
number_of_credit_problems,
count(*) as total_loans,
sum(case when loan_status = 'Charged Off' then 1 else 0 end) as defaults,
round(100.0 * sum(case when loan_status = 'Charged Off' then 1 else 0 end)/count(*),2)as default_rate_pct
from bank_loans
where loan_status is not null
and number_of_credit_problems is not null
group by number_of_credit_problems
order by number_of_credit_problems asc;

--15)Do larger loans default more than smaller loans?
select
case 
when cast(current_loan_amount as bigint)<100000 then 'Small(<100K)'
when cast(current_loan_amount as bigint)<500000 then 'Medium(100K - 500k)'
when cast(current_loan_amount as bigint)<1000000 then 'Large(500K - 1M)'
else 'Very Large (1M+)'
end as loan_size_category,
count(*) as total_loans,
sum(case when loan_status = 'Charged Off' then 1 else 0 end) as defaults,
round(100.0 * sum(case when loan_status = 'Charged Off' then 1 else 0 end)/count(*),2)as default_rate_pct
from bank_loans
where loan_status is not null
and current_loan_amount != '9999999'
group by loan_size_category
order by default_rate_pct desc ;
