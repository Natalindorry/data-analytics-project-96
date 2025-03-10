-- Step 3.
with paid_click as (
	select
		visitor_id,
		visit_date,
		source as utm_source,
		medium as utm_medium,
		campaign as utm_campaign
	from sessions 
	where medium != 'organic'
	order by visitor_id, visit_date desc
),
visitors as (
	select distinct on (visitor_id) *
	from paid_click
),
counting as(
	select
		date(v.visit_date) as visit_date,
		v.utm_source,
		v.utm_medium,
		v.utm_campaign,
		count(v.visitor_id) as visitors_count,
		count(l.lead_id) as leads_count,
		count(case
				when l.status_id = '142' then 'status_id'
			end) as purchases_count,
		sum(l.amount) as revenue
	from visitors v
	left join leads l
		on v.visitor_id = l.visitor_id
	group by 1, 2, 3, 4
),
ads as (
	(select
		date(campaign_date) as campaign_date,
		sum(daily_spent) as total_cost,
		utm_source,
		utm_medium,
		utm_campaign
	from vk_ads
	group by 1, 3, 4, 5)
	union all
	(select
		date(campaign_date) as campaign_date,
		sum(daily_spent) as total_cost,
		utm_source,
		utm_medium,
		utm_campaign
	from ya_ads
	group by 1, 3, 4, 5)
)
select
	c.visit_date,
	c.utm_source,
	c.utm_medium,
	c.utm_campaign,
	c.visitors_count,
	a.total_cost,
	c.leads_count,
	c.purchases_count,
	c.revenue
from counting c
left join ads a
	on c.visit_date = a.campaign_date
	and c.utm_source = a.utm_source
	and c.utm_medium = a.utm_medium
	and c.utm_campaign = a.utm_campaign
order by
	revenue desc nulls last,
	visit_date,
	visitors_count desc,
	utm_source,
	utm_medium,
	utm_campaign
limit 15;