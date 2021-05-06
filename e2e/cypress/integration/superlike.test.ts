import {loginWithUser} from "./utils";

const testUser = "tester";

describe("Super liking", () => {
  before(() => {
    cy.exec(
      `cd ../ && dfx canister call CanCan createTestData '(vec { "alice"; "bob";}, vec { record { "alice"; "dog0" }; })'`
    );
    cy.exec(
      `cd ../ && dfx canister call CanCan createProfile '("${testUser}", "", "")'`
    );
  });

  function getFirstVideo() {
    // TODO turn these into data-test-ids
    return cy.get(".feed").find(".video-container", {timeout: 9000}).first();
  }
  function clickSuperLike(video: Cypress.Chainable<JQuery<HTMLElement>>) {
    video.find('[data-test-id="superlike"]').click({force: true});
  }
  let firstVideo: Cypress.Chainable<JQuery<HTMLElement>>;

  it("logins with a test user id", function () {
    return loginWithUser(testUser).then(() => {
      cy.url().should("include", "feed");
    });
  });

  it("clicks on the video super like button", () => {
    firstVideo = getFirstVideo();
    clickSuperLike(firstVideo);
  });

  it("should show the superlike button in the active state", () => {
    firstVideo
      .find('[data-test-id="superlike"]')
      .find("img")
      .should("have.attr", "alt")
      .should("include", "Remove");
  });

  it("clicks on the superlike button again to deactivate", () => {
    clickSuperLike(firstVideo);
  });

  it("should show the superlike button in the inactive state", () => {
    firstVideo
      .find('[data-test-id="superlike"]')
      .find("img")
      .should("have.attr", "alt")
      .should("not.include", "Remove");
  });
});
