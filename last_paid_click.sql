-- Step 2. Создание витрины для модели атрибуции Last Paid Click

with total_tab as (
	select
		s.visitor_id,
		s.visit_date,
		row_number() over(partition by s.visitor_id order by s.visit_date desc) as rn,
		s.source as utm_source,
		s.medium as utm_medium,
		s.campaign as utm_campaign,
		l.lead_id,
		l.created_at,
		l.amount,
		l.closing_reason,
		l.status_id
	from sessions s
	left join leads l
		on s.visitor_id = l.visitor_id
		and l.created_at >= s.visit_date
	where s.medium != 'organic'
order by s.visitor_id
)
select
	visitor_id,
	visit_date,
	utm_source,
	utm_medium,
	utm_campaign,
	lead_id,
	created_at,
	amount,
	closing_reason,
	status_id
from total_tab
where rn = 1
order by 
	amount desc nulls last,
	visit_date,
	utm_source,
	utm_medium,
	utm_campaign
limit 10;

	