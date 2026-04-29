*** Settings ***
Documentation    Shared AppiumLibrary keywords for Android and iOS tests.

Library    Collections
Library    OperatingSystem
Library    String
Library    AppiumLibrary


*** Variables ***
# Set RUN_MOBILE_TESTS=true when an Appium server and device/emulator are ready.
${RUN_MOBILE_TESTS}    %{RUN_MOBILE_TESTS=false}
${MOBILE_PLATFORM}    %{MOBILE_PLATFORM=android}
${MOBILE_APPIUM_SERVER}    %{MOBILE_APPIUM_SERVER=http://127.0.0.1:4723}
${MOBILE_STARTUP_LOCATOR}    %{MOBILE_STARTUP_LOCATOR=}
${MOBILE_TIMEOUT}    %{MOBILE_TIMEOUT=20s}

# Android capabilities.
${ANDROID_AUTOMATION_NAME}    %{ANDROID_AUTOMATION_NAME=UiAutomator2}
${ANDROID_PLATFORM_NAME}    Android
${ANDROID_PLATFORM_VERSION}    %{ANDROID_PLATFORM_VERSION=}
${ANDROID_DEVICE_NAME}    %{ANDROID_DEVICE_NAME=Android Emulator}
${ANDROID_APP}    %{ANDROID_APP=}
${ANDROID_APP_PACKAGE}    %{ANDROID_APP_PACKAGE=}
${ANDROID_APP_ACTIVITY}    %{ANDROID_APP_ACTIVITY=}

# iOS capabilities.
${IOS_AUTOMATION_NAME}    %{IOS_AUTOMATION_NAME=XCUITest}
${IOS_PLATFORM_NAME}    iOS
${IOS_PLATFORM_VERSION}    %{IOS_PLATFORM_VERSION=}
${IOS_DEVICE_NAME}    %{IOS_DEVICE_NAME=iPhone Simulator}
${IOS_APP}    %{IOS_APP=}
${IOS_BUNDLE_ID}    %{IOS_BUNDLE_ID=}


*** Keywords ***
Require Mobile Test Environment
    [Documentation]    Skip mobile suites unless explicitly enabled for a configured Appium target.
    ${enabled}=    Convert To Boolean    ${RUN_MOBILE_TESTS}
    IF    not ${enabled}
        Skip    Mobile tests disabled. Set RUN_MOBILE_TESTS=true with Appium/device variables to run them.
    END

Open Configured Mobile Application
    [Documentation]    Open the configured Android or iOS application through AppiumLibrary.
    Require Mobile Test Environment
    ${platform}=    Convert To Lower Case    ${MOBILE_PLATFORM}
    IF    '${platform}' == 'android'
        Open Android Application
    ELSE IF    '${platform}' == 'ios'
        Open Ios Application
    ELSE
        Fail    Unsupported MOBILE_PLATFORM: ${MOBILE_PLATFORM}. Expected android or ios.
    END

Open Android Application
    [Documentation]    Open Android app with either app path or appPackage/appActivity capabilities.
    ${capabilities}=    Create Dictionary
    ...    automationName=${ANDROID_AUTOMATION_NAME}
    ...    platformName=${ANDROID_PLATFORM_NAME}
    ...    deviceName=${ANDROID_DEVICE_NAME}
    Add Capability If Set    ${capabilities}    platformVersion    ${ANDROID_PLATFORM_VERSION}
    Add Capability If Set    ${capabilities}    app    ${ANDROID_APP}
    Add Capability If Set    ${capabilities}    appPackage    ${ANDROID_APP_PACKAGE}
    Add Capability If Set    ${capabilities}    appActivity    ${ANDROID_APP_ACTIVITY}
    Open Application    ${MOBILE_APPIUM_SERVER}    &{capabilities}

Open Ios Application
    [Documentation]    Open iOS app with either app path or bundleId capabilities.
    ${capabilities}=    Create Dictionary
    ...    automationName=${IOS_AUTOMATION_NAME}
    ...    platformName=${IOS_PLATFORM_NAME}
    ...    deviceName=${IOS_DEVICE_NAME}
    Add Capability If Set    ${capabilities}    platformVersion    ${IOS_PLATFORM_VERSION}
    Add Capability If Set    ${capabilities}    app    ${IOS_APP}
    Add Capability If Set    ${capabilities}    bundleId    ${IOS_BUNDLE_ID}
    Open Application    ${MOBILE_APPIUM_SERVER}    &{capabilities}

Add Capability If Set
    [Documentation]    Add a desired capability only when a non-empty value is configured.
    [Arguments]    ${capabilities}    ${name}    ${value}
    IF    '${value}' != '${EMPTY}'
        Set To Dictionary    ${capabilities}    ${name}=${value}
    END

Verify Mobile App Is Ready
    [Documentation]    Verify startup using MOBILE_STARTUP_LOCATOR when provided.
    IF    '${MOBILE_STARTUP_LOCATOR}' != '${EMPTY}'
        Wait Until Page Contains Element    ${MOBILE_STARTUP_LOCATOR}    ${MOBILE_TIMEOUT}
    ELSE
        ${source}=    Get Source
        Should Not Be Empty    ${source}
    END

Take Mobile Screenshot On Failure
    [Documentation]    Capture an Appium screenshot when a mobile test fails.
    IF    '${TEST STATUS}' == 'FAIL'
        Run Keyword And Ignore Error    Create Directory    ${OUTPUT DIR}/screenshots
        Run Keyword And Ignore Error
        ...    Capture Page Screenshot
        ...    ${OUTPUT DIR}/screenshots/appium-screenshot-{index}.png
    END

Close Mobile Applications
    [Documentation]    Close all Appium sessions.
    Run Keyword And Ignore Error    Close All Applications
