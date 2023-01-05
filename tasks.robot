*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Excel.Files
Library             RPA.PDF
Library             RPA.Tables
Library             RPA.Desktop
Library             RPA.Archive


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Download the csv file
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Log    Found ROW: ${row}
        Fill the form    ${row}
        Preview the robot

        Wait Until Keyword Succeeds    10x    0.05 sec    Submit the order

        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Download the csv file
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True

Close the annoying modal
    Click Button When Visible    xpath://*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]

Get orders
    ${table}=    Read table from CSV    orders.csv
    Log    Found columns: ${table}
    RETURN    ${table}

Fill the form
    [Arguments]    ${row}
    Select From List By Value    head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${row}[Legs]
    Input Text    address    ${row}[Address]

Preview the robot
    Click Button    preview

Submit the order
    Click Button    order
    #Wait Until Keyword Succeeds    10x    0.05 sec    Submit the order
    Wait Until Page Contains Element    order-another

Go to order another robot
    #Wait Until Page Contains Element    order-another
    Click Button    order-another

Store the receipt as a PDF file
    [Arguments]    ${row}
    Wait Until Element Is Visible    id:receipt
    ${receipt}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt}    ${OUTPUT_DIR}${/}RECEIPTS${/}receipts${row}.pdf
    RETURN    ${OUTPUT_DIR}${/}RECEIPTS${/}receipts${row}.pdf

Take a screenshot of the robot
    [Arguments]    ${row}
    Wait Until Element Is Visible    id:robot-preview-image

    #Take Screenshot    ${OUTPUT_DIR}${/}robot${row}.jpg    robot-preview-image    True
    Capture Element Screenshot    xpath://*[@id="robot-preview"]    ${OUTPUT_DIR}${/}robot${row}.jpg
    RETURN    ${OUTPUT_DIR}${/}robot${row}.jpg

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    Add Watermark Image To Pdf    ${screenshot}    ${pdf}
    #Add Files To Pdf    ${pdf}
    Close Pdf

Create a ZIP file of the receipts
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}${/}PDFs.zip
    Archive Folder With Zip    ${OUTPUT_DIR}${/}RECEIPTS    ${zip_file_name}
