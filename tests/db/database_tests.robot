*** Settings ***
Documentation    Simple database test suite demonstrating database testing patterns
Resource         ../resources/common.robot
Library          ../resources/TestUtils.py
Library          ../resources/DatabaseUtils.py
Suite Setup      Database Suite Setup
Suite Teardown   Database Suite Teardown
Test Setup       Database Test Setup
Test Teardown    Database Test Cleanup

*** Variables ***
${TEST_TABLE}        users
${TEST_USER_DATA}    {"name": "Test User", "email": "testuser@example.com", "status": "active"}
${UPDATE_USER_DATA}  {"name": "Updated User", "email": "updated@example.com", "status": "inactive"}

*** Test Cases ***
Create User Record
    [Documentation]    Test creating a new user record in the database
    [Tags]             database    crud    positive
    
    # Insert test user data
    ${test_data}=    Evaluate    ${TEST_USER_DATA}
    Insert Database Test Data    ${TEST_TABLE}    ${test_data}
    
    # Verify the record was created
    Verify Database Record Count    ${TEST_TABLE}    1    email='testuser@example.com'
    
    # Query and verify the data
    ${query_result}=    Query User By Email    testuser@example.com
    Should Not Be Empty    ${query_result}
    Verify User Data    ${query_result}    ${test_data}

Update User Record
    [Documentation]    Test updating an existing user record
    [Tags]             database    crud    positive
    [Setup]            Create Test User
    
    # Update the user record
    ${update_data}=    Evaluate    ${UPDATE_USER_DATA}
    Update User By Email    testuser@example.com    ${update_data}
    
    # Verify the record was updated
    ${query_result}=    Query User By Email    updated@example.com
    Should Not Be Empty    ${query_result}
    Verify User Data    ${query_result}    ${update_data}
    
    # Verify old email doesn't exist
    ${old_result}=    Query User By Email    testuser@example.com
    Should Be Empty    ${old_result}

Delete User Record
    [Documentation]    Test deleting a user record from the database
    [Tags]             database    crud    positive
    [Setup]            Create Test User
    
    # Verify user exists before deletion
    Verify Database Record Count    ${TEST_TABLE}    1    email='testuser@example.com'
    
    # Delete the user record
    Clean Database Test Data    ${TEST_TABLE}    email='testuser@example.com'
    
    # Verify the record was deleted
    Verify Database Record Count    ${TEST_TABLE}    0    email='testuser@example.com'

Query Multiple Users
    [Documentation]    Test querying multiple user records
    [Tags]             database    query    positive
    
    # Create multiple test users
    ${user1}=    Create Dictionary    name=User One    email=user1@example.com    status=active
    ${user2}=    Create Dictionary    name=User Two    email=user2@example.com    status=active
    ${user3}=    Create Dictionary    name=User Three    email=user3@example.com    status=inactive
    
    Insert Database Test Data    ${TEST_TABLE}    ${user1}
    Insert Database Test Data    ${TEST_TABLE}    ${user2}
    Insert Database Test Data    ${TEST_TABLE}    ${user3}
    
    # Query active users
    ${active_users}=    Query Users By Status    active
    Length Should Be    ${active_users}    2
    
    # Query inactive users
    ${inactive_users}=    Query Users By Status    inactive
    Length Should Be    ${inactive_users}    1
    
    # Query all test users
    Verify Database Record Count    ${TEST_TABLE}    3    email LIKE '%@example.com'

Database Transaction Test
    [Documentation]    Test database transaction handling
    [Tags]             database    transaction    positive
    
    # Get initial count
    ${initial_count}=    Get Total User Count
    
    # Start a transaction and insert multiple records
    ${users_data}=    Create List
    ...    {"name": "Transaction User 1", "email": "txn1@example.com", "status": "active"}
    ...    {"name": "Transaction User 2", "email": "txn2@example.com", "status": "active"}
    
    Insert Multiple Users    ${users_data}
    
    # Verify all records were inserted
    ${final_count}=    Get Total User Count
    ${expected_count}=    Evaluate    ${initial_count} + 2
    Should Be Equal As Numbers    ${final_count}    ${expected_count}

Database Connection Test
    [Documentation]    Test database connection and basic operations
    [Tags]             database    connection    smoke
    
    # Test basic connection
    ${connection_status}=    Test Database Connection
    Should Be True    ${connection_status}
    
    # Test simple query
    ${result}=    Execute Simple Query
    Should Not Be Empty    ${result}
    
    Log    Database connection test passed successfully

*** Keywords ***
Database Suite Setup
    [Documentation]    Setup database connection and test environment
    Setup Database Connection
    Create Test Table If Not Exists

Database Suite Teardown
    [Documentation]    Cleanup database connection
    Cleanup All Test Data
    Cleanup Database Connection

Database Test Setup
    [Documentation]    Setup for individual database tests
    Log    Starting database test case

Database Test Cleanup
    [Documentation]    Cleanup after individual database tests
    Clean Database Test Data    ${TEST_TABLE}    email LIKE '%@example.com'

Create Test User
    [Documentation]    Helper keyword to create a test user
    ${test_data}=    Evaluate    ${TEST_USER_DATA}
    Insert Database Test Data    ${TEST_TABLE}    ${test_data}

