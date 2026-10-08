-- 16. Machine Catalogue (No IDs)

SELECT
m.machine_type, 
m.asset_tag, 
pl.line_name,
pl.site_name
FROM machine m
JOIN production_line pl ON m.line_id = pl.line_id;

