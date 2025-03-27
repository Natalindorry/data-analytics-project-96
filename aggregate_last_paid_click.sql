-- Step 3.

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
        date(lpc.visit_date) as visit_date,
        count(lpc.visitor_id) as visitors_count,
        lpc.utm_source,
        lpc.utm_medium,
        lpc.utm_campaign,
        count(lpc.lead_id) as leads_count,
        count(*) filter (where lpc.status_id = '142') as purchases_count,
        sum(lpc.amount) as revenue
    from last_paid_click as lpc
    group by 1, 3, 4, 5
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
    c.visitors_count,
    c.utm_source,
    c.utm_medium,
    c.utm_campaign,
    a.total_cost,
    c.leads_count,
    c.purchases_count,
    c.revenue
from counting as c
left join ads as a
    on
        c.visit_date = a.campaign_date
        and c.utm_source = a.utm_source
        and c.utm_medium = a.utm_medium
        and c.utm_campaign = a.utm_campaign
order by
    revenue desc nulls last,
    visit_date asc,
    visitors_count desc,
    utm_source asc,
    utm_medium asc,
    utm_campaign asc
limit 15;

