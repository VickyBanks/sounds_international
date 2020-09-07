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
       ('bbc_radio_fourfm', 'Speech'),
       ('bbc_radio_fourlw', 'Speech'),
       ('bbc_radio_foyle', 'Speech'),
       ('bbc_radio_glastonbury', 'Music'),
       ('bbc_radio_gloucestershire', 'Speech'),
       ('bbc_radio_guernsey', 'Speech'),
       ('bbc_radio_hereford_worcester', 'Speech'),
       ('bbc_radio_humberside', 'Speech'),
       ('bbc_radio_jersey', 'Speech'),
       ('bbc_radio_kent', 'Speech'),
       ('bbc_radio_lancashire', 'Speech'),
       ('bbc_radio_leeds', 'Speech'),
       ('bbc_radio_leicester', 'Speech'),
       ('bbc_radio_lincolnshire', 'Speech'),
       ('bbc_radio_manchester', 'Speech'),
       ('bbc_radio_merseyside', 'Speech'),
       ('bbc_radio_nan_gaidheal', 'Speech'),
       ('bbc_radio_newcastle', 'Speech'),
       ('bbc_radio_norfolk', 'Speech'),
       ('bbc_radio_northampton', 'Speech'),
       ('bbc_radio_nottingham', 'Speech'),
       ('bbc_radio_one', 'Music'),
       ('bbc_radio_one_vintage', 'Music'),
       ('bbc_radio_oxford', 'Speech'),
       ('bbc_radio_scotland', 'Speech'),
       ('bbc_radio_scotland_fm', 'Speech'),
       ('bbc_radio_scotland_music_extra', 'Speech'),
       ('bbc_radio_scotland_mw', 'Speech'),
       ('bbc_radio_sheffield', 'Speech'),
       ('bbc_radio_shropshire', 'Speech'),
       ('bbc_radio_solent', 'Speech'),
       ('bbc_radio_somerset_sound', 'Speech'),
       ('bbc_radio_stoke', 'Speech'),
       ('bbc_radio_suffolk', 'Speech'),
       ('bbc_radio_surrey', 'Speech'),
       ('bbc_radio_sussex', 'Speech'),
       ('bbc_radio_three', 'Music'),
       ('bbc_radio_two', 'Music'),
       ('bbc_radio_two_country', 'Music'),
       ('bbc_radio_two_fifties', 'Music'),
       ('bbc_radio_ulster', 'Speech'),
       ('bbc_radio_wales', 'Speech'),
       ('bbc_radio_wales_fm', 'Speech'),
       ('bbc_radio_webonly', 'Speech'),
       ('bbc_radio_wiltshire', 'Speech'),
       ('bbc_radio_york', 'Speech'),
       ('bbc_russian_radio', 'Speech'),
       ('bbc_school_radio', 'Speech'),
       ('bbc_scotland', 'Speech'),
       ('bbc_sinhala_radio', 'Speech'),
       ('bbc_sounds_mixes', 'Music'),
       ('bbc_sounds_podcasts', 'Speech'),
       ('bbc_sport', 'Speech'),
       ('bbc_switch', 'Speech'),
       ('bbc_tees', 'Speech'),
       ('bbc_three', 'Speech'),
       ('bbc_three_counties_radio', 'Speech'),
       ('bbc_two', 'Speech'),
       ('bbc_two_northern_ireland_digital', 'Speech'),
       ('bbc_two_wales_digital', 'Speech'),
       ('bbc_wales', 'Speech'),
       ('bbc_webonly', 'Speech'),
       ('bbc_wm', 'Speech'),
       ('bbc_world_news', 'Speech'),
       ('bbc_world_service', 'Speech'),
       ('bbc_world_service_asia', 'Speech'),
       ('bbc_world_service_audio', 'Speech'),
       ('cbbc', 'Speech'),
       ('cbeebies', 'Speech'),
       ('cbeebies_radio', 'Speech'),
       ('N/A', 'Speech'),
       ('null', 'Speech')
;

