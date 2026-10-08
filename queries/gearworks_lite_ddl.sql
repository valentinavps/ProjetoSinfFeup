-- gearworks_lite_ddl.sql
-- Reduced-complexity GearWorks schema for educational use in SQL  hackathons

CREATE SCHEMA IF NOT EXISTS gearworks_lite;
SET search_path TO gearworks_lite;

-- 1) Facility
CREATE TABLE production_line (
  line_id      INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  site_name    TEXT NOT NULL,
  line_name    TEXT NOT NULL,
  description  TEXT,
  UNIQUE(site_name, line_name)
);

-- 2) Machinery
CREATE TABLE machine (
  machine_id          INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  line_id             INT NOT NULL REFERENCES production_line(line_id),
  asset_tag           TEXT NOT NULL UNIQUE,
  machine_type        TEXT NOT NULL,            -- HOBBER, GRINDER, HEAT_TREAT
  commissioning_date  DATE,
  active              BOOLEAN NOT NULL DEFAULT TRUE
);

-- 3) People
CREATE TABLE operator (
  operator_id  INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  badge_id     TEXT NOT NULL UNIQUE,
  first_name   TEXT NOT NULL,
  last_name    TEXT NOT NULL,
  team_name    TEXT NOT NULL,
  role         TEXT NOT NULL                  -- OPERATOR, INSPECTOR, TECH
);

-- 4) Products (type+version collapsed)
CREATE TABLE product (
  product_id           INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  product_code         TEXT NOT NULL,
  version_code         TEXT NOT NULL,
  gear_family          TEXT NOT NULL,
  module_mm            NUMERIC(6,3) NOT NULL,
  pressure_angle_deg   NUMERIC(5,2) NOT NULL,
  ideal_cycle_time_s   NUMERIC(10,3) NOT NULL,
  UNIQUE(product_code, version_code)
);

-- 5) Orders
CREATE TABLE work_order (
  work_order_id  INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  product_id     INT NOT NULL REFERENCES product(product_id),
  planned_qty    INT NOT NULL CHECK (planned_qty > 0),
  start_ts       TIMESTAMPTZ NOT NULL,
  due_ts         TIMESTAMPTZ NOT NULL,
  status         TEXT NOT NULL CHECK (status IN ('PLANNED','RELEASED','DONE')),
  CHECK (due_ts > start_ts)
);

-- 6) Production runs (shift embedded here)
CREATE TABLE production_run (
  run_id         INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  work_order_id  INT NOT NULL REFERENCES work_order(work_order_id),
  machine_id     INT NOT NULL REFERENCES machine(machine_id),
  operator_id    INT NOT NULL REFERENCES operator(operator_id),
  shift_code     TEXT NOT NULL CHECK (shift_code IN ('A','B','C')),
  shift_start_ts TIMESTAMPTZ NOT NULL,
  shift_end_ts   TIMESTAMPTZ NOT NULL,
  start_ts       TIMESTAMPTZ NOT NULL,
  end_ts         TIMESTAMPTZ NOT NULL,
  produced_qty   INT NOT NULL CHECK (produced_qty >= 0),
  scrap_qty      INT NOT NULL CHECK (scrap_qty >= 0),
  CHECK (shift_end_ts > shift_start_ts),
  CHECK (end_ts > start_ts),
  CHECK (produced_qty >= scrap_qty)
);

-- 7) Machine state log (event/time-series)
CREATE TABLE machine_state_log (
  machine_id  INT NOT NULL REFERENCES machine(machine_id),
  ts          TIMESTAMPTZ NOT NULL,
  state_code  TEXT NOT NULL CHECK (state_code IN ('RUN','DOWN','IDLE','SETUP','MAINT')),
  reason      TEXT,
  PRIMARY KEY(machine_id, ts)
);

-- 8) Machine telemetry (sensor time-series)
CREATE TABLE machine_telemetry (
  machine_id   INT NOT NULL REFERENCES machine(machine_id),
  ts           TIMESTAMPTZ NOT NULL,
  sensor_code  TEXT NOT NULL CHECK (sensor_code IN ('TEMP_SPINDLE','VIB_RMS','POWER_KW')),
  value        NUMERIC(12,4) NOT NULL,
  unit         TEXT NOT NULL,
  PRIMARY KEY(machine_id, ts, sensor_code)
);

-- 9) Inspection events
CREATE TABLE inspection_event (
  inspection_id   INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  run_id          INT NOT NULL REFERENCES production_run(run_id),
  inspected_ts    TIMESTAMPTZ NOT NULL,
  inspector_id    INT NOT NULL REFERENCES operator(operator_id),
  inspection_type TEXT NOT NULL CHECK (inspection_type IN ('IN_PROCESS','FINAL')),
  sample_size     INT NOT NULL CHECK (sample_size > 0),
  result          TEXT NOT NULL CHECK (result IN ('PASS','FAIL'))
);

-- 10) Defect taxonomy
CREATE TABLE defect_type (
  defect_type_id  INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  code            TEXT NOT NULL UNIQUE,
  description     TEXT NOT NULL,
  severity_level  INT NOT NULL CHECK (severity_level BETWEEN 1 AND 5)
);

-- 11) Defects
CREATE TABLE defect (
  defect_id       INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  inspection_id   INT NOT NULL REFERENCES inspection_event(inspection_id),
  defect_type_id  INT NOT NULL REFERENCES defect_type(defect_type_id),
  quantity        INT NOT NULL CHECK (quantity > 0),
  notes           TEXT
);

-- Indexes for query performance (time-based + joins)
CREATE INDEX ix_run_machine_time ON production_run(machine_id, start_ts, end_ts);
CREATE INDEX ix_state_machine_time ON machine_state_log(machine_id, ts);
CREATE INDEX ix_telemetry_time_brin ON machine_telemetry USING BRIN(ts);
CREATE INDEX ix_defect_type ON defect(defect_type_id);
