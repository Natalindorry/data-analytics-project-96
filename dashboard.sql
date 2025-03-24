-- 1.1. Количество посетителей сайта по дням недели
select
	to_char(visit_date, 'Day') as day_of_week,
	count(distinct visitor_id) as count_visitors
from sessions
group by day_of_week, extract(isodow from visit_date)
order by extract(isodow from visit_date);

-- 1.2. Количество посетителей сайта по дням
select
	to_char(visit_date, 'dd') as visit_day,
	count(distinct visitor_id) as count_visitors
from sessions
group by visit_day
order by visit_day;

-- 2.1. Каналы, по которым приходят посетители сайта
select
	s.medium,
	count(distinct s.visitor_id) as count_visitors
from sessions s
group by s.medium;

-- 2.2. Каналы, по которым приходят посетители сайта, по дням
select
	to_char(s.visit_date, 'dd') as visit_day,
	s.medium,
	count(distinct s.visitor_id) as count_visitors
from sessions s
group by visit_day, s.medium;

-- 2.2.1. Каналы в разрезе vk и yandex, по которым приходят посетители сайта, по дням
select
	to_char(s.visit_date, 'dd') as visit_day,
	s.source,
	s.medium,
	count(distinct s.visitor_id) as count_visitors
from sessions s
where s.source = 'vk' or s.source = 'yandex'
group by visit_day, s.source, s.medium;

-- 2.3. Каналы, по которым приходят посетители сайта, по дням недели
select
	to_char(s.visit_date, 'Day') as day_of_week,
	s.medium,
	count(distinct s.visitor_id) as count_visitors
from sessions s
group by day_of_week, extract(isodow from visit_date), s.medium
order by extract(isodow from s.visit_date);

-- 2.4. Каналы, по которым приходят посетители сайта, по неделям
select
	extract(week from visit_date) as number_of_week,
	s.medium,
	count(distinct s.visitor_id) as count_visitors
from sessions s
group by number_of_week, s.medium;

-- 3.1. Количество лидов по дням недели
select
	to_char(created_at, 'Day') as day_of_week,
	count(distinct lead_id) as leads_count
from leads
group by day_of_week, extract(isodow from created_at)
order by extract(isodow from created_at);

-- 3.2. Количество лидов по дням
select
	to_char(created_at, 'dd') as created_date,
	count(distinct lead_id) as leads_count
from leads
group by created_date;   -- Почему этот запрос не группирует по created_at, если первое поле задать as created_at? 

-- 3.3. Количество посетителей и лидов по дням (общий график получился ненаглядный...)
with visitors as (
select
	to_char(s.visit_date, 'dd') as day,
	count(distinct s.visitor_id) as count_visitors
from sessions s
group by day
),
leads_tab as (
select
	to_char(l.created_at, 'dd') as day,
	count(distinct l.lead_id) as leads_count
from leads l
group by day
)
select 
	v.day,
	v.count_visitors,
	lt.leads_count
from visitors v
left join leads_tab lt 
	on v.day = lt.day
order by v.day;

-- 4.1. Конверсия из клика в лид, из лида в платящего клиента
select
	(select count(distinct visitor_id) from sessions) as count_visitors,
	(select count(distinct lead_id) from leads) as count_leads,
	(select count(distinct lead_id) from leads where amount !=0) as count_buyers;

-- 4.2. Конверсии с процентовкой
with tab as (
	select
		(select count(distinct visitor_id) from sessions) as count_visitors,
		(select count(distinct lead_id) from leads) as count_leads,
		(select count(distinct lead_id) from leads where amount !=0) as count_buyers
	)
select 
	count_visitors,
	count_leads,
	round(count_leads * 100.0 / count_visitors, 2) as per_leads,
	count_buyers,
	round(count_buyers * 100.0 / count_leads, 2) as per_buyers
from tab;

-- 5.1. Затраты по разным каналам в динамике по дням
	(select
		to_char(campaign_date, 'dd') as campaign_date,
		sum(daily_spent) as total_cost,
		utm_source,
		utm_medium
	from vk_ads
	group by 1, 3, 4)
	union all
	(select
		to_char(campaign_date, 'dd') as campaign_date,
		sum(daily_spent) as total_cost,
		utm_source,
		utm_medium
	from ya_ads
	group by 1, 3, 4)
	order by campaign_date;
	
-- 5.2. Затраты по source по дням
(select
		to_char(campaign_date, 'dd') as campaign_date,
		sum(daily_spent) as total_cost,
		utm_source
	from vk_ads
	group by 1, 3)
	union all
	(select
		to_char(campaign_date, 'dd') as campaign_date,
		sum(daily_spent) as total_cost,
		utm_source		
	from ya_ads
	group by 1, 3)
	order by campaign_date;

