*** Settings ***
Documentation    Mobile smoke suite using AppiumLibrary.
...    Disabled by default so CI stays infrastructure-free.
...    Set RUN_MOBILE_TESTS=true with Appium/device variables to execute.

Resource    ../resources/mobile.robot

Suite Setup    Require Mobile Test Environment
Suite Teardown    Close Mobile Applications
Test Setup    Open Configured Mobile Application
Test Teardown    Take Mobile Screenshot On Failure


*** Test Cases ***
Mobile Application Launches
    [Documentation]    Opens the configured Android/iOS app and verifies the first screen is inspectable.
    [Tags]    mobile    smoke    appium    positive

    Verify Mobile App Is Ready
