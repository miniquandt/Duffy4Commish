use lol;

/* Query 1 */
create table game_and_team AS
SELECT t.id AS Tournament_Id, t.slug AS Tournament_Slug, et.name[0] AS name, et3.id AS Game_Ids, et3.teams[0].id[0] AS blue, et3.teams[0].id[1] AS red
FROM tournaments t
LATERAL VIEW explode(stages.sections) exploaded_table AS et
LATERAL VIEW explode(et.matches) exptab2 AS et2
LATERAL VIEW explode(et2.games) exptab3 AS et3

/* Query 2 */
create table better_mapping_data AS 
SELECT gids.tid AS Tournament_Id, gids.tslug AS slug, gids.gameid AS gameid, md.platformgameid AS platformgameid, gids.blueside, gids.redside FROM (
	SELECT t.tournament_id as tid, t.tournament_slug as tslug, et AS GameID, t.blue AS blueside, t.red AS redside FROM game_and_team t 
	LATERAL VIEW explode(t.game_ids) exploaded_table AS et
	/* WHERE t.tournament_slug like "%2023" AND t.tournament_slug like "lcs_s%" */) AS gIds
INNER JOIN mapping_data md 
ON md.esportsgameid = gIds.GameID;

/* query 3 - took 33 minutes*/
create table games_filtered AS
SELECT * from games g 
WHERE g.gameover = true 
	OR eventtype = 'game_info'
    OR eventtype = 'game_end'
	OR (eventtype = 'epic_monster_kill' and (monstertype = 'dragon' or monstertype = 'baron' or monstertype = 'riftHerald')) 
	OR (eventtype = 'stats_update' and gametime >= 840000 and gametime <841000);