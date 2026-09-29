 -- Hourly revenue
-- Profit and revenue trends
-- Seasonal revenue
-- Rider behavior and usage analysis

-- This view will be used instead of the CTE for cleaner and more understandable queries
create view bike as
with bike as (
select *
from bike_share_0
	union all
select *
from bike_share_yr_1
)
select
	bike.date_day as date_day,
	bike.season,
	bike.yr as year,
	bike.mnth as month,
	bike.hr as hour,
	bike.holiday,
	bike.weekday,
	bike.workingday as working_day,
	bike.weather_situation as weather_situation,
	bike.temperature as temperature,
	bike.atemperature as apparent_temperature,
	bike.humidity as humidity,
	bike.wind_speed as wind_speed,
	bike.rider_type,
	bike.riders,
	costa.price,
	costa.cogs
from bike
	left join costa
		on bike.yr = costa.yr;

-- Main query for Power BI
with bike as (
select *
from bike_share_0
	union all
select *
from bike_share_yr_1
)
select
	bike.date_day as date_day,
	bike.season,
	bike.yr as year,
	bike.mnth as month,
	bike.hr as hour,
	bike.holiday,
	bike.weekday,
	bike.workingday as working_day,
	bike.weather_situation as weather_situation,
	bike.temperature as temperature,
	bike.atemperature as apparent_temperature,
	bike.humidity as humidity,
	bike.wind_speed as wind_speed,
	bike.rider_type,
	bike.riders,
	costa.price,
	costa.cogs
from bike
	left join costa
		on bike.yr = costa.yr;


-- Hourly revenue
select
	hour,
	round(sum(riders * price), 0) as hourly_revenue,
	round(sum(riders * cogs), 0) as hourly_cost,
	round(sum(riders * (price - cogs)), 0) as hourly_profit
from bike
	group by hour;
	
-- Profit and revenue trends
select
	extract(year from date_day) as year,
	extract(month from date_day) as month,
	round(sum(riders * price), 0) as revenue,
	round(sum(riders * cogs), 0) as cost,
	round(sum(riders * (price - cogs)), 0) as profit
from bike
	group by extract(year from date_day), extract(month from date_day)
	order by month, year desc;

-- Seasonal revenue
with season as (
select
	CASE
		WHEN month in (12,1,2) then 'winter'
		WHEN month in (3,4,5) then 'spring'
		WHEN month in (6,7,8) then 'summer'
		WHEN month in (9,10,11) then 'autumn'
		ELSE 'unknown'
	END as season,
	riders,
    price,
    cogs
from bike
)
select
	season,
	round(sum(riders * (price - cogs)), 0) as profit
from season
	group by season.season;

-- Yearly revenue
select
	extract(year from date_day) as year,
	to_char(sum(riders * price), 'fm999,999,999') as revenue,
	to_char(sum(riders * (price - cogs)), 'fm999,999,999') as net_profit
from bike
	group by extract(year from date_day);

-- Rider behavior and usage analysis:
-- Yearly riders
select
	extract(year from date_day) as year,
	rider_type,
	to_char(sum(riders), 'fm999,999,999') as total_riders
from bike
	group by extract(year from date_day),rider_type
	order by extract(year from date_day) desc;

-- Total riders per rider type
select
	rider_type,
	to_char(sum(riders),'fm999,999,999') as total_riders
from bike
	group by rider_type;

-- Which day has the most riders?
select
	to_char(sum(riders), 'fm999,999,999') as total_riders,
	CASE
    	WHEN weekday = 0 THEN 'Sunday'
    	WHEN weekday = 1 THEN 'Monday'
    	WHEN weekday = 2 THEN 'Tuesday'
    	WHEN weekday = 3 THEN 'Wednesday'
    	WHEN weekday = 4 THEN 'Thursday'
    	WHEN weekday = 5 THEN 'Friday'
    	WHEN weekday = 6 THEN 'Saturday'
	END AS day_name
from bike
	group by weekday
	order by total_riders;

-- Do we receive more riders on holidays?
select
	round(sum(riders)::numeric / count(distinct date_day), 0) as avg_riders_per_day,
	case
		when holiday = 'false' then 'non_holiday'
		else 'holiday'
	end as holiday
from bike
group by holiday;

-- How many riders do we have per hour?
select
	hour,
	to_char(sum(riders), 'fm999,999,999') as total_riders
from bike
group by hour
order by hour desc;

-- How does temperature relate to rider demand?
select
	round(sum(riders) / count(distinct( date_day, hour)), 0) as total_riders,
    CASE
        WHEN (temperature * 47 - 8) < 0 THEN 'Freezing'
        WHEN (temperature * 47 - 8) < 10 THEN 'Cold'
        WHEN (temperature * 47 - 8) < 20 THEN 'Mild'
        WHEN (temperature * 47 - 8) < 30 THEN 'Warm'
        ELSE 'Hot'
    END AS temperature_category
from bike
group by temperature_category
order by temperature_category;

-- How many riders do we have at each humidity level?
SELECT
	round(sum(riders) / count (distinct( date_day, hour)), 0) as total_riders,
    CASE
        WHEN humidity < 0.30 THEN 'Very Dry'
        WHEN humidity < 0.50 THEN 'Dry'
        WHEN humidity < 0.70 THEN 'Moderate'
        WHEN humidity < 0.85 THEN 'humidityid'
        ELSE 'Very Humid'
    END AS humidity_category
from bike
group by humidity_category
order by total_riders desc;

-- How does wind_speed relate to rider demand?
select
	round(sum(riders) / count(distinct( date_day, hour)), 0) as total_riders,
	CASE
    	WHEN wind_speed < 0.25 THEN 'Low'
    	WHEN wind_speed < 0.50 THEN 'Moderate'
    	ELSE 'High'
END AS wind_speed_category
from bike
group by wind_speed_category;  

-- Which weather conditions do riders prefer?
select
	round(sum(riders)::numeric / count(distinct (date_day, hour)), 1) as total_riders,
    CASE
        WHEN weather_situation = 1 THEN 'Clear'
        WHEN weather_situation = 2 THEN 'Mist / Cloudy'
        WHEN weather_situation = 3 THEN 'Light Rain / Snow'
        WHEN weather_situation = 4 THEN 'Heavy Rain / Snow'
    END AS weather_condition
FROM bike
group by weather_situation
order by total_riders desc;