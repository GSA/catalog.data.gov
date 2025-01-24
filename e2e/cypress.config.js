const { defineConfig } = require('cypress')

module.exports = defineConfig({
    e2e: {
        baseUrl: 'http://ckan:5000',
        specPattern: 'cypress/integration/*.cy.js',
        setupNodeEvents(on, config) {
            on('task', {
                deleteFile(filePath) {
                    const fs = require('fs')
                    if (fs.existsSync(filePath)) {
                        fs.unlinkSync(filePath)
                    }
                    return null
                }
            })
            return config
        }
    },
    videoCompression: false,
    videoUploadOnPasses: false,
    screenshotOnRunFailure: false,
    retries: {
        runMode: 2,
        openMode: 0,
    },
})