/*
 Get some top summaries for world service for top content and top brands
 */

SELECT * FROM radio1_sandbox.dataforce_listeners_international_top_episodes_final LIMIT 5;
SELECT DISTINCT app_type FROM radio1_sandbox.dataforce_listeners_international_top_episodes_final LIMIT 5;

with top_eps AS (
    SELECT most_common_master_brand AS masterbrand,
           week_commencing,
           country,
           signed_in_status,
           concat_title             as episode_title,
           sum(num_plays)           as number_of_plays,
           sum(num_accounts)        AS number_of_accounts
    FROM radio1_sandbox.dataforce_listeners_international_top_episodes_final
    WHERE most_common_master_brand ILIKE '%world%' AND app_type = 'All'
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

-- Top TLEOS
SELECT * FROM radio1_sandbox.dataforce_listeners_international_top_content_final
WHERE most_common_master_brand ILIKE '%world%'
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
    WHERE most_common_master_brand ILIKE '%world%' AND app_type = 'All' AND country = 'France'
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