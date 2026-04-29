*** Settings ***
Documentation    Page Object keywords for the-internet.herokuapp.com login page.

Resource    ../resources/common.robot


*** Variables ***
${LOGIN_PATH}    /login
${SECURE_PATH}    /secure
${USERNAME_FIELD}    css=#username
${PASSWORD_FIELD}    css=#password
${LOGIN_BUTTON}    css=button[type='submit']
${FLASH_MESSAGE}    css=#flash
${LOGOUT_BUTTON}    css=a.button.secondary


*** Keywords ***
Open Login Page
    [Documentation]    Navigate directly to the login page.
    Open Browser To Base URL    ${BASE_URL}${LOGIN_PATH}

Login With Credentials
    [Documentation]    Submit the login form with the supplied credentials.
    [Arguments]    ${username}    ${password}
    Fill Login Form    ${username}    ${password}
    Submit Login Form

Fill Login Form
    [Documentation]    Type username and password into the login form.
    [Arguments]    ${username}    ${password}
    Wait For Elements State    ${USERNAME_FIELD}    visible    ${TIMEOUT}
    Fill Text    ${USERNAME_FIELD}    ${username}
    Fill Text    ${PASSWORD_FIELD}    ${password}

Submit Login Form
    [Documentation]    Submit the login form.
    Wait And Click Element    ${LOGIN_BUTTON}

Logout From Secure Area
    [Documentation]    Click the logout button from the secure area.
    Wait And Click Element    ${LOGOUT_BUTTON}

Current Page Should Be Login Page
    [Documentation]    Assert the browser is on the login page.
    Current Url Should Be    ${BASE_URL}${LOGIN_PATH}

Current Page Should Be Secure Area
    [Documentation]    Assert the browser is on the secure area page.
    Current Url Should Be    ${BASE_URL}${SECURE_PATH}

Flash Message Should Contain
    [Documentation]    Assert the flash message contains expected text.
    [Arguments]    ${expected_text}
    Wait For Elements State    ${FLASH_MESSAGE}    visible    ${TIMEOUT}
    Get Text    ${FLASH_MESSAGE}    contains    ${expected_text}

Current Url Should Be
    [Documentation]    Wait for navigation to settle and assert the current URL.
    [Arguments]    ${expected_url}
    Wait For Load State    networkidle
    Get Url    ==    ${expected_url}
