*** Settings ***
Documentation    Common keywords and variables for all test suites
Library          SeleniumLibrary
Library          RequestsLibrary
Library          DatabaseLibrary
Library          Collections
Library          String
Library          OperatingSystem
Library          ../resources/TestUtils.py
Library          ../resources/DatabaseUtils.py
Library          ../resources/SecurityUtils.py

*** Variables ***
# Application URLs
${BASE_URL}          https://example.com
${API_BASE_URL}      https://api.example.com

# Browser settings
${BROWSER}           chrome
${HEADLESS}          False
${TIMEOUT}           10s
${IMPLICIT_WAIT}     5s

# Database settings
${DB_HOST}           %{DB_HOST=localhost}
${DB_PORT}           %{DB_PORT=5432}
${DB_NAME}           %{DB_NAME=test_db}
${DB_USER}           %{DB_USER=test_user}
${DB_PASSWORD}       %{DB_PASSWORD=test_password}
${DB_TYPE}           %{DB_TYPE=postgresql}

# Security settings
${ZAP_PROXY}         %{ZAP_PROXY=}
${ZAP_API_KEY}       %{ZAP_API_KEY=}

# Common selectors
${SEARCH_INPUT}      id:search
${SUBMIT_BUTTON}     id:submit
${ERROR_MESSAGE}     css:.error-message

# Test data
${VALID_EMAIL}       test@example.com
${INVALID_EMAIL}     invalid-email

*** Keywords ***
Open Browser To Base URL
    [Documentation]    Opens browser to the base URL with common settings and optional ZAP proxy
    [Arguments]        ${url}=${BASE_URL}
    
    # Check if ZAP proxy is enabled and configure browser accordingly
    ${zap_enabled}=    Is Zap Proxy Enabled
    ${browser_options}=    Set Variable    add_argument("--disable-web-security");add_argument("--disable-features=VizDisplayCompositor")
    
    IF    ${zap_enabled}
        ${zap_proxy_args}=    Configure Browser With Zap Proxy
        ${browser_options}=    Set Variable    ${browser_options};${zap_proxy_args}
        Log    Browser configured with ZAP proxy for security testing
    END
    
    Open Browser       ${url}    ${BROWSER}    options=${browser_options}
    Set Window Size    1920    1080
    Set Selenium Timeout    ${TIMEOUT}
    Set Selenium Implicit Wait    ${IMPLICIT_WAIT}

Close All Browsers And Sessions
    [Documentation]    Clean up after tests
    Close All Browsers
    Delete All Sessions
    Disconnect From All Databases

Wait And Click Element
    [Documentation]    Wait for element to be visible and click it
    [Arguments]        ${locator}    ${timeout}=${TIMEOUT}
    Wait Until Element Is Visible    ${locator}    ${timeout}
    Click Element      ${locator}

Input Text And Verify
    [Documentation]    Input text and verify it was entered correctly
    [Arguments]        ${locator}    ${text}
    Wait Until Element Is Visible    ${locator}
    Clear Element Text    ${locator}
    Input Text         ${locator}    ${text}
    ${actual_text}=    Get Value    ${locator}
    Should Be Equal    ${actual_text}    ${text}

Create API Session
    [Documentation]    Create a session for API testing with optional ZAP proxy
    [Arguments]        ${alias}=api    ${base_url}=${API_BASE_URL}
    
    # Check if ZAP proxy is enabled and configure requests accordingly
    ${zap_enabled}=    Is Zap Proxy Enabled
    
    IF    ${zap_enabled}
        ${proxy_config}=    Configure Requests With Zap Proxy
        Create Session     ${alias}    ${base_url}
        ...                headers={'Content-Type': 'application/json'}
        ...                proxies=${proxy_config['proxies']}
        ...                verify=${proxy_config['verify']}
        Log    API session configured with ZAP proxy for security testing
    ELSE
        Create Session     ${alias}    ${base_url}
        ...                headers={'Content-Type': 'application/json'}
    END

