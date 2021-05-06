import { Actor, HttpAgent } from "@dfinity/agent";
import {
  idlFactory as CanCan_idl,
  canisterId as CanCan_canister_id,
} from "dfx-generated/CanCan";
import _SERVICE from "./typings";

import dfxConfig from "../../../dfx.json";

const DFX_NETWORK = process.env.DFX_NETWORK || "local";
function getHost() {
  // Setting host to undefined will default to the window location 👍🏻
  return DFX_NETWORK === "local" ? dfxConfig.networks.local.bind : undefined;
}

const host = getHost();

// Since we're using webpack-dev-server as part of create-react-app, we need to
// add its port to our HttpAgent config as the host.
const agent = new HttpAgent({ host });
export const baseActor = Actor.createActor<_SERVICE>(CanCan_idl, {
  agent,
  canisterId: CanCan_canister_id,
});

export class CanCanActor {
  actor: _SERVICE;
  constructor(overrideActor?: _SERVICE) {
    this.actor = overrideActor ?? baseActor;
  }
}

const actor = new CanCanActor();
export default actor;
