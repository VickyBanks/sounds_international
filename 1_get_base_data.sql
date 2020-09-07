------------------ Script 1 ------------------
/*
 This finds the all the visitors and what content they viewed and for how long.
 */

--0. USe other weeks to fill table to look at
DROP TABLE IF EXISTS vb_temp_date;
CREATE TABLE vb_temp_date
(
    min_date varchar(20),
    max_date varchar(20)
);
insert into vb_temp_date
--values ('20200824','20200830')
--values ('20200817','20200823');
--values ('20200810','20200816');
--values ('20200803','20200809');
values ('20200727','20200802')

       ;

-- 1. Get VMB summary.
-- Drop and re-create each week
DROP TABLE IF EXISTS vb_vmb_summary;
CREATE TABLE vb_vmb_summary
    DISTKEY ( master_brand_id )
    SORTKEY (master_brand_id) AS (
    SELECT DISTINCT a.programme_title, a.master_brand_id, a.brand_title, a.series_title,a.episode_title, a.version_id, b.speech_music_split
    FROM prez.scv_vmb a
             LEFT JOIN radio1_sandbox.vb_speech_music_master_brand_split b ON a.master_brand_id = b.master_brand_id
)
;*/

-- 2. Get all the listening per users, sum the playback time per episode to ensure 3s of listening later
-- Drop and re-create each week
DROP TABLE IF EXISTS radio1_sandbox.vb_sounds_int_users_listening;
CREATE TABLE radio1_sandbox.vb_sounds_int_users_listening AS
SELECT DISTINCT dt :: date,
                TRUNC(DATE_TRUNC('week', getdate() - 7)) AS week_commencing,
                --CAST((SELECT min_date FROM vb_temp_date) as date) AS week_commencing,
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
  AND dt BETWEEN TO_CHAR(TRUNC(DATE_TRUNC('week', getdate() - 7)), 'yyyymmdd') -- limits to the past week (Mon-Sun)
  AND TO_CHAR(TRUNC(DATE_TRUNC('week', getdate() - 7) + 6), 'yyyymmdd')
  --AND a.dt BETWEEN (SELECT min_date FROM vb_temp_date) AND (SELECT max_date FROM vb_temp_date)
  AND geo_country_site_visited NOT IN ('United Kingdom', 'Jersey', 'Isle of Man', 'Guernsey')
AND (a.app_type = 'responsive' OR a.app_type = 'mobile-app' OR a.app_type = 'bigscreen-html')
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13
;
SELECT * FROM radio1_sandbox.vb_sounds_int_users_listening LIMIT 5;