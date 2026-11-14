# Conference talks

## DOAG Conference 2026: APEX and server-side JavaScript demo

This branch contains a photo metadata application built with Oracle APEX and server-side JavaScript in the Oracle Database Multilingual Engine (MLE). It draws on the Oracle LiveLabs workshop [APEX + Server-Side JavaScript (MLE)](https://livelabs.oracle.com/ords/r/dbpm/livelabs/view-workshop?wid=822). The workshop provides the background and guided exercises; this repository contains the application as exported for the demo.

The application lets users upload photos, extract EXIF metadata with JavaScript, store available GPS coordinates, and display photos and locations. It uses Photon, running as WebAssembly through MLE, to create thumbnails and perform error level analysis (ELA) on JPEG images. Bright areas in an ELA image indicate compression differences, not proof of manipulation.

The photo details page also requests an AI assessment of whether an image looks camera-captured or AI-generated. This assessment is an approximation, and its displayed score is not a calibrated probability or proof of authenticity.

### Application pages

- **Photo Metadata (page 1):** Upload a photo using **Add Post** and browse the timeline. The page extracts available EXIF data and GPS coordinates. Thumbnail creation runs in a background execution chain; JPEG uploads also start a separate ELA chain. JPEG is recommended to see both demonstrations.
- **Photo Metadata Details (page 2):** View the photo, extracted EXIF fields and map location. The page requests a Google Gemini assessment through the configured APEX AI service and displays a realness score and explanation. For a `real` classification the score uses the model's confidence; for `ai-generated` it uses 100 minus that confidence. An inconclusive result displays a neutral 50%. These values are not a forensic determination.
- **WebAssembly (page 3):** Browse generated PNG thumbnails with the original and thumbnail dimensions and encoded BLOB sizes. The information is read from `MLE_DATA.IMAGE_DIMENSION`, which is populated during thumbnail creation. A message indicates when photos have no thumbnail; it cannot distinguish an unfinished job from a failed one.
- **WebAssembly ELA (page 4):** Compare the photo most recently opened on page 2 with its stored ELA image. When both are available, the page sends the original JPEG and ELA image to the configured AI service for a short summary beside the hero and a detailed observation below the images. If the images together exceed 12 MiB, it sends an ELA preview limited to 1,024 pixels on its longest side instead. If even that pair exceeds the limit, the page asks for a smaller JPEG. The observation cannot establish authenticity or identify the cause of a difference.
- **Background Jobs (page 5):** View this application's queued, scheduled and executing APEX background jobs alongside pending or failed ELA results. Use **Refresh status** to update both reports. A pending ELA row can remain after its job stops; ELA errors recorded by the application can also occur when the execution chain itself reports success.

The page heroes and the application-wide `slide-theme.css` use a dark palette inspired by the presentation slides.

### Background image processing

The page 1 thumbnail chain creates a PNG at 10% of the original width and height, with each dimension at least one pixel. It stores the image in `MLE_DATA.THUMBNAIL` and the dimensions and byte sizes in `MLE_DATA.IMAGE_DIMENSION`. The separate ELA chain processes eligible new JPEG uploads, so the thumbnail job can finish independently. Jobs may still be queued by APEX, and a page refresh may be needed to see a completed thumbnail.

`MLE_DATA_ELA` stores at most one result per photo, with a foreign key to `MLE_DATA` that cascades on deletion. It contains the ELA image, JSON metadata and a `PENDING`, `READY` or `FAILED` status; an error message is stored for failures handled by the ELA step. New results are JPEGs; existing PNG results remain readable and are not converted. Existing photos are not automatically backfilled. If a background job does not reach the ELA step, a row can remain pending; check the APEX background execution for details.

ELA decodes the original image, recompresses it as JPEG at quality 90, compares RGB pixels and amplifies differences by a factor of 10. The resulting image is encoded as JPEG at quality 95, retaining its pixel dimensions but potentially changing subtle differences because JPEG is lossy. It accepts JPEG uploads and limits decoded images to 16 megapixels. Processing can be slow, and a JPEG is not guaranteed to fit the AI service's size limit. A dark image can contain differences too small to see and does not establish that a photo is authentic or unmodified.

The Background Jobs page shows active jobs and unresolved ELA results. For completed execution history and additional diagnostics, use the Debug Viewer in APEX App Builder with **View: Background Executions**. The following query lists the most recent page 1 background executions when run in the appropriate APEX workspace context:

```sql
select execution_id, process_name, current_process_name,
       status_code, status_message
  from apex_appl_page_bg_proc_status
 where application_id = 100 and page_id = 1
 order by execution_id desc
 fetch first 20 rows only;
```

ELA failures caught by the application are recorded in `MLE_DATA_ELA.ERROR_MESSAGE` and do not necessarily mark the overall background execution as failed.

### Repository contents

- [`app/mle-apex-livelab/`](app/mle-apex-livelab/) contains the APEXlang application export, including pages, shared components, static files and supporting objects. Its alias is `MLE-APEX-LIVELAB`, its metadata targets APEXlang 26.1, and its deployment file specifies application ID 100.
- [`app/mle-apex-livelab/supporting-objects/install-scripts/`](app/mle-apex-livelab/supporting-objects/install-scripts/) contains scripts for `MLE_DATA`, `MLE_DATA_ELA`, `WASM_MODULES`, the trigger, JavaScript modules, and WebAssembly objects. `webassembly.sql` defines the Photon library modules, `MLE_EXIF_ENV`, and the photo function and procedure call specifications.
- [`stage_files.sh`](stage_files.sh) downloads EXIFR 7.1.3 and Photon 0.3.3 JavaScript and WebAssembly files from jsDelivr into `stage/`. Third-party library code is not included in the repository; the staging directory is ignored by Git.

### Setup considerations

Use an APEX 26.1 environment with an Oracle Database supporting MLE and WebAssembly, and the required privileges, including those needed for APEX background jobs. Follow the linked LiveLabs workshop for environment setup and library installation. Run `./stage_files.sh` to download the library files. Staging does not load them into the database: load `stage/exifr.js` into `WASM_MODULES` as a BLOB with version `7.1.3`, and load `stage/photon_rs.js` and `stage/photon_rs_bg.wasm` with version `0.3.3`. Use the filename as `MODULE_NAME` for each row.

Review the supporting scripts before installation. `mle-objects.sql` creates `WASM_MODULES` and immediately attempts to create `MLE_EXIFR_MODULE` from its rows, with no file-loading step between those operations. `webassembly.sql` then creates the Photon library modules from rows in the same table. The table and all three files must be in place before the corresponding module statements run; staging alone does not arrange this.

`webassembly.sql` also creates `MLE_PHOTON_MODULE` and the `PHOTO_DIMENSIONS`, `PHOTO_ELA`, `PHOTO_AI_PREVIEW`, and `GENERATE_PHOTO_THUMBNAIL` call specifications that depend on it. An existing installation needs the updated MLE module and `PHOTO_AI_PREVIEW` call specification before the updated page 4 can generate its AI explanation.

The page 1 thumbnail process imports `photon-module`, which the scripted `MLE_EXIF_ENV` maps to `MLE_PHOTON_MODULE`. The environment also maps the page imports `exifr-module`, `gemini-ai-verify-module`, and `realness-score-module`, as well as `photon` to the Photon JavaScript bindings.

`MLE_PHOTON_MODULE` loads the WebAssembly module with `import source photonWasm from "photon_wasm"` and imports the Photon JavaScript bindings separately. The supporting script creates `PHOTON_WASM` from the staged WebAssembly binary.

The AI implementation calls `APEX_AI.GENERATE` with the APEX AI service static ID `google-gemini`. Page 2 sends the photo as an attachment; page 4 sends the original JPEG and ELA image or a bounded preview. The service configured under that static ID determines the actual provider. Configure a compatible image-capable service and credentials under that static ID. Keep credentials outside the repository.

The APEXlang export and supporting-object scripts are source artifacts; their presence alone does not confirm a successful import or a working runtime in another environment.