Query User By Email
    [Documentation]    Query user record by email address
    [Arguments]        ${email}
    
    IF    '${DB_TYPE}' == 'mongodb'
        ${query}=    Create Dictionary    email=${email}
        ${result}=    Execute Database Query    ${query}    ${TEST_TABLE}
    ELSE
        ${query}=    Set Variable    SELECT * FROM ${TEST_TABLE} WHERE email = '${email}'
        ${result}=    Execute Database Query    ${query}
    END
    
    RETURN    ${result}

Update User By Email
    [Documentation]    Update user record by email address
    [Arguments]        ${old_email}    ${new_data}
    
    IF    '${DB_TYPE}' == 'mongodb'
        # MongoDB update operation would go here
        Log    MongoDB update not implemented in this simple example    WARN
    ELSE
        ${name}=    Get From Dictionary    ${new_data}    name
        ${email}=    Get From Dictionary    ${new_data}    email
        ${status}=    Get From Dictionary    ${new_data}    status
        ${query}=    Set Variable    UPDATE ${TEST_TABLE} SET name='${name}', email='${email}', status='${status}' WHERE email='${old_email}'
        Execute Database Query    ${query}
    END

Query Users By Status
    [Documentation]    Query users by status
    [Arguments]        ${status}
    
    IF    '${DB_TYPE}' == 'mongodb'
        ${query}=    Create Dictionary    status=${status}
        ${result}=    Execute Database Query    ${query}    ${TEST_TABLE}
    ELSE
        ${query}=    Set Variable    SELECT * FROM ${TEST_TABLE} WHERE status = '${status}'
        ${result}=    Execute Database Query    ${query}
    END
    
    RETURN    ${result}

Get Total User Count
    [Documentation]    Get total count of users in the table
    
    IF    '${DB_TYPE}' == 'mongodb'
        ${query}=    Create Dictionary
        ${result}=    Execute Database Query    ${query}    ${TEST_TABLE}
        ${count}=    Get Length    ${result}
    ELSE
        ${query}=    Set Variable    SELECT COUNT(*) FROM ${TEST_TABLE}
        ${result}=    Execute Database Query    ${query}
        ${count}=    Set Variable    ${result[0][0]}
    END
    
    RETURN    ${count}

Insert Multiple Users
    [Documentation]    Insert multiple user records
    [Arguments]        ${users_list}
    
    FOR    ${user_data}    IN    @{users_list}
        ${user_dict}=    Evaluate    ${user_data}
        Insert Database Test Data    ${TEST_TABLE}    ${user_dict}
    END

Test Database Connection
    [Documentation]    Test basic database connectivity
    TRY
        ${result}=    Execute Simple Query
        RETURN    ${True}
    EXCEPT
        RETURN    ${False}
    END

Execute Simple Query
    [Documentation]    Execute a simple query to test connection
    
    IF    '${DB_TYPE}' == 'mongodb'
        ${query}=    Create Dictionary
        ${result}=    Execute Database Query    ${query}    ${TEST_TABLE}
    ELSE
        ${query}=    Set Variable    SELECT 1 as test_connection
        ${result}=    Execute Database Query    ${query}
    END
    
    RETURN    ${result}

Create Test Table If Not Exists
    [Documentation]    Create test table if it doesn't exist
    
    IF    '${DB_TYPE}' == 'postgresql'
        ${create_query}=    Set Variable    
        ...    CREATE TABLE IF NOT EXISTS ${TEST_TABLE} (
        ...        id SERIAL PRIMARY KEY,
        ...        name VARCHAR(100) NOT NULL,
        ...        email VARCHAR(100) UNIQUE NOT NULL,
        ...        status VARCHAR(20) DEFAULT 'active',
        ...        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ...    )
        Execute Database Query    ${create_query}
    ELSE IF    '${DB_TYPE}' == 'mysql'
        ${create_query}=    Set Variable    
        ...    CREATE TABLE IF NOT EXISTS ${TEST_TABLE} (
        ...        id INT AUTO_INCREMENT PRIMARY KEY,
        ...        name VARCHAR(100) NOT NULL,
        ...        email VARCHAR(100) UNIQUE NOT NULL,
        ...        status VARCHAR(20) DEFAULT 'active',
        ...        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ...    )
        Execute Database Query    ${create_query}
    ELSE IF    '${DB_TYPE}' == 'mongodb'
        Log    MongoDB collections are created automatically    INFO
    ELSE
        Log    Table creation not supported for database type: ${DB_TYPE}    WARN
    END

Verify User Data
    [Documentation]    Verify user data matches expected values
    [Arguments]        ${actual_data}    ${expected_data}
    
    IF    '${DB_TYPE}' == 'mongodb'
        ${actual_user}=    Set Variable    ${actual_data[0]}
        Should Be Equal    ${actual_user['name']}    ${expected_data['name']}
        Should Be Equal    ${actual_user['email']}    ${expected_data['email']}
        Should Be Equal    ${actual_user['status']}    ${expected_data['status']}
    ELSE
        ${actual_user}=    Set Variable    ${actual_data[0]}
        Should Be Equal    ${actual_user[1]}    ${expected_data['name']}    # name column
        Should Be Equal    ${actual_user[2]}    ${expected_data['email']}   # email column
        Should Be Equal    ${actual_user[3]}    ${expected_data['status']}  # status column
    END

Cleanup All Test Data
    [Documentation]    Clean up all test data from the database
    TRY
        Clean Database Test Data    ${TEST_TABLE}    email LIKE '%@example.com'
        Log    Test data cleanup completed successfully
    EXCEPT    AS    ${error}
        Log    Test data cleanup failed: ${error}    WARN
    END
