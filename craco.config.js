const generateAliases = require("./src/config/generateAliases");

const aliases = generateAliases();

const overrideWebpackConfig = ({ webpackConfig }) => {
  webpackConfig.resolve.alias = { ...webpackConfig.resolve.alias, ...aliases };
  webpackConfig.resolve.plugins = webpackConfig.resolve.plugins.filter(
    (plugin) =>
      // Removes ModuleScopePlugin so `dfx-generated/` imports work correctly
      !Object.keys(plugin).includes("appSrcs")
  );

  return webpackConfig;
};

module.exports = {
  plugins: [{ plugin: { overrideWebpackConfig } }],
};
