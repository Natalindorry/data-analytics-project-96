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
from sessions as s
group by s.medium;

-- 2.2. Каналы, по которым приходят посетители сайта, по дням
select
    s.medium,
    to_char(s.visit_date, 'dd') as visit_day,
    count(distinct s.visitor_id) as count_visitors
from sessions as s
group by visit_day, s.medium;


-- 2.2.1. Каналы в разрезе vk и yandex, по которым приходят посетители сайта,
-- по дням
select
    s.source,
    s.medium,
    to_char(s.visit_date, 'dd') as visit_day,
    count(distinct s.visitor_id) as count_visitors
from sessions as s
where s.source = 'vk' or s.source = 'yandex'
group by visit_day, s.source, s.medium;


-- 2.3. Каналы, по которым приходят посетители сайта, по дням недели
select
    s.medium,
    to_char(s.visit_date, 'Day') as day_of_week,
    count(distinct s.visitor_id) as count_visitors
from sessions as s
group by day_of_week, extract(isodow from visit_date), s.medium
order by extract(isodow from s.visit_date);

-- 2.4. Каналы, по которым приходят посетители сайта, по неделям
select
    s.medium,
    extract(week from s.visit_date) as number_of_week,
    count(distinct s.visitor_id) as count_visitors
from sessions as s
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
group by created_date;

-- 3.3. Количество посетителей и лидов по дням
with visitors as (
    select
        to_char(s.visit_date, 'dd') as visit_day,
        count(distinct s.visitor_id) as count_visitors
    from sessions as s
    group by visit_day
),

leads_tab as (
    select
        to_char(l.created_at, 'dd') as visit_day,
        count(distinct l.lead_id) as leads_count
    from leads as l
    group by visit_day
)

select
    v.visit_day,
    v.count_visitors,
    lt.leads_count
from visitors as v
left join leads_tab as lt
    on v.visit_day = lt.visit_day
order by v.visit_day;

-- 4.1. Конверсия из клика в лид, из лида в платящего клиента
with total_tab as (
    select
        s.visitor_id,
        s.visit_date,
        s.source as utm_source,
        s.medium as utm_medium,
        s.campaign as utm_campaign,
        l.lead_id,
        l.created_at,
        l.amount,
        l.closing_reason,
        l.status_id,
        row_number()
        over (
            partition by s.visitor_id
            order by s.visit_date desc
        )
        as rn
    from sessions as s
    left join leads as l
        on
            s.visitor_id = l.visitor_id
            and s.visit_date <= l.created_at
    where s.medium != 'organic'
    order by s.visitor_id
),

last_paid_click as (
    select *
    from total_tab
    where rn = 1
)

select
    count(distinct visitor_id) as count_visitors,
    count(distinct lead_id) as count_leads,
    (
        select count(distinct last_paid_click.lead_id)
        from last_paid_click
        where last_paid_click.amount != 0
    ) as count_buyers
from last_paid_click;


-- 4.2. Конверсии с процентовкой
with total_tab as (
    select
        s.visitor_id,
        s.visit_date,
        s.source as utm_source,
        s.medium as utm_medium,
        s.campaign as utm_campaign,
        l.lead_id,
        l.created_at,
        l.amount,
        l.closing_reason,
        l.status_id,
        row_number()
        over (
            partition by s.visitor_id
            order by s.visit_date desc
        )
        as rn
    from sessions as s
    left join leads as l
        on
            s.visitor_id = l.visitor_id
            and s.visit_date <= l.created_at
    where s.medium != 'organic'
    order by s.visitor_id
),

last_paid_click as (
    select *
    from total_tab
    where rn = 1
),

conversion as (
    select
        count(distinct visitor_id) as count_visitors,
        count(distinct lead_id) as count_leads,
        (
            select count(distinct last_paid_click.lead_id)
            from last_paid_click
            where last_paid_click.amount != 0
        ) as count_buyers
    from last_paid_click
)

