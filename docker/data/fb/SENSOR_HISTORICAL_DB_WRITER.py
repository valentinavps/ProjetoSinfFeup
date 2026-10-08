from datetime import datetime
import psycopg2


class SENSOR_HISTORICAL_DB_WRITER:

    def __init__(self):
        self.conn = None
        self.cursor = None

    def schedule(
        self,
        event_name=None,
        event_value=None,
        data=None,
        base_sensor_id=None,
        host=None,
        port=None,
        user=None,
        password=None,
        dbname=None,
        schema=None,
        table=None,
    ):

        # Always return correct structure:
        # [EVENT, OUT1..OUT8, STATE, RESULT]
        def empty(state="IDLE", result="SKIP"):
            return ["READ_O"] + [""] * 8 + [state, result]

        # Only process READ event
        if event_name != "READ":
            return empty("IDLE", "SKIP")

        try:
            # Safe parsing (4diac sends strings)
            base_sensor_id = int(base_sensor_id) if base_sensor_id else 0

            host = str(host) if host else "localhost"
            port = int(port) if port else 5432
            user = str(user) if user else "postgres"
            password = str(password) if password else ""
            dbname = str(dbname) if dbname else "postgres"
            schema = str(schema) if schema else "public"
            table = str(table) if table else "historical_production"

            # Lazy DB connect
            if self.conn is None:
                self.conn = psycopg2.connect(
                    dbname=dbname,
                    user=user,
                    password=password,
                    host=host,
                    port=port,
                )
                self.cursor = self.conn.cursor()

            # No data
            if not data or len(data.strip()) == 0:
                return empty("IDLE", "EMPTY")

            values = data.split(",")

            # Exactly 8 outputs (fixed size!)
            outputs = [""] * 8

            # Set schema
            self.cursor.execute(f'SET search_path TO "{schema}";')

            now = datetime.now()
            inserted = 0

            # Insert each value
            for i in range(min(8, len(values))):
                raw = values[i].strip()

                try:
                    v = float(raw)
                except:
                    continue  # skip invalid value

                sensor_id = base_sensor_id + i

                # Output format: "sensor_id,value"
                outputs[i] = f"{sensor_id},{v}"

                # DB insert
                self.cursor.execute(
                    f"""
                    INSERT INTO {table}
                    (date, value, label, sensor_id)
                    VALUES (%s, %s, %s, %s)
                    """,
                    (now, v, None, sensor_id)
                )

                inserted += 1

            self.conn.commit()

            return ["READ_O"] + outputs + ["WORK", f"OK:{inserted}"]

        except Exception as e:
            if self.conn:
                self.conn.rollback()

            return ["READ_O"] + [""] * 8 + ["REPAIR", f"ERR:{str(e)}"]