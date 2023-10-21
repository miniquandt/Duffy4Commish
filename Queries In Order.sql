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
SELECT gids.tid AS Tournament_Id, gids.tslug AS slug, gids.name, gids.gameid AS gameid, md.platformgameid AS platformgameid, gids.blueside, gids.redside FROM (
	SELECT t.tournament_id as tid, t.tournament_slug as tslug, t.name, et AS GameID, t.blue AS blueside, t.red AS redside FROM game_and_team t 
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

/* query 4 - CREATE GAMES_stats_update_with_participants */
create table games_stats_update_with_participant AS
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
WHERE eventtype = "stats_update" AND tt.teamID = pt.teamID

/* query 5 */
CREATE TABLE games_stats_update AS
SELECT DISTINCT 
	gsu.eventtime,
	gsu.eventtype,
	gsu.platformgameid,
	gsu.teamid,
	gsu.sequenceindex,
	gsu.playbackid,
	gsu.gametime,
	gsu.team_assists,
	gsu.team_baron_kills,
	gsu.team_champions_kills,
	gsu.team_deaths,
	gsu.team_dragon_kills,
	gsu.team_inhib_kills,
	gsu.team_total_gold,
	gsu.team_tower_kills,
	-- Player stats
	SUM(gsu.xp) OVER (PARTITION BY gsu.eventtime, gsu.teamid) AS team_xp_sum,
	SUM(gsu.level) OVER (PARTITION BY gsu.eventtime, gsu.teamid) AS team_level_sum,
	avg(gsu.level) OVER (PARTITION BY gsu.eventtime, gsu.teamid) AS team_level_average,
	SUM(gsu.minions_killed) OVER (PARTITION BY gsu.eventtime, gsu.teamid) AS team_minions_sum,
	SUM(gsu.neutral_minions_killed) OVER (PARTITION BY gsu.eventtime, gsu.teamid) AS team_neutral_minions_sum,
	SUM(gsu.neutral_minions_killed_your_jungle) OVER (PARTITION BY gsu.eventtime, gsu.teamid) AS team_neutral_minions_your_jungle_sum,
	SUM(neutral_minions_killed_enemy_jungle) OVER (PARTITION BY gsu.eventtime, gsu.teamid) AS team_neutral_minions_enemy_jungle_sum,
	SUM(gsu.ward_placed) OVER (PARTITION BY gsu.eventtime, gsu.teamid) AS team_wards_placed_sum,
	SUM(gsu.ward_killed) OVER (PARTITION BY gsu.eventtime, gsu.teamid) AS team_wards_killed_sum,
	SUM(gsu.vision_score) OVER (PARTITION BY gsu.eventtime, gsu.teamid) AS team_vision_score_sum
	,riftelder.team_rift_count
	,riftelder.team_elder_count
	,gf.winningteam
FROM
	lol.games_stats_update_participant gsu
INNER JOIN games_filtered gf 
on gsu.platformgameid = gf.platformgameid 
LEFT JOIN (
	SELECT 
		COALESCE(rift.platformgameid, elder.platformgameid) AS platformgameid
		, team_rift_count
		, COALESCE(rift.killerteamid, elder.killerteamid) as killerteamid
		, team_elder_count
	FROM (
		SELECT DISTINCT 
			gfrift.platformgameid AS platformgameid 
			, COUNT(gfrift.monstertype) OVER (PARTITION BY gfrift.platformgameid , gfrift.killerteamid) AS team_rift_count
			, gfrift.killerteamid AS killerteamid
		FROM lol.games_filtered gfrift
		WHERE (gfrift.eventtype = "epic_monster_kill" AND gfrift.monstertype = 'riftHerald')
	) rift
	FULL OUTER JOIN (
	SELECT DISTINCT 
		gfelder.platformgameid
		, gfelder.killerteamid AS killerteamid
		, COUNT(gfelder.dragontype) OVER (PARTITION BY gfelder.platformgameid, gfelder.killerteamid) AS team_elder_count
	FROM lol.games_filtered gfelder
	WHERE (gfelder.eventtype = "epic_monster_kill" AND gfelder.dragontype ='elder')
	) elder
	ON rift.platformgameid = elder.platformgameid AND rift.killerteamid = elder.killerteamid
) riftelder
ON gsu.platformgameid = riftelder.platformgameid AND gsu.teamid = riftelder.killerteamid
WHERE gf.eventtype ='game_end';

/* query 6  create median info from data*/
SELECT 
	mgeg.median_gold_end_game, mg14.median_gold_14_mins, b.median_baron_per_game, d.median_dragons, m.playoff_multiplier, m.international_multiplier, m.win_multiplier, m.loss_multiplier
from 
	(
		select 1 AS id, percentile(cast(team_total_gold as BIGINT), 0.5) AS median_gold_end_game 
		from games_stats_update gsu -- 60733.0
		WHERE gametime > 841000 AND winningteam = teamid
	) AS mgeg
INNER JOIN 
	(
		select 1 AS id, percentile(cast(team_total_gold as BIGINT), 0.5) AS median_gold_14_mins 
		from games_stats_update gsu -- 23600.0
		WHERE gametime >=840000 AND gametime <=841000 AND winningteam = teamid
	) AS mg14
on mgeg.id = mg14.id
INNER JOIN 
	(
		SELECT 1 as id, percentile(cast(team_baron_kills as BIGINT), 0.5) AS median_baron_per_game -- 1
			--avg(gsu.team_baron_kills) AS baron_per_game_average 
		from games_stats_update gsu
		WHERE gametime >841000
	) as b -- 0.3646188850967008
ON mgeg.id = b.id
INNER JOIN 
	(
		SELECT 1 as id, percentile(cast(team_dragon_kills as BIGINT), 0.5) AS median_dragons -- 2.0
			--avg(gsu.team_dragon_kills) AS baron_per_game_average
		from games_stats_update gsu
		WHERE gametime > 841000
	) d
on mgeg.id = d.id
INNER JOIN 
	(
		SELECT 1 as id, '1.15' AS playoff_multiplier, '1.3' AS international_multiplier, '1.2' AS win_multiplier, '.8' AS loss_multiplier
	) m
on mgeg.id = m.id;

/* query 7 */
CREATE Table games_teams_compare AS
SELECT DISTINCT 
	  bmd.tournament_id
	, bmd.slug
	, bmd.gameid
	, bmd.blueside
	, bmd.redside
	, gsu14.teamid AS teamid
	, gsu14.sequenceindex AS sequenceindex
    -- stats at 14 minutes
	, gsu14.winningteam as winningteam
    , gsu14.team_assists AS team_assists_14
	, gsu14.team_champions_kills AS team_champion_kills_14
	, gsu14.team_deaths AS team_deaths_14
	, gsu14.team_dragon_kills AS team_dragon_kills_14
	, gsu14.team_inhib_kills AS team_inhib_kills_14
	, gsu14.team_total_gold AS team_total_gold_14
	, gsu14.team_tower_kills AS team_tower_kills_14
    , gsu14.team_xp_sum AS team_xp_sum_14
    , gsu14.team_level_sum AS team_level_sum_14
    , gsu14.team_level_average AS team_level_average_14
    , gsu14.team_minions_sum AS team_minions_sum_14
    , gsu14.team_neutral_minions_sum AS team_neutral_minions_sum_14
    , gsu14.team_neutral_minions_your_jungle_sum AS team_neutral_minions_your_jungle_sum_14
    , gsu14.team_neutral_minions_enemy_jungle_sum AS team_neutral_minions_enemy_jungle_sum_14
    , gsu14.team_wards_placed_sum AS team_wards_placed_sum_14
    , gsu14.team_wards_killed_sum AS team_wards_killed_sum_14
    , gsu14.team_vision_score_sum AS team_vision_score_sum_14
	, gsu_enemy14.team_assists AS enemy_team_assists_14
	, gsu_enemy14.team_champions_kills AS enemy_team_champions_kills_14
	, gsu_enemy14.team_deaths AS enemy_team_deaths_14
	, gsu_enemy14.team_dragon_kills AS enemy_team_dragon_kills_14
	, gsu_enemy14.team_inhib_kills AS enemy_team_inhib_kills_14
	, gsu_enemy14.team_total_gold AS enemy_team_total_gold_14
	, gsu_enemy14.team_tower_kills as enemy_team_tower_kills_14
    , gsu_enemy14.team_xp_sum AS enemy_team_xp_sum_14
    , gsu_enemy14.team_level_sum AS enemy_team_level_sum_14
    , gsu_enemy14.team_level_average AS enemy_team_level_average_14
    , gsu_enemy14.team_minions_sum AS enemy_team_minions_sum_14
    , gsu_enemy14.team_neutral_minions_sum AS enemy_team_neutral_minions_sum_14
    , gsu_enemy14.team_neutral_minions_your_jungle_sum AS enemy_team_neutral_minions_your_jungle_sum_14
    , gsu_enemy14.team_neutral_minions_enemy_jungle_sum AS enemy_team_neutral_minions_enemy_jungle_sum_14
    , gsu_enemy14.team_wards_placed_sum AS enemy_team_wards_placed_sum_14
    , gsu_enemy14.team_wards_killed_sum AS enemy_team_wards_killed_sum_14
    , gsu_enemy14.team_vision_score_sum AS enemy_team_vision_score_sum_14
    -- end game stats
    , gsu_end.sequenceindex AS end_seq_index
    , gsu_end.team_assists AS team_assists_end
	, gsu_end.team_baron_kills AS team_baron_kills_end
	, gsu_end.team_champions_kills AS team_champion_kills_end
	, gsu_end.team_deaths AS team_deaths_end
	, gsu_end.team_dragon_kills AS team_dragon_kills_end
	, gsu_end.team_inhib_kills AS team_inhib_kills_end
	, gsu_end.team_total_gold AS team_total_gold_end
	, gsu_end.team_tower_kills AS team_tower_kills_end
    , gsu_end.team_xp_sum AS team_xp_sum_end
    , gsu_end.team_level_sum AS team_level_sum_end
    , gsu_end.team_level_average AS team_level_average_end
    , gsu_end.team_minions_sum AS team_minions_sum_end
    , gsu_end.team_neutral_minions_sum AS team_neutral_minions_sum_end
    , gsu_end.team_neutral_minions_your_jungle_sum AS team_neutral_minions_your_jungle_sum_end
    , gsu_end.team_neutral_minions_enemy_jungle_sum AS team_neutral_minions_enemy_jungle_sum_end
    , gsu_end.team_wards_placed_sum AS team_wards_placed_sum_end
    , gsu_end.team_wards_killed_sum AS team_wards_killed_sum_end
    , gsu_end.team_vision_score_sum AS team_vision_score_sum_end
    , gsu_end.team_rift_count AS team_rift_count
    , gsu_end.team_elder_count AS team_elder_count
	, gsu_enemy_end.team_assists AS enemy_team_assists_end
	, gsu_enemy_end.team_baron_kills AS enemy_team_baron_kills_end
	, gsu_enemy_end.team_champions_kills AS enemy_team_champions_kills_end
	, gsu_enemy_end.team_deaths AS enemy_team_deaths_end
	, gsu_enemy_end.team_dragon_kills AS enemy_team_dragon_kills_end
	, gsu_enemy_end.team_inhib_kills AS enemy_team_inhib_kills_end
	, gsu_enemy_end.team_total_gold AS enemy_team_total_gold_end
	, gsu_enemy_end.team_tower_kills as enemy_team_tower_kills_end
    , gsu_enemy_end.team_xp_sum AS enemy_team_xp_sum_end
    , gsu_enemy_end.team_level_sum AS enemy_team_level_sum_end
    , gsu_enemy_end.team_level_average AS enemy_team_level_average_end
    , gsu_enemy_end.team_minions_sum AS enemy_team_minions_sum_end
    , gsu_enemy_end.team_neutral_minions_sum AS enemy_team_neutral_minions_sum_end
    , gsu_enemy_end.team_neutral_minions_your_jungle_sum AS enemy_team_neutral_minions_your_jungle_sum_end
    , gsu_enemy_end.team_neutral_minions_enemy_jungle_sum AS enemy_team_neutral_minions_enemy_jungle_sum_end
    , gsu_enemy_end.team_wards_placed_sum AS enemy_team_wards_placed_sum_end
    , gsu_enemy_end.team_wards_killed_sum AS enemy_team_wards_killed_sum_end
    , gsu_enemy_end.team_vision_score_sum AS enemy_team_vision_score_sum_end
    , gsu_enemy_end.team_rift_count AS enemy_team_rift_count_end
    , gsu_enemy_end.team_elder_count AS enemy_team_elder_count_end
FROM lol.better_mapping_data bmd
INNER JOIN games_stats_update gsu14
ON gsu14.platformgameid = bmd.platformgameid
INNER JOIN games_stats_update gsu_enemy14
ON 
        gsu_enemy14.platformgameid = bmd.platformgameid 
    AND gsu_enemy14.sequenceindex = gsu14.sequenceindex 
    AND gsu_enemy14.teamid != gsu14.teamid 
INNER JOIN games_stats_update gsu_end
ON 
        gsu_end.platformgameid = bmd.platformgameid 
    AND gsu_end.sequenceindex > gsu14.sequenceindex 
    AND gsu_end.teamid = gsu14.teamid
INNER JOIN games_stats_update gsu_enemy_end
ON 
        gsu_enemy_end.platformgameid = bmd.platformgameid 
    AND gsu_enemy_end.sequenceindex > gsu14.sequenceindex 
    AND gsu_enemy_end.teamid != gsu14.teamid 
WHERE 
    (gsu14.gametime < 841000) AND
    (gsu_enemy14.gametime < 841000) 
    AND (gsu_end.gametime > 841000) 
    AND (gsu_enemy_end.gametime > 841000);

/* Query 8 */
CREATE TABLE team_data_final AS
SELECT  
	gtc.tournament_id 
	, gtc.slug 
	, gtc.gameid 
	--gat.tournament_slug 
	, bmd.name 
	, gtc.blueside, tb.name AS blueteam, gtc.redside, tr.name AS redTeamName, gtc.teamid, gtc.winningteam
	,  (team_total_gold_14 - enemy_team_total_gold_14) AS gold_Diff_14
	, (team_total_gold_end - enemy_team_total_gold_end) AS gold_diff_end
	, (team_tower_kills_end) AS towers_end
	--, (team_tower_kills_end - enemy_team_tower_kills_end) AS tower_diff_end
	, (team_baron_kills_end) AS baron_end
	--, (team_baron_kills_end - enemy_team_baron_kills_end) AS baron_diff_end
	, (team_dragon_kills_end) AS dragon_end
	--, (team_dragon_kills_end - enemy_team_dragon_kills_end) AS dragon_diff_end
	, (team_rift_count) AS rift_end 
	, ((team_vision_score_sum_end - enemy_team_vision_score_sum_end)/100) AS vision_score_diff_end
FROM games_teams_compare gtc 
INNER JOIN better_mapping_data bmd 
ON gtc.tournament_id = bmd.tournament_id AND gtc.gameid = bmd.gameid 
INNER JOIN teams tb
on gtc.blueside = tb.team_id
INNER JOIN teams tr
on gtc.redside = tr.team_id