use mavenfuzzyfactory;
select * from orders;

-- device type by click through rate, desktop has 85% rate and mbile has 30.9% rate
select
 device_type,
-- count(website_sessions.website_session_id) as sessions,
-- count(orders.order_id) as orders,
count(orders.order_id)/count(website_sessions.website_session_id) as click_thr_rate
from website_sessions
left join orders
on orders.website_session_id = website_sessions.website_session_id
group by device_type
order by click_thr_rate desc;

select 
utm_campaign,
utm_content,
http_referer,
count(website_session_id) as sessions 
from website_sessions 
group by 1,2,3 
order by 4 desc;

select
-- yearweek(created_at) as year_week,
min(date(created_at)) as week_start_date,
count(distinct website_session_id) as sessions
from website_sessions
where created_at < '2021-05-10'
and utm_source = 'gsearch'
and utm_campaign = 'nonbrand'
group by yearweek(created_at);

select 
-- yearweek(created_at) ,
min(date(created_at)) as weeek_start_date,
count(distinct case when device_type = 'desktop' then website_session_id else null end) as desktop_session,
count(distinct case when device_type = 'mobile' then website_session_id else null end) as mobile_session
from website_sessions
where created_at < '2012-06-09'
and created_at > '2012-04-15'
and utm_campaign = 'nonbrand'
and utm_source = 'gsearch'
group by yearweek(created_at);

# TOP WEBSITE PAGES
select  
     pageview_url,
     count(distinct website_pageview_id) as pvs,
     count(distinct website_session_id) as sessions
from website_pageviews
where created_at < '2012-06-09'
group by 1
order by 2 desc;

# TOP LANDING PAGES
# STEP 1: find the first pageview_id
# STEP 2: find the url
create temporary table first_pv_session
select 
website_session_id,
min(website_pageview_id) as first_pv
from website_pageviews
where created_at < '2012-06-12'
group by 1;

select 
website_pageviews.pageview_url as landing_page,
count(distinct website_pageviews.website_session_id) as sessions
from website_pageviews
left join first_pv_session
on first_pv_session.first_pv = website_pageviews.website_pageview_id
where created_at < '2012-06-12'
group by 1
order by 2 desc;

create temporary table first_pageview_demo
select 
website_pageviews.website_session_id as sessions,
min(website_pageview_id) as first_pv
from website_pageviews
left join website_sessions
on website_sessions.website_session_id = website_pageviews.website_session_id
and website_sessions.created_at between '2014-01-01' and '2014-02-01'
group by 1;

create temporary table session_w_landing_page
select 
website_pageviews.pageview_url as landing_page,
first_pageview_demo.sessions as sessions
from website_pageviews
left join first_pageview_demo
on first_pageview_demo.first_pv = website_pageviews.website_pageview_id
;

create temporary table bounced_sessions_only
select 
session_w_landing_page.landing_page,
session_w_landing_page.sessions,
count( website_pageviews.website_pageview_id) as count_of_pages_viewed
from session_w_landing_page
left join website_pageviews
on session_w_landing_page.sessions = website_pageviews.website_pageview_id
group by 1,2
having count(website_pageviews.website_pageview_id) = 1;

select 
session_w_landing_page.landing_page,
count(distinct session_w_landing_page.sessions) as sessions,
count(distinct bounced_sessions_only.sessions) as boounced_sessions,
count(distinct bounced_sessions_only.sessions)/count(distinct session_w_landing_page.sessions) as bounce_rate_conv
from session_w_landing_page
left join bounced_sessions_only
on bounced_sessions_only.sessions = session_w_landing_page.sessions
group by 1;

select 
	 year(website_sessions.created_at) as yr,
     quarter(orders.created_at) as qtr,
     count(distinct website_sessions.website_session_id) as sessions,
	count(distinct orders.order_id) as orders
from orders
left join website_sessions
on website_sessions.website_session_id = orders.website_session_id
group by 1,2;

select 
	 year(website_sessions.created_at) as yr,
     quarter(orders.created_at) as qtr,
	 count(distinct orders.order_id)/count(distinct website_sessions.website_session_id) as sessions_to_order_conversion_rate,
     sum(orders.price_usd)/count(distinct orders.order_id) as revenue_per_order,
     sum(orders.price_usd)/count(distinct website_sessions.website_session_id) as revenue_per_session
from orders
left join website_sessions
on website_sessions.website_session_id = orders.website_session_id
group by 1,2
order by 1,2;

select 
	 year(website_sessions.created_at) as yr,
     quarter(orders.created_at) as qtr,
     count(case when website_sessions.utm_source = 'gsearch' and website_sessions.utm_campaign = 'nonbrand' then orders.order_id else null end) as gsearch_nonbrand,
     count(case when website_sessions.utm_source = 'bsearch' and website_sessions.utm_campaign = 'nonbrand' then orders.order_id else null end) as bsearch_nonbrand,
     count(case when website_sessions.utm_campaign = 'brand' then orders.order_id else null end) as brand_overall,
     count(case when website_sessions.utm_source = 'null' and website_sessions.utm_campaign = 'null' then orders.order_id else null end) as direct_type_in,
     count(case when website_sessions.utm_source = 'null' and website_sessions.http_referer = 'not null' then orders.order_id else null end) as organic 
from orders
left join website_sessions
on website_sessions.website_session_id = orders.website_session_id
group by 1,2
order by 1,2;