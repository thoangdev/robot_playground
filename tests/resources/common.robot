*** Settings ***
Documentation    Shared keywords and variables for all test suites

Library    OperatingSystem
Library    String
Library    Browser
Library    RequestsLibrary
Library    DatabaseLibrary
Library    ../resources/TestUtils.py
Library    ../resources/DatabaseUtils.py


*** Variables ***
# ── Application URLs ─────────────────────────────────────────────────────────
# Public demo sites used by the bundled example suites.
# Override via --variable or .env when testing your own application.
${BASE_URL}    https://the-internet.herokuapp.com
${API_BASE_URL}    https://jsonplaceholder.typicode.com

# ── Browser settings ─────────────────────────────────────────────────────────
${BROWSER}    chrome
${HEADLESS}    False
${TIMEOUT}    15s

# ── Database settings ─────────────────────────────────────────────────────────
# Default: SQLite — works everywhere with no external service.
# Set DB_TYPE to postgresql / mysql / mongodb for production environments.
${DB_TYPE}    %{DB_TYPE=sqlite}
${DB_NAME}    %{DB_NAME=results/test.db}
${DB_HOST}    %{DB_HOST=localhost}
${DB_PORT}    %{DB_PORT=5432}
${DB_USER}    %{DB_USER=test_user}
${DB_PASSWORD}    %{DB_PASSWORD=test_password}

# ── ZAP proxy (passive security scanning) ────────────────────────────────────
# Leave empty to run normally.    CI sets ZAP_PROXY=http://localhost:8080 so all
# traffic is observed by ZAP without needing dedicated security test cases.
${ZAP_PROXY}    %{ZAP_PROXY=}

# ── Common API headers ────────────────────────────────────────────────────────
&{API_HEADERS}    Content-Type=application/json    Accept=application/json

# ── Common selectors (override in your suite as needed) ──────────────────────
${ERROR_MESSAGE}    css=.error-message


*** Keywords ***
# ─── Browser ──────────────────────────────────────────────────────────────────

Open Browser To Base URL
    [Documentation]    Open ${BROWSER} to ${url}, optionally routing through ZAP.
    [Arguments]    ${url}=${BASE_URL}

    ${browser_engine}=    Resolve Browser Engine    ${BROWSER}
    ${headless_mode}=    Convert To Boolean    ${HEADLESS}
    New Browser    ${browser_engine}    headless=${headless_mode}
    New Browser Context
    New Page    ${url}
    Set Browser Timeout    ${TIMEOUT}

New Browser Context
    [Documentation]    Create a Browser context, optionally routing through ZAP.
    IF    '${ZAP_PROXY}' != '${EMPTY}'
        New Context    ignoreHTTPSErrors=${True}    proxy={'server': '${ZAP_PROXY}'}
        Log    Browser proxied through ZAP: ${ZAP_PROXY}
    ELSE
        New Context
    END

Resolve Browser Engine
    [Documentation]    Map common browser names to Browser Library engines.
    [Arguments]    ${browser_name}
    ${normalized}=    Convert To Lower Case    ${browser_name}
    IF    '${normalized}' in ['chrome', 'chromium', 'edge']
        RETURN    chromium
    ELSE IF    '${normalized}' == 'firefox'
        RETURN    firefox
    ELSE IF    '${normalized}' in ['safari', 'webkit']
        RETURN    webkit
    ELSE
        Fail    Unsupported BROWSER: ${browser_name}. Expected chrome/chromium/edge, firefox, or webkit.
    END

Close All Browsers And Sessions
    [Documentation]    Tear down browsers, HTTP sessions, and DB connections.
    Run Keyword And Ignore Error    Close Browser    ALL
    Run Keyword And Ignore Error    Delete All Sessions
    Run Keyword And Ignore Error    DatabaseUtils.Disconnect From All Databases

Take Screenshot On Failure
    [Documentation]    Capture a screenshot when the test status is FAIL.
    IF    '${TEST STATUS}' == 'FAIL'
        Run Keyword And Ignore Error    Create Directory    ${OUTPUT DIR}/screenshots
        Run Keyword And Ignore Error
        ...    Take Screenshot
        ...    filename=${OUTPUT DIR}/screenshots/browser-screenshot-{index}.png
    END

