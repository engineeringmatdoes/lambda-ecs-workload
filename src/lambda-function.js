const fs = require('fs').promises;
const path = require('path');

exports.handler = async (event) => {
    const fileName = ['','/'].includes(event.path) ? 'index.html' : event.path;
    const fileContentType = ['','/'].includes(event.path) ? 'text/html' : null;
    const filePath = path.join('/static', fileName);

    try {
        console.info(`Retrieving file ${fileName}`);
        const data = await fs.readFile(filePath);
        const fileModifiedDate = await fs.stat(filePath)
            .then(stat => stat.mtime.toUTCString());
        response = {
            statusCode: 200,
            headers: {
                'Last-Modified': fileModifiedDate
            },
            body: data.toString('base64'),
            isBase64Encoded: true
        };
        if (fileContentType) {
            console.info(`Defining content-type: ${fileContentType}`);
            response.headers['Content-Type'] = fileContentType;
        }
        return response;
    } catch (error) {
        console.error(error);
        return {
            statusCode: error.statusCode === 'ENOENT' ? 404 : 500,
            body: JSON.stringify({
                message: error.message
            })
        };
    }
}
