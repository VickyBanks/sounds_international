/*
 This scripts find the top content viewed per week
 This will need
 - number of plays,
 - number of accounts -- this is singed in account or device cookie for signed out. This means that signed out users can't be deduped.
 - network/podcast/music mix
 - platform,
 - live/od
 - user frequency
 - age group
 */

 --Base data
/*SELECT * FROM radio1_sandbox.vb_sounds_int_users_listening LIMIT 50;
SELECT * FROM radio1_sandbox.vb_listeners_international_weekly_summary limit 50;
SELECT * FROM radio1_sandbox.vb_listeners_international LIMIT 50;
SELECT * FROM vb_vmb_summary where brand_title ILIKE '%Archers%' LIMIT 100;
*/

--1. Create table of listeners only (not just visitors) i.e remove anyone where the playback time was 3s or less
-- Add information about content
-- Add in if it's speech or music
-- To be dropped after use
DROP TABLE IF EXISTS radio1_sandbox.vb_listeners_international_top_content;
CREATE TABLE radio1_sandbox.vb_listeners_international_top_content
    SORTKEY (master_brand_id)
    DISTKEY (master_brand_id)
AS (
    SELECT a.*, b.programme_title, b.master_brand_id,b.brand_title, b.series_title, b.episode_title, b.speech_music_split
    FROM radio1_sandbox.vb_sounds_int_users_listening a
             LEFT JOIN vb_vmb_summary b ON a.version_id = b.version_id -- Inserts when the version_id is the an episode pid
    WHERE playback_time_total > 3
      AND playback_time_total IS NOT NULL
      AND a.id_type = 'version_id')
;

-- Inserts when the version_id is a master_brand
INSERT INTO radio1_sandbox.vb_listeners_international_top_content
with vmb_subset_mini AS
         (SELECT DISTINCT master_brand_id, speech_music_split
          FROM vb_vmb_summary) -- This is to just get distinct masterbrands as the main table has lots of entries because of the many version ids
SELECT a.*,
       b.master_brand_id,
       CAST(null as varchar) AS programme_title,
       CAST(null as varchar) AS brand_title,
       CAST(null as varchar) AS series_title,
       CAST(null as varchar) AS episode_title,
       b.speech_music_split
FROM radio1_sandbox.vb_sounds_int_users_listening a
         LEFT JOIN vmb_subset_mini b ON a.version_id = b.master_brand_id
WHERE playback_time_total > 3
  AND playback_time_total IS NOT NULL
  AND a.id_type = 'master_brand_id'
;


-- 2. Add in frequency information about the user
DROP TABLE IF EXISTS radio1_sandbox.vb_listeners_international_top_content_user_info;
CREATE TABLE radio1_sandbox.vb_listeners_international_top_content_user_info AS
SELECT a.*,
       CASE
           WHEN b.frequency_band is null THEN 'new'
           ELSE b.frequency_band END                                             AS frequency_band,
       central_insights_sandbox.udf_dataforce_frequency_groups(b.frequency_band) as frequency_group_aggregated
FROM radio1_sandbox.vb_listeners_international_top_content a
         LEFT JOIN radio1_sandbox.weekly_frequency_calculations b
                   ON a.week_commencing = b.date_of_segmentation AND a.audience_id = b.bbc_hid3;



-- 3.
/*DROP TABLE IF EXISTS radio1_sandbox.vb_listeners_international_top_content_final;
CREATE TABLE radio1_sandbox.vb_listeners_international_top_content_final
( week_commencing     date DISTKEY,
    country             varchar(255),
    signed_in_status    varchar(10),
    age_range           varchar(40),
    app_type            varchar(40),
    broadcast_type      varchar(40),
    speech_music_split  varchar(40),
    master_brand_id varchar(400),
    programme_title varchar(4000),
    frequency_band varchar(400),
    frequency_group_aggregated varchar(40),
    num_plays bigint,
    mum_accounts bigint
) SORTKEY (week_commencing)
;*/

--3.a All splits
/*
 country Y
 signed in status Y
 app type Y
 */
INSERT INTO radio1_sandbox.vb_listeners_international_top_content_final
SELECT week_commencing,
       country,
       signed_in_status,
       age_range,
       app_type,
       broadcast_type,
       speech_music_split,
       master_brand_id,
       programme_title,
       frequency_band,
       frequency_group_aggregated,
       count(audience_id) as num_plays,
       count(DISTINCT audience_id) as num_accounts
FROM radio1_sandbox.vb_listeners_international_top_content_user_info
GROUP BY 1,2,3,4,5,6,7,8,9,10,11
;
 SELECT * fROM radio1_sandbox.vb_listeners_international_top_content_final LIMIT 10;
--2.b Some splits
/*
 country N
 signed in status Y
 app type Y
 */
