-- gearworks_lite_data.sql
-- Synthetic but realistic hackathon dataset for gearworks_lite

SET search_path TO gearworks_lite;
SELECT setseed(0.42);

-- -----------------
-- Master data
-- -----------------
INSERT INTO production_line(site_name, line_name, description) VALUES
 ('PortoPlant', 'Line-01', 'Hobbing + Grinding'),
 ('PortoPlant', 'Line-02', 'Heat treatment'),
 ('StuttgartPlant', 'Line-01', 'High precision grinding');

-- 12 machines across lines
INSERT INTO machine(line_id, asset_tag, machine_type, commissioning_date, active)
SELECT pl.line_id,
       'M-' || pl.site_name || '-' || pl.line_name || '-' || lpad(gs::text, 2, '0') AS asset_tag,
       CASE WHEN pl.line_name = 'Line-02' THEN 'HEAT_TREAT'
            WHEN gs % 2 = 0 THEN 'GRINDER'
            ELSE 'HOBBER'
       END AS machine_type,
       DATE '2021-01-01' + (gs * 7) AS commissioning_date,
       TRUE
FROM production_line pl
CROSS JOIN generate_series(1,4) gs;

-- 24 people (operators + inspectors)
INSERT INTO operator(badge_id, first_name, last_name, team_name, role)
SELECT 'B' || lpad(gs::text, 4, '0') AS badge_id,
       'Op' || gs AS first_name,
       'User' || gs AS last_name,
       CASE WHEN gs <= 8 THEN 'Team-A'
            WHEN gs <= 16 THEN 'Team-B'
            ELSE 'Quality'
       END AS team_name,
       CASE WHEN gs > 18 THEN 'INSPECTOR'
            WHEN gs % 10 = 0 THEN 'TECH'
            ELSE 'OPERATOR'
       END AS role
FROM generate_series(1,24) gs;

-- Products (6 products × 2 versions = 12 rows)
INSERT INTO product(product_code, version_code, gear_family, module_mm, pressure_angle_deg, ideal_cycle_time_s)
SELECT 'EVG-' || lpad(p::text, 2, '0') AS product_code,
       v AS version_code,
       CASE WHEN p % 2 = 0 THEN 'helical' ELSE 'spur' END AS gear_family,
       (1.25 + 0.15*p)::numeric(6,3) AS module_mm,
       20.00::numeric(5,2) AS pressure_angle_deg,
       (18 + (p*2) + CASE WHEN v='B' THEN 1 ELSE 0 END)::numeric(10,3) AS ideal_cycle_time_s
FROM generate_series(1,6) p
CROSS JOIN (VALUES ('A'),('B')) vv(v);

-- Defect types (lookup)
INSERT INTO defect_type(code, description, severity_level) VALUES
 ('PIT', 'Pitting on tooth flank', 4),
 ('BURR', 'Burr after hobbing', 2),
 ('OUT_TOL', 'Out of tolerance measurement', 5),
 ('SCRATCH', 'Surface scratch', 2),
 ('HEAT_DIS', 'Heat discoloration', 3);

-- -----------------
-- Work orders (60)
-- -----------------
WITH prod AS (
  SELECT product_id, row_number() OVER (ORDER BY product_id) AS rn
  FROM product
),
nums AS (SELECT generate_series(1,60) AS i)
INSERT INTO work_order(product_id, planned_qty, start_ts, due_ts, status)
SELECT p.product_id,
       (200 + (i % 7)*25) AS planned_qty,
       timestamptz '2026-03-01 06:00+00' + (i * interval '2 hours') AS start_ts,
       timestamptz '2026-03-03 18:00+00' + (i * interval '2 hours') AS due_ts,
       CASE WHEN i % 5 = 0 THEN 'DONE'
            WHEN i % 3 = 0 THEN 'RELEASED'
            ELSE 'PLANNED'
       END AS status
FROM nums
JOIN prod p ON p.rn = ((i - 1) % (SELECT count(*) FROM prod)) + 1;

-- -----------------
-- Production runs (300)
-- -----------------
WITH wo AS (
  SELECT work_order_id, row_number() OVER (ORDER BY work_order_id) AS rn FROM work_order
),
m AS (
  SELECT machine_id, row_number() OVER (ORDER BY machine_id) AS rn FROM machine
),
op AS (
  SELECT operator_id, row_number() OVER (ORDER BY operator_id) AS rn
  FROM operator WHERE role IN ('OPERATOR','TECH')
),
nums AS (SELECT generate_series(1,300) AS i)
INSERT INTO production_run(
  work_order_id, machine_id, operator_id,
  shift_code, shift_start_ts, shift_end_ts,
  start_ts, end_ts,
  produced_qty, scrap_qty
)
SELECT wo.work_order_id,
       m.machine_id,
       op.operator_id,
       CASE WHEN (i % 3) = 1 THEN 'A'
            WHEN (i % 3) = 2 THEN 'B'
            ELSE 'C'
       END AS shift_code,
       -- Shift windows (simplified)
       date_trunc('day', base_ts) + CASE WHEN (i % 3)=1 THEN interval '06:00'
                                         WHEN (i % 3)=2 THEN interval '14:00'
                                         ELSE interval '22:00'
                                    END AS shift_start_ts,
       date_trunc('day', base_ts) + CASE WHEN (i % 3)=1 THEN interval '14:00'
                                         WHEN (i % 3)=2 THEN interval '22:00'
                                         ELSE interval '30:00'  -- next day 06:00
                                    END AS shift_end_ts,
       base_ts AS start_ts,
       base_ts + (interval '25 minutes' + (i % 6)*interval '10 minutes') AS end_ts,
       (80 + (i % 9)*10) AS produced_qty,
       (i % 7) AS scrap_qty
