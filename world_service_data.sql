/*
 Get some top summaries for world service for top content and top brands

 1. top epsidoes per country
 2. top episodes total
 3. top TLEOS per country
 4. top TLEOs total
 5. number of listeners to WS SI vs SO.
 6. number of listeners to WS SI vs SO with coutnry
 7. how many hours of live vs od content listened split by country, SI vs SO
 8. how many hours of live vs od content listened, SI vs SO
 9. top 10 countries by number of listeners
 10. top 10 countries by time spent
 11. top 10 countries by number of listeners - every week
 12. top 10 countries by playback time - every week

 */

-- 1. Top episodes per country and signed in status
with top_eps AS (
    SELECT most_common_master_brand AS masterbrand,
           week_commencing,
           country,
           signed_in_status,
           concat_title             as episode_title,
           sum(num_plays)           as number_of_plays,
           sum(num_accounts)        AS number_of_accounts
    FROM radio1_sandbox.dataforce_listeners_international_top_episodes_final
    WHERE most_common_master_brand = 'bbc_world_service'
      AND app_type = 'All'
    AND week_commencing = (SELECT max(week_commencing) FROM radio1_sandbox.dataforce_listeners_international_top_episodes_final)
    GROUP BY 1, 2, 3, 4, 5),
    top_eps_ranked AS (
         SELECT *,
                row_number() over (partition by week_commencing, country, signed_in_status ORDER BY number_of_plays DESC) as rank_by_plays
         FROM top_eps
     )
SELECT *
FROM top_eps_ranked
WHERE rank_by_plays <=10
ORDER BY week_commencing, country, rank_by_plays
;
-- 2. top episodes no country split
with top_eps AS (
    SELECT most_common_master_brand AS masterbrand,
           week_commencing,
           signed_in_status,
           concat_title             as episode_title,
           sum(num_plays)           as number_of_plays,
           sum(num_accounts)        AS number_of_accounts
    FROM radio1_sandbox.dataforce_listeners_international_top_episodes_final
    WHERE most_common_master_brand = 'bbc_world_service'
      AND app_type = 'All'
    AND week_commencing = (SELECT max(week_commencing) FROM radio1_sandbox.dataforce_listeners_international_top_episodes_final)

    GROUP BY 1, 2, 3, 4),
    top_eps_ranked AS (
         SELECT *,
                row_number() over (partition by week_commencing, signed_in_status ORDER BY number_of_plays DESC) as rank_by_plays
         FROM top_eps
     )
SELECT *
FROM top_eps_ranked
WHERE rank_by_plays <=10
ORDER BY week_commencing, signed_in_status,  rank_by_plays
;

-- 3. Top TLEOS per country and signed in status
SELECT * FROM radio1_sandbox.dataforce_listeners_international_top_content_final
WHERE most_common_master_brand = 'bbc_world_service'
LIMIT 5;

with top_tleos AS (
    SELECT most_common_master_brand AS masterbrand,
           week_commencing,
           country,
           signed_in_status,
           tleo,
           sum(num_plays)           as number_of_plays,
           sum(num_accounts)        AS number_of_accounts
    FROM radio1_sandbox.dataforce_listeners_international_top_content_final
    WHERE most_common_master_brand = 'bbc_world_service'
      AND app_type = 'All'
    AND week_commencing = (SELECT max(week_commencing) FROM radio1_sandbox.dataforce_listeners_international_top_content_final)
    GROUP BY 1, 2, 3, 4, 5),
    top_tleos_ranked AS (
         SELECT *,
                row_number() over (partition by week_commencing, country, signed_in_status ORDER BY number_of_plays DESC) as rank_by_plays
         FROM top_tleos
     )
SELECT *
FROM top_tleos_ranked
WHERE rank_by_plays <= 10
ORDER BY week_commencing, country, rank_by_plays
;



--4. top TLEOS
with top_tleos AS (
    SELECT most_common_master_brand AS masterbrand,
           week_commencing,
           signed_in_status,
           tleo,
           sum(num_plays)           as number_of_plays,
           sum(num_accounts)        AS number_of_accounts
    FROM radio1_sandbox.dataforce_listeners_international_top_content_final
    WHERE most_common_master_brand = 'bbc_world_service'
      AND app_type = 'All'

    AND week_commencing = (SELECT max(week_commencing) FROM radio1_sandbox.dataforce_listeners_international_top_content_final)
    GROUP BY 1, 2, 3, 4),
    top_tleos_ranked AS (
         SELECT *,
                row_number() over (partition by week_commencing, signed_in_status ORDER BY number_of_plays DESC) as rank_by_plays
         FROM top_tleos
     )
SELECT *
FROM top_tleos_ranked
WHERE rank_by_plays <= 10
ORDER BY week_commencing, signed_in_status,  rank_by_plays
;


--5. number of listeners to WS SI vs SO.
SELECT masterbrand, week_commencing, signed_in_status, sum(num_listeners) AS number_of_listeners
FROM radio1_sandbox.dataforce_listeners_international_weekly_summary
WHERE masterbrand = 'bbc_world_service'
  AND app_type = 'All'
  AND week_commencing =
      (SELECT max(week_commencing) FROM radio1_sandbox.dataforce_listeners_international_weekly_summary)
