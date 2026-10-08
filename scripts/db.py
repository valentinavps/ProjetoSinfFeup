from typing import Union, List
import psycopg2


# Data Sample:
#   {
#       "timestamp": "2024-04-09 12:46:58",
#       "highPressureInputTime": 10.812,
#       "lowerPlateTemperature": 188.382,
#       "loweringTime": 20.662,
#       "anomaly_flag": True
#   }


EXAMPLES = [
    ("2025-03-14 12:46:58", 10.812, 188.382, 20.662, False),
    ("2025-03-14 12:47:58", 10.812, 188.382, 20.662, False),
    ("2025-03-14 12:48:58", 10.812, 188.382, 20.662, True),
]


class SINFDb(object):

    def __init__(
        self,
        database="sinf",
        username="sinf",
        password="sinf",
        host="localhost",
        port=5432,
    ):
        # Establishing the connection
        self.conn = psycopg2.connect(
            database=database,
            user=username,
            password=password,
            host=host,
            port=port,
        )
        self.initDB()

    def __del__(self):
        """
        Closing the connection
        """
        self.conn.close()

    def initDB(self, verbose: bool = True):
        # Creating a cursor object using the cursor() method
        cursor = self.conn.cursor()

        # Executing an SQL function using the execute() method
        cursor.execute("select version()")

        # Fetch a single row using fetchone() method
        data = cursor.fetchone()

        if verbose:
            print(f"PostGres: connection established to: {data[0]}")

        # Create Schema
        cursor.execute('CREATE SCHEMA IF NOT EXISTS "DINASORE"')

        # Setting the path to DINASORE
        cursor.execute('SET search_path TO "DINASORE"')

        cursor.execute(
            'CREATE TABLE IF NOT EXISTS PRESSING_SAMPLES (\
            "id" serial primary key, \
            "timestamp" timestamp, \
            "high_pressure_input_time" float, \
            "lower_plate_temperature" int, \
            "lowering_time" float, \
            "anomaly_flag" bool)'
        )

        # Apply changes/SQL code
        self.conn.commit()

        if verbose:
            print("PostGres: Success! Tables/schema initialized.")

    def delete(self, verbose: bool = True):
        cursor = self.conn.cursor()

        # Delete tables and data
        cursor.execute('DROP SCHEMA IF EXISTS "DINASORE" CASCADE')

        self.conn.commit()

        if verbose:
            print("PostGres: Success! Data deleted.")

    def insert(self, data: Union[List[str], None] = None, verbose: bool = True):

        try:
            cursor = self.conn.cursor()
            cursor.execute('SET search_path TO "DINASORE"')

            # cursor.mogrify() to format string and insert multiple values
            args = ",".join(
                cursor.mogrify(f"{i}").decode("utf-8") for i in data
            )

            # executing the sql statement
            sql_query = (
                "INSERT INTO PRESSING_SAMPLES "
                "(timestamp, high_pressure_input_time, lower_plate_temperature, lowering_time, anomaly_flag) VALUES "
            )

            cursor.execute(sql_query + (args))

            self.conn.commit()

            if verbose:
                # executing sql statement to display output
                cursor.execute("SELECT * FROM PRESSING_SAMPLES;")

                # fetching rows
                print("PostGres, added data:")
                for i in cursor.fetchall():
                    print(i)

                print("PostGres: Success! Data added.")

            # committing changes
            self.conn.commit()

            return len(data)

        except Exception as e:
            print(e)

            return -1


# 1. Create DB and Table
db = SINFDb()

# 2. Insert Samples
db.insert(EXAMPLES)

# 3. Clean up. Delete Table and data.
#db.delete()
