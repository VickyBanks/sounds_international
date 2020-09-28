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
    SELECT a.*, b.master_brand_id, b.tleo, b.tleo_id, b.speech_music_split
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
       CAST(null as varchar) AS tleo,
       CAST(null as varchar) AS tleo_id,
       b.speech_music_split
FROM radio1_sandbox.vb_sounds_int_users_listening a
         LEFT JOIN vmb_subset_mini b ON a.version_id = b.master_brand_id
WHERE playback_time_total > 3
  AND playback_time_total IS NOT NULL
  AND a.id_type = 'master_brand_id'
;

--2.
-- Many tleos have a small amount of content under another masterbrand.
-- This is annoying for tableau so simplify to only choose the most common one for all records
DROP TABLE IF EXISTS radio1_sandbox.master_brand_rename;
CREATE TABLE radio1_sandbox.master_brand_rename AS
with most_common_master_brand AS (
    SELECT tleo,
       master_brand_id,
       count(audience_id)                                            as num_plays,
       row_number() over (partition by tleo order by num_plays desc) as most_common
FROM radio1_sandbox.vb_listeners_international_top_content
GROUP BY 1, 2)
SELECT DISTINCT tleo, master_brand_id as most_common_master_brand
FROM most_common_master_brand
    WHERE most_common = 1;



-- 2. Add in frequency information about the user
DROP TABLE IF EXISTS radio1_sandbox.vb_listeners_international_top_content_user_info;
CREATE TABLE radio1_sandbox.vb_listeners_international_top_content_user_info AS
SELECT a.*,
       c.most_common_master_brand,
       CASE
           WHEN b.frequency_band is null THEN 'new'
           ELSE b.frequency_band END                                             AS frequency_band,
       central_insights_sandbox.udf_dataforce_frequency_groups(b.frequency_band) as frequency_group_aggregated
FROM radio1_sandbox.vb_listeners_international_top_content a
         LEFT JOIN radio1_sandbox.weekly_frequency_calculations b
                   ON a.week_commencing = b.date_of_segmentation AND a.audience_id = b.bbc_hid3
LEFT JOIN radio1_sandbox.master_brand_rename c on a.tleo = c.tleo
;


-- 3.Final table for top TLEO to be inserted into not dropped
/*DROP TABLE IF EXISTS radio1_sandbox.vb_listeners_international_top_content_final;
CREATE TABLE radio1_sandbox.vb_listeners_international_top_content_final
(
    week_commencing            date DISTKEY,
    country                    varchar(255),
    signed_in_status           varchar(10),
    age_range                  varchar(40),
    app_type                   varchar(40),
    broadcast_type             varchar(40),
    speech_music_split         varchar(40),
    most_common_master_brand   varchar(400),
    tleo                       varchar(4000),
    tleo_id                    varchar(255),
    frequency_band             varchar(400),
    frequency_group_aggregated varchar(40),
    num_plays                  bigint,
    num_accounts               bigint
) SORTKEY (week_commencing)
;
*/

--3.a fill table
INSERT INTO radio1_sandbox.vb_listeners_international_top_content_final
SELECT week_commencing,
       country,
       signed_in_status,
       age_range,
       app_type,
       broadcast_type,
       speech_music_split,
       most_common_master_brand,
       tleo,
       tleo_id,
       frequency_band,
       frequency_group_aggregated,
       count(audience_id) as num_plays,
       count(DISTINCT audience_id) as num_accounts
FROM radio1_sandbox.vb_listeners_international_top_content_user_info
GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12
;
--3.b  dedup by app type
INSERT INTO radio1_sandbox.vb_listeners_international_top_content_final
SELECT week_commencing,
       country,
       signed_in_status,
       age_range,
       CAST('all' as varchar)      AS app_type,
       broadcast_type,
       speech_music_split,
       most_common_master_brand,
       tleo,
       tleo_id,
       frequency_band,
       frequency_group_aggregated,
       count(audience_id)          as num_plays,
       count(DISTINCT audience_id) as num_accounts
