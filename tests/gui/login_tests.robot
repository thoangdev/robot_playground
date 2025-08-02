*** Settings ***
Documentation    Sample GUI test suite demonstrating basic web testing patterns
Resource         ../resources/common.robot
Library          ../resources/TestUtils.py
Suite Setup      Suite Setup Keywords
Suite Teardown   Suite Teardown Keywords
Test Setup       Test Setup Keywords
Test Teardown    Test Teardown Keywords

*** Variables ***
${LOGIN_URL}           ${BASE_URL}/login
${DASHBOARD_URL}       ${BASE_URL}/dashboard
${USERNAME_FIELD}      id:username
${PASSWORD_FIELD}      id:password
${LOGIN_BUTTON}        id:login-btn
${WELCOME_MESSAGE}     css:.welcome-message

*** Test Cases ***
Valid User Login
    [Documentation]    Test successful login with valid credentials
    [Tags]             smoke    login    positive
    
    Navigate To Login Page
    Enter Valid Credentials
    Click Login Button
    Verify Successful Login
    Verify Dashboard Is Displayed

Invalid User Login
    [Documentation]    Test login failure with invalid credentials
    [Tags]             login    negative
    
    Navigate To Login Page
    Enter Invalid Credentials
    Click Login Button
    Verify Login Error Message

Empty Credentials Login
    [Documentation]    Test login with empty credentials
    [Tags]             login    negative    validation
    
    Navigate To Login Page
    Leave Credentials Empty
    Click Login Button
    Verify Validation Error Messages

User Logout
    [Documentation]    Test user logout functionality
    [Tags]             logout    smoke
    
    [Setup]    Login With Valid User
    Click Logout Button
    Verify User Is Logged Out
    Verify Redirected To Login Page

*** Keywords ***
Suite Setup Keywords
    [Documentation]    Run once before all tests in this suite
    Log    Starting GUI test suite
    ${timestamp}=    Get Current Timestamp
    Set Suite Variable    ${SUITE_START_TIME}    ${timestamp}

Suite Teardown Keywords
    [Documentation]    Run once after all tests in this suite
    Log    GUI test suite completed
    Close All Browsers And Sessions

Test Setup Keywords
    [Documentation]    Run before each test case
    Open Browser To Base URL

Test Teardown Keywords
    [Documentation]    Run after each test case
    Run Keyword If Test Failed    Take Screenshot On Failure
    Close All Browsers

Navigate To Login Page
    [Documentation]    Navigate to the login page
    Go To    ${LOGIN_URL}
    Wait Until Page Contains Element    ${USERNAME_FIELD}
    Title Should Be    Login Page

Enter Valid Credentials
    [Documentation]    Enter valid username and password
    ${test_data}=    Load Json Test Data    test_data.json
    ${username}=     Set Variable    ${test_data['users']['valid_user']['username']}
    ${password}=     Set Variable    ${test_data['users']['valid_user']['password']}
    
    Input Text And Verify    ${USERNAME_FIELD}    ${username}
    Input Text And Verify    ${PASSWORD_FIELD}    ${password}

Enter Invalid Credentials
    [Documentation]    Enter invalid username and password
    Input Text And Verify    ${USERNAME_FIELD}    invalid_user
    Input Text And Verify    ${PASSWORD_FIELD}    wrong_password

Leave Credentials Empty
    [Documentation]    Leave both credential fields empty
    Clear Element Text    ${USERNAME_FIELD}
    Clear Element Text    ${PASSWORD_FIELD}

Click Login Button
    [Documentation]    Click the login button
    Wait And Click Element    ${LOGIN_BUTTON}

Verify Successful Login
    [Documentation]    Verify that login was successful
    Wait Until Page Contains Element    ${WELCOME_MESSAGE}    timeout=${TIMEOUT}
    Element Should Be Visible    ${WELCOME_MESSAGE}

Verify Dashboard Is Displayed
    [Documentation]    Verify that dashboard page is displayed
    Location Should Be    ${DASHBOARD_URL}
    Wait Until Page Contains    Dashboard    timeout=${TIMEOUT}

Verify Login Error Message
    [Documentation]    Verify that error message is displayed for invalid login
    Wait Until Page Contains    Invalid credentials    timeout=${TIMEOUT}
    Element Should Be Visible    ${ERROR_MESSAGE}

Verify Validation Error Messages
    [Documentation]    Verify validation error messages for empty fields
    Wait Until Page Contains    Username is required    timeout=${TIMEOUT}
    Wait Until Page Contains    Password is required    timeout=${TIMEOUT}

Login With Valid User
    [Documentation]    Helper keyword to login with valid user
    Navigate To Login Page
    Enter Valid Credentials
    Click Login Button
    Verify Successful Login

Click Logout Button
    [Documentation]    Click the logout button
    Wait And Click Element    id:logout-btn

Verify User Is Logged Out
    [Documentation]    Verify that user is successfully logged out
    Wait Until Page Does Not Contain Element    ${WELCOME_MESSAGE}    timeout=${TIMEOUT}

Verify Redirected To Login Page
    [Documentation]    Verify that user is redirected to login page after logout
    Location Should Be    ${LOGIN_URL}
    Wait Until Page Contains Element    ${USERNAME_FIELD}    timeout=${TIMEOUT}
