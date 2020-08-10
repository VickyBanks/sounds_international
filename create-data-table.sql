DROP TABLE IF EXISTS radio1_sandbox.vb_ace_scv_raw_data;
CREATE TABLE radio1_sandbox.vb_ace_scv_raw_data
(
    d_visitor_id             VARCHAR(255),
    d_time_date              varchar(255) DISTKEY,
    d_rm_content             varchar(255),
    d_rm_broadcast           VARCHAR(255),
    app_name                 VARCHAR(255),
    app_type                 VARCHAR(255),
    stream_starts_min_3_secs INT,
    stream_playing_time      INT
) SORTKEY (d_time_date);


INSERT INTO radio1_sandbox.vb_ace_scv_raw_data
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
      AND dt = TO_CHAR(TRUNC(getdate() - 1), 'yyyymmdd')
      AND geo_country_site_visited IN ('United Kingdom')
      AND is_signed_in IS TRUE
      AND is_personalisation_on IS TRUE
    AND dt > 20200805
    group by 1, 2, 3, 4, 5, 6, 7
)
select dt :: date,
       audience_id,
       version_id,
       app_type,
       app_name,
       broadcast_type,
       count(distinct play_id),
       sum(playback_time_agg)
from play_ids
where playback_time_agg >= 3
group by 1, 2, 3, 4, 5, 6
;

SELECT * FROM radio1_sandbox.vb_ace_scv_raw_data LIMIT 10;