FROM radio1_sandbox.vb_listeners_international_top_content_user_info
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
;

--3.c  dedup by broadcast type for if a show can be viewed live and od
INSERT INTO radio1_sandbox.vb_listeners_international_top_content_final
SELECT week_commencing,
       country,
       signed_in_status,
       age_range,
       CAST('all' as varchar)      AS app_type,
       CAST('all' as varchar)      AS broadcast_type,
       speech_music_split,
       most_common_master_brand,
       tleo,
       tleo_id,
       frequency_band,
       frequency_group_aggregated,
       count(audience_id)          as num_plays,
       count(DISTINCT audience_id) as num_accounts
FROM radio1_sandbox.vb_listeners_international_top_content_user_info
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
;

--3.d  dedup by broadcast type for if a show can be viewed live and od
INSERT INTO radio1_sandbox.vb_listeners_international_top_content_final
SELECT week_commencing,
       country,
       signed_in_status,
       age_range,
       app_type,
       CAST('all' as varchar)      AS broadcast_type,
       speech_music_split,
       most_common_master_brand,
       tleo,
       tleo_id,
       frequency_band,
       frequency_group_aggregated,
       count(audience_id)          as num_plays,
       count(DISTINCT audience_id) as num_accounts
FROM radio1_sandbox.vb_listeners_international_top_content_user_info
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
;

---

-- 5. Change to more stakeholder friendly language
UPDATE radio1_sandbox.vb_listeners_international_weekly_summary
SET broadcast_type = (CASE
                          WHEN broadcast_type = 'Clip' THEN 'On-Demand'
                          WHEN broadcast_type = 'Live' THEN 'Live'
    WHEN broadcast_type = 'all' THEN 'All'
                          ELSE broadcast_type END)
;

UPDATE radio1_sandbox.vb_listeners_international_weekly_summary
SET speech_music_split = (CASE
                          WHEN speech_music_split ISNULL THEN 'Speech'
                          ELSE speech_music_split END)
;

UPDATE radio1_sandbox.vb_listeners_international_weekly_summary
SET app_type = (CASE
                    WHEN app_type = 'bigscreen-html' THEN 'TV'
                    WHEN app_type = 'mobile-app' THEN 'Mobile'
                    WHEN app_type = 'responsive' THEN 'Web'
                    WHEN app_type = 'all' THEN 'All'
                    ELSE app_type END)
;

UPDATE radio1_sandbox.vb_listeners_international_weekly_summary
SET signed_in_status = (CASE
                            WHEN signed_in_status = 'signed in' THEN 'Signed-in'
                            WHEN signed_in_status = 'signed out' THEN 'Signed-out'
                            ELSE signed_in_status END);

---6.  The above table is HUGE to import to tableau so this next part finds just the top 10 tleos for each field combination
DROP TABLE IF EXISTS radio1_sandbox.vb_listeners_international_weekly_summary_top10_temp;
CREATE TABLE radio1_sandbox.vb_listeners_international_weekly_summary_top10_temp AS
SELECT *,
       row_number()
       over (PARTITION BY week_commencing, country, signed_in_status, age_range, app_type, broadcast_type,speech_music_split, frequency_band,frequency_group_aggregated
           ORDER BY num_plays DESC) as row_count
FROM radio1_sandbox.vb_listeners_international_top_content_final
    WHERE week_commencing = (SELECT distinct week_commencing FROM radio1_sandbox.vb_listeners_international_top_content_user_info) ;--TRUNC(DATE_TRUNC('week', getdate() - 7));