-- 5.3. Затраты по разным каналам в динамике по дням недели
with tab as (	
	(select
		extract(isodow from campaign_date) as number_day,
		to_char(campaign_date, 'Day') as day_of_week,
		sum(daily_spent) as total_cost,
		utm_source,
		utm_medium
	from vk_ads
	group by 1, 2, 4, 5)
	union all
	(select
		extract(isodow from campaign_date) as number_day,
		to_char(campaign_date, 'Day') as day_of_week,
		sum(daily_spent) as total_cost,
		utm_source,
		utm_medium
	from ya_ads
	group by 1, 2, 4, 5)
)
select 
	day_of_week,
	total_cost,
	utm_source,
	utm_medium
from tab
group by 1, 2, 3, 4, number_day
order by number_day;

-- 6.1. Маркетинговые метрики, окупаемость по source
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
	c.utm_source,
	round(sum(a.total_cost) / sum(c.visitors_count), 2) as cpu,
	round(sum(a.total_cost) / sum(c.leads_count), 2) as cpl,
	round(sum(a.total_cost) / sum(c.purchases_count), 2) as cppu,
	round((sum(c.revenue) - sum(a.total_cost)) / sum(a.total_cost) * 100.0, 2) as roi
from counting c
left join ads a
	on c.visit_date = a.campaign_date
	and c.utm_source = a.utm_source
	and c.utm_medium = a.utm_medium
	and c.utm_campaign = a.utm_campaign
where c.utm_source = 'vk' or c.utm_source = 'yandex'
group by c.utm_source;

-- 6.2. Попытка рассчитать те же метрики детально: по medium и campaign.
-- Выпадает ошибка: деление на ноль
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
	c.utm_source,
	c.utm_medium,
	c.utm_campaign,
	round(sum(a.total_cost) / sum(c.visitors_count), 2) as cpu,
	round(sum(a.total_cost) / sum(c.leads_count), 2) as cpl,
	round(sum(a.total_cost) / sum(c.purchases_count), 2) as cppu,
	round((sum(c.revenue) - sum(a.total_cost)) / sum(a.total_cost) * 100.0, 2) as roi
from counting c
left join ads a
	on c.visit_date = a.campaign_date
	and c.utm_source = a.utm_source
	and c.utm_medium = a.utm_medium
	and c.utm_campaign = a.utm_campaign
where c.utm_source = 'vk' or c.utm_source = 'yandex'
group by c.utm_source, c.utm_medium, c.utm_campaign;

-- 7.1. Сводная таблица затрат и выручки по vk и yandex
with cost as (
(select
		to_char(campaign_date, 'dd') as campaign_date,
		sum(daily_spent) as total_cost,
		utm_source
	from vk_ads
	group by 1, 3)
	union all
	(select
		to_char(campaign_date, 'dd') as campaign_date,
		sum(daily_spent) as total_cost,
		utm_source		
	from ya_ads
	group by 1, 3)
),
rev as (
select
	to_char(l.created_at, 'dd') as campaign_date,
	s.source as utm_source,
	sum(l.amount) as total_revenue
from leads l 
join sessions s
	on l.visitor_id = s.visitor_id
where s.source = 'vk' or s.source = 'yandex'
group by campaign_date, utm_source
)
select 
--	c.campaign_date,
	c.utm_source,
	sum(c.total_cost) as total_cost,
	sum(rev.total_revenue) as total_revenue
from cost c
left join rev
	on c.campaign_date = rev.campaign_date
	and c.utm_source = rev.utm_source
group by c.utm_source;

-- 7.2. Сводная таблица затрат и выручки по каналам vk и yandex по дням
with cost as (
(select
		to_char(campaign_date, 'dd') as campaign_date,
		sum(daily_spent) as total_cost,
		utm_source,
		utm_medium
	from vk_ads
	group by 1, 3, 4)
	union all
	(select
		to_char(campaign_date, 'dd') as campaign_date,
		sum(daily_spent) as total_cost,
		utm_source,
		utm_medium
	from ya_ads
	group by 1, 3, 4)
),
rev as (
select
	to_char(l.created_at, 'dd') as campaign_date,
	s.source as utm_source,
	s.medium as utm_medium,
	sum(l.amount) as total_revenue
from leads l 
join sessions s
	on l.visitor_id = s.visitor_id
where s.source = 'vk' or s.source = 'yandex'
group by campaign_date, utm_source, utm_medium
)
select 
	c.campaign_date,
	c.utm_source,
	c.utm_medium,
	sum(c.total_cost) as total_cost,
	sum(rev.total_revenue) as total_revenue
from cost c
left join rev
	on c.campaign_date = rev.campaign_date
	and c.utm_source = rev.utm_source
	and c.utm_medium = rev.utm_medium
group by c.campaign_date, c.utm_source, c.utm_medium;

-- 7.3. Количество дней, за которое закрывается 90% лидов
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
tab as(
	select
		v.visitor_id,
		v.visit_date,
		v.utm_source,
		v.utm_medium,
		v.utm_campaign,
		l.created_at,
		l.status_id,
		l.amount
	from visitors v
	left join leads l
		on v.visitor_id = l.visitor_id
		and l.created_at >= v.visit_date
)
select
	tab.utm_source,
	tab.utm_medium,
	percentile_disc(0.90) within group (
		order by date_part('day', created_at - visit_date)
		) as days_to_lead
from tab
group by 1, 2
order by 3 desc nulls last;
