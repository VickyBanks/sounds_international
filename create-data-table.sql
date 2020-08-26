--SELECT * FROM radio1_sandbox.audio_content_enriched LIMIT 10;

--0. USe other weeks to fill table to look at
DROP TABLE vb_temp_date;
CREATE TABLE vb_temp_date
(
    min_date varchar(20),
    max_date varchar(20)
);
insert into vb_temp_date
--values ('20200817','20200823');
--values ('20200810','20200816');
--values ('20200803','20200809');
values ('20200727','20200802');

-- 1. Get VMB summary. This table is quicker than using 'with table AS ()'
-- Drop and re-create each week
/*DROP TABLE IF EXISTS vb_vmb_summary;
CREATE TABLE vb_vmb_summary AS
SELECT DISTINCT master_brand_id, version_id
FROM prez.scv_vmb;*/

-- 2. Get all the listening per users, sum the playback time per episode to ensure 3s of listening later
-- Drop and re-create each week
DROP TABLE IF EXISTS vb_users_listening;
CREATE TABLE vb_users_listening AS
SELECT DISTINCT dt :: date,
                --TRUNC(DATE_TRUNC('week', getdate() - 7)) AS week_commencing,
                CAST((SELECT min_date FROM vb_temp_date) as date) AS week_commencing,
                audience_id,
                geo_country_site_visited                          as country,
                CASE
                    WHEN is_signed_in = TRUE AND is_personalisation_on = TRUE THEN 'signed in'
                    ELSE 'signed out' END                         AS signed_in_status,
                version_id,
                CASE
                    WHEN version_id SIMILAR TO '%[0-9]%' THEN 'version_id'
                    WHEN version_id ISNULL then NULL
                    ELSE 'master_brand_id' END                    AS id_type, -- to hep with the join
                app_type,
                app_name,
                broadcast_type,
                play_id,
                sum(playback_time_total)                          as playback_time_total
FROM s3_audience.audience_activity_daily_summary a
WHERE destination = 'PS_SOUNDS'
  --AND dt BETWEEN TO_CHAR(TRUNC(DATE_TRUNC('week', getdate() - 7)), 'yyyymmdd') -- limits to the past week (Mon-Sun)
  -- AND TO_CHAR(TRUNC(DATE_TRUNC('week', getdate() - 7) + 6), 'yyyymmdd')
  AND a.dt BETWEEN (SELECT min_date FROM vb_temp_date) AND (SELECT max_date FROM vb_temp_date)
  AND geo_country_site_visited NOT IN ('United Kingdom', 'Jersey', 'Isle of Man', 'Guernsey')
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
;

SELECT count(*) FROM vb_users_listening;

-- 3. Get the time of playing for each piece of content for each user and the number of times they played it
-- Drop and re-create each week
DROP TABLE IF EXISTS radio1_sandbox.vb_ace_scv_international_data;
CREATE TABLE radio1_sandbox.vb_ace_scv_international_data
(
    dt                       date DISTKEY,
    week_commencing          date,
    audience_id              VARCHAR(255),
    country                  varchar(255),
    signed_in_status         varchar(20),
    age_range                varchar(40),
    gender                   varchar(255),
    app_type                 VARCHAR(255),
    app_name                 VARCHAR(255),
    version_id               varchar(255),
    master_brand_id          varchar(255),
    broadcast_type           VARCHAR(255),
    stream_starts_min_3_secs INT,
    stream_playing_time      INT
) SORTKEY (dt);

INSERT INTO radio1_sandbox.vb_ace_scv_international_data
SELECT dt,
       week_commencing,
       audience_id,
       country,
       signed_in_status,
       CASE
           WHEN c.age_range = '0-5' OR c.age_range = '6-10' OR c.age_range = '11-15' THEN 'Under 16'
           WHEN c.age_range = '16-19' OR c.age_range = '20-24' OR c.age_range = '25-29' OR
                c.age_range = '30-34' THEN '16-34'
           WHEN c.age_range ISNULL THEN 'Unknown'
           ELSE 'Over 35' END                  AS age_range,
       c.gender,
       app_type,
       app_name,
       a.version_id,
       ISNULL(b.master_brand_id, a.version_id) AS master_brand_id,-- sometimes the version id IS the masterbrand. In those cases this will be NULL from the join
       broadcast_type,                                            --Live or OD (clip)
       count(distinct play_id),                                   -- counts the number of plays per person of a piece of content
       sum(playback_time_total)                as playback_time_agg
FROM vb_users_listening a
         LEFT JOIN vb_vmb_summary b ON a.version_id = b.version_id -- Join with the vmb to get the master brand
         LEFT JOIN prez.profile_extension c on a.audience_id = c.bbc_hid3
WHERE playback_time_total > 3
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11,12
;


-- 4. Create summary table for data grouping
-- Insert into table each week
/*DROP TABLE IF EXISTS radio1_sandbox.vb_sounds_dashboard_5_listening_international;
CREATE TABLE radio1_sandbox.vb_sounds_dashboard_5_listening_international
(
    week_commencing     date DISTKEY,
    country             varchar(255),
    signed_in_status    varchar(255),
    age_range           varchar(255),
    gender              varchar(255),
    app_type            VARCHAR(255),
    live_aod_split      varchar(255),
    master_brand_id     varchar(255),
    stream_starts       BIGINT,
    stream_playing_time BIGINT
) SORTKEY (week_commencing );
;
*/

