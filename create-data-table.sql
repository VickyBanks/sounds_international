SELECT * FROM radio1_sandbox.audio_content_enriched LIMIT 10;

-- 1. Get the time of playing for each piece of content for each user
DROP TABLE IF EXISTS radio1_sandbox.vb_ace_scv_international_data;
CREATE TABLE radio1_sandbox.vb_ace_scv_international_data
(
    dt                       date DISTKEY,
    week_commencing          date,
    audience_id              VARCHAR(255),
    country                  varchar(255),
    signed_in_status         varchar(20),
    age_range                varchar(40),
    app_name                 VARCHAR(255),
    app_type                 VARCHAR(255),
    version_id               varchar(255),
    master_brand_id          varchar(255),
    broadcast_type           VARCHAR(255),
    stream_starts_min_3_secs INT,
    stream_playing_time      INT
) SORTKEY (dt);

-- Get VMB summary. This temp table is quicker than using 'with tablee AS ()'
CREATE TEMP TABLE vmb_summary AS
SELECT DISTINCT master_brand_id, version_id
FROM prez.scv_vmb
WHERE media_type = 'audio';

INSERT INTO radio1_sandbox.vb_ace_scv_international_data
with
    -- get the information about the user and what they watched
    play_ids as (
        SELECT dt :: date,
               TRUNC(DATE_TRUNC('week', getdate() - 7)) AS week_commencing,
               audience_id,
               geo_country_site_visited                 as country,
               CASE
                   WHEN is_signed_in = TRUE AND is_personalisation_on = TRUE THEN 'signed in'
                   ELSE 'signed out' END                AS signed_in_status,
               version_id,
               app_type,
               app_name,
               broadcast_type,
               play_id,
               playback_time_total
        FROM s3_audience.audience_activity_daily_summary a
        WHERE destination = 'PS_SOUNDS'
          AND dt BETWEEN TO_CHAR(TRUNC(DATE_TRUNC('week', getdate() - 7)), 'yyyymmdd') -- limits to the past week (Mon-Sun)
            AND TO_CHAR(TRUNC(DATE_TRUNC('week', getdate() - 7) + 6), 'yyyymmdd')
          AND geo_country_site_visited IN ('United Kingdom', 'Jersey', 'Isle of Man', 'Guernsey')
    ),

    -- Add in the user's metadata
    user_age AS (
        SELECT DISTINCT bbc_hid3, age_range
        FROM prez.profile_extension
    )
SELECT dt,
       week_commencing,
       audience_id,
       country,
       signed_in_status,
       c.age_range,
       app_type,
       app_name,
       a.version_id,
       b.master_brand_id,
       broadcast_type,          --Live or OD (clip)
       count(distinct play_id), -- counts the number of plays
       sum(playback_time_total) as playback_time_agg
FROM play_ids a
         LEFT JOIN vmb_summary b
                   ON a.version_id = b.version_id OR a.version_id = b.master_brand_id -- Join with the vmb to get the master brand -- this OR is because sometimes only the master brand is sent in the version_id column not the actual ID
         LEFT JOIN user_age c on a.audience_id = c.bbc_hid3
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
HAVING playback_time_agg >= 3
;

SELECT * FROM radio1_sandbox.vb_ace_scv_international_data LIMIT 10;


SELECT * FROM radio1_sandbox.audio_content_enriched  LIMIT 10;
SELECT * FROM  radio1_sandbox.sounds_dashboard_5_listening  LIMIT 10;


SELECT geo_country_site_visited, count(DISTINCT dt||visit_id||audience_id) AS dist_visit_id, sum(playback_time_total) AS playback_time_agg
FROM s3_audience.audience_activity_daily_summary
WHERE dt = 20200810 AND destination = 'PS_SOUNDS'
GROUP BY 1;