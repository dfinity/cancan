# Local Development with internet-identity

Follow these steps to run cancan locally along with locally running [dfinity/internet-identity](https://github.com/dfinity/internet-identity) canisters on the same replica.

## Overview

The internet-identity canisters must be running on the same IC replica as the CanCan canisters.

Because CanCan's dfx.json configures its replica to run on port 9000, we need to be sure to install the local internet-identity to the replica running on that port.

CanCan must then be accessed in such a way that it uses the local internet-identity canisters to log in instead of the product internet-identity canisters.

## Steps

1. Follow the CanCan [README](../README.md) to start a local replica, deploy CanCan, and opn the app to the sign in screen.
2. Clone the git repo for https://github.com/dfinity/internet-identity to another directory
3. Ensure you have the correct dependencies to build internet-identity (e.g. `rustc@1.51.0` at time of this writing)
4. Add a network called `local-cancan` to the internet-identity `dfx.json` that corresponds to the same network that cancan runs on (the `local` network in cancan dfx.json).
    ```
    ~/dfinity/internet-identity  main 
    ▶ cat dfx.json | jq '.networks | with_entries(select(.key == "local-cancan"))'
    {
    "local-cancan": {
        "bind": "127.0.0.1:9000",
        "type": "ephemeral"
    }
    }
    ```
5. Deploy internet-identity to the `local-cancan` network using command like:
    ```
    II_ENV=development dfx deploy --no-wallet --argument '(null)' --network local-cancan
    ```
    * Explanation of command
        * `II_ENV=development` is configures internet-identity to know it is running on a development replica.
        * `dfx deploy --no-wallet --argument '(null)'` is from the internet-identity README
        * `--network local-cancan` configures `dfx deploy` to deploy to the network labled `local-cancan` that we added to internet-identity's `dfx.json` in an earlier step. This way internet-identity is deployed to the same IC replica that runs cancan.
    * When the deploy succeeds, take note of the canister id of internet-identity. You should be able to access internet-identity via a URL like `http://{canisters.internet-identity.id}.localhost:9000/`
6. Access CanCan with URL querystring parameter `internetIdentityUrl` set to the local URL of internet-identity on the local replica, e.g. `http://ryjl3-tyaaa-aaaaa-aaaba-cai.localhost:9000/sign-in?internetIdentityUrl=http://rno2w-sqaaa-aaaaa-aaacq-cai.localhost:9000/`
7. Click 'Authorize' and follow the prompts in the CanCan + internet-identity web pages.
