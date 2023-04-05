const { defineConfig } = require('cypress')

module.exports = defineConfig({
  e2e: {
    baseUrl: 'http://ckan:5000',
    specPattern: 'cypress/integration/*.cy.js'
  },
//   component: {
    
//   }
  videos: {
    videoCompression: false,
    videoUploadOnPasses: false
  },
  screenshots: {
    screenshotOnRunFailure: false
  }
})