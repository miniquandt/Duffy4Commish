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
	SELECT t.tournament_id as tid, t.tournament_slug as tslug, et AS GameID, t.blue AS blueside, t.name t.red AS redside FROM game_and_team t 
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
	
	,assistants
	,monstertype
	,killer
	,inenemyjungle
	,killerteamid
	/*
	,localgold
	,globalgold
	,bountygold
	 */
	,killtype
	/*
	 ,stageid
	 ,killergold
	 ,dragontype
	 ,gamename
	 ,gameversion
	 ,statsupdateinterval
	 */
	,playbackid
	,gametime
	/*
	,nextdragonspawntime
	,nextdragonname
	,gameover
	 */
	/*
	 * teams
	 */
	,itemid
	,participantid
	/*
	,goldgain
	,itemafterundo
	,itembeforeundo
	,skillslot
	 */
	,participant
	/*
	,evolved
	 */
	,wardtype
	,placer
	
	
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
	,pt.position.z, pt.position.x
	,pt.currentgold
	,pt.xp,pt.level,pt.totalgold
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
	,pt.teamid, pt.participantid
	, pt.position.z, pt.position.x
	,pt.currentgold
	,pt.xp,pt.level,pt.totalgold
FROM games g
LATERAL VIEW explode(g.participants) participants_table AS pt
LATERAL VIEW explode(g.teams) teams_table as tt
WHERE eventtype = "stats_update" AND tt.teamID = pt.teamID
LIMIT 500;

/* get only data we care about in games table */
SELECT * from games g 
WHERE g.gameover = true 
	OR eventtype = 'game_info'
	OR (eventtype = 'epic_monster_kill' and (monstertype = 'dragon' or monstertype = 'baron' or monstertype = 'riftHerald')) 
	OR (eventtype = 'stats_update' and gametime >= 840000 and gametime <841000);