select
    count_visitors,
    count_leads,
    count_buyers,
    round(count_leads * 100.0 / count_visitors, 2) as per_leads,
    round(count_buyers * 100.0 / count_leads, 2) as per_buyers
from conversion;


-- 5.1. Затраты по разным каналам в динамике по дням
(select
    utm_source,
    utm_medium,
    to_char(campaign_date, 'dd') as campaign_date,
    sum(daily_spent) as total_cost
from vk_ads
group by to_char(campaign_date, 'dd'), utm_source, utm_medium)
union all
(select
    utm_source,
    utm_medium,
    to_char(campaign_date, 'dd') as campaign_date,
    sum(daily_spent) as total_cost
from ya_ads
group by to_char(campaign_date, 'dd'), utm_source, utm_medium)
order by campaign_date;


-- 5.2. Затраты по source по дням
(select
    utm_source,
    to_char(campaign_date, 'dd') as campaign_date,
    sum(daily_spent) as total_cost
from vk_ads
group by to_char(campaign_date, 'dd'), utm_source)
union all
(select
    utm_source,
    to_char(campaign_date, 'dd') as campaign_date,
    sum(daily_spent) as total_cost
from ya_ads
group by to_char(campaign_date, 'dd'), utm_source)
order by campaign_date;

-- 5.3. Затраты по разным каналам в динамике по дням недели
with tab as (
    (
        select
            utm_source,
            utm_medium,
            extract(isodow from campaign_date) as number_day,
            to_char(campaign_date, 'Day') as day_of_week,
            sum(daily_spent) as total_cost
        from vk_ads
        group by
            extract(isodow from campaign_date),
            to_char(campaign_date, 'Day'),
            utm_source,
            utm_medium
    )
    union all
    (
        select
            utm_source,
            utm_medium,
            extract(isodow from campaign_date) as number_day,
            to_char(campaign_date, 'Day') as day_of_week,
            sum(daily_spent) as total_cost
        from ya_ads
        group by
            extract(isodow from campaign_date),
            to_char(campaign_date, 'Day'),
            utm_source,
            utm_medium
    )
)

select
    day_of_week,
    total_cost,
    utm_source,
    utm_medium
from tab
group by day_of_week, total_cost, utm_source, utm_medium, number_day
order by number_day;

-- 6.1. Маркетинговые метрики, окупаемость по source
with total_tab as (
    select
        s.visitor_id,
        s.visit_date,
        s.source as utm_source,
        s.medium as utm_medium,
        s.campaign as utm_campaign,
        l.lead_id,
        l.created_at,
        l.amount,
        l.closing_reason,
        l.status_id,
        row_number()
        over (
            partition by s.visitor_id
            order by s.visit_date desc
        )
        as rn
    from sessions as s
    left join leads as l
        on
            s.visitor_id = l.visitor_id
            and s.visit_date <= l.created_at
    where s.medium != 'organic'
    order by s.visitor_id
),

last_paid_click as (
    select *
    from total_tab
    where rn = 1
),

counting as (
    select
        lpc.utm_source,
        lpc.utm_medium,
        lpc.utm_campaign,
        date(lpc.visit_date) as visit_date,
        count(lpc.visitor_id) as visitors_count,
        count(lpc.lead_id) as leads_count,
        count(*) filter (where lpc.status_id = '142') as purchases_count,
        sum(lpc.amount) as revenue
    from last_paid_click as lpc
    group by
        date(lpc.visit_date),
        lpc.utm_source,
        lpc.utm_medium,
        lpc.utm_campaign
),

ads as (
    (
        select
            utm_source,
            utm_medium,
            utm_campaign,
            date(campaign_date) as campaign_date,
            sum(daily_spent) as total_cost
        from vk_ads
        group by
            date(campaign_date),
            utm_source,
            utm_medium,
            utm_campaign
    )
    union all
    (
        select
            utm_source,
            utm_medium,
            utm_campaign,
            date(campaign_date) as campaign_date,
            sum(daily_spent) as total_cost
        from ya_ads
        group by
            date(campaign_date),
            utm_source,
            utm_medium,
            utm_campaign
    )
)

