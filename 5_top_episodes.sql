/*
 Script to find the number of accounts and plays for each episode of content per week.
 The final table only contains the top 20 most popular episodes
 */

--0. This table radio1_sandbox.vb_sounds_int_ep_titles is created previously to create a concat title for each episode
--SELECT * FROM radio1_sandbox.vb_sounds_int_ep_titles LIMIT 10;

--1. Create table of listeners only (not just visitors) i.e remove anyone where the playback time was 3s or less
-- Add information about content
-- Add in if it's speech or music
-- To be dropped after use
DROP TABLE IF EXISTS radio1_sandbox.vb_listeners_international_top_episodes;
CREATE TABLE radio1_sandbox.vb_listeners_international_top_episodes
    SORTKEY (master_brand_id)
    DISTKEY (master_brand_id)
AS (
    SELECT a.*, b.master_brand_id, b.speech_music_split, c.concatenated_title
    FROM radio1_sandbox.vb_sounds_int_users_listening a
             LEFT JOIN vb_vmb_summary b
                       ON a.version_id = b.version_id -- Inserts when the version_id is the an episode pid
             LEFT JOIN radio1_sandbox.vb_sounds_int_ep_titles c on a.version_id = c.version_id
    WHERE playback_time_total > 3
      AND playback_time_total IS NOT NULL
      AND a.id_type = 'version_id')
;


--2.
-- Some episodes have a small amount of content under another masterbrand.
-- This is annoying for tableau so simplify to only choose the most common one for all records
DROP TABLE IF EXISTS radio1_sandbox.master_brand_rename_eps;
CREATE TABLE radio1_sandbox.master_brand_rename_eps AS
with most_common_master_brand AS (
    SELECT concatenated_title,
           master_brand_id,
           count(audience_id)                                                          as num_plays,
           row_number() over (partition by concatenated_title order by num_plays desc) as most_common
    FROM radio1_sandbox.vb_listeners_international_top_episodes
    GROUP BY 1, 2)
SELECT DISTINCT concatenated_title, master_brand_id as most_common_master_brand
FROM most_common_master_brand
WHERE most_common = 1;

-- 3. Add in frequency information about the user
DROP TABLE IF EXISTS radio1_sandbox.vb_listeners_international_top_episodes_user_info;
CREATE TABLE radio1_sandbox.vb_listeners_international_top_episodes_user_info AS
SELECT a.*,
       c.most_common_master_brand,
       CASE
           WHEN b.frequency_band is null THEN 'new'
           ELSE b.frequency_band END                                             AS frequency_band,
       central_insights_sandbox.udf_dataforce_frequency_groups(b.frequency_band) as frequency_group_aggregated
FROM radio1_sandbox.vb_listeners_international_top_episodes a
         LEFT JOIN radio1_sandbox.weekly_frequency_calculations b
                   ON a.week_commencing = b.date_of_segmentation AND a.audience_id = b.bbc_hid3
         LEFT JOIN radio1_sandbox.master_brand_rename_eps c on a.concatenated_title = c.concatenated_title
;

SELECT * FROM radio1_sandbox.vb_listeners_international_top_episodes_user_info
LIMIT 20;

-- 4.
/*DROP TABLE IF EXISTS radio1_sandbox.vb_listeners_international_top_episodes_final;
CREATE TABLE radio1_sandbox.vb_listeners_international_top_episodes_final
(
    week_commencing            date DISTKEY,
    country                    varchar(255),
    signed_in_status           varchar(10),
    age_range                  varchar(40),
    app_type                   varchar(40),
    broadcast_type             varchar(40),
    speech_music_split         varchar(40),
    most_common_master_brand   varchar(400),
    concat_title               varchar(4000),
    version_id                 varchar(255),
    frequency_band             varchar(400),
    frequency_group_aggregated varchar(40),
    num_plays                  bigint,
    num_accounts               bigint
) SORTKEY (week_commencing)
;
*/

--3.a All splits
/*
 country Y
 signed in status Y
 app type Y
 */
INSERT INTO radio1_sandbox.vb_listeners_international_top_episodes_final
SELECT week_commencing,
       country,
       signed_in_status,
       age_range,
       app_type,
       broadcast_type,
       speech_music_split,
       most_common_master_brand,
       concatenated_title,
       version_id,
       frequency_band,
       frequency_group_aggregated,
       count(audience_id)          as num_plays,
       count(DISTINCT audience_id) as num_accounts
FROM radio1_sandbox.vb_listeners_international_top_episodes_user_info
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
;
SELECT * fROM radio1_sandbox.vb_listeners_international_top_episodes_final LIMIT 10;
--4.b Some splits
/*
 country N
 signed in status Y
 app type Y
 */
