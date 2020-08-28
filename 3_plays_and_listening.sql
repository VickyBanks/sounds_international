------------------ Script 3 ------------------
/*
 This finds the all the visitors and what content they viewed and for how long.
 Group the content by: play,s live/od, speach/music,
 */

SELECT * FROM radio1_sandbox.vb_sounds_int_users_listening WHERE playback_time_total >3 AND playback_time_total IS NOT NULL LIMIT 10;
--0. Create table to split content into speach or music
CREATE TABLE radio1_sandbox.vb_speech_music_master_brand_split (
    master_brand_id varchar (255),
    speech_music_split varchar(40)
);

--1. Create table of listeners only (not jsut visitors) i.e remove anyone where the playback time was 3s or less
-- Add in if it's speach or music and add in master_brand

DROP TABLE IF EXISTS radio1_sandbox.vb_listeners_international;
CREATE TABLE radio1_sandbox.vb_listeners_international
    SORTKEY (master_brand_id)
    DISTKEY ( master_brand_id )
AS (
    SELECT a.*, b.master_brand_id, b.speech_music_split
    FROM radio1_sandbox.vb_sounds_int_users_listening a
             LEFT JOIN vb_vmb_summary b ON a.version_id = b.version_id -- Inserts when the version_id is the an episode pid
    WHERE playback_time_total > 3
      AND playback_time_total IS NOT NULL
      AND a.id_type = 'version_id')
;
-- Inserts when the version_id is a master_brand
INSERT INTO radio1_sandbox.vb_listeners_international
with vmb_subset_mini AS
    (SELECT DISTINCT master_brand_id, speech_music_split FROM vb_vmb_summary) -- This is to just get distinct masterbrands as the main table has lots of entries because of the many version ids

SELECT a.*, b.master_brand_id, b.speech_music_split
FROM radio1_sandbox.vb_sounds_int_users_listening a
         LEFT JOIN vmb_subset_mini b ON a.version_id = b.master_brand_id
WHERE playback_time_total > 3
  AND playback_time_total IS NOT NULL
  AND a.id_type = 'master_brand_id'
;

SELECT speech_music_split, count(*) FROM radio1_sandbox.vb_listeners_international GROUP BY 1;


SELECT week_commencing,
       country,
       signed_in_status,
       age_range,
       app_type,
       broadcast_type,
       speech_music_split,
       count(distinct audience_id) as num_dist_listeners,
       count(play_id) as num_plays,
       sum(playback_time_total) as playback_time
FROM radio1_sandbox.vb_listeners_international
GROUP BY 1,2,3,4,5,6,7
;

SELECT * FROM radio1_sandbox.vb_sounds_int_users_listening a
LEFT JOIN vb_vmb_summary b ON a.version_id = b.version_id
WHERE broadcast_type = 'Clip' AND id_type = 'version_id'
LIMIT 10;

-- need to summarise with all these fileds for the lsitening tab
