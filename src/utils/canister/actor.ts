import { Actor, HttpAgent, Identity } from "@dfinity/agent";
import {
  idlFactory as CanCan_idl,
  canisterId as CanCan_canister_id,
} from "dfx-generated/CanCan";
import _SERVICE from "./typings";

import dfxConfig from "../../../dfx.json";

const DFX_NETWORK = process.env.DFX_NETWORK || "local";
const isLocalEnv = DFX_NETWORK === "local";

function getHost() {
  // Setting host to undefined will default to the window location 👍🏻
  return isLocalEnv ? dfxConfig.networks.local.bind : undefined;
}

const host = getHost();

function createActor(identity?: Identity) {
  const agent = new HttpAgent({ host, identity });
  const actor = Actor.createActor<_SERVICE>(CanCan_idl, {
    agent,
    canisterId: CanCan_canister_id,
  });
  return { actor, agent };
}

/*
 * Responsible for keeping track of the actor, whether the user has logged
 * in again or not. A logged in user uses a different actor with their
 * Identity, to ensure their Principal is passed to the backend.
 */
class ActorController {
  _actor: _SERVICE;
  _isAuthenticated: boolean = false;
  isReady: boolean = false;

  constructor() {
    this._actor = this.initBaseActor();
  }

  initBaseActor() {
    const { agent, actor } = createActor();
    // The root key only has to be fetched for local development environments
    if (isLocalEnv) {
      agent.fetchRootKey().then(() => (this.isReady = true));
    }
    return actor;
  }

  /*
   * Get the actor instance to run commands on the canister.
   */
  get actor() {
    return this._actor;
  }

  /*
   * Once a user has authenticated and has an identity pass this identity
   * to create a new actor with it, so they pass their Principal to the backend.
   */
  async authenticateActor(identity: Identity) {
    const { agent, actor } = createActor(identity);
    if (isLocalEnv) {
      await agent.fetchRootKey();
    }
    this._actor = actor;
    this._isAuthenticated = true;
    this.isReady = true;
  }

  /*
   * If a user unauthenticates, recreate the actor without an identity.
   */
  unauthenticateActor() {
    this._actor = this.initBaseActor();
  }
}

export const actorController = new ActorController();
