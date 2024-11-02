const fs = require('fs').promises;
const path = require('path');

exports.handler = async (event) => {
    const fileName = ['','/'].includes(event.path) ? 'index.html' : event.path;
    const filePath = path.join('/static', fileName);

    try {
        const data = await fs.readFile(filePath);
        response = {
            statusCode: 200,
            headers: {},
            body: data.toString('base64'),
            isBase65Encoded: true
        };
        return response;
    } catch (error) {
        return {
            statusCode: error.statusCode === 'ENOENT' ? 404 : 500,
            body: JSON.stringify({
                message: error.message
            })
        };
    }
}
