-- 25. Top 5 Defect Types

SET search_path TO gearworks_lite;

SELECT 
    dt.code, 
    dt.description, 
    COUNT(d.defect_id) AS occurrence_frequency,
    SUM(d.quantity) AS total_pieces_defective
FROM defect d
JOIN defect_type dt ON d.defect_type_id = dt.defect_type_id
GROUP BY dt.code, dt.description
ORDER BY occurrence_frequency DESC
LIMIT 5;