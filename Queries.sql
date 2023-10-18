SELECT l.id, l.name, l.slug, t.name, t.id FROM leagues l 
INNER JOIN tournaments t on t.leagueid = l.id WHERE l.slug = "lcs" LIMIT 1;

SELECT * FROM teams WHERE slug = "cloud9";

/* Gets teams total gold*/
SELECT eventtime, eventtype, platformgameid, teams.totalgold, gametime
FROM games 
WHERE eventtype = "stats_update" 
LIMIT 10;

/* Gets teams total gold at a specific time (14 minutes= 840 seconds=840000ms*/
/* 10 rows 1m 45s*/
SELECT eventtime, eventtype, platformgameid, gametime
FROM games 
WHERE eventtype = "stats_update" AND gametime > 840000
LIMIT 10;

/* Gets Game IDs for all matches for a specific tournament */
SELECT t.id AS Tournament_Id, t.slug AS Tournament_Slug, et.name AS Match_Name, et2.id AS Matches_Ids, et3.id AS Game_Ids
FROM tournaments t 
LATERAL VIEW explode(stages.sections) exploaded_table AS et
LATERAL VIEW explode(et.matches) exptab2 AS et2
LATERAL VIEW explode(et2.games) exptab3 AS et3
WHERE t.slug like "lcs_s%" OR t.slug like "lck_s%" or t.slug like "lec_s%";
/*WHERE slug = 'lcs_summer_2022';*/

/**********************************************************************************
VVVVVVVVVVVVVVVVVVVVVVVVVVvVV Possibly Broken Queries VVVVVVVVVVVVVVVVVVVVVVVVVVVVV
**********************************************************************************/
select activity, bricktotalamount, customername, datetime, deviceid, orderid, name, 
amount from temp.test_json
lateral view inline(color) c as amount,name

 SELECT explode(stages.sections) FROM tournaments WHERE slug = 'lcs_summer_2022';

SELECT t.id, et.* FROM tournaments t LATERAL VIEW explode(stages.sections) et;

SELECT t.id, et.name FROM tournaments t LATERAL VIEW explode(stages.sections) exploaded_table AS et WHERE t.slug = 'lcs_summer_2022';

SELECT t.id, et.matches FROM tournaments t LATERAL VIEW explode(stages.sections) exploaded_table AS et WHERE t.slug = 'lcs_summer_2022';

LATERAL VIEW explode(et.matches) exptab2 AS et2 WHERE t.slug = 'lcs_summer_2022';

/*//////////////////////////////////////////////////////////////////////////// */
/* Creates new table with way less info for tournaments 
create table tournSmall AS
SELECT t.id AS Tournament_Id, t.slug AS Tournament_Slug, et.name AS Match_Name, et2.id AS Matches_Ids, et3.id AS Game_Ids
FROM tournaments t 
LATERAL VIEW explode(stages.sections) exploaded_table AS et
LATERAL VIEW explode(et.matches) exptab2 AS et2
LATERAL VIEW explode(et2.games) exptab3 AS et3
*/
create table game_and_team AS
SELECT t.id AS Tournament_Id, t.slug AS Tournament_Slug, et.name[0] AS name, et3.id AS Game_Ids, et3.teams[0].id[0] AS blue, et3.teams[0].id[1] AS red
FROM tournaments t
LATERAL VIEW explode(stages.sections) exploaded_table AS et
LATERAL VIEW explode(et.matches) exptab2 AS et2
LATERAL VIEW explode(et2.games) exptab3 AS et3

/* Get all games for all the different tournaments */
SELECT t.tournament_id, t.tournament_slug, et AS GameID FROM tournsmall t 
	LATERAL VIEW explode(t.game_ids) exploaded_table AS et

/* Map Game to the Game Data */
SELECT * FROM (
	SELECT t.tournament_id as tid, t.tournament_slug as tslug, et AS GameID FROM tournsmall t 
	LATERAL VIEW explode(t.game_ids) exploaded_table AS et) AS gIds
INNER JOIN mapping_data md 
ON md.esportsgameid = gIds.GameID;

