create database cybersecurity_analysis;
use cybersecurity_analysis;
select * from cybersecurity_threats limit 10;
describe cybersecurity_threats;
#Q1.The cybersecurity team wants to identify which attack types cause the greatest total financial damage.
select `Attack Type`,sum(`Financial Loss (in Million $)`) as total_financial_loss
from cybersecurity_threats group by `Attack Type`
order by total_financial_loss desc;
#Q2.Which target industries experience the highest average financial loss from cyberattacks?
select `Target Industry`,avg(`Financial Loss (in Million $)`) as avg_loss
from cybersecurity_threats group by `Target Industry`
order by avg_loss desc;
#Q3.Which attack sources are associated with the highest number of affected users?
select `Attack Source`,sum(`Number of Affected Users`) as Total_of_affected_users
from cybersecurity_threats group by `Attack Source`
order by Total_of_affected_users desc;
#Q4.Which vulnerability types have the longest average resolution time?
select `Security Vulnerability Type`,avg(`Incident Resolution Time (in Hours)`)
as avg_resolution from cybersecurity_threats 
group by `Security Vulnerability Type` 
order by avg_resolution desc;
#Q5.Which defense mechanisms are associated with the lowest average financial loss?
select`Defense Mechanism Used`,avg(`Financial Loss (in Million $)`) as avg_loss
from cybersecurity_threats group by `Defense Mechanism Used`
order by avg_loss asc;
#Q6. Which countries have the highest average financial loss per incident?
select`Country`,avg(`Financial Loss (in Million $)`) as avg_loss
from cybersecurity_threats group by `Country`
order by avg_loss desc;
#Q7. Which attack types take the longest to resolve on average?
select `Attack Type`,avg(`Incident Resolution Time (in Hours)`) as avg_resolution
from cybersecurity_threats group by `Attack Type`
order by avg_resolution desc;
#Q8. Which industries have the highest average number of affected users per incident?
select`Target Industry`,avg(`Number of Affected Users`) as avg_affected_users
from cybersecurity_threats
group by `Target Industry` order by avg_affected_users desc;
#Q9. Which attack types combine high financial loss with long resolution times?
select`Attack Type`,sum(`Financial Loss (in Million $)`) as total_loss,
avg(`Incident Resolution Time (in Hours)`) as avg_resolution
from cybersecurity_threats group by `Attack Type`
order by total_loss desc, avg_resolution desc;
#Q10. What percentage of total financial loss comes from each attack type?
select`Attack Type`,sum(`Financial Loss (in Million $)`) as total_loss,
round(sum(`Financial Loss (in Million $)`) * 100.0 /
        (select sum(`Financial Loss (in Million $)`)
         from cybersecurity_threats),2) as loss_percentage
from cybersecurity_threats
group by `Attack Type`
order by loss_percentage desc;
#Q11. Which attack source is most frequently associated with each target industry?
with source_counts as (select`Target Industry`,`Attack Source`,
        count(*) as incident_count,
        row_number() over (partition by `Target Industry`
            order by count(*) desc
        ) as rn
    from cybersecurity_threats
    group by `Target Industry`, `Attack Source`
)
select
    `Target Industry`,
    `Attack Source`,
    incident_count
from source_counts
where rn = 1;
#Q12. Which countries have an average incident loss above the overall average?
select `Country`,avg(`Financial Loss (in Million $)`) as avg_loss
from cybersecurity_threats group by `Country`
having avg(`Financial Loss (in Million $)`) >
    (select avg(`Financial Loss (in Million $)`)
     from cybersecurity_threats)
order by avg_loss desc;
#Q13. Which attack types have an average resolution time above the overall average?
select`Attack Type`,avg(`Incident Resolution Time (in Hours)`) as avg_resolution
from cybersecurity_threats
group by `Attack Type`
having avg(`Incident Resolution Time (in Hours)`) >
    (select avg(`Incident Resolution Time (in Hours)`)
     from cybersecurity_threats)
