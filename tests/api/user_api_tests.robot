*** Settings ***
Documentation    Sample API test suite demonstrating REST API testing patterns
Resource         ../resources/common.robot
Library          ../resources/TestUtils.py
Library          Collections
Suite Setup      Create API Session
Suite Teardown   Delete All Sessions

*** Variables ***
${USER_ID}            1
${VALID_USER_DATA}    {"name": "John Doe", "email": "john@example.com"}
${INVALID_USER_DATA}  {"name": "", "email": "invalid-email"}

*** Test Cases ***
Get All Users
    [Documentation]    Test retrieving all users via API
    [Tags]             api    smoke    get
    
    ${response}=    GET On Session    api    /users
    Verify API Response    ${response}    200
    ${users}=    Set Variable    ${response.json()}
    Should Be True    len(${users}) > 0
    Log    Retrieved ${len(${users})} users

Get Single User
    [Documentation]    Test retrieving a single user by ID
    [Tags]             api    get
    
    ${response}=    GET On Session    api    /users/${USER_ID}
    Verify API Response    ${response}    200
    ${user}=    Set Variable    ${response.json()}
    Should Contain    ${user}    id
    Should Contain    ${user}    name
    Should Contain    ${user}    email

Create New User
    [Documentation]    Test creating a new user via API
    [Tags]             api    post    crud
    
    ${test_email}=    Generate Test Data    email
    ${user_data}=    Create Dictionary    name=Test User    email=${test_email}
    
    ${response}=    POST On Session    api    /users    json=${user_data}
    Verify API Response    ${response}    201
    ${created_user}=    Set Variable    ${response.json()}
    Should Be Equal    ${created_user['name']}    ${user_data['name']}
    Should Be Equal    ${created_user['email']}    ${user_data['email']}
    
    Set Test Variable    ${CREATED_USER_ID}    ${created_user['id']}

Update Existing User
    [Documentation]    Test updating an existing user via API
    [Tags]             api    put    crud
    [Setup]            Create Test User
    
    ${updated_data}=    Create Dictionary    name=Updated User    email=updated@example.com
    ${response}=    PUT On Session    api    /users/${CREATED_USER_ID}    json=${updated_data}
    Verify API Response    ${response}    200
    ${updated_user}=    Set Variable    ${response.json()}
    Should Be Equal    ${updated_user['name']}    ${updated_data['name']}
    Should Be Equal    ${updated_user['email']}    ${updated_data['email']}

Delete User
    [Documentation]    Test deleting a user via API
    [Tags]             api    delete    crud
    [Setup]            Create Test User
    
    ${response}=    DELETE On Session    api    /users/${CREATED_USER_ID}
    Verify API Response    ${response}    204
    
    # Verify user is deleted
    ${response}=    GET On Session    api    /users/${CREATED_USER_ID}    expected_status=404

Invalid User Creation
    [Documentation]    Test API validation with invalid user data
    [Tags]             api    negative    validation
    
    ${response}=    POST On Session    api    /users    json=${INVALID_USER_DATA}    expected_status=400
    Should Be Equal As Strings    ${response.status_code}    400
    ${error_response}=    Set Variable    ${response.json()}
    Should Contain    ${error_response}    errors

Unauthorized Access
    [Documentation]    Test API security with unauthorized access
    [Tags]             api    security    negative
    
    # Create session without authorization
    Create Session    unauthorized    ${API_BASE_URL}
    ${response}=    GET On Session    unauthorized    /admin/users    expected_status=401
    Should Be Equal As Strings    ${response.status_code}    401

API Rate Limiting
    [Documentation]    Test API rate limiting (if implemented)
    [Tags]             api    performance    rate-limit
    
    FOR    ${i}    IN RANGE    1    11
        ${response}=    GET On Session    api    /users    expected_status=any
        Log    Request ${i}: Status ${response.status_code}
        Exit For Loop If    ${response.status_code} == 429
    END
    
    # Note: This test depends on your API's rate limiting implementation

*** Keywords ***
Create Test User
    [Documentation]    Helper keyword to create a test user for other tests
    ${test_email}=    Generate Test Data    email
    ${user_data}=    Create Dictionary    name=Test User    email=${test_email}
    
    ${response}=    POST On Session    api    /users    json=${user_data}
    Verify API Response    ${response}    201
    ${created_user}=    Set Variable    ${response.json()}
    Set Test Variable    ${CREATED_USER_ID}    ${created_user['id']}
