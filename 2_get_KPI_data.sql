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
       app_type,
       app_name,
       CASE
           WHEN playback_time_total < 3 OR playback_time_total ISNULL THEN 0
           ELSE playback_time_total END as playback_time_3s
FROM radio1_sandbox.vb_sounds_int_users_listening;

-- 2. Count listeners
DROP TABLE IF EXISTS radio1_sandbox.vb_sounds_int_KPI_listeners;
CREATE TABLE radio1_sandbox.vb_sounds_int_KPI_listeners AS
SELECT week_commencing,
       country,
       age_range,
       app_type,
       signed_in_status,
       count(distinct audience_id) as num_listeners
      FROM radio1_sandbox.vb_sounds_int_users_listening
    WHERE playback_time_total < 3
GROUP BY 1,2,3,4,5;

INSERT INTO radio1_sandbox.vb_sounds_int_KPI_listeners
SELECT week_commencing,
       country,
       age_range,
       CAST('all' AS varchar) AS app_type,
       signed_in_status,
       count(distinct audience_id) as num_listeners
      FROM radio1_sandbox.vb_sounds_int_users_listening
    WHERE playback_time_total < 3
GROUP BY 1,2,3,4,5;


--3. Create the table with the summary data and fill it
--3.a Create table -- This is to be inserted into weekly and NOT dropped
/*DROP TABLE IF EXISTS radio1_sandbox.vb_sounds_int_KPI;
CREATE TABLE radio1_sandbox.vb_sounds_int_KPI
(
    week_commencing     date,
    country             varchar(400),
    age_range           varchar(40),
    app_type            varchar(40),
    signed_in_status    varchar(40),
    num_visitors        integer,
    stream_playing_time BIGINT,
    num_listeners       bigint
);*/

-- 2.a Insert data
INSERT INTO radio1_sandbox.vb_sounds_int_KPI
with visitors as (
    SELECT week_commencing,
           country,
           age_range,
           app_type,
           signed_in_status,
           count(distinct audience_id) AS num_visitors,
           sum(playback_time_3s)       AS stream_playing_time
    FROM radio1_sandbox.vb_sounds_int_KPI_temp
    GROUP BY 1, 2, 3, 4, 5
)
SELECT a.*, b.num_listeners
FROM visitors a
         LEFT JOIN radio1_sandbox.vb_sounds_int_KPI_listeners b ON
        a.week_commencing = b.week_commencing AND
        a.country = b.country AND
        a.age_range = b.age_range AND
        a.app_type = b.app_type AND
        a.signed_in_status = b.signed_in_status
;


-- Insert data but dedup across app type
INSERT INTO radio1_sandbox.vb_sounds_int_KPI
with visitors as (
    SELECT week_commencing,
           country,
           age_range,
           CAST('all' as varchar)      AS app_type,
           signed_in_status,
           count(distinct audience_id) AS num_visitors,
           sum(playback_time_3s)       AS stream_playing_time
    FROM radio1_sandbox.vb_sounds_int_KPI_temp
    GROUP BY 1, 2, 3, 4, 5
)
SELECT a.*, ISNULL(b.num_listeners,0)
FROM visitors a
         LEFT JOIN radio1_sandbox.vb_sounds_int_KPI_listeners b ON
        a.week_commencing = b.week_commencing AND
        a.country = b.country AND
        a.age_range = b.age_range AND
        a.app_type = b.app_type AND
        a.signed_in_status = b.signed_in_status
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

UPDATE radio1_sandbox.vb_sounds_int_KPI
SET signed_in_status = (CASE
                            WHEN signed_in_status = 'signed in' THEN 'Signed-in'
                            WHEN signed_in_status = 'signed out' THEN 'Signed-out'
                            ELSE signed_in_status END);


---- Drop tables
DROP TABLE IF EXISTS radio1_sandbox.vb_sounds_int_KPI_temp;
DROP TABLE IF EXISTS radio1_sandbox.vb_sounds_int_KPI_listeners;

-- Grants
GRANT SELECT ON radio1_sandbox.vb_sounds_int_KPI TO GROUP radio;
GRANT SELECT ON radio1_sandbox.vb_sounds_int_KPI TO GROUP central_insights;
GRANT SELECT ON radio1_sandbox.vb_sounds_int_KPI TO GROUP central_insights_server;
GRANT SELECT ON radio1_sandbox.vb_sounds_int_KPI TO GROUP dataforce_analysts;
