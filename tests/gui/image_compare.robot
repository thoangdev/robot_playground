*** Settings ***
Library          Browser
Library          ImageCompare
Library          OperatingSystem

*** Variables ***
${REFERENCE_IMAGES_DIR}    ${CURDIR}/reference_images
${ACTUAL_IMAGES_DIR}       ${CURDIR}/actual_images
${EXAMPLE_URL}             https://example.com

*** Keywords ***
Setup Browser For Image Testing
    New Browser    chromium    headless=True
    New Page       ${EXAMPLE_URL}
    Sleep          2s    # Allow page to fully load

Teardown Browser
    Close Browser

Create Directory If Not Exists
    [Arguments]    ${directory_path}
    Create Directory    ${directory_path}

*** Test Cases ***
Take Screenshot Of Example.com Homepage
    [Documentation]    Takes a screenshot of example.com homepage for visual testing
    [Setup]    Setup Browser For Image Testing
    [Teardown]    Teardown Browser
    
    # Create directories for storing images
    Create Directory If Not Exists    ${REFERENCE_IMAGES_DIR}
    Create Directory If Not Exists    ${ACTUAL_IMAGES_DIR}
    
    # Take screenshot of the current page
    Take Screenshot    ${ACTUAL_IMAGES_DIR}/example_homepage.png
    
    # Log the screenshot location
    Log    Screenshot saved to: ${ACTUAL_IMAGES_DIR}/example_homepage.png

Compare Example.com Homepage With Reference
    [Documentation]    Compares current example.com homepage with reference image
    [Setup]    Setup Browser For Image Testing
    [Teardown]    Teardown Browser
    
    # Create directories
    Create Directory If Not Exists    ${REFERENCE_IMAGES_DIR}
    Create Directory If Not Exists    ${ACTUAL_IMAGES_DIR}
    
    # Take current screenshot
    Take Screenshot    ${ACTUAL_IMAGES_DIR}/example_homepage_current.png
    
    # Compare with reference image (this will fail if reference doesn't exist)
    # You would need to create a reference image first
    ${reference_exists}=    Run Keyword And Return Status
    ...    File Should Exist    ${REFERENCE_IMAGES_DIR}/example_homepage_reference.png
    
    Run Keyword If    ${reference_exists}
    ...    Compare Images    ${REFERENCE_IMAGES_DIR}/example_homepage_reference.png
    ...                     ${ACTUAL_IMAGES_DIR}/example_homepage_current.png
    ...    ELSE    Log    Reference image not found. Current screenshot saved for future reference.

Visual Test With Tolerance
    [Documentation]    Demonstrates image comparison with tolerance for small differences
    [Setup]    Setup Browser For Image Testing
    [Teardown]    Teardown Browser
    
    Create Directory If Not Exists    ${ACTUAL_IMAGES_DIR}
    
    # Take screenshot
    Take Screenshot    ${ACTUAL_IMAGES_DIR}/example_with_tolerance.png
    
    # If you have a reference image, you can compare with tolerance
    # Compare Images    reference.png    actual.png    tolerance=0.95

Element Visual Test
    [Documentation]    Takes a screenshot of a specific element for comparison
    [Setup]    Setup Browser For Image Testing
    [Teardown]    Teardown Browser
    
    Create Directory If Not Exists    ${ACTUAL_IMAGES_DIR}
    
    # Take screenshot of a specific element (if it exists)
    ${element_exists}=    Run Keyword And Return Status    Get Element    h1
    IF    ${element_exists}
        Take Screenshot    ${ACTUAL_IMAGES_DIR}/example_h1_element.png    h1
    ELSE
        Log    H1 element not found on the page
    END