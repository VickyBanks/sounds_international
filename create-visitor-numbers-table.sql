--https://github.com/bbc/sounds-analytics/blob/master/sounds-product/dashboards/signed-in-accounts/main_dashboad_scv_users_with_voice_and_tv_weekly_enriched.sql
/*
In the main Sounds KPI dash on the KPI tab the audience_activity_daily_summary_enriched is used to
find signed-in user data and feeds the table radio1_sandbox.sounds_dashboard_1_page_views  which powers the dash.
*/

--------------- For Sounds International ---------------------
-- Create a table to hold the raw un-summarised data
DROP TABLE IF EXISTS radio1_sandbox.vb_sounds_int_users;
CREATE TABLE radio1_sandbox.vb_sounds_int_users
(
    week_commencing          date,
    signed_in_status         varchar(40),
    audience_id              varchar(400),
    app_type                 varchar(40),
    geo_country_site_visited varchar(400),
    age_range                varchar(20),
    gender                   varchar(40)
);
-- 1. Get the user, if they're signed in or not, country and metadata for the past week.
INSERT INTO radio1_sandbox.vb_sounds_int_users
SELECT DISTINCT TRUNC(DATE_TRUNC('week', getdate() - 7)) AS week_commencing,
                CASE
                    WHEN aads.is_signed_in = TRUE AND aads.is_personalisation_on = TRUE THEN 'signed in'
                    ELSE 'signed out' END AS signed_in_status,
                aads.audience_id,
                aads.app_type,
                aads.geo_country_site_visited,
                p.age_range,
                p.gender
FROM s3_audience.audience_activity_daily_summary aads
         LEFT JOIN prez.profile_extension p
                    ON p.bbc_hid3 = aads.audience_id
WHERE aads.destination = 'PS_SOUNDS'
  AND aads.app_name = 'sounds'
  AND aads.geo_country_site_visited IN ('United Kingdom', 'Jersey', 'Isle of Man', 'Guernsey') -- Not UK
  AND aads.dt BETWEEN TO_CHAR(TRUNC(DATE_TRUNC('week', getdate() - 7)), 'yyyymmdd') -- limits to the past week (Mon-Sun)
      AND TO_CHAR(TRUNC(DATE_TRUNC('week', getdate() - 7) + 6), 'yyyymmdd')
  AND (aads.app_type = 'responsive' OR aads.app_type = 'mobile-app' OR aads.app_type = 'bigscreen-html')
;


--2. Some users may be seen on multiple platforms so find distinct users to ALL platfomrs
INSERT INTO radio1_sandbox.vb_sounds_int_users
SELECT DISTINCT TRUNC(DATE_TRUNC('week', getdate() - 7)) AS week_commencing,
                CASE
                    WHEN aads.is_signed_in = TRUE AND aads.is_personalisation_on = TRUE THEN 'signed in'
                    ELSE 'signed out' END AS signed_in_status,
                aads.audience_id,
                CAST('all' AS varchar(20)) AS app_type,
                aads.geo_country_site_visited,
                p.age_range,
                p.gender
FROM s3_audience.audience_activity_daily_summary aads
         LEFT JOIN prez.profile_extension p
                    ON p.bbc_hid3 = aads.audience_id
WHERE aads.destination = 'PS_SOUNDS'
  AND aads.app_name = 'sounds'
  AND aads.geo_country_site_visited IN ('United Kingdom', 'Jersey', 'Isle of Man', 'Guernsey') -- Not UK
  AND aads.dt BETWEEN TO_CHAR(TRUNC(DATE_TRUNC('week', getdate() - 7)), 'yyyymmdd') -- limits to the past week (Mon-Sun)
      AND TO_CHAR(TRUNC(DATE_TRUNC('week', getdate() - 7) + 6), 'yyyymmdd')
  AND (aads.app_type = 'responsive' OR aads.app_type = 'mobile-app' OR aads.app_type = 'bigscreen-html')
;

--3. Some users may be seen in multiple countries so these need deduping for each app type and for all countries
-- all countries all apps
INSERT INTO radio1_sandbox.vb_sounds_int_users
SELECT DISTINCT TRUNC(DATE_TRUNC('week', getdate() - 7)) AS week_commencing,
                CASE
                    WHEN aads.is_signed_in = TRUE AND aads.is_personalisation_on = TRUE THEN 'signed in'
                    ELSE 'signed out' END AS signed_in_status,
                aads.audience_id,
                CAST('all' AS varchar(20)) AS app_type,
                CAST('All International' as varchar(20)) AS geo_country_site_visited, -- combine everyone regardless of country
                p.age_range,
                p.gender
FROM s3_audience.audience_activity_daily_summary aads
         LEFT JOIN prez.profile_extension p
                    ON p.bbc_hid3 = aads.audience_id
WHERE aads.destination = 'PS_SOUNDS'
  AND aads.app_name = 'sounds'
  AND aads.geo_country_site_visited IN ('United Kingdom', 'Jersey', 'Isle of Man', 'Guernsey') -- Not UK
  AND aads.dt BETWEEN TO_CHAR(TRUNC(DATE_TRUNC('week', getdate() - 7)), 'yyyymmdd') -- limits to the past week (Mon-Sun)
      AND TO_CHAR(TRUNC(DATE_TRUNC('week', getdate() - 7) + 6), 'yyyymmdd')
  AND (aads.app_type = 'responsive' OR aads.app_type = 'mobile-app' OR aads.app_type = 'bigscreen-html')
