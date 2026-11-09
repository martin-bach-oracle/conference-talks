/*!
 Copyright (c) 2022, Oracle and/or its affiliates. All rights reserved.
 */
( function ( da, util, item, event, message, env, debug, $ ) {
    "use strict";

    /**
     * Initialization function for Enhanced File Uploader DA plugin
     *
     * @ignore
     * @param {object} pAction
     *
     * @param {object} pOptions Required options object.
     * @param {string} pOptions.affectedElement
     * @param {boolean} pOptions.enableImageResize
     * @param {number} pOptions.maxImageSize
     * @param {boolean} pOptions.enableImagePreview
     * @param {string} pOptions.previewContainer
     * @param {array} pOptions.itemsToSubmit
     * @param {boolean} pOptions.showProcessing
     * @param {string} pOptions.ajaxIdentifier
     *
     * @param {function} pFileProcessingFunction
     */
    da.enhancedFileUpload = function ( pAction, pOptions, pFileProcessingFunction ) {
        const PLUGIN = "COM.ORACLE.APEX.ENHANCED_FILE_UPLOADER",
              EVENT_PREFIX = "enhancedfileuploader",
              EVENT_AJAX_SUCCESS = EVENT_PREFIX + "success",
              EVENT_AJAX_ERROR = EVENT_PREFIX + "error",
              EVENT_UPLOAD_COMPLETE = EVENT_PREFIX + "complete",
              EVENT_FILE_CANCEL = EVENT_PREFIX + "filecancel",
              EVENT_FILE_PROGRESS = EVENT_PREFIX + "fileprogress",
              EVENT_TOTAL_PROGRESS = EVENT_PREFIX + "totalprogress",
              FILEBROWSE_CONTAINER_ELEMENT = "div.apex-item-filedrop",
              FILE_STATUS_START = "start",
              FILE_STATUS_UPLOAD = "upload",
              FILE_STATUS_SUCCESS = "success",
              FILE_STATUS_ERROR = "error";

        let defaultOptions = {
            affectedElement: "",
            enableImageResize: false,
            maxImageSize: 1024,
            enableImagePreview: false,
            previewContainer: "",
            itemsToSubmit: [],
            showProcessing: true,
            cancelWithEscape: false,
            ajaxIdentifier: ""
        };

        let options = $.extend( {}, defaultOptions, pOptions ),
            itemId = util.escapeCSS( options.affectedElement ),
            itemElem = document.getElementById( itemId ),
            item$ = $( "#" + itemId, apex.gPageContext$ ),
            action = pAction,
            fileProcessingFunction = pFileProcessingFunction,
            processedFiles = [],
            xhrRequest,
            fileInfo = {},
            abortEscape = false,
            spinner$;

        if ( options.itemsToSubmit && typeof options.itemsToSubmit === "string" ) {
            options.itemsToSubmit = options.itemsToSubmit.split( "," );
        }

        debug.info( PLUGIN, action, options, fileProcessingFunction );

        /**
         * Check if a given object or variable is a function
         * @function isFunction
         * @param {object} pFunction
         * @return {boolean}
         */
        function isFunction( pFunction ) {
            return pFunction instanceof Function;
        }

        /**
         * Check if a given object or variable is a object
         * @function isObject
         * @param {object} pObject
         * @return {boolean}
         */
        function isObject( pObject ) {
            return pObject instanceof Object;
        }

        /**
         * Check if a given file is an image
         * @function isFileImage
         * @param {object} pFile object
         * @return {boolean}
         */
        function isFileImage( pFile ) {
            return pFile && pFile.type.split( "/" )[0] === "image";
        }

        /**
         * Show a processing spinner, either on the file browse item when supported, or on the page
         * @function showSpinner
         */
        function showSpinner() {
            let fileBrowseContainer$ = item$.next( FILEBROWSE_CONTAINER_ELEMENT );

            if ( options.showProcessing ) {
                if ( fileBrowseContainer$ && fileBrowseContainer$.length > 0 ) {
                    fileBrowseContainer$.addClass( "is-loading" );
                } else {
                    spinner$ = util.showSpinner( $( "body" ) );
                }
            }
        }

        /**
         * Hide / Remove the processing spinner, either on the file browse item when supported, or on the page
         * @function hideSpinner
         */
        function hideSpinner() {
            let fileBrowseContainer$ = item$.next( FILEBROWSE_CONTAINER_ELEMENT );

            if ( options.showProcessing ) {
                if ( fileBrowseContainer$ && fileBrowseContainer$.length > 0 ) {
                    if ( fileBrowseContainer$.hasClass( "is-loading" ) ) {
                        fileBrowseContainer$.removeClass( "is-loading" );
                    }
                } else {
                    if ( spinner$ && spinner$.length > 0 ) {
                        spinner$.remove();
                    }
                }
            }
        }

        /**
         * Resize a given image to max * max dimensions ( options.maxImageSize )
         * @function resizeImage
         * @param {object} pImageFile
         * @return {Promise}
         */
        async function resizeImage( pImageFile ) {
            return new Promise( ( resolve ) => {
                const maxWidth = options.maxImageSize,
                      maxHeight = options.maxImageSize;

                if ( pImageFile ) {
                    let reader = new FileReader();

                    // Set the image for the FileReader
                    reader.onload = function ( e ) {
                        let img = new Image();

                        img.onload = function () {
                            // create canvas
                            let canvas = document.createElement( "canvas" );
                            let ctx = canvas.getContext( "2d" );
                            ctx.drawImage( img, 0, 0 );

                            let imgWidth = img.width,
                                imgHeight = img.height,
                                resizeWidth,
                                resizeHeight;

                            // add resizing logic
                            if ( imgWidth > imgHeight ) {
                                resizeWidth = imgWidth > maxWidth ? maxWidth : imgWidth;
                                resizeHeight = imgWidth > maxWidth ? imgHeight * ( maxWidth / imgWidth ) : imgHeight * ( imgWidth / maxWidth );
                            } else {
                                resizeHeight = imgHeight > maxHeight ? maxHeight : imgHeight;
                                resizeWidth = imgHeight > maxHeight ? imgWidth * ( maxHeight / imgHeight ) : imgWidth * ( imgHeight / maxHeight );
                            }

                            // specify the resizing result
                            canvas.width = resizeWidth;
                            canvas.height = resizeHeight;

                            ctx = canvas.getContext( "2d" );
                            ctx.drawImage( img, 0, 0, resizeWidth, resizeHeight );

                            // return the resized blob as a file object
                            canvas.toBlob(
                                function ( blob ) {
                                    resolve( new File( [blob], pImageFile.name, { type: pImageFile.type, lastModified: new Date().getTime() } ) );
                                },
                                pImageFile.type,
                                0.85
                            );
                        };
                        img.src = e.target.result;
                    };
                    reader.readAsDataURL( pImageFile );
                }
            } );
        }

        /**
         * Renders a given image file to a defined container DOM element
         * @function renderImagePreview
         * @param {object} pFile
         */
        function renderImagePreview( pFile ) {
            let previewContainer$ = $( options.previewContainer, apex.gPageContext$ );

            if ( previewContainer$.prop( "tagName" ) === "IMG" ) {
                previewContainer$.attr( "src", URL.createObjectURL( pFile ) );
            } else {
                previewContainer$.prepend( $( "<img>", { src: URL.createObjectURL( pFile ) } ) );
            }
        }

        /**
         * Get the total size of all files of an upload action
         * @function getTotalFilesSize
         * @return {number}
         */
        function getTotalFilesSize() {
            let files = itemElem.files,
                totalSize = 0;

            for ( let i = 0; i < files.length; i++ ) {
                let file = files[i],
                    processedFile = processedFiles[processedFiles.findIndex( ( obj ) => obj.file.name === file.name )];

                if ( isFileImage( file ) && processedFile && processedFile.file && processedFile.file.size < file.size ) {
                    totalSize += processedFile.file.size || 0;
                } else {
                    totalSize += file.size || 0;
                }
            }

            return totalSize;
        }

        /**
         * Get the size of all files which are already processed and uploaded
         * @function getProcessedFilesSize
         * @return {number}
         */
        function getProcessedFilesSize() {
            let processedSize = 0;

            for ( let i = 0; i < processedFiles.length; i++ ) {
                if ( [FILE_STATUS_SUCCESS, FILE_STATUS_ERROR].includes( processedFiles[i].status ) ) {
                    processedSize += processedFiles[i].file.size || 0;
                }
            }

            return processedSize;
        }

        /**
         * Shows an error notification using apex.message.showErrors
         * @function showError
         * @param {string} pErrorMessage
         */
        function showError( pErrorMessage ) {
            message.clearErrors();
            message.showErrors( [
                {
                    type: "error",
                    location: ["page"],
                    pageItem: itemId,
                    message: pErrorMessage,
                    unsafe: false
                }
            ] );
        }

        /**
         * Makes an FormData AJAX request to the DB server uploading a particular file
         * @function makeFormDataRequest
         * @param {object} pFormData
         * @param {object} pFile
         * @return {object}
         */
        async function makeFormDataRequest( pFormData, pFile ) {
            const totalFilesSize = getTotalFilesSize(),
                  processedFilesSize = getProcessedFilesSize();

            processedFiles[processedFiles.findIndex( ( obj ) => obj.file.name === pFile.name )].status = FILE_STATUS_UPLOAD;

            try {
                const response = await $.ajax( {
                    type: "POST",
                    url: "wwv_flow.ajax",
                    dataType: "json",
                    processData: false,
                    contentType: false,
                    data: pFormData,
                    // xhr function for file upload progress event support
                    xhr: function () {
                        xhrRequest = $.ajaxSettings.xhr();

                        xhrRequest.upload.onprogress = function ( e ) {
                            if ( e.lengthComputable ) {
                                event.trigger( item$, EVENT_FILE_PROGRESS, {
                                    name: pFile.name,
                                    type: pFile.type,
                                    size: pFile.size,
                                    progress: ( e.loaded / e.total ) * 100,
                                    loaded: e.loaded,
                                    total: e.total
                                } );

                                let totalProgress = ( ( processedFilesSize + e.loaded ) / totalFilesSize ) * 100;

                                event.trigger( item$, EVENT_TOTAL_PROGRESS, {
                                    progress: totalProgress > 100 ? 100 : totalProgress,
                                    loaded: processedFilesSize + e.loaded > totalFilesSize ? totalFilesSize : processedFilesSize + e.loaded,
                                    total: totalFilesSize
                                } );
                            }
                        };

                        return xhrRequest;
                    }
                } );

                return response;
            } catch ( error ) {
                if ( abortEscape ) {
                    abortEscape = false;
                    return { success: true };
                }

                return { success: false, error: error };
            }
        }

        /**
         * Wrapping function to upload a single file using AJAX. Here we build the FormData object and call the request function
         * @function uploadFile
         * @param {object} pFile
         * @return {object}
         */
        async function uploadFile( pFile ) {
            let formData = new FormData(),
                result;

            formData.append( "p_request", "PLUGIN=" + options.ajaxIdentifier );
            formData.append( "p_flow_id", env.APP_ID );
            formData.append( "p_flow_step_id", env.APP_PAGE_ID );
            formData.append( "p_instance", env.APP_SESSION );
            formData.append( "p_debug", $v( "pdebug" ) );
            formData.append( "F01", pFile, pFile.name );
            formData.append( "X01", pFile.name );
            formData.append( "X02", pFile.type );

            if ( pFile._metadata && isObject( pFile._metadata ) ) {
                formData.append( "X03", JSON.stringify( pFile._metadata ) );
            }

            for ( let i = 0; i < options.itemsToSubmit.length; i++ ) {
                formData.append( "p_arg_names", options.itemsToSubmit[i] );
            }
            for ( let i = 0; i < options.itemsToSubmit.length; i++ ) {
                formData.append( "p_arg_values", item( options.itemsToSubmit[i] ).getValue() );
            }

            result = await makeFormDataRequest( formData, pFile );

            return result;
        }

        /**
         * Main function which handles the processing of all files of an file browse item
         * @function processFiles
         * @param {array} pFiles
         * @param {function} callback
         */
        async function processFiles( pFiles, callback ) {
            let result,
                hasError = false;

            processedFiles = [];

            for ( let i = 0; i < pFiles.length; i++ ) {
                let file = pFiles[i],
                    fileMetadata = {};

                // all files should have a valid mime type
                if ( !file.type ) {
                    file = new File( [file], file.name, { type: "application/octet-stream", lastModified: new Date().getTime() } );
                }

                // if a developer has specified a optional file processing / manipulation function we execute it here
                // beside manipulating the file itself, devs can add file._metadata and file._cancel to cancel the upload of this file
                if ( fileProcessingFunction && isFunction( fileProcessingFunction ) ) {
                    file = await fileProcessingFunction( file );

                    fileMetadata = file._metadata;

                    if ( file._cancel ) {
                        event.trigger( item$, EVENT_FILE_CANCEL, { name: file.name, type: file.type, size: file.size } );
                        continue;
                    }
                }

                // if image resizing is enabled we execute our logic and optionally render a image preview
                if ( options.enableImageResize && isFileImage( file ) ) {
                    file = await resizeImage( file );

                    if ( options.enableImagePreview ) {
                        renderImagePreview( file );
                    }
                }

                // if file._metadata is lost, e.g. by image resizing, we add it again
                if ( !file._metadata ) {
                    file._metadata = fileMetadata || {};
                }

                // build a global fileInfo object which can be used outside of this processing function
                // and without leaking the whole file
                fileInfo = {
                    name: file.name,
                    type: file.type,
                    size: file.size
                };

                // now upload the file
                processedFiles.push( { file: file, status: FILE_STATUS_START } );

                result = await uploadFile( file );

                if ( result.success ) {
                    processedFiles[processedFiles.findIndex( ( obj ) => obj.file.name === file.name )].status = FILE_STATUS_SUCCESS;
                    event.trigger( item$, EVENT_AJAX_SUCCESS, { name: file.name, type: file.type, size: file.size } );
                } else {
                    processedFiles[processedFiles.findIndex( ( obj ) => obj.file.name === file.name )].status = FILE_STATUS_ERROR;
                    event.trigger( item$, EVENT_AJAX_ERROR, { name: file.name, type: file.type, size: file.size, error: result.error } );
                    showError( result.error.statusText );

                    if ( !hasError ) {
                        hasError = true;
                    }
                }

                debug.info( PLUGIN, file.name, result );
            }
            callback( hasError );
        }

        // if cancel with esc key is enabled we add a event listener for that
        if ( options.cancelWithEscape ) {
            $( document ).keyup( function ( e ) {
                if ( e.key === "Escape" ) {
                    if ( xhrRequest ) {
                        event.trigger( item$, EVENT_FILE_CANCEL, fileInfo );
                        abortEscape = true;
                        xhrRequest.abort();
                    }
                }
            } );
        }

        // if files are present on the file browse item we start processing the uploads
        if ( itemElem.files && itemElem.files.length > 0 ) {
            showSpinner();

            processFiles( itemElem.files, function ( errorOccurred ) {
                hideSpinner();

                event.trigger( item$, EVENT_UPLOAD_COMPLETE );
                item$.val( "" ).change();

                da.resume( action.resumeCallback, errorOccurred );
            } );
        }
    };
} )( apex.da, apex.util, apex.item, apex.event, apex.message, apex.env, apex.debug, apex.jQuery );
