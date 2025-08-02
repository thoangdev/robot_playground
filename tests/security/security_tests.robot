*** Settings ***
Documentation    Security testing suite with OWASP ZAP integration
Resource         ../resources/common.robot
Library          ../resources/SecurityUtils.py
Suite Setup      Security Suite Setup
Suite Teardown   Security Suite Teardown
Test Setup       Security Test Setup
Test Teardown    Security Test Teardown

*** Variables ***
${TARGET_URL}        ${BASE_URL}
${TEST_API_URL}      ${API_BASE_URL}/users

*** Test Cases ***
Basic Security Spider Scan
    [Documentation]    Perform a basic spider scan to discover application structure
    [Tags]             security    spider    discovery
    
    ${zap_enabled}=    Is Zap Proxy Enabled
    Skip If    not ${zap_enabled}    ZAP proxy not configured - skipping security tests
    
    # Start spider scan
    ${scan_id}=    Start Security Spider Scan    ${TARGET_URL}
    Log    Spider scan started with ID: ${scan_id}
    
    # Wait for scan completion
    Wait For Spider Scan Complete    ${scan_id}    timeout=300
    
    # Generate basic report
    ${report_path}=    Generate Security Report    HTML    spider-security-report.html
    Log    Spider scan report generated: ${report_path}

API Security Scan
    [Documentation]    Perform security testing on API endpoints
    [Tags]             security    api    active-scan
    
    ${zap_enabled}=    Is Zap Proxy Enabled
    Skip If    not ${zap_enabled}    ZAP proxy not configured - skipping security tests
    
    # First, do some API calls to populate ZAP's understanding
    Create API Session    security_api    ${API_BASE_URL}
    
    # Make some API requests through the proxy
    TRY
        ${response}=    GET On Session    security_api    /users    expected_status=any
        Log    API request made through ZAP proxy: ${response.status_code}
    EXCEPT    AS    ${error}
        Log    API request failed (expected in test environment): ${error}    WARN
    END
    
    # Start active security scan on API
    ${scan_id}=    Start Security Active Scan    ${TEST_API_URL}
    Log    Active scan started with ID: ${scan_id}
    
    # Wait for scan completion (shorter timeout for API)
    Wait For Active Scan Complete    ${scan_id}    timeout=300
    
    # Check for vulnerabilities
    Verify No High Risk Vulnerabilities    ${API_BASE_URL}

Web Application Security Scan
    [Documentation]    Comprehensive security scan of web application
    [Tags]             security    web    comprehensive
    
    ${zap_enabled}=    Is Zap Proxy Enabled
    Skip If    not ${zap_enabled}    ZAP proxy not configured - skipping security tests
    
    # Browse the application to let ZAP learn about it
    Open Browser To Base URL    ${TARGET_URL}
    
    TRY
        # Navigate through key pages
        Go To    ${TARGET_URL}
        Sleep    2s    # Allow page to load
        
        # Try to visit common paths
        Go To    ${TARGET_URL}/login
        Sleep    1s
        
        Go To    ${TARGET_URL}/about
        Sleep    1s
        
    EXCEPT    AS    ${error}
        Log    Navigation failed (expected in test environment): ${error}    WARN
    FINALLY
        Close Browser
    END
    
    # Start spider scan first
    ${spider_scan_id}=    Start Security Spider Scan    ${TARGET_URL}
    Wait For Spider Scan Complete    ${spider_scan_id}    timeout=300
    
    # Then start active scan
    ${active_scan_id}=    Start Security Active Scan    ${TARGET_URL}
    Wait For Active Scan Complete    ${active_scan_id}    timeout=600
    
    # Verify security posture
    Verify No High Risk Vulnerabilities    ${TARGET_URL}

Generate Comprehensive Security Report
    [Documentation]    Generate a comprehensive security report
    [Tags]             security    reporting
    
    ${zap_enabled}=    Is Zap Proxy Enabled
    Skip If    not ${zap_enabled}    ZAP proxy not configured - skipping security tests
    
    # Generate HTML report
    ${html_report}=    Generate Security Report    HTML    comprehensive-security-report.html
    Log    HTML security report generated: ${html_report}
    
    # Generate XML report for CI/CD processing
    ${xml_report}=    Generate Security Report    XML    comprehensive-security-report.xml
    Log    XML security report generated: ${xml_report}
    
    # Get and log security alerts summary
    ${alerts}=    Get Zap Alerts    ${BASE_URL}
    ${alert_count}=    Get Length    ${alerts}
    Log    Total security alerts found: ${alert_count}
    
    # Log summary by risk level
    ${high_risk}=    Count Alerts By Risk Level    ${alerts}    High
    ${medium_risk}=    Count Alerts By Risk Level    ${alerts}    Medium
    ${low_risk}=    Count Alerts By Risk Level    ${alerts}    Low
    ${info_risk}=    Count Alerts By Risk Level    ${alerts}    Informational
    
    Log    Security Alert Summary:
    Log    - High Risk: ${high_risk}
    Log    - Medium Risk: ${medium_risk}
    Log    - Low Risk: ${low_risk}
    Log    - Informational: ${info_risk}

*** Keywords ***
Security Suite Setup
    [Documentation]    Setup for security testing suite
    ${zap_enabled}=    Is Zap Proxy Enabled
    
    IF    ${zap_enabled}
        Log    ZAP proxy detected - security testing enabled
        Clear Security Session
    ELSE
        Log    ZAP proxy not configured - security tests will be skipped    WARN
    END

Security Suite Teardown
    [Documentation]    Cleanup after security testing
    ${zap_enabled}=    Is Zap Proxy Enabled
    
    IF    ${zap_enabled}
        # Generate final comprehensive report
        TRY
            Generate Security Report    HTML    final-security-report.html
            Log    Final security report generated successfully
        EXCEPT    AS    ${error}
            Log    Failed to generate final security report: ${error}    WARN
        END
    END
    
    Close All Browsers And Sessions

Security Test Setup
    [Documentation]    Setup for individual security tests
    Log    Starting security test case

Security Test Teardown
    [Documentation]    Cleanup after individual security tests
    # Close any open browsers
    TRY
        Close All Browsers
    EXCEPT
        Log    No browsers to close    DEBUG
    END

Count Alerts By Risk Level
    [Documentation]    Count security alerts by risk level
    [Arguments]        ${alerts}    ${risk_level}
    
    ${count}=    Set Variable    0
    FOR    ${alert}    IN    @{alerts}
        ${alert_risk}=    Get From Dictionary    ${alert}    risk    default=Unknown
        IF    '${alert_risk}' == '${risk_level}'
            ${count}=    Evaluate    ${count} + 1
        END
    END
    
    RETURN    ${count}
