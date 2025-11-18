# **Abstract: Oracle APEX with AI and 23AI - AI for database-driven applications**

# Oracle APEX in combination with the 23AI platform is an incredible solution that allows you to
# integrate artificial intelligence directly into your database-driven APEX applications.

# From AI integrated into the database to AI-powered functionality in the APEX application, we'll
# show you how machine learning, predictive analytics and natural language processing are seamlessly
# integrated to generate intelligent insights.
# We'll also demonstrate how AI is integrated into the database and how these technologies can be
# implemented in an APEX application to deliver concrete, data-driven results.
# WKSP_MLEGENAI 2024_APEX_Dev

## environment ##
DB: 23ai
APEX: 24.2



# DEMO 1
## Create Data Model with A1
### SCHEMA GENERATION USING APEX GEN AI SERVICES

please create a table for emailing called “eml_recipients” add metadata column as json format, a subject column as varchar2, a body column as json format and a recipient with 10 example data using email sonja.meyer@oracle.com exclusively and in body create email text like an invitiation for an event on the sunny roof in my database 26ai. please separate email content as child table called “EML_EMAIL_CONTENT” and recipient table as parent table in separate tables.
    
    # unter SQL Scripts: DEMO1_create data model event parent child


### FROM SQL SCRIPT TO APPLICATION
please create an app "Email Management App NEW" for my email data from tables EML_RECIPIENTS and EML_EMAIL_CONTENT.
it has 1st page as interactive grid called "Email Recipients", 
2nd page smart filter called "Emails Overview" 
    which calls a form with the name "Add Email Content"
    and you can add or modify data here. No breadcrumb for this form page.

    # unter SQL Scripts: create_app_NL

### improve sql script
    DEMO1_create data model event parent child

    and run the AI Assist with explain and improve


# Demo 2 Oracle Code Assist

in VSCode wechseln und kurz extension erwähnen und zeigen. dann

- in folder src/typescript die Datei "sampleData example.ts" auswählen und über CLINE kommentieren lassen:
    @"/src/typescript/sampleData example.ts"  please add comments

- package.json auswählen und das Bundle generieren via cline
    @/package.json  generate bundle.js


## APEX MLE environment setup.
    1. copy the content of the bundle.js file and create SAMPLE_DATA_MODULE

    2. SQL Commands and do a testrun : 
        - MLE - generate Sample EMAILS
        - MLE - generateSampleRecipients

    2. VALIDATOR MODULE create via URL = https://cdn.jsdelivr.net/npm/validator@13.15.23/+esm

    3. EMAIL_SUBJECT_VALIDATION = EMAIL_SUBJECT_VALIDATION create

    4. CREATE MLE ENV =  EMAIL_VALIDATE create env

    5. assign the mle env to app shared components


# Demo 3 

    1. email validation page 1
        - APEX - create new incorrect email (Garfield@test.de)
        - page config dynamic action 

    2. email sample data 
        - APEX Button "Create Example Data"
        - page create_example_data 

    3. email page 3 email-subject-validation
        - APEX Form change metadata
        - page validation on P3_METADATA


