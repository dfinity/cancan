describe("smoke test", () => {
  const canisters = Cypress.env("CANISTER_IDS");
  const dfxConfig = JSON.parse(Cypress.env("DFX_CONFIG"));
  const host = "http://localhost";
  const port = dfxConfig.defaults.start.port;
  const UI_CANISTER_ID = "cancan_ui";
  it("loads cancan ui", function () {
    cy.visit({
      url: host + ":" + port,
      qs: {
        canisterId: canisters[UI_CANISTER_ID].local,
      },
    });
    cy.url().should("include", "/sign-in");
  });
});
