*** Settings ***
Documentation    GUI test suite using the-internet.herokuapp.com/login
...    This public demo site provides a stable login form ideal for template examples.
...    Credentials: tomsmith / SuperSecretPassword!
...    Replace BASE_URL and selectors when integrating with your own application.

Resource    ../resources/common.robot
Library    ../resources/TestUtils.py

Suite Setup    Log    Starting GUI login suite
Suite Teardown    Close All Browsers And Sessions
Test Setup    Open Browser To Base URL    ${LOGIN_URL}
Test Teardown    Take Screenshot On Failure


*** Variables ***
${LOGIN_URL}    ${BASE_URL}/login
${SECURE_URL}    ${BASE_URL}/secure
${USERNAME_FIELD}    css=#username
${PASSWORD_FIELD}    css=#password
${LOGIN_BUTTON}    css=button[type='submit']
${FLASH_MESSAGE}    css=#flash
${LOGOUT_BUTTON}    css=a.button.secondary


*** Test Cases ***
Valid User Login
    [Documentation]    Successful login redirects to the secure area
    [Tags]    gui    smoke    login    positive

    Enter Credentials    tomsmith    SuperSecretPassword!
    Click Login
    Current Url Should Be    ${SECURE_URL}
    Flash Should Contain    You logged into a secure area

Invalid Credentials Login
    [Documentation]    Wrong password shows an error flash message
    [Tags]    gui    login    negative

    Enter Credentials    tomsmith    wrongpassword
    Click Login
    Flash Should Contain    Your password is invalid!

Empty Username Login
    [Documentation]    Submitting with no username shows a validation error
    [Tags]    gui    login    negative    validation

    Enter Credentials    ${EMPTY}    somepassword
    Click Login
    Flash Should Contain    Your username is invalid!

User Logout
    [Documentation]    Logging out redirects back to the login page
    [Tags]    gui    smoke    logout

    Enter Credentials    tomsmith    SuperSecretPassword!
    Click Login
    Current Url Should Be    ${SECURE_URL}
    Wait And Click Element    ${LOGOUT_BUTTON}
    Current Url Should Be    ${LOGIN_URL}
    Flash Should Contain    You logged out of the secure area!


*** Keywords ***
Enter Credentials
    [Documentation]    Type username and password into the login form.
    [Arguments]    ${username}    ${password}
    Wait For Elements State    ${USERNAME_FIELD}    visible    ${TIMEOUT}
    Fill Text    ${USERNAME_FIELD}    ${username}
    Fill Text    ${PASSWORD_FIELD}    ${password}

Click Login
    [Documentation]    Submit the login form.
    Wait And Click Element    ${LOGIN_BUTTON}

Current Url Should Be
    [Documentation]    Wait for navigation to settle and assert the current URL.
    [Arguments]    ${expected_url}
    Wait For Load State    networkidle
    Get Url    ==    ${expected_url}

Flash Should Contain
    [Documentation]    Assert the flash message contains the expected text.
    [Arguments]    ${expected_text}
    Wait For Elements State    ${FLASH_MESSAGE}    visible    ${TIMEOUT}
    Get Text    ${FLASH_MESSAGE}    contains    ${expected_text}
