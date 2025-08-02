"""
Database utility library for Robot Framework tests
Provides enhanced database testing capabilities with multiple database support
"""

import os
import psycopg2
import pymongo
import pymysql
from robot.api.deco import keyword
from robot.libraries.BuiltIn import BuiltIn


class DatabaseUtils:
    """Custom database library for Robot Framework with multi-database support"""
    
    ROBOT_LIBRARY_SCOPE = 'GLOBAL'
    
    def __init__(self):
        self.builtin = BuiltIn()
        self.connections = {}
    
    @keyword
    def connect_to_postgresql(self, host, port, database, user, password, alias='default'):
        """
        Connect to PostgreSQL database
        
        Args:
            host: Database host
            port: Database port
            database: Database name
            user: Database user
            password: Database password
            alias: Connection alias for multiple connections
        """
        try:
            connection_string = f"postgresql://{user}:{password}@{host}:{port}/{database}"
            self.builtin.run_keyword('Connect To Database', 'psycopg2', database, user, password, host, port)
            self.connections[alias] = {
                'type': 'postgresql',
                'connection_string': connection_string
            }
            return f"Connected to PostgreSQL database: {database}"
        except Exception as e:
            raise Exception(f"Failed to connect to PostgreSQL: {str(e)}")
    
    @keyword
    def connect_to_mysql(self, host, port, database, user, password, alias='default'):
        """
        Connect to MySQL database
        
        Args:
            host: Database host
            port: Database port  
            database: Database name
            user: Database user
            password: Database password
            alias: Connection alias for multiple connections
        """
        try:
            self.builtin.run_keyword('Connect To Database', 'pymysql', database, user, password, host, port)
            self.connections[alias] = {
                'type': 'mysql',
                'host': host,
                'port': port,
                'database': database
            }
            return f"Connected to MySQL database: {database}"
        except Exception as e:
            raise Exception(f"Failed to connect to MySQL: {str(e)}")
    
    @keyword
    def connect_to_mongodb(self, host, port, database, user=None, password=None, alias='default'):
        """
        Connect to MongoDB database
        
        Args:
            host: MongoDB host
            port: MongoDB port
            database: Database name
            user: MongoDB user (optional)
            password: MongoDB password (optional)
            alias: Connection alias for multiple connections
        """
        try:
            if user and password:
                connection_string = f"mongodb://{user}:{password}@{host}:{port}/{database}"
            else:
                connection_string = f"mongodb://{host}:{port}"
            
            client = pymongo.MongoClient(connection_string)
            db = client[database]
            
            self.connections[alias] = {
                'type': 'mongodb',
                'client': client,
                'database': db,
                'connection_string': connection_string
            }
            return f"Connected to MongoDB database: {database}"
        except Exception as e:
            raise Exception(f"Failed to connect to MongoDB: {str(e)}")
    
    @keyword
    def execute_sql_query(self, query, alias='default'):
        """
        Execute SQL query and return results
        
        Args:
            query: SQL query to execute
            alias: Connection alias
        """
        try:
            if alias not in self.connections:
                raise Exception(f"No connection found with alias: {alias}")
            
            connection_type = self.connections[alias]['type']
            
            if connection_type in ['postgresql', 'mysql']:
                result = self.builtin.run_keyword('Query', query)
                return result
            else:
                raise Exception(f"SQL queries not supported for {connection_type}")
        except Exception as e:
            raise Exception(f"Failed to execute query: {str(e)}")
    
    @keyword
    def execute_mongodb_query(self, collection_name, query, alias='default'):
        """
        Execute MongoDB query
        
        Args:
            collection_name: MongoDB collection name
            query: MongoDB query (as dict)
            alias: Connection alias
        """
        try:
            if alias not in self.connections:
                raise Exception(f"No connection found with alias: {alias}")
            
            if self.connections[alias]['type'] != 'mongodb':
                raise Exception("This method only works with MongoDB connections")
            
            db = self.connections[alias]['database']
            collection = db[collection_name]
            
            # Convert string query to dict if needed
            if isinstance(query, str):
                import json
                query = json.loads(query)
            
            results = list(collection.find(query))
            return results
        except Exception as e:
            raise Exception(f"Failed to execute MongoDB query: {str(e)}")
    
    @keyword
    def insert_test_data(self, table_name, data, alias='default'):
        """
        Insert test data into database
        
        Args:
            table_name: Table/collection name
            data: Data to insert (dict or list of dicts)
            alias: Connection alias
        """
        try:
            if alias not in self.connections:
                raise Exception(f"No connection found with alias: {alias}")
            
            connection_type = self.connections[alias]['type']
            
            if connection_type == 'mongodb':
                db = self.connections[alias]['database']
                collection = db[table_name]
                
                if isinstance(data, list):
                    result = collection.insert_many(data)
                    return f"Inserted {len(result.inserted_ids)} documents"
                else:
                    result = collection.insert_one(data)
                    return f"Inserted document with ID: {result.inserted_id}"
            
            elif connection_type in ['postgresql', 'mysql']:
                # Build INSERT statement for SQL databases
                if isinstance(data, dict):
                    columns = ', '.join(data.keys())
                    values = ', '.join([f"'{v}'" if isinstance(v, str) else str(v) for v in data.values()])
                    query = f"INSERT INTO {table_name} ({columns}) VALUES ({values})"
                    self.builtin.run_keyword('Execute Sql String', query)
                    return f"Inserted 1 row into {table_name}"
                else:
                    raise Exception("SQL insert requires dict data format")
            
        except Exception as e:
            raise Exception(f"Failed to insert test data: {str(e)}")
    
    @keyword
    def cleanup_test_data(self, table_name, condition, alias='default'):
        """
        Clean up test data from database
        
        Args:
            table_name: Table/collection name
            condition: Cleanup condition (SQL WHERE clause or MongoDB query)
            alias: Connection alias
        """
        try:
            if alias not in self.connections:
                raise Exception(f"No connection found with alias: {alias}")
            
            connection_type = self.connections[alias]['type']
            
            if connection_type == 'mongodb':
                db = self.connections[alias]['database']
                collection = db[table_name]
                
                if isinstance(condition, str):
                    import json
                    condition = json.loads(condition)
                
                result = collection.delete_many(condition)
                return f"Deleted {result.deleted_count} documents"
            
            elif connection_type in ['postgresql', 'mysql']:
                query = f"DELETE FROM {table_name} WHERE {condition}"
                self.builtin.run_keyword('Execute Sql String', query)
                return f"Deleted rows from {table_name}"
            
        except Exception as e:
            raise Exception(f"Failed to cleanup test data: {str(e)}")
    
    @keyword
    def verify_database_state(self, table_name, expected_count, condition="", alias='default'):
        """
        Verify database state by checking record count
        
        Args:
            table_name: Table/collection name
            expected_count: Expected number of records
            condition: Optional condition (SQL WHERE or MongoDB query)
            alias: Connection alias
        """
        try:
            if alias not in self.connections:
                raise Exception(f"No connection found with alias: {alias}")
            
            connection_type = self.connections[alias]['type']
            
            if connection_type == 'mongodb':
                db = self.connections[alias]['database']
                collection = db[table_name]
                
                if condition:
                    if isinstance(condition, str):
                        import json
                        condition = json.loads(condition)
                    actual_count = collection.count_documents(condition)
                else:
                    actual_count = collection.count_documents({})
            
            elif connection_type in ['postgresql', 'mysql']:
                if condition:
                    query = f"SELECT COUNT(*) FROM {table_name} WHERE {condition}"
                else:
                    query = f"SELECT COUNT(*) FROM {table_name}"
                
                result = self.builtin.run_keyword('Query', query)
                actual_count = result[0][0]
            
            if actual_count != expected_count:
                raise AssertionError(
                    f"Database state verification failed. "
                    f"Expected {expected_count} records, but found {actual_count} in {table_name}"
                )
            
            return f"Database state verified: {actual_count} records in {table_name}"
            
        except Exception as e:
            raise Exception(f"Failed to verify database state: {str(e)}")
    
    @keyword
    def disconnect_from_database(self, alias='default'):
        """
        Disconnect from database
        
        Args:
            alias: Connection alias
        """
        try:
            if alias in self.connections:
                connection_type = self.connections[alias]['type']
                
                if connection_type == 'mongodb':
                    self.connections[alias]['client'].close()
                elif connection_type in ['postgresql', 'mysql']:
                    self.builtin.run_keyword('Disconnect From Database')
                
                del self.connections[alias]
                return f"Disconnected from {connection_type} database"
            else:
                return f"No connection found with alias: {alias}"
        except Exception as e:
            raise Exception(f"Failed to disconnect from database: {str(e)}")
    
    @keyword
    def disconnect_from_all_databases(self):
        """Disconnect from all database connections"""
        try:
            for alias in list(self.connections.keys()):
                self.disconnect_from_database(alias)
            return "Disconnected from all databases"
        except Exception as e:
            raise Exception(f"Failed to disconnect from all databases: {str(e)}")
