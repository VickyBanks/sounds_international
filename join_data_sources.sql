SELECT * FROM radio1_sandbox.vb_sounds_dashboard_1_page_views_international LIMIT 10;
SELECT * FROM radio1_sandbox.vb_sounds_dashboard_5_listening_international LIMIT 10;

with time_spent AS (
    SELECT week_commencing,
           country,
           signed_in_status,
           age_range,
           gender,
           app_type,
           sum(stream_starts)       as stream_starts,
           sum(stream_playing_time) as stream_playing_time
    FROM radio1_sandbox.vb_sounds_dashboard_5_listening_international
    GROUP BY 1, 2, 3, 4, 5, 6
)
SELECT *, b.stream_starts, b.stream_playing_time
FROM radio1_sandbox.vb_sounds_dashboard_1_page_views_international a
         FULL OUTER JOIN time_spent b
                         ON a.week_commencing = b.week_commencing AND a.country = b.country
                             AND a.signed_in_status = b.signed_in_status AND a.age_range = b.age_range
                             AND a.gender = b.gender AND a.app_type = b.app_type
WHERE a.country = 'Israel' AND b.country = 'Israel'
;