-- Select only top 10.
-- to be inserted into not dropped and re-created
/*DROP TABLE IF EXISTS radio1_sandbox.vb_listeners_international_weekly_summary_top10;
CREATE TABLE radio1_sandbox.vb_listeners_international_weekly_summary_top10
(
    week_commencing            date DISTKEY,
    country                    varchar(255),
    signed_in_status           varchar(10),
    age_range                  varchar(40),
    app_type                   varchar(40),
    broadcast_type             varchar(40),
    speech_music_split         varchar(40),
    most_common_master_brand   varchar(400),
    tleo                       varchar(4000),
    tleo_id                    varchar(255),
    frequency_band             varchar(400),
    frequency_group_aggregated varchar(40),
    num_plays                  bigint,
    num_accounts               bigint,
    row_count                  int,
    master_brand_fancy_name varchar(400)
) SORTKEY (week_commencing)
;*/

INSERT INTO radio1_sandbox.vb_listeners_international_weekly_summary_top10
SELECT a.*, b.master_brand_fancy_name
FROM radio1_sandbox.vb_listeners_international_weekly_summary_top10_temp a
         LEFT JOIN radio1_sandbox.vb_speech_music_master_brand_split b
                   ON a.most_common_master_brand = b.master_brand_id
WHERE row_count <= 10;

-- 7. Change to more stakeholder friendly language
UPDATE radio1_sandbox.vb_listeners_international_weekly_summary_top10
SET broadcast_type = (CASE
                          WHEN broadcast_type = 'Clip' THEN 'On-Demand'
                          WHEN broadcast_type = 'Live' THEN 'Live'
    WHEN broadcast_type = 'all' THEN 'All'
                          ELSE broadcast_type END)
;

UPDATE radio1_sandbox.vb_listeners_international_weekly_summary_top10
SET speech_music_split = (CASE
                          WHEN speech_music_split ISNULL THEN 'Speech'
                          ELSE speech_music_split END)
;

UPDATE radio1_sandbox.vb_listeners_international_weekly_summary_top10
SET app_type = (CASE
                    WHEN app_type = 'bigscreen-html' THEN 'TV'
                    WHEN app_type = 'mobile-app' THEN 'Mobile'
                    WHEN app_type = 'responsive' THEN 'Web'
                    WHEN app_type = 'all' THEN 'All'
                    ELSE app_type END)
;
UPDATE radio1_sandbox.vb_listeners_international_weekly_summary_top10
SET signed_in_status = (CASE
                            WHEN signed_in_status = 'signed in' THEN 'Signed-in'
                            WHEN signed_in_status = 'signed out' THEN 'Signed-out'
                            ELSE signed_in_status END);


--- Drop TABLEs
DROP TABLE IF EXISTS radio1_sandbox.vb_listeners_international_top_content;
DROP TABLE IF EXISTS radio1_sandbox.vb_listeners_international_top_content_user_info;
DROP TABLE IF EXISTS radio1_sandbox.vb_listeners_international_weekly_summary_top10_temp;

--- Check
SELECT week_commencing, count(*) as num_records, sum(num_plays) as num_plays
FROM radio1_sandbox.vb_listeners_international_weekly_summary_top10 GROUP BY 1;


GRANT SELECT ON  radio1_sandbox.vb_listeners_international_weekly_summary_top10 TO GROUP radio;
GRANT SELECT ON  radio1_sandbox.vb_listeners_international_weekly_summary_top10 TO GROUP central_insights;
GRANT SELECT ON  radio1_sandbox.vb_listeners_international_weekly_summary_top10 TO GROUP central_insights_server;
GRANT SELECT ON  radio1_sandbox.vb_listeners_international_weekly_summary_top10 TO GROUP dataforce_analysts;

GRANT SELECT ON  radio1_sandbox.vb_listeners_international_top_content_final TO GROUP radio;
GRANT SELECT ON  radio1_sandbox.vb_listeners_international_top_content_final TO GROUP central_insights;
GRANT SELECT ON  radio1_sandbox.vb_listeners_international_top_content_final TO GROUP central_insights_server;
GRANT SELECT ON  radio1_sandbox.vb_listeners_international_top_content_final TO GROUP dataforce_analysts;