INSERT INTO radio1_sandbox.vb_listeners_international_top_content_final
SELECT week_commencing,
       CAST('All International' AS varchar) AS country,
       signed_in_status,
       age_range,
       app_type,
       broadcast_type,
       speech_music_split,
       master_brand_id,
       programme_title,
       frequency_band,
       frequency_group_aggregated,
       count(audience_id) as num_plays,
       count(DISTINCT audience_id) as num_accounts
FROM radio1_sandbox.vb_listeners_international_top_content_user_info
GROUP BY 1,2,3,4,5,6,7,8,9,10,11
;

--2.c Some splits
/*
 country N
 signed in status N
 app type Y
 */

INSERT INTO radio1_sandbox.vb_listeners_international_top_content_final
SELECT week_commencing,
       CAST('All International' AS varchar) AS country,
       CAST ('all' AS varchar) AS signed_in_status,
       age_range,
       app_type,
       broadcast_type,
       speech_music_split,
       master_brand_id,
       programme_title,
       frequency_band,
       frequency_group_aggregated,
       count(audience_id) as num_plays,
       count(DISTINCT audience_id) as num_accounts
FROM radio1_sandbox.vb_listeners_international_top_content_user_info
GROUP BY 1,2,3,4,5,6,7,8,9,10,11
;
--2.d Some splits
/*
 country N
 signed in status N
 app type N
 */
INSERT INTO radio1_sandbox.vb_listeners_international_top_content_final
SELECT week_commencing,
       CAST('All International' AS varchar) AS country,
       CAST ('all' AS varchar) AS signed_in_status,
       age_range,
       CAST( 'all' as varchar) AS app_type,
       broadcast_type,
       speech_music_split,
       master_brand_id,
       programme_title,
       frequency_band,
       frequency_group_aggregated,
       count(audience_id) as num_plays,
       count(DISTINCT audience_id) as num_accounts
FROM radio1_sandbox.vb_listeners_international_top_content_user_info
GROUP BY 1,2,3,4,5,6,7,8,9,10,11
;

--2.e Some splits
/*
 country N
 signed in status Y
 app type N
 */

INSERT INTO radio1_sandbox.vb_listeners_international_top_content_final
SELECT week_commencing,
       CAST('All International' AS varchar) AS country,
       signed_in_status,
       age_range,
       CAST( 'all' as varchar) AS app_type,
       broadcast_type,
       speech_music_split,
       master_brand_id,
       programme_title,
       frequency_band,
       frequency_group_aggregated,
       count(audience_id) as num_plays,
       count(DISTINCT audience_id) as num_accounts
FROM radio1_sandbox.vb_listeners_international_top_content_user_info
GROUP BY 1,2,3,4,5,6,7,8,9,10,11
;
--2.f Some splits
/*
 country Y
 signed in status N
 app type N
 */
INSERT INTO radio1_sandbox.vb_listeners_international_top_content_final
SELECT week_commencing,
       country,
       CAST ('all' AS varchar) AS signed_in_status,
       age_range,
       CAST( 'all' as varchar) AS app_type,
       broadcast_type,
       speech_music_split,
       master_brand_id,
       programme_title,
       frequency_band,
       frequency_group_aggregated,
       count(audience_id) as num_plays,
       count(DISTINCT audience_id) as num_accounts
FROM radio1_sandbox.vb_listeners_international_top_content_user_info
GROUP BY 1,2,3,4,5,6,7,8,9,10,11
;
--2.g Some splits
/*
 country Y
 signed in status Y
 app type N
 */
INSERT INTO radio1_sandbox.vb_listeners_international_top_content_final
SELECT week_commencing,
      country,
       signed_in_status,
       age_range,
       CAST( 'all' as varchar) AS app_type,
       broadcast_type,
       speech_music_split,
       master_brand_id,
       programme_title,
       frequency_band,
       frequency_group_aggregated,
       count(audience_id) as num_plays,
       count(DISTINCT audience_id) as num_accounts
FROM radio1_sandbox.vb_listeners_international_top_content_user_info
GROUP BY 1,2,3,4,5,6,7,8,9,10,11
;
--2.h Some splits
/*
 country Y
 signed in status N
 app type Y
 */
INSERT INTO radio1_sandbox.vb_listeners_international_top_content_final
SELECT week_commencing,
       country,
       CAST ('all' AS varchar) AS signed_in_status,
       age_range,
       app_type,
       broadcast_type,
       speech_music_split,
       master_brand_id,
       programme_title,
       frequency_band,
       frequency_group_aggregated,
       count(audience_id) as num_plays,
       count(DISTINCT audience_id) as num_accounts
FROM radio1_sandbox.vb_listeners_international_top_content_user_info
GROUP BY 1,2,3,4,5,6,7,8,9,10,11
;


--- Drop TABLEs
DROP TABLE IF EXISTS radio1_sandbox.vb_listeners_international_top_content;
DROP TABLE IF EXISTS radio1_sandbox.vb_listeners_international_top_content_user_info;


--- Check
SELECT week_commencing, sum(num_plays) as num_plays FROM radio1_sandbox.vb_listeners_international_top_content_final group by 1;
