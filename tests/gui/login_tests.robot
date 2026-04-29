*** Settings ***
Documentation    GUI test suite using the-internet.herokuapp.com/login
...    This public demo site provides a stable login form ideal for template examples.
...    Credentials: tomsmith / SuperSecretPassword!
...    Replace BASE_URL and selectors when integrating with your own application.

Resource    ../pages/login_page.robot

Suite Setup    Log    Starting GUI login suite
Suite Teardown    Close All Browsers And Sessions
Test Setup    Open Login Page
Test Teardown    Take Screenshot On Failure


*** Variables ***
${VALID_USERNAME}    tomsmith
${VALID_PASSWORD}    SuperSecretPassword!


*** Test Cases ***
Valid User Login
    [Documentation]    Successful login redirects to the secure area
    [Tags]    gui    smoke    login    positive

    Login With Credentials    ${VALID_USERNAME}    ${VALID_PASSWORD}
    Current Page Should Be Secure Area
    Flash Message Should Contain    You logged into a secure area

Invalid Credentials Login
    [Documentation]    Wrong password shows an error flash message
    [Tags]    gui    regression    login    negative

    Login With Credentials    ${VALID_USERNAME}    wrongpassword
    Flash Message Should Contain    Your password is invalid!

Empty Username Login
    [Documentation]    Submitting with no username shows a validation error
    [Tags]    gui    regression    login    negative    validation

    Login With Credentials    ${EMPTY}    somepassword
    Flash Message Should Contain    Your username is invalid!

User Logout
    [Documentation]    Logging out redirects back to the login page
    [Tags]    gui    smoke    logout    positive

    Login With Credentials    ${VALID_USERNAME}    ${VALID_PASSWORD}
    Current Page Should Be Secure Area
    Logout From Secure Area
    Current Page Should Be Login Page
    Flash Message Should Contain    You logged out of the secure area!
