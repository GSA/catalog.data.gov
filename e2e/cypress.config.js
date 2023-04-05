const { defineConfig } = require('cypress')

module.exports = defineConfig({
    e2e: {
        baseUrl: 'http://ckan:5000',
        specPattern: 'cypress/integration/*.cy.js'
    },
//   component: {
    
//   }
    videoCompression: false,
    videoUploadOnPasses: false,
    screenshotOnRunFailure: false,
})