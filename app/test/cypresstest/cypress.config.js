const { defineConfig } = require("cypress");

module.exports = defineConfig({

  "reporter": "cypress-multi-reporters",
  "reporterOptions": {
    "reporterEnabled": "mochawesome, mocha-junit-reporter",
    "mochawesomeReporterOptions": {
      "charts": true,
      "embeddedScreenshots": true,
      "reportDir": "reports",
      "reportFilename": "report.html"
    },
    "mochaJunitReporterReporterOptions": {
      "mochaFile": "test-result.xml",
      "toConsole": true
    },
  },
  e2e: {
    setupNodeEvents(on, config) {
      require('cypress-mochawesome-reporter/plugin')(on);
    },
  },
});

