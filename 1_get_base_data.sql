------------------ Script 1 ------------------
/*
 This finds the all the visitors and what content they viewed and for how long.
 */

--0. USe other weeks to fill table to look at
DROP TABLE IF EXISTS dataforce_temp_date;
CREATE TABLE dataforce_temp_date
(
    min_date varchar(20),
    max_date varchar(20)
);
insert into dataforce_temp_date
--values ('20200831','20200906')
--values ('20200824','20200830')
--values ('20200817','20200823');
--values ('20200810','20200816');
--values ('20200803','20200809');
--values ('20200727','20200802')

values ( '20200803', '20201011')
;

-- 1. Get VMB summary. -- create a TLEO field matching the normal Sounds dash
-- Drop and re-create each week
DROP TABLE IF EXISTS dataforce_sandbox.dataforce_vmb_summary;
CREATE TABLE dataforce_sandbox.dataforce_vmb_summary
    DISTKEY ( master_brand_id )
    SORTKEY (master_brand_id) AS (
    SELECT DISTINCT
                    b.speech_music_split,
                    CASE
                        WHEN a.brand_title != 'N/A' AND a.brand_title != '' AND a.brand_title != 'null' AND a.brand_title IS NOT NULL THEN a.brand_title
                        WHEN a.series_title != 'N/A' AND a.series_title != '' AND a.series_title != 'null' AND a.series_title IS NOT NULL THEN a.series_title
                        WHEN a.programme_title != 'N/A' AND a.programme_title != '' AND a.programme_title != 'null' AND a.programme_title IS NOT NULL THEN a.programme_title
                        WHEN a.episode_title != 'N/A' AND a.episode_title != '' AND a.episode_title != 'null' AND a.episode_title IS NOT NULL THEN a.episode_title
                        WHEN a.presentation_title != 'N/A' AND a.presentation_title != '' AND a.presentation_title != 'null' AND a.presentation_title IS NOT NULL THEN a.presentation_title
                        WHEN a.clip_title != 'N/A' AND a.clip_title != '' AND a.clip_title != 'null' AND a.clip_title IS NOT NULL THEN a.clip_title
                        END AS tleo,
                    CASE
                        WHEN a.brand_id != 'N/A' AND a.brand_id != '' AND a.brand_id != 'null' AND a.brand_id IS NOT NULL THEN a.brand_id
                        WHEN a.series_id != 'N/A' AND a.series_id != '' AND a.series_id != 'null' AND a.series_id IS NOT NULL THEN a.series_id
                        WHEN a.episode_id != 'N/A' AND a.episode_id != '' AND a.episode_id != 'null' AND a.episode_id IS NOT NULL THEN a.episode_id
                        WHEN a.clip_id != 'N/A' AND a.clip_id != '' AND a.clip_id != 'null' AND a.clip_id IS NOT NULL THEN a.clip_id
                        END AS tleo_id,
                    a.master_brand_id,
                    a.version_id
    FROM prez.scv_vmb a
             LEFT JOIN radio1_sandbox.dataforce_speech_music_master_brand_split b ON a.master_brand_id = b.master_brand_id
)
;
GRANT SELECT ON dataforce_sandbox.dataforce_vmb_summary TO GROUP radio;
GRANT SELECT ON dataforce_sandbox.dataforce_vmb_summary TO GROUP central_insights;
GRANT ALL ON dataforce_sandbox.dataforce_vmb_summary TO GROUP central_insights_server;
GRANT All ON dataforce_sandbox.dataforce_vmb_summary TO GROUP dataforce_analysts;



-- 2. Get all the listening per users, sum the playback time per episode to ensure 3s of listening later
-- Drop and re-create each week
DROP TABLE IF EXISTS radio1_sandbox.dataforce_sounds_int_users_listening;
CREATE TABLE radio1_sandbox.dataforce_sounds_int_users_listening AS
SELECT DISTINCT dt :: date,
                TRUNC(DATE_TRUNC('week', dt::date )) AS week_commencing,
                --CAST((SELECT min_date FROM dataforce_temp_date) as date) AS week_commencing,
                audience_id,
                geo_country_site_visited                          as country,
                CASE
                    WHEN is_signed_in = TRUE AND is_personalisation_on = TRUE THEN 'signed in'
                    ELSE 'signed out' END                         AS signed_in_status,
                CASE
                    WHEN b.age_range = '0-5' OR b.age_range = '6-10' OR b.age_range = '11-15' THEN 'Under 16'
                    WHEN b.age_range = '16-19' OR b.age_range = '20-24' OR b.age_range = '25-29' OR
                         b.age_range = '30-34' THEN '16-34'
                    WHEN b.age_range ISNULL THEN 'Unknown'
                    ELSE 'Over 35' END                            AS age_range,
                b.gender,
                version_id,
                CASE
                    WHEN version_id SIMILAR TO '%[0-9]%' AND version_id NOT ILIKE '%bbc%' THEN 'version_id'
                    WHEN version_id ISNULL then NULL
                    ELSE 'master_brand_id' END                    AS id_type, -- to hep with the join
                app_type,
                app_name,
                broadcast_type,
                play_id,
                sum(playback_time_total)                          as playback_time_total
FROM s3_audience.audience_activity_daily_summary a
         LEFT JOIN prez.profile_extension b ON a.audience_id = b.bbc_hid3
WHERE destination = 'PS_SOUNDS'
  --AND dt BETWEEN TO_CHAR(TRUNC(DATE_TRUNC('week', getdate() - 7)), 'yyyymmdd') -- limits to the past week (Mon-Sun)
--AND TO_CHAR(TRUNC(DATE_TRUNC('week', getdate() - 7) + 6), 'yyyymmdd')
 AND a.dt BETWEEN (SELECT min_date FROM dataforce_temp_date) AND (SELECT max_date FROM dataforce_temp_date)
  AND geo_country_site_visited NOT IN ('United Kingdom', 'Jersey', 'Isle of Man', 'Guernsey')
AND (a.app_type = 'responsive' OR a.app_type = 'mobile-app' OR a.app_type = 'bigscreen-html')
AND app_name = 'sounds'
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13
;
---- END
-- Grants
GRANT SELECT ON radio1_sandbox.dataforce_sounds_int_users_listening TO GROUP radio;
GRANT SELECT ON radio1_sandbox.dataforce_sounds_int_users_listening TO GROUP central_insights;
GRANT ALL ON radio1_sandbox.dataforce_sounds_int_users_listening TO GROUP central_insights_server;
GRANT All ON radio1_sandbox.dataforce_sounds_int_users_listening TO GROUP dataforce_analysts;



SELECT app_name, app_type, count(*) FROM  radio1_sandbox.dataforce_sounds_int_users_listening GROUP BY 1,2;
SELECT * FROM dataforce_vmb_summary LIMIT 5;

SELECT week_commencing, count(*)
FROM radio1_sandbox.dataforce_sounds_int_users_listening
GROUP BY 1
ORDER BY 1;
