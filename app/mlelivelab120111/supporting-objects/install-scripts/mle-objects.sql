  CREATE OR REPLACE MLE MODULE "MLE_EXIFR_MODULE" 
   LANGUAGE JAVASCRIPT AS 
   
// Get this JavaScript module from your preferred Content Delivery Network as described in the LiveLab
// For License reasons it cannot be bundled with the complete solution

/

  CREATE OR REPLACE MLE MODULE "MLE_GEMINI_AI_VERIFY_MODULE" 
   LANGUAGE JAVASCRIPT
   VERSION '1.0'  AS 
/**
 * Analyze an uploaded image with the configured APEX AI service.
 *
 * This module demonstrates how MLE JavaScript can orchestrate database work and
 * call native APEX functionality. JavaScript controls the flow, while PL/SQL
 * is used to demonstrate the interoperability of both languages.
 *
 * Returned JSON shape:
 * {
 *   status: "ok" | "error" | "no-image",
 *   classification: "real" | "ai-generated" | "inconclusive",
 *   confidence: number | null,
 *   reason: string
 * }
 *
 * @param {number} id - MLE_DATA.ID of the uploaded image record.
 * @returns {string} JSON assessment returned to the APEX page.
 */
export function analyzePhotoWithGemini(id) {
    if (!id) {
        throw new Error("Please provide an image record ID.");
    }

    // First do a cheap database check so we avoid calling Gemini without an image.
    const photo = session.execute(
        `
        select 1 as has_photo
          from mle_data
         where id = :id
           and file_blob is not null
        `,
        { id }
    );

    if (photo.rows.length !== 1) {
        return JSON.stringify({
            status: "no-image",
            classification: "inconclusive",
            confidence: null,
            reason: "No image available for analysis."
        });
    }

    try {
        const result = session.execute(
            `
            declare
                l_file_blob   blob;
                l_file_mime   varchar2(255);
                l_file_name   varchar2(255);
                l_response    clob;
                l_attachments apex_ai.t_attachments := apex_ai.t_attachments();
            begin
                -- Load the image inside PL/SQL so the BLOB stays a native APEX AI attachment.
                select file_blob,
                       nvl(file_mime, 'image/jpeg'),
                       nvl(file_name, 'photo.jpg')
                  into l_file_blob,
                       l_file_mime,
                       l_file_name
                  from mle_data
                 where id = :id;

                -- Build the attachment expected by APEX_AI.GENERATE.
                l_attachments.extend;
                l_attachments(1).mime_type    := l_file_mime;
                l_attachments(1).content_blob := l_file_blob;
                l_attachments(1).file_name    := l_file_name;
                l_attachments(1).detail_level := apex_ai.c_detail_level_high;

                -- APEX manages the endpoint, model, and credential through the AI service static ID.
                l_response := apex_ai.generate(
                    p_service_static_id => 'google-gemini',
                    p_system_prompt     => 'You assess whether a photo is likely camera-captured or AI-generated. Return only valid JSON. No markdown. No code fences.',
                    p_prompt            => 'Return one JSON object with keys: status, classification, confidence, reason. status must be ok. classification must be real, ai-generated, or inconclusive. confidence must be an integer from 0 to 100. Reason must be one short sentence.',
                    p_temperature       => 0.2,
                    p_attachments       => l_attachments
                );

                :assessment := dbms_lob.substr(l_response, 4000, 1);
            end;
            `,
            {
                id,
                assessment: {
                    dir: oracledb.BIND_OUT,
                    type: oracledb.STRING,
                    maxSize: 4000
                }
            }
        );

        return result.outBinds.assessment;
    } catch (err) {
        // Return structured JSON even when the external AI call fails.
        // This keeps the APEX page simple and prevents false score calculations.
        return JSON.stringify({
            status: "error",
            classification: "inconclusive",
            confidence: null,
            reason: `AI assessment unavailable: ${err}`
        });
    }
}
/

  CREATE OR REPLACE MLE MODULE "MLE_REALNESS_SCORE_MODULE" 
   LANGUAGE JAVASCRIPT
   VERSION '1.0'  AS 
