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