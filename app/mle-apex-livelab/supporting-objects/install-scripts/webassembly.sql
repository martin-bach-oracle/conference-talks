  CREATE TABLE "WASM_MODULES" 
   (	"MODULE_NAME" VARCHAR2(255) NOT NULL ENABLE, 
	"MODULE_VERSION" VARCHAR2(255), 
	"MODULE_BLOB" BLOB, 
	"MODULE_COMMENT" VARCHAR2(255), 
	 CONSTRAINT "PK_WASM_MODULES" PRIMARY KEY ("MODULE_NAME", "MODULE_VERSION")
  USING INDEX  ENABLE
   ) ; 
  
create or replace mle module photon 
language javascript
using blob
    select
        module_blob
    from
        wasm_modules
    where
        module_name = 'photon_rs.js'
        and module_version = '0.3.3';
/

-- followed by the actual Web Assembly module
create or replace mle module photon_wasm
language wasm
using blob
    select
        module_blob
    from
        wasm_modules
    where
        module_name = 'photon_rs_bg.wasm'
        and module_version = '0.3.3';
/

CREATE OR REPLACE MLE ENV "MLE_EXIF_ENV" IMPORTS (
  'photon-module' MODULE "MLE_PHOTON_MODULE",
  'realness-score-module' MODULE "MLE_REALNESS_SCORE_MODULE",
  'exifr-module' MODULE "MLE_EXIFR_MODULE",
  'gemini-ai-verify-module' MODULE "MLE_GEMINI_AI_VERIFY_MODULE",
  'photon' MODULE "PHOTON"
);