INSERT INTO radio1_sandbox.vb_listeners_international_top_episodes_final
SELECT week_commencing,
       CAST('All International' AS varchar) AS country,
       signed_in_status,
       age_range,
       app_type,
       broadcast_type,
       speech_music_split,
       most_common_master_brand,
       concatenated_title,
       version_id,
       frequency_band,
       frequency_group_aggregated,
       count(audience_id)                   as num_plays,
       count(DISTINCT audience_id)          as num_accounts
FROM radio1_sandbox.vb_listeners_international_top_episodes_user_info
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
;

--4.c Some splits
/*
 country N
 signed in status N
 app type Y
 */

INSERT INTO radio1_sandbox.vb_listeners_international_top_episodes_final
SELECT week_commencing,
       CAST('All International' AS varchar) AS country,
       CAST('all' AS varchar)               AS signed_in_status,
       age_range,
       app_type,
       broadcast_type,
       speech_music_split,
       most_common_master_brand,
       concatenated_title,
       version_id,
       frequency_band,
       frequency_group_aggregated,
       count(audience_id)                   as num_plays,
       count(DISTINCT audience_id)          as num_accounts
FROM radio1_sandbox.vb_listeners_international_top_episodes_user_info
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
;
--4.d Some splits
/*
 country N
 signed in status N
 app type N
 */
INSERT INTO radio1_sandbox.vb_listeners_international_top_episodes_final
SELECT week_commencing,
       CAST('All International' AS varchar) AS country,
       CAST('all' AS varchar)               AS signed_in_status,
       age_range,
       CAST('all' as varchar)               AS app_type,
       broadcast_type,
       speech_music_split,
       most_common_master_brand,
       concatenated_title,
       version_id,
       frequency_band,
       frequency_group_aggregated,
       count(audience_id)                   as num_plays,
       count(DISTINCT audience_id)          as num_accounts
FROM radio1_sandbox.vb_listeners_international_top_episodes_user_info
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
;

--4.e Some splits
/*
 country N
 signed in status Y
 app type N
 */

INSERT INTO radio1_sandbox.vb_listeners_international_top_episodes_final
SELECT week_commencing,
       CAST('All International' AS varchar) AS country,
       signed_in_status,
       age_range,
       CAST('all' as varchar)               AS app_type,
       broadcast_type,
       speech_music_split,
       most_common_master_brand,
       concatenated_title,
       version_id,
       frequency_band,
       frequency_group_aggregated,
       count(audience_id)                   as num_plays,
       count(DISTINCT audience_id)          as num_accounts
FROM radio1_sandbox.vb_listeners_international_top_episodes_user_info
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
;
--4.f Some splits
/*
 country Y
 signed in status N
 app type N
 */
INSERT INTO radio1_sandbox.vb_listeners_international_top_episodes_final
SELECT week_commencing,
       country,
       CAST('all' AS varchar)      AS signed_in_status,
       age_range,
       CAST('all' as varchar)      AS app_type,
       broadcast_type,
       speech_music_split,
       most_common_master_brand,
       concatenated_title,
       version_id,
       frequency_band,
       frequency_group_aggregated,
       count(audience_id)          as num_plays,
       count(DISTINCT audience_id) as num_accounts
FROM radio1_sandbox.vb_listeners_international_top_episodes_user_info
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
;
--4.g Some splits
/*
 country Y
 signed in status Y
 app type N
 */
INSERT INTO radio1_sandbox.vb_listeners_international_top_episodes_final
SELECT week_commencing,
       country,
       signed_in_status,
       age_range,
       CAST('all' as varchar)      AS app_type,
       broadcast_type,
       speech_music_split,
       most_common_master_brand,
       concatenated_title,
       version_id,
       frequency_band,
       frequency_group_aggregated,
       count(audience_id)          as num_plays,
       count(DISTINCT audience_id) as num_accounts
FROM radio1_sandbox.vb_listeners_international_top_episodes_user_info
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
;
--4.h Some splits
/*
 country Y
 signed in status N
 app type Y
 */
INSERT INTO radio1_sandbox.vb_listeners_international_top_episodes_final
SELECT week_commencing,
       country,
       CAST('all' AS varchar)      AS signed_in_status,
       age_range,
       app_type,
       broadcast_type,
       speech_music_split,
       most_common_master_brand,
       concatenated_title,
       version_id,
       frequency_band,
       frequency_group_aggregated,
       count(audience_id)          as num_plays,
       count(DISTINCT audience_id) as num_accounts
FROM radio1_sandbox.vb_listeners_international_top_episodes_user_info
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
;


-- 5. Change to more stakeholder friendly language
UPDATE radio1_sandbox.vb_listeners_international_top_episodes_final
SET broadcast_type = (CASE
                          WHEN broadcast_type = 'Clip' THEN 'On-Demand'
                          WHEN broadcast_type = 'Live' THEN 'Live'
                          ELSE broadcast_type END)
;