Verify API Response
    [Documentation]    Common API response verification
    [Arguments]        ${response}    ${expected_status}=200
    Should Be Equal As Strings    ${response.status_code}    ${expected_status}
    Should Be True    ${response.headers['Content-Type'].startswith('application/json')}

Take Screenshot On Failure
    [Documentation]    Take screenshot when test fails
    Run Keyword If Test Failed    Capture Page Screenshot

# Database Keywords
Setup Database Connection
    [Documentation]    Setup database connection based on DB_TYPE
    IF    '${DB_TYPE}' == 'postgresql'
        Connect To Postgresql    ${DB_HOST}    ${DB_PORT}    ${DB_NAME}    ${DB_USER}    ${DB_PASSWORD}
    ELSE IF    '${DB_TYPE}' == 'mysql'
        Connect To Mysql    ${DB_HOST}    ${DB_PORT}    ${DB_NAME}    ${DB_USER}    ${DB_PASSWORD}
    ELSE IF    '${DB_TYPE}' == 'mongodb'
        Connect To Mongodb    ${DB_HOST}    ${DB_PORT}    ${DB_NAME}    ${DB_USER}    ${DB_PASSWORD}
    ELSE
        Log    Database type '${DB_TYPE}' not supported    WARN
    END

Cleanup Database Connection
    [Documentation]    Clean up database connections
    Disconnect From All Databases

Execute Database Query
    [Documentation]    Execute database query based on database type
    [Arguments]        ${query}    ${collection_name}=${EMPTY}
    IF    '${DB_TYPE}' == 'mongodb' and '${collection_name}' != '${EMPTY}'
        ${result}=    Execute Mongodb Query    ${collection_name}    ${query}
    ELSE
        ${result}=    Execute Sql Query    ${query}
    END
    RETURN    ${result}

Insert Database Test Data
    [Documentation]    Insert test data into database
    [Arguments]        ${table_name}    ${data}
    Insert Test Data    ${table_name}    ${data}

Clean Database Test Data
    [Documentation]    Clean up test data from database
    [Arguments]        ${table_name}    ${condition}
    Cleanup Test Data    ${table_name}    ${condition}

Verify Database Record Count
    [Documentation]    Verify number of records in database table
    [Arguments]        ${table_name}    ${expected_count}    ${condition}=${EMPTY}
    Verify Database State    ${table_name}    ${expected_count}    ${condition}

# Security Testing Keywords
Start Security Spider Scan
    [Documentation]    Start ZAP spider scan if security testing is enabled
    [Arguments]        ${target_url}=${BASE_URL}
    ${scan_id}=    Start Zap Spider    ${target_url}
    RETURN    ${scan_id}

Wait For Spider Scan Complete
    [Documentation]    Wait for ZAP spider scan to complete
    [Arguments]        ${scan_id}    ${timeout}=300
    Wait For Zap Spider Completion    ${scan_id}    ${timeout}

Start Security Active Scan
    [Documentation]    Start ZAP active security scan
    [Arguments]        ${target_url}=${BASE_URL}
    ${scan_id}=    Start Zap Active Scan    ${target_url}
    RETURN    ${scan_id}

Wait For Active Scan Complete
    [Documentation]    Wait for ZAP active scan to complete
    [Arguments]        ${scan_id}    ${timeout}=600
    Wait For Zap Active Scan Completion    ${scan_id}    ${timeout}

Generate Security Report
    [Documentation]    Generate ZAP security report
    [Arguments]        ${format}=HTML    ${filename}=security_report.html
    ${report_path}=    Generate Zap Report    ${format}    ${filename}
    RETURN    ${report_path}

Verify No High Risk Vulnerabilities
    [Documentation]    Verify no high-risk vulnerabilities were found
    [Arguments]        ${base_url}=${BASE_URL}
    Verify No High Risk Vulnerabilities    ${base_url}

Clear Security Session
    [Documentation]    Clear ZAP session data
    Clear Zap Session