Wait And Click Element
    [Documentation]    Wait for element to be visible then click it.
    [Arguments]    ${locator}    ${timeout}=${TIMEOUT}
    Wait For Elements State    ${locator}    visible    ${timeout}
    Click    ${locator}

Input Text And Verify
    [Documentation]    Type text into a field and assert it was accepted.
    [Arguments]    ${locator}    ${text}
    Wait For Elements State    ${locator}    visible    ${TIMEOUT}
    Fill Text    ${locator}    ${text}
    ${actual}=    Get Property    ${locator}    value
    Should Be Equal    ${actual}    ${text}

# ─── API ──────────────────────────────────────────────────────────────────────

Create API Session
    [Documentation]    Open an HTTP session to ${base_url}, optionally via ZAP proxy.
    [Arguments]    ${alias}=api    ${base_url}=${API_BASE_URL}

    IF    '${ZAP_PROXY}' != '${EMPTY}'
        ${proxies}=    Create Dictionary    http=${ZAP_PROXY}    https=${ZAP_PROXY}
        Create Session    ${alias}    ${base_url}    headers=${API_HEADERS}    proxies=${proxies}    verify=${False}
        Log    API session proxied through ZAP: ${ZAP_PROXY}
    ELSE
        Create Session    ${alias}    ${base_url}    headers=${API_HEADERS}    verify=${True}
    END

Verify API Response
    [Documentation]    Assert status code and JSON content-type.
    [Arguments]    ${response}    ${expected_status}=200
    Should Be Equal As Strings    ${response.status_code}    ${expected_status}
    Should Be True    $response.headers.get('Content-Type','').startswith('application/json')

# ─── Database ─────────────────────────────────────────────────────────────────

Setup Database Connection
    [Documentation]    Connect to the database selected by DB_TYPE.
    IF    '${DB_TYPE}' == 'sqlite'
        Connect To Sqlite    ${DB_NAME}
    ELSE IF    '${DB_TYPE}' == 'postgresql'
        Connect To Postgresql    ${DB_HOST}    ${DB_PORT}    ${DB_NAME}    ${DB_USER}    ${DB_PASSWORD}
    ELSE IF    '${DB_TYPE}' == 'mysql'
        Connect To Mysql    ${DB_HOST}    ${DB_PORT}    ${DB_NAME}    ${DB_USER}    ${DB_PASSWORD}
    ELSE IF    '${DB_TYPE}' == 'mongodb'
        Connect To Mongodb    ${DB_HOST}    ${DB_PORT}    ${DB_NAME}    ${DB_USER}    ${DB_PASSWORD}
    ELSE
        Fail    Unsupported DB_TYPE: '${DB_TYPE}'. Expected sqlite / postgresql / mysql / mongodb.
    END

Cleanup Database Connection
    [Documentation]    Close all database connections.
    DatabaseUtils.Disconnect From All Databases

Execute Database Query
    [Documentation]    Run a query; use collection_name for MongoDB.
    [Arguments]    ${query}    ${collection_name}=${EMPTY}
    IF    '${DB_TYPE}' == 'mongodb' and '${collection_name}' != '${EMPTY}'
        ${result}=    Execute Mongodb Query    ${collection_name}    ${query}
    ELSE
        ${result}=    Execute Sql Query    ${query}
    END
    RETURN    ${result}

Insert Database Test Data
    [Documentation]    Insert a dict (or list of dicts) into table/collection.
    [Arguments]    ${table_name}    ${data}
    Insert Test Data    ${table_name}    ${data}

Clean Database Test Data
    [Documentation]    Delete records matching condition from table/collection.
    [Arguments]    ${table_name}    ${condition}
    Cleanup Test Data    ${table_name}    ${condition}

Verify Database Record Count
    [Documentation]    Assert the number of records (optionally filtered).
    [Arguments]    ${table_name}    ${expected_count}    ${condition}=${EMPTY}
    Verify Database State    ${table_name}    ${expected_count}    ${condition}
