--0. Create table to split content into speach or music
DROP TABLE IF EXISTS radio1_sandbox.vb_speech_music_master_brand_split;
CREATE TABLE IF NOT EXISTS radio1_sandbox.vb_speech_music_master_brand_split
(
    master_brand_id    varchar(255),
    master_brand_fancy_name varchar (255),
    speech_music_split varchar(40)
);
INSERT INTO radio1_sandbox.vb_speech_music_master_brand_split
values ('bbc_1xtra','BBC 1Xtra','Music'),
('bbc_6music','BBC 6 Music','Music'),
('bbc_7','BBC 7','Speech'),
('bbc_afrique_radio','BBC Afrique Radio','Speech'),
('bbc_alba','BBC Alba','Speech'),
('bbc_arabic_radio','BBC Arabic Radio','Speech'),
('bbc_arts','BBC Arts','Speech'),
('bbc_asian_network','BBC Asian Network','Music'),
('bbc_cymru','BBC Cymru','Speech'),
('bbc_dari_radio','BBC Dari Radio','Speech'),
('bbc_four','BBC Radio 4','Speech'),
('bbc_hindi_radio','BBC Hinda Radio','Speech'),
('bbc_learning_english','BBC Learning English','Speech'),
('bbc_local_radio','BBC Local Radio','Speech'),
('bbc_london','BBC London','Speech'),
('bbc_mundo','BBC Mundo','Speech'),
('bbc_music','BBC Music','Music'),
('bbc_music_jazz','BBC Music Jazz','Music'),
('bbc_news','BBC News','Speech'),
('bbc_one','BBC One','Speech'),
('bbc_one_northern_ireland','BBC One Northern Ireland','Speech'),
('bbc_one_scotland','BBC One Scotland','Speech'),
('bbc_one_wales','BBC One Wales','Speech'),
('bbc_persian_radio','BBC Persian Radio','Speech'),
('bbc_radio_berkshire','BBC Radio Berkshire','Speech'),
('bbc_radio_bristol','BBC Radio Bristol','Speech'),
('bbc_radio_cambridge','BBC Radio Cambridge','Speech'),
('bbc_radio_cornwall','BBC Radio Cornwall','Speech'),
('bbc_radio_coventry_warwickshire','BBC Radio Coventry & Warwickshire','Speech'),
('bbc_radio_cumbria','BBC Radio Cumbria','Speech'),
('bbc_radio_cymru','BBC Radio Cymry','Speech'),
('bbc_radio_cymru_2','BBC Radio Cymru 2','Speech'),
('bbc_radio_cymru_mwy','BBC Radio Cymru Mwy','Speech'),
('bbc_radio_derby','BBC Radio Derby','Speech'),
('bbc_radio_devon','BBC Radio Devon','Speech'),
('bbc_radio_essex','BBC Radio Essexs','Speech'),
('bbc_radio_five_live','BBC Radio Five Live','Speech'),
('bbc_radio_five_live_olympics_extra','BBC Radio Five Live Olympics Extra','Speech'),
('bbc_radio_five_live_sports_extra','BBC Radio Five Live Sports Extra','Speech'),
('bbc_radio_four','BBC Radio 4','Speech'),
('bbc_radio_four_extra','BBC Radio 4 Extra','Speech'),
('bbc_radio_fourfm','BBC Radio 4 FM','Speech'),
('bbc_radio_fourlw','BBC Radio 4 LW','Speech'),
('bbc_radio_foyle','BBC Radio Foyle','Speech'),
('bbc_radio_glastonbury','BBC Radio Glastonbury','Music'),
('bbc_radio_gloucestershire','BBC Radio Gloucestershire','Speech'),
('bbc_radio_guernsey','BBC Radio Guernsey','Speech'),
('bbc_radio_hereford_worcester','BBC Radio Hereford & Worcester','Speech'),
('bbc_radio_humberside','BBC Radio Humbeside','Speech'),
('bbc_radio_jersey','BBC Radio Jersey','Speech'),
('bbc_radio_kent','BBC Radio Kent','Speech'),
('bbc_radio_lancashire','BBC Radio Lancashire','Speech'),
('bbc_radio_leeds','BBC Radio Leeds','Speech'),
('bbc_radio_leicester','BBC Radio Leiester','Speech'),
('bbc_radio_lincolnshire','BBC Radio Lincolnshire','Speech'),
('bbc_radio_manchester','BBC Radio Manchester','Speech'),
('bbc_radio_merseyside','BBC Radio Merseyside','Speech'),
('bbc_radio_nan_gaidheal','BBC Radio Nan Gaidheel','Speech'),
('bbc_radio_newcastle','BBC Radio Newcastle','Speech'),
('bbc_radio_norfolk','BBC Radio Norfolk','Speech'),
('bbc_radio_northampton','BBC Radio Northampton','Speech'),
('bbc_radio_nottingham','BBC Radio Nottingham','Speech'),
('bbc_radio_one','BBC Radio 1','Music'),
('bbc_radio_one_vintage','BBC Radio 1 Vintage','Music'),
('bbc_radio_oxford','BBC Radio Oxford','Speech'),
('bbc_radio_scotland','BBC Radio Scotland','Speech'),
('bbc_radio_scotland_fm','BBC Radio Scotland FM','Speech'),
('bbc_radio_scotland_music_extra','BBC Radio Scotland Music Extra','Speech'),
('bbc_radio_scotland_mw','BBC Radio Scotland MW','Speech'),
('bbc_radio_sheffield','BBC Radio Sheffield','Speech'),
('bbc_radio_shropshire','BBC Radio Shropshire','Speech'),
('bbc_radio_solent','BBC Radio Solent','Speech'),
('bbc_radio_somerset_sound','BBC Radio Somerset Sound','Speech'),
('bbc_radio_stoke','BBC Radio Stoke','Speech'),
('bbc_radio_suffolk','BBC Radio Suffold','Speech'),
('bbc_radio_surrey','BBC Radio Surrey','Speech'),
('bbc_radio_sussex','BBC Radio Sussex','Speech'),
('bbc_radio_three','BBC Radio 3','Music'),
('bbc_radio_two','BBC Radio 2','Music'),
('bbc_radio_two_country','BBC Radio 2 Country','Music'),
('bbc_radio_two_fifties','BBC Radio 2 Fifties','Music'),
('bbc_radio_ulster','BBC Radio Ulster','Speech'),
('bbc_radio_wales','BBC Radio Wales','Speech'),
('bbc_radio_wales_fm','BBC Radio Wales FM','Speech'),
('bbc_radio_webonly','BBC Radio Web Only','Speech'),
('bbc_radio_wiltshire','BBC Radio Wiltshire','Speech'),
('bbc_radio_york','BBC Radio York','Speech'),
('bbc_russian_radio','','Speech'),
('bbc_school_radio','BBC Radio School','Speech'),
('bbc_scotland','BBC Scotland','Speech'),
('bbc_sinhala_radio','BBC Sinhala Radio','Speech'),
('bbc_sounds_mixes','BBC Sounds Mixes','Music'),
('bbc_sounds_podcasts','BBC Sounds Podcasts','Speech'),
('bbc_sport','BBC Sport','Speech'),
('bbc_switch','BBC Switch','Speech'),
('bbc_tees','BBC Tees','Speech'),
('bbc_three','BBC Three','Speech'),
('bbc_three_counties_radio','BBC Three Counties Radio','Speech'),
('bbc_two','BBC Two','Speech'),
('bbc_two_northern_ireland_digital','BBC Two Northern Ireland Digital','Speech'),
('bbc_two_wales_digital','BBC Two Wales Digital','Speech'),
('bbc_wales','BBC Wales','Speech'),
('bbc_webonly','BBC Web Only','Speech'),
('bbc_wm','BBC WM','Speech'),
('bbc_world_news','BBC World News','Speech'),
('bbc_world_service','BBC World Service','Speech'),
('bbc_world_service_asia','BBC World Service Asia','Speech'),
('bbc_world_service_audio','BBC World Service Audio','Speech'),
('cbbc','CBBC','Speech'),
('cbeebies','Cbeebies','Speech'),
('cbeebies_radio','Cbeebies Radio','Speech'),
('N/A','','Speech'),
('null','','Speech')
;


GRANT SELECT ON radio1_sandbox.vb_speech_music_master_brand_split TO GROUP radio;
GRANT SELECT ON radio1_sandbox.vb_speech_music_master_brand_split TO GROUP central_insights;
GRANT SELECT ON radio1_sandbox.vb_speech_music_master_brand_split TO GROUP central_insights_server;
GRANT SELECT ON radio1_sandbox.vb_speech_music_master_brand_split TO GROUP dataforce_analysts;