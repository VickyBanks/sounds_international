-- Create a table of version id and a concatenated episode title
DROP TABLE IF EXISTS radio1_sandbox.vb_sounds_int_ep_titles;
CREATE TABLE radio1_sandbox.vb_sounds_int_ep_titles AS
with vmb_subset as (
    SELECT distinct version_id,
                    CASE WHEN clip_title = 'null' THEN null ELSE clip_title END                 as clip_title,
                    CASE WHEN episode_title = 'null' THEN null ELSE episode_title END           as episode_title,
                    CASE WHEN series_title = 'null' THEN null ELSE series_title END             as series_title,
                    CASE WHEN brand_title = 'null' THEN null ELSE brand_title END               as brand_title,
                    CASE WHEN presentation_title = 'null' THEN null ELSE presentation_title END as presentation_title
    FROM prez.scv_vmb
)
SELECT DISTINCT version_id,
                CASE
                    WHEN episode_title = presentation_title AND episode_title = clip_title
                        THEN -- if episode, presentation and clip all match then only use one
                        REPLACE(
                                RTRIM(
                                        LTRIM(
                                                REPLACE(
                                                        (
                                                                    COALESCE(brand_title, '') ||
                                                                    COALESCE(' - ' || series_title, '') ||
                                                                    COALESCE(' - ' || clip_title, '')
                                                            )
                                                    , 'null', ''),
                                                ' - '),
                                        ' - '),
                                ' -  - ', ' - ')
                    WHEN episode_title = presentation_title THEN -- if episode and presentation match then only use one
                        REPLACE(
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
                                                            , 'null', ''),
                                                        ' - '),
                                                ' - '),
                                        ' -  -  - ', ' - '),
                                ' -  - ', ' - ')
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
                                                                    , 'null', ''),
                                                                ' - '),
                                                        ' - '),
                                                ' -  -  -  - ', ' - '),
                                        ' -  -  - ', ' - '),
                                ' -  - ', ' - ')
                    END AS concatenated_title
FROM vmb_subset
;

GRANT SELECT ON  radio1_sandbox.vb_sounds_int_ep_titles TO GROUP radio;
GRANT SELECT ON  radio1_sandbox.vb_sounds_int_ep_titles TO GROUP central_insights;
GRANT SELECT ON  radio1_sandbox.vb_sounds_int_ep_titles TO GROUP central_insights_server;
GRANT ALL ON  radio1_sandbox.vb_sounds_int_ep_titles TO GROUP dataforce_analysts;

SELECT * FROM radio1_sandbox.vb_sounds_int_ep_titles LIMIT 10;