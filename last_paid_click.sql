-- Step 2. Создание витрины для модели атрибуции Last Paid Click

with paid_click as (
	select
		visitor_id,
		visit_date,
		source,
		medium,
		campaign
	from sessions 
	where medium != 'organic'
	order by visitor_id, visit_date desc
),
visitors as (
	select distinct on (visitor_id) *
	from paid_click
)
select
	v.visitor_id,
	v.visit_date,
	v.source as utm_source,
	v.medium as utm_medium,
	v.campaign as utm_campaign,
	l.lead_id,
	l.created_at,
	l.amount,
	l.closing_reason,
	l.status_id
from visitors v
left join leads l
	on v.visitor_id = l.visitor_id
order by
	amount desc nulls last,
	visit_date,
	utm_source,
	utm_medium,
	utm_campaign
limit 10;
