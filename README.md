# Hackathon 2023: Duffy4Commish

The folowing steps will hopefully get the project downloaded and installed testing locally. Feel free to skip steps if you already have them installed.

0. Download and install this git repro
    - Probably can download Zip from online
    - download git, install that way
        - https://desktop.github.com/

# Download Public Data

0. Download and install Python 3
    - I already have it installed, so reach out if you are having trouble
    - https://www.python.org/downloads/
1. Run the python file "downloadAllRiotData.py" in the folder "DownloadRiotData"
    - I am able to run in Visual Studio Code by
        1. opening the Duffy4Commish folder
        2. select the python file
        3. select [run] in the taskbar at the nav bar then [start without debugging]
            - [ctrl][f5]
        4. if you get a dropdown "select a dubug configuration"
            - select "Python File"
2. after a few minutes you should have ~60 gb of files in a esports-data folder
    - that folder should be in the project's root directory, not in the DownloadRiotData folder

# Set up Docker

1. Download and install Docker: https://www.docker.com/products/docker-desktop/
    - You will also need to install docker command line/terminal tools unsure if it will be installed with above
2. open up command prompt/terminal, Navigate to directory where this folder is in
    - Command Prompt(windows)/Terminal (mac/linux) commands
        - dir / ls -> show all files and folders in the current folder that you are in
        - cd .. -> change Directory by moving backwards up the folder structure
        - cd Duffy4Commish -> change directory by moving fowards into the folder names "Duffy4Commish"
3. run command: docker-compose up
    - you should see many logs being processed
    - after running this command, in Docker Desktop you should see duffy4commish as a container
    - if you wish to run docker in the background add a "-d" on the end to run it detached
        - docker-compose up -d
    - to shut down the docker container, 
        - in terminal press [ctrl][c]
        - in docker container press the stop button for duffy4commish, and it will shut down all the containers

# load data 

1. connect to hive-server
    - docker exec -it hive-server /bin/bash
    - open Docker, containers
        1. find the hive-server container
        2. click the 3 vertical dots
        3. click [Open in Terminal]
        4. enter command "bash" 
2. run following command to move json serde with dependancy files to proper install location
    - cp /hive-lib/json-serde-1.3.8-jar-with-dependencies.jar /opt/hive/lib/
3. run following commands to create sql tables
    - cd /sql
    - hive -f leagues.hql
    - hive -f players.hql
    - hive -f teams.hql
    - hive -f tournaments.hql
    - hive -f mapping-data.hql
    - hive -f games.hql
4. load data (warning 1: if file fails to find a folder or directory ping me; 2 the last command may take 20 minutes)
    - cd /esportsSql
    - hadoop fs -mkdir /esports-sql
    - hadoop fs -put leagues.json hdfs://namenode:8020/esports-sql/leagues.json
    - hadoop fs -put players.json hdfs://namenode:8020/esports-sql/players.json
    - hadoop fs -put teams.json hdfs://namenode:8020/esports-sql/teams.json
    - hadoop fs -put tournaments.json hdfs://namenode:8020/esports-sql/tournaments.json
    - hadoop fs -put mapping-data.json hdfs://namenode:8020/esports-sql/mapping-data.json
    - hadoop fs -mkdir /esports-data
    - hadoop fs -put /esportsData/* hdfs://namenode:8020/esports-data/
        - Or ^possibly faster but copies file need 2x space // V slower, but doesn't need extra storage
        - hadoop fs -moveFromLocal /esportsData/* hdfs://namenode:8020/esports-data/

# Connect to Database

0. attempt at visualizing data mapping https://dbdiagram.io/d/650d1dc4ffbf5169f0481c88
1. type: hive
2. commands:
    - show databases;
    - use [database];
        - use lol;
    - show tables;
    - desc [table];
        - desc games;
3. get query from "Queries.sql" file

# Build Data: SQL Queries
In order to access the Hive Database, I found it easiest to use DBeaver. It gives a better graphical user experiance than the command line.
https://dbeaver.io/download/

you many need to select the lol database.
```sql
use lol;
```

### Create Game and Team
```sql
create table game_and_team AS
SELECT 
    t.id AS Tournament_Id, 
    t.slug AS Tournament_Slug, 
    et.name[0] AS name, 
    et3.id AS Game_Ids, 
    et3.teams[0].id[0] AS blue, 
    et3.teams[0].id[1] AS red
FROM tournaments t
LATERAL VIEW explode(stages.sections) exploaded_table AS et
LATERAL VIEW explode(et.matches) exptab2 AS et2
LATERAL VIEW explode(et2.games) exptab3 AS et3
```

### Filter out Mapping Data and combine with tournament for a better query experiance
If you would like to filter more, you can uncomment the WHERE clause and filter even more for just the teams and regions
```sql
create table better_mapping_data AS 
SELECT gids.tid AS Tournament_Id, gids.tslug AS slug, gids.name, gids.gameid AS gameid, md.platformgameid AS platformgameid, gids.blueside, gids.redside FROM (
	SELECT t.tournament_id as tid, t.tournament_slug as tslug, t.name, et AS GameID, t.blue AS blueside, t.red AS redside FROM game_and_team t 
	LATERAL VIEW explode(t.game_ids) exploaded_table AS et
	/* WHERE t.tournament_slug like "%2023" AND t.tournament_slug like "lcs_s%" */) AS gIds