FROM nums
CROSS JOIN LATERAL (
  SELECT timestamptz '2026-03-01 06:10+00' + (i * interval '20 minutes') AS base_ts
) t
JOIN wo ON wo.rn = ((i - 1) % (SELECT count(*) FROM wo)) + 1
JOIN m  ON m.rn  = ((i - 1) % (SELECT count(*) FROM m)) + 1
JOIN op ON op.rn = ((i - 1) % (SELECT count(*) FROM op)) + 1;

-- -----------------
-- Inspections (one per run)
-- -----------------
WITH r AS (
  SELECT run_id, start_ts, end_ts, operator_id,
         row_number() OVER (ORDER BY run_id) AS rn
  FROM production_run
),
ins AS (
  SELECT operator_id, row_number() OVER (ORDER BY operator_id) AS rn
  FROM operator WHERE role='INSPECTOR'
)
INSERT INTO inspection_event(run_id, inspected_ts, inspector_id, inspection_type, sample_size, result)
SELECT r.run_id,
       r.end_ts + interval '10 minutes' AS inspected_ts,
       ins.operator_id,
       CASE WHEN r.rn % 4 = 0 THEN 'FINAL' ELSE 'IN_PROCESS' END AS inspection_type,
       10 + (r.rn % 10) AS sample_size,
       CASE WHEN r.rn % 9 = 0 THEN 'FAIL' ELSE 'PASS' END AS result
FROM r
JOIN ins ON ins.rn = ((r.rn - 1) % (SELECT count(*) FROM ins)) + 1;

-- -----------------
-- Defects (about ~30% of inspections get defects)
-- -----------------
WITH ie AS (
  SELECT inspection_id, row_number() OVER (ORDER BY inspection_id) AS rn
  FROM inspection_event
),
dt AS (
  SELECT defect_type_id, row_number() OVER (ORDER BY defect_type_id) AS rn
  FROM defect_type
)
INSERT INTO defect(inspection_id, defect_type_id, quantity, notes)
SELECT ie.inspection_id,
       dt.defect_type_id,
       1 + (ie.rn % 4) AS quantity,
       NULL::text
FROM ie
JOIN dt ON dt.rn = ((ie.rn - 1) % (SELECT count(*) FROM dt)) + 1
WHERE ie.rn % 3 = 0;

-- -----------------
-- Machine state logs (20-minute sampling, 7 days)
-- -----------------
INSERT INTO machine_state_log(machine_id, ts, state_code, reason)
SELECT m.machine_id,
       t.ts,
       CASE
         WHEN random() < 0.70 THEN 'RUN'
         WHEN random() < 0.82 THEN 'IDLE'
         WHEN random() < 0.92 THEN 'SETUP'
         WHEN random() < 0.97 THEN 'DOWN'
         ELSE 'MAINT'
       END AS state_code,
       NULL::text
FROM machine m
CROSS JOIN LATERAL (
  SELECT generate_series(
    timestamptz '2026-03-01 06:00+00',
    timestamptz '2026-03-07 22:00+00',
    interval '20 minutes'
  ) AS ts
) t;

-- -----------------
-- Machine telemetry (5-minute sampling, 3 sensors, 7 days)
-- -----------------
INSERT INTO machine_telemetry(machine_id, ts, sensor_code, value, unit)
SELECT m.machine_id,
       t.ts,
       s.sensor_code,
       CASE s.sensor_code
         WHEN 'TEMP_SPINDLE' THEN 35 + 10*random()
         WHEN 'VIB_RMS'      THEN 0.8 + 0.6*random()
         WHEN 'POWER_KW'     THEN 4 + 3*random()
       END AS value,
       CASE s.sensor_code
         WHEN 'TEMP_SPINDLE' THEN 'C'
         WHEN 'VIB_RMS'      THEN 'mm/s'
         WHEN 'POWER_KW'     THEN 'kW'
       END AS unit
FROM machine m
CROSS JOIN LATERAL (
  SELECT generate_series(
    timestamptz '2026-03-01 06:00+00',
    timestamptz '2026-03-07 22:00+00',
    interval '5 minutes'
  ) AS ts
) t
CROSS JOIN (VALUES ('TEMP_SPINDLE'), ('VIB_RMS'), ('POWER_KW')) s(sensor_code);