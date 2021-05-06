const FEED_SELECTOR = ".feed";
const VIDEO_SELECTOR = ".video-container";
const DEFAULT_TIMEOUT = 9000;
const CANISTERS = Cypress.env("CANISTER_IDS");
const UI_CANISTER_ID = "cancan_ui";

export function getFirstVideo() {
  // TODO turn these into data-test-ids
  return cy
    .get(FEED_SELECTOR)
    .find(VIDEO_SELECTOR, {timeout: DEFAULT_TIMEOUT})
    .first();
}

export function loginWithUser(testUser: string) {
  const qs = {
    canisterId: CANISTERS[UI_CANISTER_ID].local,
    testUser: testUser,
  };
  // Seems I have to wait for the first request to complete, which does the
  // fake login and then the 2nd request.
  cy.visit({
    url: "/feed",
    qs,
  });
  cy.wait(3000);
  cy.reload();
  cy.wait(1000);
  return cy.visit({
    url: "/feed",
    qs,
  });
}
