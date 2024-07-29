const { defineConfig } = require('cypress');

module.exports = defineConfig({
    e2e: {
        baseUrl: 'http://ckan:5000',
        specPattern: 'cypress/integration/*.cy.js',
    },
    videoCompression: false,
    videoUploadOnPasses: false,
    screenshotOnRunFailure: false,
});
