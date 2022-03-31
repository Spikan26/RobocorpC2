*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium    auto_close=${False}
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.FileSystem
Library           RPA.HTTP
Library           RPA.Robocorp.Vault
Library           Dialogs

*** Tasks ***
Orders robots from RobotSpareBin Industries Inc.
    ${url_csv}=    Ask user for CSV Url
    ${vault}=    Get Secret    credentials
    Open the robot order website    ${vault}
    ${orders}=    Get orders    ${url_csv}
    FOR    ${row}    IN    @{orders}
        Close the modal
        Fill the form    ${row}
        Preview the robot
        Wait Until Keyword Succeeds    5x    1s    Submit the order
        ${pdf}=    Store the receipt as a PDF    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create ZIP file of receipts
    [Teardown]    Clean receipt folder

*** Keywords ***
Ask user for CSV Url
    ${response}=    Get Value From User    Enter the CSV Url
    [Return]    ${response}

Open the robot order website
    [Arguments]    ${vault}
    Open Browser    ${vault}[url_web]    chrome

Get orders
    [Arguments]    ${url_csv}
    Download    ${url_csv}    ${OUTPUT_DIR}${/}input${/}orders.csv    overwrite=True
    ${orders}=    Read table from CSV    ${OUTPUT_DIR}${/}input${/}orders.csv    header=True
    Empty Directory    ${OUTPUT_DIR}${/}input
    [Return]    ${orders}

Close the modal
    Click Button    css:button.btn-danger

Fill the form
    [Arguments]    ${row}
    Select From List By Value    id:head    ${row}[Head]
    Click Element    id-body-${row}[Body]
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${row}[Legs]
    Input Text    id:address    ${row}[Address]

Preview the robot
    Click Button    id:preview

Submit the order
    Click Button    id:order
    Element Should Be Visible    id:order-completion

Store the receipt as a PDF
    [Arguments]    ${order_number}
    ${receipt}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt}    ${OUTPUT_DIR}${/}receipts${/}${order_number}.pdf
    [Return]    ${OUTPUT_DIR}${/}receipts${/}${order_number}.pdf

Take a screenshot of the robot
    [Arguments]    ${order_number}
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}receipts${/}${order_number}.png
    [Return]    ${OUTPUT_DIR}${/}receipts${/}${order_number}.png

Embed the robot screenshot to the receipt
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    Add Watermark Image To Pdf    ${screenshot}    ${pdf}
    Close Pdf    ${pdf}
    Remove File    ${screenshot}

Go to order another robot
    Click Button    id:order-another

Create ZIP file of receipts
    Archive Folder With Zip    ${OUTPUT_DIR}${/}receipts    ${OUTPUT_DIR}${/}output${/}all_receipts.zip

Clean receipt folder
    Empty Directory    ${OUTPUT_DIR}${/}receipts