UPDATE radio1_sandbox.vb_listeners_international_top_episodes_final
SET speech_music_split = (CASE
                          WHEN speech_music_split ISNULL THEN 'Speech'
                          ELSE speech_music_split END)
;

UPDATE radio1_sandbox.vb_listeners_international_top_episodes_final
SET app_type = (CASE
                    WHEN app_type = 'bigscreen-html' THEN 'TV'
                    WHEN app_type = 'mobile-app' THEN 'Mobile'
                    WHEN app_type = 'responsive' THEN 'Web'
                    WHEN app_type = 'all' THEN 'All'
                    ELSE app_type END)
;


---6.  The above table is huge to import to tableau so this next part finds just the top 20 tleos for each field combination
DROP TABLE IF EXISTS radio1_sandbox.vb_listeners_international_weekly_summary_top20_episodes_temp;
CREATE TABLE radio1_sandbox.vb_listeners_international_weekly_summary_top20_episodes_temp AS
SELECT *,
       row_number()
       over (PARTITION BY week_commencing, country, signed_in_status, age_range, app_type, broadcast_type,speech_music_split, frequency_band,frequency_group_aggregated
           ORDER BY num_plays DESC) as row_count
FROM radio1_sandbox.vb_listeners_international_top_episodes_final
    WHERE week_commencing = (SELECT distinct week_commencing FROM radio1_sandbox.vb_listeners_international_top_episodes_user_info) ;--TRUNC(DATE_TRUNC('week', getdate() - 7));

-- Select only top 20
/*DROP TABLE IF EXISTS radio1_sandbox.vb_listeners_international_weekly_summary_top20_episodes;
CREATE TABLE radio1_sandbox.vb_listeners_international_weekly_summary_top20_episodes
(
    week_commencing            date DISTKEY,
    country                    varchar(255),
    signed_in_status           varchar(10),
    age_range                  varchar(40),
    app_type                   varchar(40),
    broadcast_type             varchar(40),
    speech_music_split         varchar(40),
    most_common_master_brand   varchar(400),
    concat_title               varchar(4000),
    version_id                 varchar(255),
    frequency_band             varchar(400),
    frequency_group_aggregated varchar(40),
    num_plays                  bigint,
    num_accounts               bigint,
    row_count                  int,
    master_brand_fancy_name    varchar(400)
) SORTKEY (week_commencing)
;*/
INSERT INTO radio1_sandbox.vb_listeners_international_weekly_summary_top20_episodes
SELECT a.*, b.master_brand_fancy_name
FROM radio1_sandbox.vb_listeners_international_weekly_summary_top20_episodes_temp a
         LEFT JOIN radio1_sandbox.vb_speech_music_master_brand_split b
                   ON a.most_common_master_brand = b.master_brand_id
WHERE row_count <= 20;

-- 7. Change to more stakeholder friendly language
UPDATE radio1_sandbox.vb_listeners_international_weekly_summary_top20_episodes
SET broadcast_type = (CASE
                          WHEN broadcast_type = 'Clip' THEN 'On-Demand'
                          WHEN broadcast_type = 'Live' THEN 'Live'
                          ELSE broadcast_type END)
;

UPDATE radio1_sandbox.vb_listeners_international_weekly_summary_top20_episodes
SET speech_music_split = (CASE
                          WHEN speech_music_split ISNULL THEN 'Speech'
                          ELSE speech_music_split END)
;

UPDATE radio1_sandbox.vb_listeners_international_weekly_summary_top20_episodes
SET app_type = (CASE
                    WHEN app_type = 'bigscreen-html' THEN 'TV'
                    WHEN app_type = 'mobile-app' THEN 'Mobile'
                    WHEN app_type = 'responsive' THEN 'Web'
                    WHEN app_type = 'all' THEN 'All'
                    ELSE app_type END)
;



--Drop tables
DROP TABLE IF EXISTS radio1_sandbox.vb_listeners_international_top_episodes;
DROP TABLE IF EXISTS radio1_sandbox.vb_listeners_international_top_episodes_user_info;
DROP TABLE IF EXISTS radio1_sandbox.vb_listeners_international_weekly_summary_top20_episodes_temp;

SELECT week_commencing, count(*) as num_rows, sum(num_plays) as total_plays
FROM radio1_sandbox.vb_listeners_international_weekly_summary_top20_episodes GROUP BY 1;

SELECT master_brand_fancy_name, concat_title, sum(num_accounts) as total_accounts
FROM radio1_sandbox.vb_listeners_international_weekly_summary_top20_episodes
WHERE app_type = 'All' and country != 'All International' and signed_in_status = 'all'
GROUP BY 1,2
ORDER BY 3 DESC
;

GRANT ALL ON radio1_sandbox.vb_listeners_international_top_episodes_final to helen_jones;
GRANT ALL ON radio1_sandbox.vb_listeners_international_weekly_summary_top20_episodes to helen_jones;