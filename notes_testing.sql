
/*
 Need to replicated this table
    SELECT * FROM radio1_sandbox.sounds_dashboard_1_page_views LIMIT 10;
 Using this table SELECT * FROM audience.audience_activity_daily_summary_enriched  WHERE destination = 'PS_SOUNDS' LIMIT 10;

 BUT the first table is only needed for
 - week commencing
 - id_age_range
 - app_type
 - num signed in accounts (distinct bbc_hid 3

 The other fields are no longer needed
 */
SELECT * FROM radio1_sandbox.sounds_dashboard_1_page_views LIMIT 10;

SELECT * FROM audience.audience_activity_daily_summary_enriched  WHERE destination = 'PS_SOUNDS' LIMIT 10;

 SELECT DISTINCT TRUNC(DATE_TRUNC('week', getdate() - 7)) AS week_commencing,
                id_age_range,
                app_type,
                count(DISTINCT bbc_hid)
FROM audience.audience_activity_daily_summary_enriched
 WHERE destination = 'PS_SOUNDS';

----From Sohail original
DROP TABLE IF EXISTS radio1_sandbox.ace_scv_raw_data;
CREATE TABLE radio1_sandbox.ace_scv_raw_data (
    d_visitor_id VARCHAR(55),
    d_time_date varchar(55) DISTKEY,
    d_rm_content varchar(55),
    d_rm_broadcast VARCHAR(55),
    app_name   VARCHAR(55),
    app_type   VARCHAR(55),
    stream_starts_min_3_secs  INT,
    stream_playing_time INT
) SORTKEY(d_time_date);

INSERT INTO radio1_sandbox.ace_scv_raw_data
with play_ids as (
    SELECT dt,
           audience_id,
           version_id,
           app_type,
           app_name,
           broadcast_type,
           play_id,
           sum(playback_time_total) AS playback_time_agg
    FROM s3_audience.audience_activity_daily_summary a
    WHERE destination = 'PS_SOUNDS'
      AND dt = TO_CHAR(TRUNC(getdate() - 1),'yyyymmdd')
      AND geo_country_site_visited IN ('United Kingdom')
      AND is_signed_in IS TRUE
      AND is_personalisation_on IS TRUE
    group by 1,2,3,4,5,6,7
)
select
    dt :: date,
    audience_id,
    version_id,
    app_type,
    app_name,
    broadcast_type,
    count(distinct play_id),
    sum(playback_time_agg)
from play_ids
where playback_time_agg >= 3
group by 1,2,3,4,5,6
;

with visitors AS (
    SELECT week_commencing, country, sum(num_visitors) as total_visitors
    FROM radio1_sandbox.vb_sounds_dashboard_1_page_views_international
    WHERE app_type = 'all'
      AND signed_in_status = 'all'
      AND country != 'All International'
    GROUP BY 1, 2
),
     time AS (
         SELECT week_commencing, country, sum(stream_playing_time) as total_time
         FROM radio1_sandbox.vb_sounds_dashboard_5_listening_international
         WHERE app_type = 'all'
           AND signed_in_status = 'all'
           AND country != 'All International'
         GROUP BY 1, 2)
SELECT a.week_commencing,
       a.country,
       a.total_visitors,
       b.total_time,
       round(CAST((total_time::double precision /3600 )/ total_visitors::double precision as double precision),1) AS time_per_user
FROM visitors a
         FULL JOIN time b ON a.week_commencing = b.week_commencing AND a.country = b.country
WHERE total_visitors >100
AND a.week_commencing = '2020-08-17' AND b.week_commencing = '2020-08-17'
;

SELECT * FROM radio1_sandbox.vb_listeners_international LIMIT 5;

SELECT a.*, b.master_brand_id, b.speech_music_split
FROM radio1_sandbox.vb_sounds_int_users_listening a
         LEFT JOIN vb_vmb_summary b
                   ON a.version_id = b.master_brand_id
WHERE playback_time_total
    > 3
  AND playback_time_total IS NOT NULL
  AND a.id_type = 'master_brand_id'
