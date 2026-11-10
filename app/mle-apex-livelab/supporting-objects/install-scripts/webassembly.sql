
  
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

create or replace mle module mle_photon_module language javascript as
import source photonWasm from "photon_wasm";
import * as photon from "photon";

export function errorLevelImage(blob) {
    if (!blob || blob.length() === 0) return null;
    photon.initSync({ module: photonWasm });
    const original = photon.PhotonImage.new_from_byteslice(blob.getData());
    let recompressed;
    let result;
    try {
        const width = original.get_width();
        const height = original.get_height();
        if (width * height > 16000000) throw new Error('ELA image exceeds 16 megapixels');
        recompressed = photon.PhotonImage.new_from_byteslice(original.get_bytes_jpeg(90));
        const a = original.get_raw_pixels();
        const b = recompressed.get_raw_pixels();
        const diff = new Uint8Array(a.length);
        for (let i = 0; i < a.length; i += 4) {
            diff[i] = Math.min(255, Math.abs(a[i] - b[i]) * 10);
            diff[i + 1] = Math.min(255, Math.abs(a[i + 1] - b[i + 1]) * 10);
            diff[i + 2] = Math.min(255, Math.abs(a[i + 2] - b[i + 2]) * 10);
            diff[i + 3] = 255;
        }
        result = new photon.PhotonImage(diff, width, height);
        const output = OracleBlob.createTemporary(false);
        output.write(1, result.get_bytes());
        return output;
    } finally {
        try { if (result) result.free(); }
        finally { try { if (recompressed) recompressed.free(); } finally { original.free(); } }
    }
}

export function createThumbnail(id) {
    const result = session.execute(
        'select file_blob from mle_data where id = :id and thumbnail is null for update',
        { id: { val: id, type: oracledb.NUMBER } }
    );
    if (result.rows.length !== 1 || !result.rows[0].FILE_BLOB) return;
    const blob = result.rows[0].FILE_BLOB;
    if (blob.length() === 0) throw new Error('Uploaded photo is empty');
    photon.initSync({ module: photonWasm });
    const image = photon.PhotonImage.new_from_byteslice(blob.getData());
    let resized;
    let thumbnail;
    try {
        resized = photon.resize(image, Math.max(1, Math.floor(image.get_width() * 0.1)),
            Math.max(1, Math.floor(image.get_height() * 0.1)), photon.SamplingFilter.Lanczos3);
        thumbnail = OracleBlob.createTemporary(false);
        thumbnail.write(1, resized.get_bytes());
        const update = session.execute('update mle_data set thumbnail = :thumbnail where id = :id and thumbnail is null',
            {thumbnail: {val: thumbnail, type: oracledb.ORACLE_BLOB}, id: {val: id, type: oracledb.NUMBER}});
        if (update.rowsAffected !== 1) throw new Error('Thumbnail update failed');
    } finally {
        try { if (thumbnail) thumbnail.freeTemporary(); }
        finally { try { if (resized) resized.free(); } finally { image.free(); } }
    }
}
export function imageDimensions(blob) {
    if (!blob || blob.length() === 0) return null;
    photon.initSync({ module: photonWasm });
    const image = photon.PhotonImage.new_from_byteslice(blob.getData());
    try { return image.get_width() + ' Ã ' + image.get_height() + ' px'; }
    finally { image.free(); }
}
/

  CREATE OR REPLACE MLE ENV "MLE_EXIF_ENV" IMPORTS (
    'photon_wasm' MODULE "PHOTON_WASM",
    'realness-score-module' MODULE "MLE_REALNESS_SCORE_MODULE",
    'exifr-module' MODULE "MLE_EXIFR_MODULE",
    'gemini-ai-verify-module' MODULE "MLE_GEMINI_AI_VERIFY_MODULE",
    'photon-module' MODULE "MLE_PHOTON_MODULE",
    'photon' MODULE "PHOTON"
);

create or replace function photo_dimensions(p_image blob) 
return varchar2 as
    mle module mle_photon_module
    env mle_exif_env
    signature 'imageDimensions';
/

create or replace function photo_ela(p_image blob) 
return blob as
    mle module mle_photon_module
    env mle_exif_env
    signature 'errorLevelImage';
/

create or replace procedure generate_photo_thumbnail(p_id number) as
    mle module mle_photon_module
    env mle_exif_env
    signature 'createThumbnail';
/