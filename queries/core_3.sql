SELECT 
    first_name || ' ' || last_name AS inspector_name,
    inspection_id,
    inspected_ts,
    result
FROM inspection_event
JOIN operator ON inspector_id = operator_id
WHERE team_name = 'Quality';