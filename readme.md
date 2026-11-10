# Conference talks

## DOAG Conference 2026: APEX and server-side JavaScript demo

This branch contains a photo metadata application built with Oracle APEX and server-side JavaScript in the Oracle Database Multilingual Engine (MLE). It draws on the Oracle LiveLabs workshop [APEX + Server-Side JavaScript (MLE)](https://livelabs.oracle.com/ords/r/dbpm/livelabs/view-workshop?wid=822). The workshop provides the background and guided exercises; this repository contains the application as exported for the demo.

The application lets users upload photos, extract EXIF metadata with JavaScript, store available GPS coordinates, and display photos and locations. It uses Photon for thumbnail generation. The WebAssembly pages display original and thumbnail dimensions and sizes, and provide error level analysis (ELA) for JPEG images. Bright areas in an ELA image indicate compression differences, not proof of manipulation.

The photo details page also requests an AI assessment of whether an image looks camera-captured or AI-generated. This assessment is an approximation, and its displayed score is not a calibrated probability or proof of authenticity.

### Repository contents

- [`app/mle-apex-livelab/`](app/mle-apex-livelab/) contains the APEXlang application export, including pages, shared components, static files and supporting objects. Its alias is `MLE-APEX-LIVELAB`, its metadata targets APEXlang 26.1, and its deployment file specifies application ID 100.
- [`app/mle-apex-livelab/supporting-objects/install-scripts/`](app/mle-apex-livelab/supporting-objects/install-scripts/) contains scripts for the `MLE_DATA` and `WASM_MODULES` tables, the trigger, JavaScript modules, and WebAssembly objects. `webassembly.sql` defines the Photon library modules, `MLE_EXIF_ENV`, and the photo function and procedure call specifications.
- [`stage_files.sh`](stage_files.sh) downloads EXIFR 7.1.3 and Photon 0.3.3 JavaScript and WebAssembly files from jsDelivr into `stage/`. Third-party library code is not included in the repository; the staging directory is ignored by Git.

### Setup considerations

Use an APEX 26.1 environment with an Oracle Database supporting MLE and WebAssembly, and the required privileges. Follow the linked LiveLabs workshop for environment setup and library installation. Run `./stage_files.sh` to download the library files. Staging does not load them into the database: load `stage/exifr.js` into `WASM_MODULES` as a BLOB with version `7.1.3`, and load `stage/photon_rs.js` and `stage/photon_rs_bg.wasm` with version `0.3.3`. Use the filename as `MODULE_NAME` for each row.

Review the supporting scripts before installation. `mle-objects.sql` creates `WASM_MODULES` and immediately attempts to create `MLE_EXIFR_MODULE` from its rows, with no file-loading step between those operations. `webassembly.sql` then creates the Photon library modules from rows in the same table. The table and all three files must be in place before the corresponding module statements run; staging alone does not arrange this.

`webassembly.sql` now also creates `MLE_PHOTON_MODULE` and the `PHOTO_DIMENSIONS`, `PHOTO_ELA`, and `GENERATE_PHOTO_THUMBNAIL` call specifications that depend on it. The application-referenced objects identified in the connected schema have corresponding creation statements in the supporting scripts.

The schema also contains `PHOTON_ENV`, `PHOTON_UTILITIES`, `PHOTON_API`, and `UPLOADED_FILES`, none of which is created by the supporting scripts. The inspected application source does not directly reference them; their presence in the schema alone does not establish that the application needs them.

The supporting-object metadata associates `MLE_EXIF_ENV` with `mle-objects.sql`, but its creation statement is in `webassembly.sql`. It also associates `WASM_MODULES` with `webassembly.sql` under the hard-coded owner `EMILY`, although the table creation statement is in `mle-objects.sql`. Review these associations when correcting the export.

The page 1 thumbnail process imports `photon-module`, which `webassembly.sql` and the `MLE_EXIF_ENV` inspected through the `doag-demo` connection map to `MLE_PHOTON_MODULE`. The other page imports—`exifr-module`, `gemini-ai-verify-module`, and `realness-score-module`—also match the inspected environment; it maps `photon` to the Photon JavaScript bindings.

`MLE_PHOTON_MODULE` loads the WebAssembly module with `import source photonWasm from "photon_wasm"` and imports the Photon JavaScript bindings separately. The supporting script creates `PHOTON_WASM` from the staged WebAssembly binary.

The AI implementation currently calls `APEX_AI.GENERATE` with the APEX AI service static ID `google-gemini` and sends the photo as an attachment. Configure a compatible image-capable service and credentials under that static ID for the assessment to work. The code currently references Gemini; Cohere was discussed as an alternative but is not configured by this export. Keep credentials outside the repository.

The APEXlang export and supporting-object scripts are source artifacts; their presence alone does not confirm a successful import or a working runtime in another environment.