/* create better mapping data table */
create table better_mapping_data AS 
SELECT gids.tid AS Tournament_Id, gids.tslug AS slug, gids.gameid AS gameid, md.platformgameid AS platformgameid, gids.blueside, gids.redside FROM (
	SELECT t.tournament_id as tid, t.tournament_slug as tslug, et AS GameID, t.blue AS blueside, t.red AS redside FROM game_and_team t 
	LATERAL VIEW explode(t.game_ids) exploaded_table AS et
	WHERE t.tournament_slug like "%2023" AND t.tournament_slug like "lcs_s%" ) AS gIds
INNER JOIN mapping_data md 
ON md.esportsgameid = gIds.GameID;

/* get better game data table */
SELECT 
	/*info to identify */
	 eventtime
	,eventtype
	,platformgameid
	,pt.teamid
	,pt.participantid
	,sequenceindex
	,playbackid
	,gametime
	/* team stats */
	,tt.assists AS Team_Assists
	,tt.baronKills AS Team_Baron_Kills
	,tt.championsKills AS Team_Champions_Kills
	,tt.deaths AS Team_Deaths
	,tt.dragonKills AS Team_Dragon_Kills
	,tt.inhibKills AS Team_Inhib_Kills
	,tt.totalGold AS Team_Total_Gold
	,tt.towerKills AS Team_Tower_Kills
	/* player stats*/
	,pt.currentgold
	,pt.xp
	,pt.level
	,pt.totalgold
	,pt.stats[0].value AS Minions_Killed
	,pt.stats[1].value AS Neutral_Minions_Killed
	,pt.stats[2].value AS Neutral_Minions_Killed_Your_Jungle
	,pt.stats[3].value AS Neutral_Minions_Killed_Enemy_Jungle
	,pt.stats[4].value AS Champions_Killed
	,pt.stats[5].value AS Num_Deaths
	,pt.stats[6].value AS Assists
	,pt.stats[31].value AS Ward_Placed
	,pt.stats[32].value AS Ward_Killed
	,pt.stats[33].value AS Vision_Score
FROM games_filtered g
LATERAL VIEW explode(g.participants) participants_table AS pt
LATERAL VIEW explode(g.teams) teams_table as tt
WHERE eventtype = "stats_update" AND tt.teamID = pt.teamID;

/* get only data we care about in games table */
create table games_filtered AS
SELECT * from games g 
WHERE g.gameover = true 
	OR eventtype = 'game_info'
	OR (eventtype = 'epic_monster_kill' and (monstertype = 'dragon' or monstertype = 'baron' or monstertype = 'riftHerald')) 
	OR (eventtype = 'stats_update' and gametime >= 840000 and gametime <841000);

/************************************************************************************/
/************************************************************************************/
/************************************************************************************/
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
	OR (eventtype = 'epic_monster_kill' and (monstertype = 'dragon' or monstertype = 'baron' or monstertype = 'riftHerald')) 
	OR (eventtype = 'stats_update' and gametime >= 840000 and gametime <841000);

/* query 4 */
CREATE Table games_teams_compare AS
SELECT DISTINCT 
	  bmd.tournament_id
	, bmd.slug
	, bmd.gameid
	, bmd.blueside
	, bmd.redside
	, gsu.teamid
	, gsu.sequenceindex
	, gsu.team_assists 
	, gsu.team_baron_kills 
	, gsu.team_champions_kills 
	, gsu.team_deaths 
	, gsu.team_dragon_kills 
	, gsu.team_inhib_kills 
	, gsu.team_total_gold 
	, gsu.team_tower_kills 
	, gsu_enemy.team_assists AS enemy_team_assists
	, gsu_enemy.team_baron_kills AS enemy_team_baron_kills
	, gsu_enemy.team_champions_kills AS enemy_team_champions_kills 
	, gsu_enemy.team_deaths AS enemy_team_deaths 
	, gsu_enemy.team_dragon_kills AS enemy_team_dragon_kills 
	, gsu_enemy.team_inhib_kills AS enemy_team_inhib_kills 
	, gsu_enemy.team_total_gold AS enemy_team_total_gold 
	, gsu_enemy.team_tower_kills as enemy_team_tower_kills 
FROM lol.better_mapping_data_all bmd
INNER JOIN games_stats_updates gsu
ON gsu.platformgameid = bmd.platformgameid
INNER JOIN games_stats_updates gsu_enemy
ON gsu_enemy.platformgameid = bmd.platformgameid AND gsu_enemy.sequenceindex = gsu.sequenceindex AND gsu_enemy.teamid != gsu.teamid
WHERE ((gsu.teamid = 100) OR (gsu.teamid = 200)) AND ((gsu_enemy.teamid = 200) OR (gsu_enemy.teamid = 100));