select
    c.utm_source,
    round(sum(a.total_cost) / sum(c.visitors_count), 2) as cpu,
    round(sum(a.total_cost) / sum(c.leads_count), 2) as cpl,
    round(sum(a.total_cost) / sum(c.purchases_count), 2) as cppu,
    round(
        (sum(c.revenue) - sum(a.total_cost)) / sum(a.total_cost) * 100.0, 2
    ) as roi
from counting as c
inner join ads as a
    on
        c.visit_date = a.campaign_date
        and c.utm_source = a.utm_source
        and c.utm_medium = a.utm_medium
        and c.utm_campaign = a.utm_campaign
group by c.utm_source;


-- 7.1. Сводная таблица затрат и выручки по vk и yandex
with cost as (
    (select
        utm_source,
        to_char(campaign_date, 'dd') as campaign_date,
        sum(daily_spent) as total_cost
    from vk_ads
    group by to_char(campaign_date, 'dd'), utm_source)
    union all
    (select
        utm_source,
        to_char(campaign_date, 'dd') as campaign_date,
        sum(daily_spent) as total_cost
    from ya_ads
    group by to_char(campaign_date, 'dd'), utm_source)
),

rev as (
    select
        s.source as utm_source,
        to_char(l.created_at, 'dd') as campaign_date,
        sum(l.amount) as total_revenue
    from leads as l
    inner join sessions as s
        on l.visitor_id = s.visitor_id
    where s.source = 'vk' or s.source = 'yandex'
    group by campaign_date, utm_source
)

select
    c.utm_source,
    sum(c.total_cost) as total_cost,
    sum(rev.total_revenue) as total_revenue
from cost as c
left join rev
    on
        c.campaign_date = rev.campaign_date
        and c.utm_source = rev.utm_source
group by c.utm_source;

-- 7.2. Сводная таблица затрат и выручки по каналам vk и yandex по дням
with cost as (
    (select
        utm_source,
        utm_medium,
        to_char(campaign_date, 'dd') as campaign_date,
        sum(daily_spent) as total_cost
    from vk_ads
    group by to_char(campaign_date, 'dd'), utm_source, utm_medium)
    union all
    (select
        utm_source,
        utm_medium,
        to_char(campaign_date, 'dd') as campaign_date,
        sum(daily_spent) as total_cost
    from ya_ads
    group by to_char(campaign_date, 'dd'), utm_source, utm_medium)
),

rev as (
    select
        s.source as utm_source,
        s.medium as utm_medium,
        to_char(l.created_at, 'dd') as campaign_date,
        sum(l.amount) as total_revenue
    from leads as l
    inner join sessions as s
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
from cost as c
left join rev
    on
        c.campaign_date = rev.campaign_date
        and c.utm_source = rev.utm_source
        and c.utm_medium = rev.utm_medium
group by c.campaign_date, c.utm_source, c.utm_medium;


-- 7.3. Количество дней, за которое закрывается 90% лидов
with total_tab as (
    select
        s.visitor_id,
        s.visit_date,
        s.source as utm_source,
        s.medium as utm_medium,
        s.campaign as utm_campaign,
        l.lead_id,
        l.created_at,
        l.amount,
        l.closing_reason,
        l.status_id,
        row_number()
        over (
            partition by s.visitor_id
            order by s.visit_date desc
        )
        as rn
    from sessions as s
    left join leads as l
        on
            s.visitor_id = l.visitor_id
            and s.visit_date <= l.created_at
    where s.medium != 'organic'
    order by s.visitor_id
),

last_paid_click as (
    select *
    from total_tab
    where rn = 1
)

select
    utm_source,
    utm_medium,
    percentile_disc(0.90) within group (
        order by date_part('day', created_at - visit_date)
    ) as days_to_lead
from last_paid_click
group by utm_source, utm_medium
order by days_to_lead desc nulls last;
