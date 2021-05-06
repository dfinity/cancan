const path = require("path");

const dfxJson = require(`${process.cwd()}/dfx.json`);
const { DFX_NETWORK = "local" } = process.env;

function generateAliases() {
  return Object.entries(dfxJson.canisters).reduce((result, [name]) => {
    const outputRoot = path.join(
      process.cwd(),
      ".dfx",
      DFX_NETWORK,
      "canisters",
      name
    );
    return {
      ...result,
      ["dfx-generated/" + name]: path.join(outputRoot, name + ".js"),
    };
  }, {});
}

module.exports = generateAliases;
