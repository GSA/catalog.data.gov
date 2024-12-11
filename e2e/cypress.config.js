const { defineConfig } = require('cypress')

module.exports = defineConfig({
    e2e: {
        baseUrl: 'http://ckan:5000',
        specPattern: 'cypress/integration/*.cy.js',
        experimentalRunAllSpecs: true
    },
    videoCompression: false,
    screenshotOnRunFailure: false,
})