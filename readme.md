# Conference talks

## DOAG Conference 2026: APEX and server-side JavaScript demo

This branch contains a photo metadata application built with Oracle APEX and server-side JavaScript in the Oracle Database Multilingual Engine (MLE). It draws on the Oracle LiveLabs workshop [APEX + Server-Side JavaScript (MLE)](https://livelabs.oracle.com/ords/r/dbpm/livelabs/view-workshop?wid=822). The workshop provides the background and guided exercises; this repository contains the application as exported for the demo.

The application lets users upload photos, extracts EXIF metadata with JavaScript, stores the metadata and available GPS coordinates, and displays photos and locations. The Photon library is used during the upload to generate a thumbnail of the photo. The application's photo details page also requests an AI assessment of whether an image looks camera-captured or AI-generated. This assessment is an approximation, and its displayed score is not a calibrated probability or proof of authenticity.

### Repository contents

- [`app/mlelivelab120111/`](app/mlelivelab120111/) contains the APEXlang application export, including pages, shared components, static files and supporting objects. Its metadata targets APEXlang 26.1; the deployment file specifies application ID 100.
- [`app/mlelivelab120111/supporting-objects/install-scripts/`](app/mlelivelab120111/supporting-objects/install-scripts/) contains scripts for the `MLE_DATA` table and trigger, MLE modules, and the MLE environment. The export also contains a deinstallation script.
- The livelab cannot feature any third party code. [`stage_files.sh`](stage_files.sh) downloads EXIFR 7.1.3 and Photon 0.3.3 JavaScript and WebAssembly files from jsDelivr into `stage/`. The staging directory is ignored by Git. Staging these files does not itself install them into the database or application.

### Setup considerations

Use an APEX 26.1 environment with an Oracle Database supporting MLE and the required database privileges. Follow the linked LiveLabs workshop for environment setup and the JavaScript library installation. Review the supporting-object scripts before installing them: the exported `MLE_EXIFR_MODULE` contains a placeholder rather than the EXIFR library, so EXIF extraction requires the library to be installed separately. You can find it in the `stage` directory. The export's supporting objects list table and trigger privileges, and creating MLE modules and an environment requires appropriate privileges as well.

The AI implementation currently calls `APEX_AI.GENERATE` with the APEX AI service static ID `google-gemini` and sends the photo as an attachment. Configure a compatible image-capable service and credentials under that static ID for the assessment to work. The code currently references Gemini; Cohere was discussed as an alternative but is not configured by this export. Keep credentials outside the repository.

The APEXlang export and supporting-object scripts are source artifacts; their presence alone does not confirm a successful import or a working runtime in another environment.