/*
SELECT * From games_stats_updates gsu;
SELECT 
	  eventtime
	, eventtype
	, platformgameid
	, teamid, participantid, sequenceindex, playbackid, gametime, team_assists, team_baron_kills, team_champions_kills, team_deaths, team_dragon_kills, team_inhib_kills, team_total_gold, team_tower_kills, currentgold, xp, level, totalgold, minions_killed, neutral_minions_killed, neutral_minions_killed_your_jungle, neutral_minions_killed_enemy_jungle, champions_killed, num_deaths, assists, ward_placed, ward_killed, vision_score
FROM lol.games_stats_updates
WHERE teamid = "98767991877340524";

SELECT * from game_and_team gat;
SELECT 
	  tournament_id
	, tournament_slug
	, name
	, game_ids
	, blue
	, red
FROM lol.game_and_team;

SELECT * FROM games_stats_updates gsu WHERE playbackid = 2;

SELECT * FROM better_mapping_data_all bmd;

SELECT * from games_teams_compare gtc ;
SELECT
	gtc.tournament_id,
	gtc.slug,
	gtc.gameid,
	gtc.blueside,
	bt.name AS Blue_Team_Name,
	gtc.redside,
	rt.name AS Red_Team_Name,
	gtc.teamid,
	gtc.sequenceindex,
	gtc.team_assists,
	gtc.team_baron_kills,
	gtc.team_champions_kills,
	gtc.team_deaths,
	gtc.team_dragon_kills,
	gtc.team_inhib_kills,
	gtc.team_total_gold,
	gtc.team_tower_kills,
	gtc.enemy_team_assists,
	gtc.enemy_team_baron_kills,
	gtc.enemy_team_champions_kills,
	gtc.enemy_team_deaths,
	gtc.enemy_team_dragon_kills,
	gtc.enemy_team_inhib_kills,
	gtc.enemy_team_total_gold,
	gtc.enemy_team_tower_kills
FROM lol.games_teams_compare gtc
INNER JOIN teams bt 
ON bt.team_id = gtc.blueside 
INNER JOIN teams rt
ON rt.team_id = gtc.redside ;

SELECT DISTINCT monstertype from games_filtered gf ;

SELECT * from games_filtered gf WHERE eventtype ="stats_update" AND gameover != true


CREATE Table games_teams_compare AS
SELECT DISTINCT 
	  bmd.tournament_id
	, bmd.slug
	, bmd.gameid
	, bmd.blueside
	, bmd.redside
	, gsu.eventtime
	, gsu.teamid
	, gsu.sequenceindex
	, gsu.team_assists 
	, gsu.team_baron_kills 
	, gsu.team_champions_kills 
	, gsu.team_deaths 
	, gsu.team_dragon_kills 
	, gsu.team_inhib_kills 
	, gsu.team_total_gold 
	, gsu.team_tower_kills 
	, gsu_enemy.team_assists AS enemy_team_assists
	, gsu_enemy.team_baron_kills AS enemy_team_baron_kills
	, gsu_enemy.team_champions_kills AS enemy_team_champions_kills 
	, gsu_enemy.team_deaths AS enemy_team_deaths 
	, gsu_enemy.team_dragon_kills AS enemy_team_dragon_kills 
	, gsu_enemy.team_inhib_kills AS enemy_team_inhib_kills 
	, gsu_enemy.team_total_gold AS enemy_team_total_gold 
	, gsu_enemy.team_tower_kills as enemy_team_tower_kills 
FROM lol.better_mapping_data_all bmd
INNER JOIN games_stats_updates gsu
ON gsu.platformgameid = bmd.platformgameid
INNER JOIN games_stats_updates gsu_enemy
ON gsu_enemy.platformgameid = bmd.platformgameid AND gsu_enemy.sequenceindex = gsu.sequenceindex AND gsu_enemy.teamid != gsu.teamid
WHERE ((gsu.teamid = 100) OR (gsu.teamid = 200)) AND ((gsu_enemy.teamid = 200) OR (gsu_enemy.teamid = 100));

select * from games_stats_updates gf;

order by bmd.gameid;
/* 110060650668050170	98767991877340524	98926509892121852	2772
 * Cloud 9 team Id: 98767991877340524
 */
