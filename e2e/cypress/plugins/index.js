/// <reference types="cypress" />
// ***********************************************************
// This example plugins/index.js can be used to load plugins
//
// You can change the location of this file or turn off loading
// the plugins file with the 'pluginsFile' configuration option.
//
// You can read more here:
// https://on.cypress.io/plugins-guide
// ***********************************************************

// This function is called when a project is opened or re-opened (e.g. due to
// the project's config changing)
const fs = require("fs");
const path = require("path");

// This function is called when a project is opened or re-opened (e.g. due to
// the project's config changing)
module.exports = (on, config) => {
  // `on` is used to hook into various events Cypress emits
  // `config` is the resolved Cypress config
  const canisters = JSON.parse(
    fs.readFileSync(
      path.join(__dirname, "..", "..", "..", ".dfx/local", "canister_ids.json"),
      "utf-8"
    )
  );
  config.env.CANISTER_IDS = canisters;

  const dfxConfig = fs.readFileSync(
    path.join(__dirname, "..", "..", "..", "dfx.json"),
    "utf-8"
  );
  config.env.DFX_CONFIG = dfxConfig;
  const parsedConfig = JSON.parse(dfxConfig);

  const host = `localhost`;
  const port = parsedConfig.defaults.start.port;
  // TODO use real port
  config.baseUrl = `http://${host}:${port}`;

  return config;
};