/**
 * Helper functions for presenting the Gemini assessment in APEX.
 *
 * The Gemini module returns JSON. This module keeps the UI-facing conversion in
 * JavaScript too, so the APEX page only receives simple display values.
 */

/**
 * Extracts the short text shown in the Google AI Analysis region.
 *
 * @param {string} assessmentJson - JSON returned by MLE_GEMINI_AI_VERIFY_MODULE.
 * @returns {string} Human-readable reason text.
 */
export function getAssessmentReason(assessmentJson) {
    const assessment = parseAssessment(assessmentJson);
    return assessment.reason || assessmentJson || "";
}

/**
 * Converts the structured Gemini assessment into a short score text.
 *
 * The score is intentionally simple for the lab:
 * - real:         confidence is the realness score
 * - ai-generated: realness is the inverse of confidence
 * - inconclusive: neutral 50% score
 *
 * @param {string} assessmentJson - JSON returned by MLE_GEMINI_AI_VERIFY_MODULE.
 * @param {number|string} imageId - Current MLE_DATA.ID displayed on the page.
 * @param {number|string} assessmentImageId - MLE_DATA.ID used for the assessment.
 * @returns {string} Plain text such as "82% likely real".
 */
export function formatRealnessScore(assessmentJson, imageId, assessmentImageId) {
    // Do not show a score when the page has no current image.
    if (imageId === undefined || imageId === null || imageId === "") {
        return "";
    }

    // Avoid showing a score that belongs to a previously viewed image.
    if (assessmentImageId === undefined || assessmentImageId === null || assessmentImageId === "" || (assessmentImageId + "") !== (imageId + "")) {
        return "Assessment pending";
    }

    // Wait until the Gemini assessment has been returned.
    if (assessmentJson === undefined || assessmentJson === null || (assessmentJson + "") === "") {
        return "Assessment pending";
    }

    const assessment = parseAssessment(assessmentJson);
    const status = valueAsText(assessment.status, "error").toLowerCase();

    // If Gemini failed, do not calculate a misleading score.
    if (status !== "ok") {
        return "Score unavailable";
    }

    const classification = valueAsText(assessment.classification, "inconclusive").toLowerCase();
    const confidence = clamp(valueAsNumber(assessment.confidence, 50));

    let score = 50;
    let label = "inconclusive";

    if (classification === "real") {
        score = confidence;
        label = "likely real";
    } else if (classification === "ai-generated") {
        score = 100 - confidence;
        label = "likely AI";
    }

    return Math.round(clamp(score)) + "% " + label;
}

/**
 * Parses JSON safely so malformed AI output does not break the page.
 */
function parseAssessment(assessmentJson) {
    try {
        return JSON.parse((assessmentJson === undefined || assessmentJson === null) ? "{}" : assessmentJson + "");
    } catch (error) {
        return {
            status: "error",
            reason: assessmentJson || "Score unavailable"
        };
    }
}

/**
 * Converts optional values to text with a fallback.
 */
function valueAsText(value, fallback) {
    return (value === undefined || value === null) ? fallback : value + "";
}

/**
 * Converts optional values to numbers with a fallback.
 */
function valueAsNumber(value, fallback) {
    const numberValue = Number(value);
    return isNaN(numberValue) ? fallback : numberValue;
}

/**
 * Keeps score values inside the 0-100 range.
 */
function clamp(value) {
    return Math.min(Math.max(value, 0), 100);
}
/

  CREATE OR REPLACE MLE ENV "MLE_EXIF_ENV" IMPORTS ('realness-score-module' MODULE "MLE_REALNESS_SCORE_MODULE", 'exifr-module' MODULE "MLE_EXIFR_MODULE", 'gemini-ai-verify-module' MODULE "MLE_GEMINI_AI_VERIFY_MODULE");