order by avg_resolution desc;
#Q14. How does total financial loss change year over year?
with yearly_loss as (
    select
        `Year`,
        sum(`Financial Loss (in Million $)`) as total_loss
    from cybersecurity_threats
    group by `Year`
),
loss_changes as (
    select
        `Year`,
        total_loss,
        lag(total_loss) over (order by `Year`) as previous_loss
    from yearly_loss
)
select
    `Year`,
    total_loss,
    previous_loss,
    total_loss - previous_loss as loss_change
from loss_changes
order by `Year`;
#Q15. Which attack type ranks highest in financial loss within each year?
with yearly_attacks as (
    select
        `Year`,
        `Attack Type`,
        sum(`Financial Loss (in Million $)`) as total_loss
    from cybersecurity_threats
    group by `Year`, `Attack Type`
),
ranked_attacks as (
    select
        *,
        row_number() over (
            partition by `Year`
            order by total_loss desc
        ) as rn
    from yearly_attacks
)
select
    `Year`,
    `Attack Type`,
    total_loss
from ranked_attacks
where rn = 1
order by `Year`;
#Q16. Which industries show the greatest increase in financial loss between consecutive years?
with yearly_industry_loss as (
    select
        `Year`,
        `Target Industry`,
        sum(`Financial Loss (in Million $)`) as total_loss
    from cybersecurity_threats
    group by `Year`, `Target Industry`
),
industry_changes as (
    select
        `Year`,
        `Target Industry`,
        total_loss,
        lag(total_loss) over (
            partition by `Target Industry`
            order by `Year`
        ) as previous_loss
    from yearly_industry_loss
)
select
    `Year`,
    `Target Industry`,
    total_loss,
    previous_loss,
    total_loss - previous_loss as loss_increase
from industry_changes
where previous_loss is not null
order by loss_increase desc;
#Q17. Which attack sources have the highest average financial loss per affected user?
select`Attack Source`,
    sum(`Financial Loss (in Million $)`) as total_loss,
    sum(`Number of Affected Users`) as total_affected_users,
    sum(`Financial Loss (in Million $)`) /
        nullif(sum(`Number of Affected Users`), 0) as loss_per_user
from cybersecurity_threats
group by `Attack Source`
order by loss_per_user desc;
#Q18. Which defense mechanism has the shortest average resolution time for each attack type?
with defense_rank as (
    select
        `Attack Type`,
        `Defense Mechanism Used`,
        avg(`Incident Resolution Time (in Hours)`) as avg_resolution,
        row_number() over (
            partition by `Attack Type`
            order by avg(`Incident Resolution Time (in Hours)`) asc
        ) as rn
    from cybersecurity_threats
    group by `Attack Type`, `Defense Mechanism Used`
)
select
    `Attack Type`,
    `Defense Mechanism Used`,
    avg_resolution
from defense_rank
where rn = 1;
#Q19. Which country–industry combinations have higher average losses than their country's average incident loss?
with country_avg as (
    select
        `Country`,
        avg(`Financial Loss (in Million $)`) as avg_country_loss
    from cybersecurity_threats
    group by `Country`
),
industry_avg as (
    select
        `Country`,
        `Target Industry`,
        avg(`Financial Loss (in Million $)`) as avg_industry_loss
    from cybersecurity_threats
    group by `Country`, `Target Industry`
)
select
    i.`Country`,
    i.`Target Industry`,
    i.avg_industry_loss,
    c.avg_country_loss
from industry_avg i
join country_avg c
    on i.`Country` = c.`Country`
where i.avg_industry_loss > c.avg_country_loss
order by
    (i.avg_industry_loss - c.avg_country_loss) desc;
#Q20. Which combinations of attack type, source, and vulnerability have the greatest combined impact?
select
    `Attack Type`,
    `Attack Source`,
    `Security Vulnerability Type`,
    count(*) as incident_count,
    sum(`Financial Loss (in Million $)`) as total_loss,
    sum(`Number of Affected Users`) as total_affected_users,
    avg(`Incident Resolution Time (in Hours)`) as avg_resolution
from cybersecurity_threats
group by
    `Attack Type`,
    `Attack Source`,
    `Security Vulnerability Type`
order by
    total_loss desc,
    total_affected_users desc;