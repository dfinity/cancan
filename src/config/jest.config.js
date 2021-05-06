const generateAliases = require("./generateAliases");
const aliases = generateAliases();

const moduleMap = {};
for (const key in aliases) {
  if (aliases.hasOwnProperty(key)) {
    moduleMap[`^${key}$`] = aliases[key];
  }
}

module.exports = {
  moduleNameMapper: moduleMap,
  "roots": [
    "<rootDir>/src"
  ],
  "transform": {
    "^.+\\.tsx?$": "ts-jest"
  }
};
