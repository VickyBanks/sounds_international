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

-- 2.a Insert data
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
-- Insert data but dedup across app type
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

SELECT * FROM radio1_sandbox.vb_sounds_int_KPI LIMIT 10;
SELECT DISTINCT week_commencing FROM radio1_sandbox.vb_sounds_int_KPI ORDER BY 1;
GRANT ALL ON radio1_sandbox.vb_sounds_int_KPI to helen_jones;

---- Drop tables
DROP TABLE IF EXISTS radio1_sandbox.vb_sounds_int_KPI_temp;
