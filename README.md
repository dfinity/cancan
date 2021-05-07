# CanCan

[![Build Status](https://github.com/dfinity/cancan/workflows/CI/badge.svg)](https://github.com/dfinity/cancan/actions)

> A scalable video-sharing service.

## Installation

### Prerequisites

- [Internet Computer SDK](https://sdk.dfinity.org)
- [Node.js](https://nodejs.org)
- [Python](https://www.python.org)
- [Vessel@0.6.0](https://github.com/dfinity/vessel/releases/tag/v0.6.0)

Double-check you have [vessel](https://github.com/dfinity/vessel) installed at version 0.6.0, then clone this repository and navigate to the `cancan` directory.

```shell
$ vessel --version
# vessel 0.6.0
# if this does not work, run ./scripts/vessel-install.sh to download and install

$ git clone git@github.com:dfinity/cancan.git
$ cd cancan
```

Start a local Internet Computer replica.

```shell
$ dfx start
```

Execute the following commands in another terminal tab in the same directory.

```shell
$ npm ci # <- This installs packages from the lockfile for consistency

$ ./bootstrap.sh
```

This will deploy a local canister called `cancan_ui`. To open the front-end, get the asset canister id by running `dfx canister id cancan_ui`. Then open your browser, and navigate to `http://<cancan_ui-canister-id>.localhost:9000/sign-in`.

## Frontend Development

To run a development server with fast refreshing and hot-reloading, you can use this command in the app's root directory:

```shell
$ npm run start
```

Your default browser will open (or focus) a tab at `localhost:3000`, to which you must then append `/?canisterId=${cancan_ui_canister_id}`, where `cancan_ui_canister_id` is typically (at current) `ryjl3-tyaaa-aaaaa-aaaba-cai`.

Now you can make changes to any frontend code and see instant updates, in many cases not even requiring a page refresh, so UI state is preserved between changes. Occasionally adding a CSS rule won't trigger an update, and the user has to manually refresh to see those changes.

## Internet Identity (the app formerly known as IDP) Locally

Clone and setup [the project](https://github.com/dfinity/idp-service) and make sure that the `idp_service` is deployed, and you have the front-end available. then change our `DEFAULT_IDP_URL` to reflect where it is running. That should allow you to do auth locally to try out new IDP. For production, we will probably configure `auth.ic0.app` to be running this canister, but for now this is how to get it running.

## TODO

- see [issues](https://github.com/dfinity/cancan/issues)

## Deploying to Mainnet (Beta)

**TBD**