GROUP BY 1,2,3
ORDER BY 2,3,4;

--6.  country split.
SELECT masterbrand, week_commencing, country, signed_in_status, sum(num_listeners) AS number_of_listeners
FROM radio1_sandbox.dataforce_listeners_international_weekly_summary
WHERE masterbrand = 'bbc_world_service'
  AND app_type = 'All'
  AND week_commencing =
      (SELECT max(week_commencing) FROM radio1_sandbox.dataforce_listeners_international_weekly_summary)
GROUP BY 1,2,3,4
ORDER BY 2,3,4,5
LIMIT 5;

SELECT * FROM radio1_sandbox.dataforce_listeners_international_weekly_summary LIMIT 5;
-- 7. how many hours of live vs od content listened split by country, SI vs SO
SELECT masterbrand, week_commencing, signed_in_status, broadcast_type, round(sum(playback_time_total)::double precision/(60*60),1) as playback_time_hours
FROM radio1_sandbox.dataforce_listeners_international_weekly_summary
WHERE masterbrand = 'bbc_world_service'
  AND app_type = 'All'
  AND week_commencing =
      (SELECT max(week_commencing) FROM radio1_sandbox.dataforce_listeners_international_weekly_summary)
GROUP BY 1,2,3,4
ORDER BY 3,4
;

-- 8. how many hours of live vs od content listened, SI vs SO
SELECT masterbrand, week_commencing, country, signed_in_status, broadcast_type, round(sum(playback_time_total)::double precision/(60*60),1) as playback_time_hours
FROM radio1_sandbox.dataforce_listeners_international_weekly_summary
WHERE masterbrand = 'bbc_world_service'
  AND app_type = 'All'
  AND week_commencing =
      (SELECT max(week_commencing) FROM radio1_sandbox.dataforce_listeners_international_weekly_summary)
GROUP BY 1,2,3,4,5
ORDER BY 3,4,5
;


-- 9. top 10 countries by number of listeners
with top_by_listners AS
         (SELECT masterbrand,
                 week_commencing,
                 country,
                 sum(num_listeners) as number_of_listeners
          FROM radio1_sandbox.dataforce_listeners_international_weekly_summary
          WHERE masterbrand = 'bbc_world_service'
            AND app_type = 'All'
            AND week_commencing =
                (SELECT max(week_commencing) FROM radio1_sandbox.dataforce_listeners_international_weekly_summary)
          GROUP BY 1, 2, 3
          ORDER BY 3)
SELECT *,
       row_number() over (order by number_of_listeners DESC) as rank_by_listener_numbers
FROM top_by_listners
ORDER BY rank_by_listener_numbers;


-- 10. top 10 countries by time spent
with top_by_time AS
         (SELECT masterbrand,
                 week_commencing,
                 country,
                 round(sum(playback_time_total)::double precision / (60 * 60), 1) as playback_time_hours
          FROM radio1_sandbox.dataforce_listeners_international_weekly_summary
          WHERE masterbrand = 'bbc_world_service'
            AND app_type = 'All'
            AND week_commencing =
                (SELECT max(week_commencing) FROM radio1_sandbox.dataforce_listeners_international_weekly_summary)
          GROUP BY 1, 2, 3
          ORDER BY 3)
SELECT *,
       row_number() over (order by playback_time_hours DESC) as rank_by_time
FROM top_by_time
ORDER BY rank_by_time;


-- 11. top 10 countries by number of listeners - every week
with top_by_listners AS
         (SELECT masterbrand,
                 week_commencing,
                 country,
                 sum(num_listeners) as number_of_listeners
          FROM radio1_sandbox.dataforce_listeners_international_weekly_summary
          WHERE masterbrand = 'bbc_world_service'
            AND app_type = 'All'
          GROUP BY 1, 2, 3
          ORDER BY 3),
     top_by_listners_ranked AS (
         SELECT *,
                row_number()
                over (partition by week_commencing order by number_of_listeners DESC) as rank_by_listener_numbers
         FROM top_by_listners
     )
SELECT *
FROM top_by_listners_ranked
WHERE rank_by_listener_numbers <=10
ORDER BY rank_by_listener_numbers, week_commencing;


 --12. top 10 countries by playback time - every week
with top_by_time AS
         (SELECT masterbrand,
                 week_commencing,
                 country,
                 round(sum(playback_time_total)::double precision / (60 * 60), 1) as playback_time_hours
          FROM radio1_sandbox.dataforce_listeners_international_weekly_summary
          WHERE masterbrand = 'bbc_world_service'
            AND app_type = 'All'
          GROUP BY 1, 2, 3
          ORDER BY 3),
     top_by_time_ranked AS (
         SELECT *,
                row_number()
                over (partition by week_commencing order by playback_time_hours DESC) as rank_by_playback_time
         FROM top_by_time
     )
SELECT *
FROM top_by_time_ranked
WHERE rank_by_playback_time <= 10
ORDER BY rank_by_playback_time, week_commencing;