LIMIT 100;

select count(*) FROM vb_vmb_summary ;


SELECT a.version_id,
       CASE WHEN programme_title NOT IN ('null','n/a', 'N/A','') AND programme_title IS NOT NULL
                     AND episode_title NOT IN ('null','n/a', 'N/A','') AND episode_title IS NOT NULL THEN programme_title || ' - ' ||episode_title
           WHEN programme_title NOT IN ('null','n/a', 'N/A','') AND programme_title IS NOT NULL AND
                (episode_title IN ('null','n/a', 'N/A','') OR episode_title IS  NULL) THEN programme_title
           WHEN (programme_title IN ('null','n/a', 'N/A','') or programme_title IS NULL) AND
                episode_title NOT IN ('null','n/a', 'N/A','') AND episode_title IS NOT NULL THEN episode_title
           END as episode_fancy_title,
       count(a.*) as num_plays
FROM radio1_sandbox.vb_listeners_international_top_content a
LEFT JOIN prez.scv_vmb b on a.version_id = b.version_id
GROUP BY 1,2
ORDER BY 3 DESC;

CASE
    WHEN episode_title = presentation_title AND episode_title = clip_title THEN -- if episode, presentation and clip all match then only use one
          REPLACE (
            RTRIM(
              LTRIM(
                REPLACE(
                  (
                  COALESCE(brand_title, '') ||
                  COALESCE(' - ' || series_title, '') ||
                  COALESCE(' - ' || clip_title, '')
                  )
                ,'null', ''),
              ' - '),
            ' - '),
      ' -  - ',' - ')
    WHEN episode_title = presentation_title THEN -- if episode and presentation match then only use one
      REPLACE (
        REPLACE(
            RTRIM(
              LTRIM(
                REPLACE(
                  (
                  COALESCE(brand_title, '') ||
                  COALESCE(' - ' || series_title, '') ||
                  COALESCE(' - ' || episode_title, '') ||
                  COALESCE(' - ' || clip_title, '')
                  )
                ,'null', ''),
              ' - '),
            ' - '),
      ' -  -  - ',' - '),
      ' -  - ',' - ')
    ELSE
  REPLACE(
      REPLACE(
          REPLACE(
            RTRIM(
              LTRIM(
                REPLACE(
                  (
                  COALESCE(brand_title, '') ||
                  COALESCE(' - ' || series_title, '') ||
                  COALESCE(' - ' || episode_title, '') ||
                  COALESCE(' - ' || presentation_title, '') ||
                  COALESCE(' - ' || clip_title, '')
                  )
                ,'null', ''),
              ' - '),
            ' - '),
          ' -  -  -  - ',' - '),
        ' -  -  - ',' - '),
      ' -  - ',' - ')
    END AS concatenated_title;




SELECT * FROM radio1_sandbox.tleo_metadata LIMIT 10;
SELECT * FROM radio1_sandbox.episode_metadata LIMIT 10;
SELECT * FROM radio1_sandbox.audio_content_enriched LIMIT 10;

with dist_formats AS (
    SELECT DISTINCT version_id,
           CASE
               WHEN LOWER(bbc_st_lod) = 'live' THEN 'live_radio'
               WHEN sounds_mixes_bool THEN 'od_sounds_mixes'
               WHEN all_mixes_bool THEN 'od_linear_mixes'
               WHEN rail_podcasts_bool THEN 'od_sounds_podcasts'
               WHEN all_podcasts_bool THEN 'od_radio_podcasts'
               ELSE 'od_radio'
               END AS format
    FROM radio1_sandbox.audio_content_enriched
)
SELECT version_id, format, row_number() over (partition by version_id order by 2) FROM dist_formats
ORDER BY 1,3;


SELECT day, hashed_id,age
FROM  radio1_sandbox.audio_content_enriched LIMIT 10;

SELECT DISTINCT nation FROM radio1_sandbox.audio_content_enriched;

SELECT * FROM radio1_sandbox.vb_speech_music_master_brand_split LIMIT 5;