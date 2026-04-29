*** Settings ***
Documentation    Database test suite — defaults to SQLite (zero infrastructure required).
...    Set DB_TYPE=postgresql / mysql / mongodb and supply DB_* variables in .env
...    to run against a real database server.

Resource    ../resources/common.robot
Library    ../resources/TestUtils.py
Library    ../resources/DatabaseUtils.py

Suite Setup    Database Suite Setup
Suite Teardown    Database Suite Teardown
Test Teardown    Database Test Cleanup


*** Variables ***
${TEST_TABLE}    test_users


*** Test Cases ***
Create User Record
    [Documentation]    INSERT a row and verify it is retrievable
    [Tags]    database    smoke    crud    positive

    ${data}=    Create Dictionary
    ...    name=Test User
    ...    email=testuser@example.com
    ...    status=active

    Insert Database Test Data    ${TEST_TABLE}    ${data}
    Verify Database Record Count    ${TEST_TABLE}    1    email='testuser@example.com'

    ${rows}=    Execute Database Query
    ...    SELECT name, email, status FROM ${TEST_TABLE} WHERE email='testuser@example.com'
    Should Not Be Empty    ${rows}
    Should Be Equal    ${rows}[0][0]    Test User
    Should Be Equal    ${rows}[0][1]    testuser@example.com

Update User Record
    [Documentation]    UPDATE a row and verify the change is reflected
    [Tags]    database    crud    positive
    [Setup]    Insert Test User

    Execute Database Query
    ...    UPDATE ${TEST_TABLE} SET name='Updated User', email='updated@example.com' WHERE email='testuser@example.com'
    Verify Database Record Count    ${TEST_TABLE}    0    email='testuser@example.com'
    Verify Database Record Count    ${TEST_TABLE}    1    email='updated@example.com'

    [Teardown]    Execute Database Query    DELETE FROM ${TEST_TABLE} WHERE email='updated@example.com'

Delete User Record
    [Documentation]    DELETE a row and verify it is gone
    [Tags]    database    crud    positive
    [Setup]    Insert Test User

    Verify Database Record Count    ${TEST_TABLE}    1    email='testuser@example.com'
    Clean Database Test Data    ${TEST_TABLE}    email='testuser@example.com'
    Verify Database Record Count    ${TEST_TABLE}    0    email='testuser@example.com'

Query Multiple Records
    [Documentation]    INSERT several rows then filter by status
    [Tags]    database    query    positive

    ${alice}=    Create Dictionary    name=Alice    email=alice@example.com    status=active
    ${bob}=    Create Dictionary    name=Bob    email=bob@example.com    status=active
    ${active_users}=    Create List    ${alice}    ${bob}
    FOR    ${row}    IN    @{active_users}
        Insert Database Test Data    ${TEST_TABLE}    ${row}
    END

    ${data}=    Create Dictionary    name=Charlie    email=charlie@example.com    status=inactive
    Insert Database Test Data    ${TEST_TABLE}    ${data}

    Verify Database Record Count    ${TEST_TABLE}    2    status='active'
    Verify Database Record Count    ${TEST_TABLE}    1    status='inactive'
    Verify Database Record Count    ${TEST_TABLE}    3

Database Connection Smoke Test
    [Documentation]    Basic connectivity check — SELECT 1 must succeed
    [Tags]    database    smoke    connection

    ${result}=    Execute Database Query    SELECT 1 AS connection_ok
    Should Not Be Empty    ${result}
    Log    Database connection confirmed


*** Keywords ***
Database Suite Setup
    [Documentation]    Connect and create the test table; skip the entire suite on failure.
    TRY
        Setup Database Connection
        Create Test Table
    EXCEPT    AS    ${err}
        Log    Database unavailable — skipping suite: ${err}    WARN
        Skip    Database not available: ${err}
    END

Database Suite Teardown
    [Documentation]    Drop the test table and disconnect.
    TRY
        Execute Database Query    DROP TABLE IF EXISTS ${TEST_TABLE}
    EXCEPT    AS    ${err}
        Log    Could not drop table: ${err}    WARN
    END
    Cleanup Database Connection

Database Test Cleanup
    [Documentation]    Remove all rows written during the test.
    TRY
        Clean Database Test Data    ${TEST_TABLE}    1=1
    EXCEPT    AS    ${err}
        Log    Cleanup warning: ${err}    DEBUG
    END

Insert Test User
    [Documentation]    Helper: insert a known user record before a test.
    ${data}=    Create Dictionary    name=Test User    email=testuser@example.com    status=active
    Insert Database Test Data    ${TEST_TABLE}    ${data}

Create Test Table
    [Documentation]    CREATE TABLE IF NOT EXISTS for the DB_TYPE in use.
    IF    '${DB_TYPE}' == 'sqlite' or '${DB_TYPE}' == 'postgresql'
        ${create_table_sql}=    Catenate
        ...    SEPARATOR=${SPACE}
        ...    CREATE TABLE IF NOT EXISTS ${TEST_TABLE} (
        ...    id INTEGER PRIMARY KEY,
        ...    name TEXT NOT NULL,
        ...    email TEXT UNIQUE NOT NULL,
        ...    status TEXT DEFAULT 'active'
        ...    )
        Execute Database Query    ${create_table_sql}
    ELSE IF    '${DB_TYPE}' == 'mysql'
        ${create_table_sql}=    Catenate
        ...    SEPARATOR=${SPACE}
        ...    CREATE TABLE IF NOT EXISTS ${TEST_TABLE} (
        ...    id INT AUTO_INCREMENT PRIMARY KEY,
        ...    name VARCHAR(100) NOT NULL,
        ...    email VARCHAR(100) UNIQUE NOT NULL,
        ...    status VARCHAR(20) DEFAULT 'active'
        ...    )
        Execute Database Query    ${create_table_sql}
    ELSE IF    '${DB_TYPE}' == 'mongodb'
        Log    MongoDB creates collections on first write — no explicit CREATE needed    INFO
    ELSE
        Fail    Unsupported DB_TYPE: ${DB_TYPE}
    END
