SELECT l.id, l.name, l.slug, t.name, t.id FROM leagues l 
INNER JOIN tournaments t on t.leagueid = l.id WHERE l.slug = "lcs";

SELECT * FROM teams WHERE slug = "cloud9";