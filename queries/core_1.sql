-- 1. Operators Outside Quality Team

SELECT 
    o.operator_id, 
    o.full_name, 
    t.team_name
FROM 
    operator o
JOIN 
    team t ON o.team_id = t.team_id
WHERE 
    t.team_name != 'Quality';