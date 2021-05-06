import {
  HttpAgent,
  makeActorFactory,
  makeExpiryTransform,
  makeNonceTransform,
} from "@dfinity/agent";

// @ts-ignore
import fetch from "node-fetch";

import fs from "fs";
import path from "path";
import { execSync } from "child_process";

globalThis.crypto = require("@trust/webcrypto");
const topLevelPath = execSync("git rev-parse --show-toplevel", {
  encoding: "utf8",
}).trimEnd();
const { defaults, networks } = require(path.join(topLevelPath, "dfx.json"));

const networkName = process.env["DFX_NETWORK"] || "local";
const DEFAULT_HOST =
  networkName === "local"
    ? `http://${defaults.start.address}:${defaults.start.port}`
    : networks[networkName].providers[0];
const outputRoot = path.join(topLevelPath, ".dfx", networkName);

const credentials = {
  name: process.env["DFX_CREDS_USER"],
  password: process.env["DFX_CREDS_PASS"],
};
// Exports
const getCanister = (canisterName: string, host = DEFAULT_HOST) => {
  const candid = eval(getCandid(canisterName));
  const canisterId = getCanisterId(canisterName);
  const config = { fetch, host };
  if (credentials.name && credentials.password) {
    // @ts-ignore
    config.credentials = credentials;
  }
  const agent = new HttpAgent(config);
  agent.addTransform(makeNonceTransform());
  agent.addTransform(makeExpiryTransform(5 * 60 * 1000));

  return makeActorFactory(candid)({ canisterId, agent });
};

// Helpers

const getCanisterPath = (canisterName) => {
  return path.join(outputRoot, "canisters", canisterName);
};

const getCandid = (canisterName) =>
  fs
    .readFileSync(`${getCanisterPath(canisterName)}/${canisterName}.did.js`)
    .toString()
    .replace(/(\bexport\b\s+(default\s+)?)/g, "");

const getCanisterId = (canisterName) => {
  const canisterIdsPath = networkName === "local" ? outputRoot : ".";
  const newLocal = path.resolve(canisterIdsPath, "canister_ids.json");
  let manifest = JSON.parse(fs.readFileSync(newLocal, { encoding: "utf8" }));
  return manifest[canisterName][networkName];
};

const cancan = getCanister("CanCan");
const cancanId = getCanisterId("CanCan");
console.log(cancan.__proto__);
console.log(cancanId);

module.exports = {
  getCanister,
  getCanisterId,
};
