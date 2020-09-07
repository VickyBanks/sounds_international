/*
 Get the summary for the KPI dash tab
 Need the number of visitors, time spent and num stream starts

 Uses this table SELECT * FROM radio1_sandbox.vb_sounds_int_users_listening LIMIT 5;
 */

--1. Get the number of visitors and the length of playing time
-- Any stream with playing time <3s is not counted so here is set to 0
DROP TABLE IF EXISTS radio1_sandbox.vb_sounds_int_KPI_temp;
CREATE TABLE radio1_sandbox.vb_sounds_int_KPI_temp AS
SELECT week_commencing,
       audience_id,
       country,
       signed_in_status,
       age_range,
       gender,
       app_type,
       app_name,
       CASE WHEN playback_time_total < 3  OR playback_time_total ISNULL THEN 0 ELSE playback_time_total END as playback_time_3s
FROM radio1_sandbox.vb_sounds_int_users_listening;

--2. Create the table with the summary data and fill it
--2.a Create table -- This is to be inserted into weekly and NOT dropped
/*DROP TABLE IF EXISTS radio1_sandbox.vb_sounds_int_KPI;
CREATE TABLE radio1_sandbox.vb_sounds_int_KPI (
    week_commencing  date,
    country          varchar(400),
    age_range        varchar(40),
    app_type         varchar(40),
    gender           varchar(40),
    signed_in_status varchar(40),
    num_visitors     integer,
    stream_playing_time BIGINT
);*/

-- 2b. Insert normal data will all the splits
-- Country Y
-- App type Y
-- signed in Y
INSERT INTO radio1_sandbox.vb_sounds_int_KPI
SELECT week_commencing,
       country,
       age_range,
       app_type,
       gender,
       signed_in_status,
       count(distinct audience_id) AS num_visitors,
       sum(playback_time_3s) AS stream_playing_time
FROM radio1_sandbox.vb_sounds_int_KPI_temp
GROUP BY 1,2,3,4,5,6
;
-- 2c. Insert with no country split
-- Country N
-- App type Y
-- signed in Y
INSERT INTO radio1_sandbox.vb_sounds_int_KPI
SELECT week_commencing,
       CAST('All International' as varchar) AS country,
       age_range,
       app_type,
       gender,
       signed_in_status,
       count(distinct audience_id) AS num_visitors,
       sum(playback_time_3s) AS stream_playing_time
FROM radio1_sandbox.vb_sounds_int_KPI_temp
GROUP BY 1,2,3,4,5,6
;

-- 2d. Insert with no country split AND no app type split
-- Country N
-- App type N
-- signed in Y
INSERT INTO radio1_sandbox.vb_sounds_int_KPI
SELECT week_commencing,
       CAST('All International' as varchar) AS country,
       age_range,
       CAST('all' as varchar) AS app_type,
       gender,
       signed_in_status,
       count(distinct audience_id) AS num_visitors,
       sum(playback_time_3s) AS stream_playing_time
FROM radio1_sandbox.vb_sounds_int_KPI_temp
GROUP BY 1,2,3,4,5,6
;

-- 2e. Insert with no country split AND no app type split AND no signed in status split
-- Country N
-- App type N
-- signed in N
INSERT INTO radio1_sandbox.vb_sounds_int_KPI
SELECT week_commencing,
       CAST('All International' as varchar) AS country,
       age_range,
       CAST('all' as varchar) AS app_type,
       gender,
       CAST('all' as varchar) AS signed_in_status,
       count(distinct audience_id) AS num_visitors,
       sum(playback_time_3s) AS stream_playing_time
FROM radio1_sandbox.vb_sounds_int_KPI_temp
GROUP BY 1,2,3,4,5,6
;

-- 2f. Insert with no country split AND no app type split AND no signed in status split
-- Country N
-- App type Y
-- signed in N
INSERT INTO radio1_sandbox.vb_sounds_int_KPI
SELECT week_commencing,
       CAST('All International' as varchar) AS country,
       age_range,
       app_type,
       gender,
       CAST('all' as varchar) AS signed_in_status,
       count(distinct audience_id) AS num_visitors,
       sum(playback_time_3s) AS stream_playing_time
FROM radio1_sandbox.vb_sounds_int_KPI_temp
GROUP BY 1,2,3,4,5,6
;

-- 2g. Insert with no app type split AND no signed in status split
-- Country Y
-- App type N
-- signed in N
INSERT INTO radio1_sandbox.vb_sounds_int_KPI
SELECT week_commencing,
       country,
       age_range,
       CAST('all' as varchar) AS app_type,
       gender,
       CAST('all' as varchar) AS signed_in_status,
       count(distinct audience_id) AS num_visitors,
       sum(playback_time_3s) AS stream_playing_time
FROM radio1_sandbox.vb_sounds_int_KPI_temp
GROUP BY 1,2,3,4,5,6
;

-- 2h. Insert with no signed in status split
-- Country Y
-- App type Y
-- signed in N
INSERT INTO radio1_sandbox.vb_sounds_int_KPI
SELECT week_commencing,
       country,
       age_range,
       app_type,
       gender,
       CAST('all' as varchar) AS signed_in_status,
       count(distinct audience_id) AS num_visitors,
       sum(playback_time_3s) AS stream_playing_time
FROM radio1_sandbox.vb_sounds_int_KPI_temp
GROUP BY 1,2,3,4,5,6
;
-- 2i. Insert with no app type split
-- Country Y
-- App type N
-- signed in Y
INSERT INTO radio1_sandbox.vb_sounds_int_KPI
SELECT week_commencing,
       country,
       age_range,
       CAST('all' as varchar) AS app_type,
       gender,
       signed_in_status,
       count(distinct audience_id) AS num_visitors,
       sum(playback_time_3s) AS stream_playing_time
FROM radio1_sandbox.vb_sounds_int_KPI_temp
GROUP BY 1,2,3,4,5,6
;


-- Stakeholder friendly language
UPDATE radio1_sandbox.vb_sounds_int_KPI
SET app_type = (CASE
                    WHEN app_type = 'bigscreen-html' THEN 'TV'
                    WHEN app_type = 'mobile-app' THEN 'Mobile'
                    WHEN app_type = 'responsive' THEN 'Web'
                    WHEN app_type = 'all' THEN 'All'
                    ELSE app_type END)
;


/*SELECT DISTINCT week_commencing,
                country,
                app_type,
                signed_in_status,
                sum(num_visitors)                  as num_visitors_total--,
                --sum(stream_playing_time)           as stream_playing_time_total
                /*CAST(round((stream_playing_time_total::double precision / 3600) / num_visitors_total::double precision,
                           2) as double precision) as hrs_per_visitor*/
FROM radio1_sandbox.vb_sounds_int_KPI
WHERE country != 'All International'
  --AND app_type ILIKE '%bigscreen%'
  --and signed_in_status = 'all'
GROUP BY 1,2,3,4
ORDER BY 3 DESC;*/

SELECT DISTINCT week_commencing
FROM radio1_sandbox.vb_sounds_int_KPI
ORDER BY 1;

---- Drop tables
DROP TABLE IF EXISTS radio1_sandbox.vb_sounds_int_KPI_temp;