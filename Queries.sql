SELECT l.id, l.name, l.slug, t.name 
FROM leagues l 
INNER JOIN tournaments t 
on t.leagueid = l.id 
WHERE l.slug = "lcs";