INNER JOIN mapping_data md 
ON md.esportsgameid = gIds.GameID;
```
### Filter Games table
This will take a long time to run dependent upon how much data you included. Can take over 30 minutes.
```sql
/* query 3 - took 33 minutes*/
create table games_filtered AS
SELECT * from games g 
WHERE g.gameover = true 
	OR eventtype = 'game_info'
    OR eventtype = 'game_end'
	OR (eventtype = 'epic_monster_kill' and (monstertype = 'dragon' or monstertype = 'baron' or monstertype = 'riftHerald')) 
	OR (eventtype = 'stats_update' and gametime >= 840000 and gametime <841000);
```
### Focus on Team and Player stats for each entry
```sql
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
```

### focus on team stats
```sql
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
```

### fixed stats used for building ranking system
```sql
create table stats AS
SELECT 
	mgeg.median_gold_end_game, mg14.median_gold_14_mins, med.median_gold_diff_winner_end_game, med.median_gold_diff_winner_14, b.median_baron_per_game, d.median_dragons, g.max_gold, v.max_vision_score, m.playoff_multiplier, m.international_multiplier, m.win_multiplier, m.loss_multiplier, m.win_bonus, m.loss_bonus
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
		SELECT 1 as id, '1.15' AS playoff_multiplier, '1.3' AS international_multiplier, '1.2' AS win_multiplier, '.8' AS loss_multiplier, '.2' AS win_bonus, '-.2' AS loss_bonus
	) m
on mgeg.id = m.id
INNER JOIN (
		select 1 AS id, percentile(cast(gold_diff_end as BIGINT), 0.5) AS median_gold_diff_winner_end_game, percentile(cast(gold_diff_14 as BIGINT), 0.5) AS median_gold_diff_winner_14
		from team_data_final tdf -- 60733.0
		WHERE winningteam = teamid
	) med
ON mgeg.id = med.id
INNER JOIN (
SELECT 1 AS id,
	(t.gold_diff_14 / s.median14) + (t.gold_diff_end / s.median_end) AS max_gold
from (
select 1 AS id, gold_diff_end, gold_diff_14
		from team_data_final
) t
INNER JOIN (
		select 1 AS id, percentile(cast(gold_diff_end as BIGINT), 0.5) AS median_end, percentile(cast(gold_diff_14 as BIGINT), 0.5) AS median14
		from team_data_final tdf -- 60733.0
		WHERE winningteam = teamid
) s
ON s.id = t.id
ORDER BY max_gold DESC
LIMIT 1
) g
ON mgeg.id = g.id
INNER JOIN (
select 1 AS id, MAX(vision_score_diff_end) AS max_vision_score
		from team_data_final
) v
ON mgeg.id = v.id;
```

### Compare teams vs their opponent
```sql
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
```

### SELECT only the values we decided to use
```sql
CREATE TABLE team_data_final AS
SELECT  
	gtc.tournament_id 
	, gtc.slug 
	, gtc.gameid 
	, bmd.name 
	, gtc.blueside, tb.name AS blueteam, gtc.redside, tr.name AS redTeamName, gtc.teamid, gtc.winningteam
	,  (team_total_gold_14 - enemy_team_total_gold_14) AS gold_Diff_14
	, (team_total_gold_end - enemy_team_total_gold_end) AS gold_diff_end
	, (team_tower_kills_end) AS towers_end
	, (team_baron_kills_end) AS baron_end
	, (team_dragon_kills_end) AS dragon_end
	, (team_rift_count) AS rift_end 
	, ((team_vision_score_sum_end - enemy_team_vision_score_sum_end)/100) AS vision_score_diff_end
FROM games_teams_compare gtc 
INNER JOIN better_mapping_data bmd 
ON gtc.tournament_id = bmd.tournament_id AND gtc.gameid = bmd.gameid 
INNER JOIN teams tb
on gtc.blueside = tb.team_id
INNER JOIN teams tr
on gtc.redside = tr.team_id
```

# Compile Data for use in the website.
Due to time restraints, I was unable to automatically pull in data from the database into the Nuxt 3 front end webiste. Instead they have to be manually updated. The files that need to be updated are 
- /composables/gameStats.js
- /composables/teamData.js
- /composables/tournamentData.js
- /composables/tournaments.js

In DBeaver, you are able to run SQL queries and export them by: 
- clicking the [Export data] button at the bottom of the screen
- Export Target:
    - select JSON files
- Extraction Settings
    - Single query
    - fetch size 300000
        - Or any number larger than the largest query count
- Format settings
    - no change
- Output
    - Select Copy to Clipboard
- Confirm
    - no change
After you have the query copied over, you must manually format the result to match the format. I suggest using the find and replace tool in order to remove the quotes especially for the tournamentData.js file.

### gameStats.js
```sql
SELECT * FROM stats s;
```
### teamData.js
```sql
SELECT DISTINCT blueside AS id, blueteam AS name FROM team_data_final tdf;
```

### tournamentData.js
```sql
SELECT DISTINCT * FROM team_data_final tdf;
```

### tournaments.js
```sql
SELECT DISTINCT tournament_id AS id, slug FROM team_data_final tdf;
```
