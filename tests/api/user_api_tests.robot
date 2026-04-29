*** Settings ***
Documentation    API test suite using JSONPlaceholder (https://jsonplaceholder.typicode.com)
...    This free public API simulates a real REST back-end — no auth, no setup.
...    Replace BASE_URL with your own API when integrating this template.

Resource    ../resources/common.robot
Library    Collections

Suite Setup    Create API Session
Suite Teardown    Delete All Sessions


*** Variables ***
${USER_ID}    1


*** Test Cases ***
Get All Users
    [Documentation]    GET /users returns a non-empty list with the expected fields
    [Tags]    api    smoke    get

    ${response}=    GET On Session    api    /users
    Verify API Response    ${response}    200
    ${users}=    Set Variable    ${response.json()}
    Should Be True    len(${users}) > 0
    Dictionary Should Contain Key    ${users}[0]    id
    Dictionary Should Contain Key    ${users}[0]    name
    Dictionary Should Contain Key    ${users}[0]    email
    Log    Retrieved ${users.__len__()} users

Get Single User
    [Documentation]    GET /users/{id} returns the expected user object
    [Tags]    api    smoke    get

    ${response}=    GET On Session    api    /users/${USER_ID}
    Verify API Response    ${response}    200
    ${user}=    Set Variable    ${response.json()}
    Should Be Equal As Integers    ${user}[id]    ${USER_ID}
    Dictionary Should Contain Key    ${user}    name
    Dictionary Should Contain Key    ${user}    email

Get Non-existent User Returns 404
    [Documentation]    GET /users/{id} for an id that does not exist returns 404
    [Tags]    api    negative    get

    ${response}=    GET On Session    api    /users/9999    expected_status=404
    Should Be Equal As Strings    ${response.status_code}    404

Get User Posts (nested resource)
    [Documentation]    GET /users/{id}/posts returns posts belonging to that user
    [Tags]    api    get    nested

    ${response}=    GET On Session    api    /users/${USER_ID}/posts
    Verify API Response    ${response}    200
    ${posts}=    Set Variable    ${response.json()}
    Should Be True    len(${posts}) > 0
    FOR    ${post}    IN    @{posts}
        Should Be Equal As Integers    ${post}[userId]    ${USER_ID}
    END

Create New User
    [Documentation]    POST /users returns 201 with an id assigned to the new record
    [Tags]    api    smoke    post    crud

    ${email}=    Generate Test Data    email
    ${payload}=    Create Dictionary    name=QA Tester    email=${email}    username=qa_tester

    ${response}=    POST On Session    api    /users    json=${payload}
    Verify API Response    ${response}    201
    ${created}=    Set Variable    ${response.json()}
    Dictionary Should Contain Key    ${created}    id
    Should Be Equal    ${created}[name]    ${payload}[name]
    Should Be Equal    ${created}[email]    ${payload}[email]

Update Existing User
    [Documentation]    PUT /users/{id} returns 200 with the updated fields
    [Tags]    api    put    crud

    ${payload}=    Create Dictionary    name=Updated Name    email=updated@example.com

    ${response}=    PUT On Session    api    /users/${USER_ID}    json=${payload}
    Verify API Response    ${response}    200
    ${updated}=    Set Variable    ${response.json()}
    Should Be Equal    ${updated}[name]    ${payload}[name]
    Should Be Equal    ${updated}[email]    ${payload}[email]

Patch Existing User
    [Documentation]    PATCH /users/{id} updates a subset of fields
    [Tags]    api    patch    crud

    ${payload}=    Create Dictionary    name=Patched Name

    ${response}=    PATCH On Session    api    /users/${USER_ID}    json=${payload}
    Verify API Response    ${response}    200
    ${patched}=    Set Variable    ${response.json()}
    Should Be Equal    ${patched}[name]    ${payload}[name]

Delete User
    [Documentation]    DELETE /users/{id} returns 200 (JSONPlaceholder convention)
    [Tags]    api    delete    crud

    ${response}=    DELETE On Session    api    /users/${USER_ID}
    Should Be Equal As Strings    ${response.status_code}    200