-- 5. Insert in data, differentiating between signed in and signed out
INSERT INTO radio1_sandbox.vb_sounds_dashboard_5_listening_international
SELECT week_commencing,
       country,
       signed_in_status,
       age_range,
       gender,
       app_type,
       CASE
           WHEN broadcast_type = 'Clip' THEN 'on-demand'
           WHEN broadcast_type = 'Live' then 'live' END as live_aod_split,
       master_brand_id,
       count(stream_starts_min_3_secs)                  as stream_starts,
       sum(stream_playing_time)                         AS stream_playing_time
FROM radio1_sandbox.vb_ace_scv_international_data
GROUP BY 1, 2, 3, 4, 5, 6, 7,8
;

-- Add in all users with no signed in status split
INSERT INTO radio1_sandbox.vb_sounds_dashboard_5_listening_international
SELECT week_commencing,
       country,
       CAST('all' as varchar)                           AS signed_in_status,
       age_range,
       gender,
       app_type,
       CASE
           WHEN broadcast_type = 'Clip' THEN 'on-demand'
           WHEN broadcast_type = 'Live' then 'live' END as live_aod_split,
       master_brand_id,
       count(stream_starts_min_3_secs)                  as stream_starts,
       sum(stream_playing_time)                         AS stream_playing_time
FROM radio1_sandbox.vb_ace_scv_international_data
GROUP BY 1, 2, 3, 4, 5, 6, 7,8
;

-- Add in all users with no app_type split
INSERT INTO radio1_sandbox.vb_sounds_dashboard_5_listening_international
SELECT week_commencing,
       country,
       signed_in_status,
       age_range,
       gender,
       CAST('all' as varchar)                           AS app_type,
       CASE
           WHEN broadcast_type = 'Clip' THEN 'on-demand'
           WHEN broadcast_type = 'Live' then 'live' END as live_aod_split,
       master_brand_id,
       count(stream_starts_min_3_secs)                  as stream_starts,
       sum(stream_playing_time)                         AS stream_playing_time
FROM radio1_sandbox.vb_ace_scv_international_data
GROUP BY 1, 2, 3, 4, 5, 6, 7,8
;

--Add in all users with no signed in status split and no app type split
INSERT INTO radio1_sandbox.vb_sounds_dashboard_5_listening_international
SELECT week_commencing,
       country,
       CAST('all' as varchar)                           AS signed_in_status,
       age_range,
       gender,
       CAST('all' as varchar)                           AS app_type,
       CASE
           WHEN broadcast_type = 'Clip' THEN 'on-demand'
           WHEN broadcast_type = 'Live' then 'live' END as live_aod_split,
       master_brand_id,
       count(stream_starts_min_3_secs)                  as stream_starts,
       sum(stream_playing_time)                         AS stream_playing_time
FROM radio1_sandbox.vb_ace_scv_international_data
GROUP BY 1, 2, 3, 4, 5, 6, 7,8
;

-- For all countries, all apps, all signed in
INSERT INTO radio1_sandbox.vb_sounds_dashboard_5_listening_international
SELECT week_commencing,
       CAST('All International' as varchar) AS country,
       CAST('all' as varchar)                           AS signed_in_status,
       age_range,
       gender,
       CAST('all' as varchar)                           AS app_type,
       CASE
           WHEN broadcast_type = 'Clip' THEN 'on-demand'
           WHEN broadcast_type = 'Live' then 'live' END as live_aod_split,
       master_brand_id,
       count(stream_starts_min_3_secs)                  as stream_starts,
       sum(stream_playing_time)                         AS stream_playing_time
FROM radio1_sandbox.vb_ace_scv_international_data
GROUP BY 1, 2, 3, 4, 5, 6, 7,8
;
-- All countries and all apps
INSERT INTO radio1_sandbox.vb_sounds_dashboard_5_listening_international
SELECT week_commencing,
       CAST('All International' as varchar) AS country,
       signed_in_status,
       age_range,
       gender,
       CAST('all' as varchar)                           AS app_type,
       CASE
           WHEN broadcast_type = 'Clip' THEN 'on-demand'
           WHEN broadcast_type = 'Live' then 'live' END as live_aod_split,
       master_brand_id,
       count(stream_starts_min_3_secs)                  as stream_starts,
       sum(stream_playing_time)                         AS stream_playing_time
FROM radio1_sandbox.vb_ace_scv_international_data
GROUP BY 1, 2, 3, 4, 5, 6, 7,8
;
-- all countries
INSERT INTO radio1_sandbox.vb_sounds_dashboard_5_listening_international
SELECT week_commencing,
       CAST('All International' as varchar) AS country,
       signed_in_status,
       age_range,
       gender,
       app_type,
       CASE
           WHEN broadcast_type = 'Clip' THEN 'on-demand'
           WHEN broadcast_type = 'Live' then 'live' END as live_aod_split,
       master_brand_id,
       count(stream_starts_min_3_secs)                  as stream_starts,
       sum(stream_playing_time)                         AS stream_playing_time
FROM radio1_sandbox.vb_ace_scv_international_data
GROUP BY 1, 2, 3, 4, 5, 6, 7,8
;



-- Drop tables that are no longer needed
DROP TABLE IF EXISTS vb_users_listening;
--DROP TABLE IF EXISTS vb_vmb_summary;


SELECT week_commencing, country, sum(stream_playing_time) as total_time FROM radio1_sandbox.vb_sounds_dashboard_5_listening_international
WHERE app_type = 'all' AND signed_in_status = 'all' AND country = 'All International'
GROUP BY 1,2;