SELECT l.id, l.name, l.slug, t.name, t.id FROM leagues l 
INNER JOIN tournaments t on t.leagueid = l.id WHERE l.slug = "lcs" LIMIT 1;

SELECT * FROM teams WHERE slug = "cloud9";

/* Gets teams total gold*/
SELECT eventtime, eventtype, platformgameid, teams.totalgold, gametime
FROM games 
WHERE eventtype = "stats_update" 
LIMIT 10;

/* Gets teams total gold at a specific time (14 minutes= 840 seconds=840000ms*/
SELECT eventtime, eventtype, platformgameid, teams.totalgold, gametime
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
/* Creates new table with way less info for tournaments */
create table tournSmall AS
SELECT t.id AS Tournament_Id, t.slug AS Tournament_Slug, et.name AS Match_Name, et2.id AS Matches_Ids, et3.id AS Game_Ids
FROM tournaments t 
LATERAL VIEW explode(stages.sections) exploaded_table AS et
LATERAL VIEW explode(et.matches) exptab2 AS et2
LATERAL VIEW explode(et2.games) exptab3 AS et3