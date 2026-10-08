import unittest
import psycopg2
import sys


sys.path.insert(0, "docker/data/fb")
from POSTGRE_DB_INSERT import POSTGRE_DB_INSERT
from MACHINE_SIMULATOR import MACHINE_SIMULATOR
from POSTGRE_DB_QUERY import POSTGRE_DB_QUERY


class PostgreSQL(unittest.TestCase):

    def setUp(self):

        self.config = {
            "host": "localhost",
            "port": 5432,
            "user": "sinf",
            "password": "sinf",
            "dbname": "sinf",
        }

        # Check if Postgre is available
        self.conn = psycopg2.connect(
            dbname=self.config["dbname"],
            user=self.config["user"],
            password=self.config["password"],
            host=self.config["host"],
            port=self.config["port"],
        )
        self.cursor = self.conn.cursor()

        # Create auxiliary schema and table
        self.cursor.execute('CREATE SCHEMA IF NOT EXISTS "DEBUG";')
        self.cursor.execute('SET SEARCH_PATH TO "DEBUG";')
        self.cursor.execute(
            'CREATE TABLE IF NOT EXISTS EXAMPLE ("id" SERIAL PRIMARY KEY, "data" FLOAT);'
        )
        self.conn.commit()

    def tearDown(self):
        # Clean up
        self.cursor.execute('SET SEARCH_PATH TO "DEBUG";')
        self.cursor.execute("DROP TABLE IF EXISTS EXAMPLE;")
        self.conn.commit()
        self.conn.close()

    def test_DB_CONNECTION(self):
        """
        Evaluate connection to POSTGRE
        """

        self.assertTrue(self.conn.status == 1)

        try:
            cur = self.conn.cursor()
            cur.execute("SELECT 1;")
        except:
            raise psycopg2.OperationalError()


class PostgreInsert(PostgreSQL):

    def test_POSTGRE_DB_INSERT(self):
        """
        Evaluate POSTGRE_DB_INSERT function block
        """
        cur = self.conn.cursor()

        # test function block
        function_block = POSTGRE_DB_INSERT()

        function_block.schedule(event_name="INIT", **self.config)

        result = function_block.schedule(
            event_name="RUN",
            data="15.945",
            table="EXAMPLE",
            schema="DEBUG",
            **self.config
        )

        self.assertTrue(result[-1])


class PostgreQuery(PostgreSQL):

    def test_POSTGRE_DB_QUERY(self):
        """
        Evaluate POSTGRE_DB_QUERY function block
        """
        function_block = POSTGRE_DB_QUERY()

        function_block.schedule(
            event_name="INIT", event_value=None, query="", **self.config
        )
        result = function_block.schedule(
            event_name="RUN",
            event_value=None,
            query='SET SEARCH_PATH TO "DEBUG"; SELECT table_name FROM information_schema.tables WHERE table_schema = current_schema();',
            **self.config
        )

        self.assertTrue(len(result[-1]) > 0)


class MachineSimulator(unittest.TestCase):

    def setUp(self):

        self.config = {
            "params_data": "[((15, 0.4), (10, 0.4)), ((19, 0.1), (16, 0.1))]",
            "ratio": 0.3,
            "params_mtbf": "(18, 1.5)",
            "params_mtts": "(2, 1.5)",
            "params_mttr": "(5, 1.5)",
            "delay": 1.0,
        }

    def test_INIT(self):
        function_block = MACHINE_SIMULATOR()

        # Initialize machine
        returns = function_block.schedule(event_name="INIT", **self.config)

        self.assertEqual(returns[-1], "IDLE")

    def test_RUN(self):
        function_block = MACHINE_SIMULATOR()

        # Initialize machine
        function_block.schedule(event_name="INIT", **self.config)

        # Activate machine
        function_block.schedule(event_name="ON-OFF", **self.config)

        # Obtain results
        result = function_block.schedule(event_name="READ", **self.config)
        self.assertTrue(result[-1], "WORK")

        sensor_data = result[-2].split(",")
        self.assertEqual(len(sensor_data), 2)


if __name__ == "__main__":
    unittest.main()