;
-- All countries but split by app
INSERT INTO radio1_sandbox.vb_sounds_int_users
SELECT DISTINCT TRUNC(DATE_TRUNC('week', getdate() - 7)) AS week_commencing,
                CASE
                    WHEN aads.is_signed_in = TRUE AND aads.is_personalisation_on = TRUE THEN 'signed in'
                    ELSE 'signed out' END AS signed_in_status,
                aads.audience_id,
                app_type,
                CAST('All International' as varchar(20)) AS geo_country_site_visited, -- combine everyone regardless of country
                p.age_range,
                p.gender
FROM s3_audience.audience_activity_daily_summary aads
         LEFT JOIN prez.profile_extension p
                    ON p.bbc_hid3 = aads.audience_id
WHERE aads.destination = 'PS_SOUNDS'
  AND aads.app_name = 'sounds'
  AND aads.geo_country_site_visited IN ('United Kingdom', 'Jersey', 'Isle of Man', 'Guernsey') -- Not UK
  AND aads.dt BETWEEN TO_CHAR(TRUNC(DATE_TRUNC('week', getdate() - 7)), 'yyyymmdd') -- limits to the past week (Mon-Sun)
      AND TO_CHAR(TRUNC(DATE_TRUNC('week', getdate() - 7) + 6), 'yyyymmdd')
  AND (aads.app_type = 'responsive' OR aads.app_type = 'mobile-app' OR aads.app_type = 'bigscreen-html')
;

--Check data
SELECT distinct week_commencing FROM radio1_sandbox.vb_sounds_int_users;
SELECT * FROM radio1_sandbox.vb_sounds_int_users
ORDER BY week_commencing,audience_id, app_type, geo_country_site_visited
LIMIT 200;

-- Create summary table to hold all data and insert into it weekly
DROP TABLE IF EXISTS radio1_sandbox.sounds_dashboard_1_page_views_international;
CREATE TABLE radio1_sandbox.sounds_dashboard_1_page_views_international
(
    week_commencing          date,
    geo_country_site_visited varchar(400),
    id_age_range             varchar(40),
    app_type                 varchar(40),
    gender                   varchar(40),
    signed_in_accounts       integer,
    all_visitors_si_so       integer
);

INSERT INTO radio1_sandbox.sounds_dashboard_1_page_views_international
with si_users AS (
    SELECT week_commencing,
           geo_country_site_visited,
           age_range,
           app_type,
           gender,
           --week_commencing || geo_country_site_visited || age_range || app_type || gender AS for_join,
           count(distinct audience_id) AS num_si_visitors
    FROM radio1_sandbox.vb_sounds_int_users
    WHERE signed_in_status = 'signed in'
    GROUP BY 1, 2, 3, 4, 5--, 6
),
     all_users AS (
         SELECT week_commencing,
                geo_country_site_visited,
                age_range,
                app_type,
                gender,
                --week_commencing || geo_country_site_visited || age_range || app_type || gender AS for_join,

                count(distinct audience_id) AS num_visitors_si_so
         FROM radio1_sandbox.vb_sounds_int_users
         GROUP BY 1, 2, 3, 4, 5--, 6
     )
SELECT a.week_commencing,
       a.geo_country_site_visited,
       a.age_range,
       a.app_type,
       a.gender,
       b.num_si_visitors,
       a.num_visitors_si_so
FROM all_users a
         JOIN si_users b ON a.geo_country_site_visited = b.geo_country_site_visited
    AND a.age_range = b.age_range AND a.app_type = b.app_type AND a.gender = b.gender
ORDER BY 1, 2, 3, 4, 5
;


-- Compare
SELECT * FROM radio1_sandbox.sounds_dashboard_1_page_views_international
WHERE id_age_range = '25-29' AND geo_country_site_visited = 'United Kingdom'
;

with uk_table_summary AS (
    SELECT week_commencing, CAST('United Kingdom' as varchar) as geo_country_site_visited,
           id_age_range, app_type, sum(signed_in_accounts) as num_si_uk
    FROM radio1_sandbox.sounds_dashboard_1_page_views
    WHERE id_age_range = '25-29' AND week_commencing = '2020-08-17'
    GROUP BY 1, 2, 3,4
),
     int_table_summary AS (
         SELECT week_commencing, geo_country_site_visited, id_age_range, app_type, sum(signed_in_accounts) as num_si_vb
         FROM radio1_sandbox.sounds_dashboard_1_page_views_international
         --WHERE geo_country_site_visited = 'United Kingdom'
         GROUP BY 1, 2, 3,4
     )
SELECT a.week_commencing,
       a.geo_country_site_visited,
       a.id_age_range,
       a.app_type,
       a.num_si_vb,
       b.num_si_uk
FROM int_table_summary a
         JOIN uk_table_summary b ON a.week_commencing = b.week_commencing
    AND a.id_age_range = b.id_age_range AND a.app_type = b.app_type and a.geo_country_site_visited = b.geo_country_site_visited
WHERE a.id_age_range = '25-29'
ORDER BY 1, 2, 3;
