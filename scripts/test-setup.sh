#!/usr/bin/env bats

dfx canister call CanCan createTestData '(
  vec { "alice"; "bob"; "fred" },
  vec { 
    record { "alice"; "dog0" }; 
    record { "bob"; "fish0" }; 
  })'
