------------------ Script 3 ------------------
/*
 This finds the all the visitors and what content they viewed and for how long.
 Group the content by: play,s live/od, speach/music,
 */

--SELECT * FROM radio1_sandbox.dataforce_sounds_int_users_listening WHERE playback_time_total >3 AND playback_time_total IS NOT NULL LIMIT 10;
--0. A simplified VMB has been created in script 0 and 1
--SELECT * FROM radio1_sandbox.dataforce_speech_music_master_brand_split LIMIT 10;
--SELECT * FROM dataforce_vmb_summary WHERE speech_music_split IS NOT NULL LIMIT 10;

--0. Create music mix list
DROP TABLE IF EXISTS dataforce_sandbox.dataforce_music_mixes;
CREATE TEMP TABLE dataforce_music_mixes AS
SELECT DISTINCT version_id, all_mixes_bool FROM radio1_sandbox.audio_content_enriched
WHERE all_mixes_bool = TRUE;


--1. Create table of listeners only (not just visitors) i.e remove anyone where the playback time was 3s or less
-- Add in if it's speech or music and add in master_brand
-- To be dropped after use
DROP TABLE IF EXISTS radio1_sandbox.dataforce_listeners_international;
CREATE TABLE radio1_sandbox.dataforce_listeners_international
    SORTKEY (master_brand_id)
    DISTKEY ( master_brand_id )
AS (
    SELECT a.*, b.master_brand_id, b.speech_music_split,c.all_mixes_bool
    FROM radio1_sandbox.dataforce_sounds_int_users_listening a
             LEFT JOIN dataforce_sandbox.dataforce_vmb_summary b ON a.version_id = b.version_id -- Inserts when the version_id is the an episode pid
    LEFT JOIN dataforce_music_mixes c ON a.version_id = c.version_id
    WHERE playback_time_total > 3
      AND playback_time_total IS NOT NULL
      AND a.id_type = 'version_id')
;


-- Inserts when the version_id is a master_brand
INSERT INTO radio1_sandbox.dataforce_listeners_international
with vmb_subset_mini AS
         (SELECT DISTINCT master_brand_id, speech_music_split
          FROM dataforce_sandbox.dataforce_vmb_summary) -- This is to just get distinct masterbrands as the main table has lots of entries because of the many version ids
SELECT a.*, b.master_brand_id, b.speech_music_split
FROM radio1_sandbox.dataforce_sounds_int_users_listening a
         LEFT JOIN vmb_subset_mini b ON a.version_id = b.master_brand_id
WHERE playback_time_total > 3
  AND playback_time_total IS NOT NULL
  AND a.id_type = 'master_brand_id'
;


-- 2. Create a table summarising the number of listeners.
-- Split by country, signed in status, age range, app_type, live vs od, speech vs music
-- Because these will need to be deduped, need to add in 'all' fields
/*DROP TABLE IF EXISTS radio1_sandbox.dataforce_listeners_international_weekly_summary;
CREATE TABLE radio1_sandbox.dataforce_listeners_international_weekly_summary
(
    week_commencing     date DISTKEY,
    country             varchar(255),
    signed_in_status    varchar(10),
    age_range           varchar(40),
    app_type            varchar(40),
    broadcast_type      varchar(40),
    speech_music_split  varchar(40),
    masterbrand         varchar(255),
    num_listeners       bigint,
    num_plays           bigint,
    playback_time_total bigint
) SORTKEY (week_commencing)
;*/

--2.a All splits
INSERT INTO radio1_sandbox.dataforce_listeners_international_weekly_summary
SELECT week_commencing,
       country,
       signed_in_status,
       age_range,
       app_type,
       broadcast_type,
       speech_music_split,
       master_brand_id,
       count(distinct audience_id) as num_listeners,
       count(play_id) as num_plays,
       sum(playback_time_total) as playback_time_total
FROM radio1_sandbox.dataforce_listeners_international
GROUP BY 1,2,3,4,5,6,7,8
;

--2.b - dedup across app type
INSERT INTO radio1_sandbox.dataforce_listeners_international_weekly_summary
SELECT week_commencing,
       country,
       signed_in_status,
       age_range,
       cast('all' as varchar) as app_type,
       broadcast_type,
       speech_music_split,
       master_brand_id,
       count(distinct audience_id) as num_listeners,
       count(play_id) as num_plays,
       sum(playback_time_total) as playback_time_total
FROM radio1_sandbox.dataforce_listeners_international
GROUP BY 1,2,3,4,5,6,7,8
;

-- 3. Change to more stakeholder friendly language
UPDATE radio1_sandbox.dataforce_listeners_international_weekly_summary
SET broadcast_type = (CASE
                          WHEN broadcast_type = 'Clip' THEN 'On-Demand'
                          WHEN broadcast_type = 'Live' THEN 'Live'
                          ELSE broadcast_type END)
;

UPDATE radio1_sandbox.dataforce_listeners_international_weekly_summary
SET speech_music_split = (CASE
                          WHEN speech_music_split ISNULL THEN 'Speech'
                          ELSE speech_music_split END)
;

UPDATE radio1_sandbox.dataforce_listeners_international_weekly_summary
SET app_type = (CASE
                    WHEN app_type = 'bigscreen-html' THEN 'TV'
                    WHEN app_type = 'mobile-app' THEN 'Mobile'
                    WHEN app_type = 'responsive' THEN 'Web'
                    WHEN app_type = 'all' THEN 'All'
                    ELSE app_type END)
;
UPDATE radio1_sandbox.dataforce_listeners_international_weekly_summary
SET signed_in_status = (CASE
                            WHEN signed_in_status = 'signed in' THEN 'Signed-in'
                            WHEN signed_in_status = 'signed out' THEN 'Signed-out'
                            ELSE signed_in_status END);


-------------------- Drop TABLES
DROP TABLE IF EXISTS radio1_sandbox.dataforce_listeners_international;
DROP TABLE IF EXISTS dataforce_sandbox.dataforce_music_mixes;

--- Grants
GRANT SELECT ON  radio1_sandbox.dataforce_listeners_international_weekly_summary TO GROUP radio;
GRANT SELECT ON  radio1_sandbox.dataforce_listeners_international_weekly_summary TO GROUP central_insights;
GRANT ALL ON  radio1_sandbox.dataforce_listeners_international_weekly_summary TO GROUP central_insights_server;
GRANT ALL ON  radio1_sandbox.dataforce_listeners_international_weekly_summary TO GROUP dataforce_analysts;

SELECT week_commencing, count(*)
FROM radio1_sandbox.dataforce_listeners_international_weekly_summary
GROUP BY 1;

