--0. Create table to split content into speach or music
DROP TABLE IF EXISTS radio1_sandbox.vb_speech_music_master_brand_split;
CREATE TABLE IF NOT EXISTS radio1_sandbox.vb_speech_music_master_brand_split
(
    master_brand_id    varchar(255),
    speech_music_split varchar(40)
);
INSERT INTO radio1_sandbox.vb_speech_music_master_brand_split
values ('bbc_1xtra', 'Music'),
       ('bbc_6music', 'Music'),
       ('bbc_7', 'Speech'),
       ('bbc_afrique_radio', 'Speech'),
       ('bbc_alba', 'Speech'),
       ('bbc_arabic_radio', 'Speech'),
       ('bbc_arts', 'Speech'),
       ('bbc_asian_network', 'Music'),
       ('bbc_cymru', 'Speech'),
       ('bbc_dari_radio', 'Speech'),
       ('bbc_four', 'Speech'),
       ('bbc_hindi_radio', 'Speech'),
       ('bbc_learning_english', 'Speech'),
       ('bbc_local_radio', 'Speech'),
       ('bbc_london', 'Speech'),
       ('bbc_mundo', 'Speech'),
       ('bbc_music', 'Music'),
       ('bbc_music_jazz', 'Music'),
       ('bbc_news', 'Speech'),
       ('bbc_one', 'Speech'),
       ('bbc_one_northern_ireland', 'Speech'),
       ('bbc_one_scotland', 'Speech'),
       ('bbc_one_wales', 'Speech'),
       ('bbc_persian_radio', 'Speech'),
       ('bbc_radio_berkshire', 'Speech'),
       ('bbc_radio_bristol', 'Speech'),
       ('bbc_radio_cambridge', 'Speech'),
       ('bbc_radio_cornwall', 'Speech'),
       ('bbc_radio_coventry_warwickshire', 'Speech'),
       ('bbc_radio_cumbria', 'Speech'),
       ('bbc_radio_cymru', 'Speech'),
       ('bbc_radio_cymru_2', 'Speech'),
       ('bbc_radio_cymru_mwy', 'Speech'),
       ('bbc_radio_derby', 'Speech'),
       ('bbc_radio_devon', 'Speech'),
       ('bbc_radio_essex', 'Speech'),
       ('bbc_radio_five_live', 'Speech'),
       ('bbc_radio_five_live_olympics_extra', 'Speech'),
       ('bbc_radio_five_live_sports_extra', 'Speech'),
       ('bbc_radio_four', 'Speech'),
       ('bbc_radio_four_extra', 'Speech'),
       ('bbc_radio_fourfm', 'Speech')
;

