-- 4. Technical Operators
SELECT 
    operator_id, 
    badge_id, 
    first_name, 
    last_name, 
    team_name, 
    role
FROM operator
WHERE role = 'TECH';