#!ic-repl -r http://localhost:8000

load "prelude.repl";
call CanCan.doDemo(vec {
  variant { putSuperLike = record {
    userId = "alice";
    videoId = "bob-fish0-0";
    superLikes = true;
  }};
  variant { putSuperLike = record {
    userId = "bob";
    videoId = "bob-fish0-0";
    superLikes = true;
  }};
  variant { putSuperLike = record {
    userId = "cathy";
    videoId = "bob-fish0-0";
    superLikes = true;
  }};
  variant { putSuperLike = record {
    userId = "cathy";
    videoId = "bob-fish0-0";
    superLikes = false;
  }};
  variant { putSuperLike = record {
    userId = "dexter";
    videoId = "bob-fish0-0";
    superLikes = true;
  }};
  variant { putSuperLike = record {
    userId = "esther";
    videoId = "bob-fish0-0";
    superLikes = true;
  }};
});
// not enough superlikes for viral events
call CanCan.getVideoInfo(null, "bob-fish0-0");
assert _ ~= opt record { viralAt = null : opt int };
call CanCan.getProfileInfo("cathy");
assert _ ~= opt record { rewards = 0 : nat };
call CanCan.getMessages("bob");
assert _ == opt vec {};

// duplicate superlikes doesn't count
call CanCan.putSuperLike("alice", "bob-fish0-0", true);
call CanCan.getVideoInfo(null, "bob-fish0-0");
assert _ ~= opt record { viralAt = null : opt int };

// assert viral events
call CanCan.putSuperLike("cathy", "bob-fish0-0", true);
call CanCan.getVideoInfo(null, "bob-fish0-0");
assert _ ~= opt record { viralAt = opt 0 : opt int };
call CanCan.getProfileInfo("cathy");
assert _ ~= opt record { rewards = 10 : nat};
call CanCan.getProfileInfo("bob");
assert _ ~= opt record { rewards = 60 : nat };
call CanCan.getMessages("bob");
assert _ == opt vec {
    record {
      id = 26 : nat;
      time = 0 : int;
      event = variant {
        uploadReward = record { rewards = 50 : nat; videoId = "bob-fish0-0" }
      };
    };
    record {
      id = 31 : nat;
      time = 0 : int;
      event = variant {
        superlikerReward = record { rewards = 10 : nat; videoId = "bob-fish0-0" }
      };
    };
};

// more superlikes after viral events won't affect rewards
call CanCan.putSuperLike("fred", "bob-fish0-0", true);
call CanCan.getProfileInfo("cathy");
assert _ ~= opt record { rewards = 10 : nat };
call CanCan.getProfileInfo ("fred");
assert _ ~= opt record { rewards = 0 : nat };

// Cathy sends Fred some of her points, and the balances are correct afterward.
call CanCan.putRewardTransfer("cathy", "fred", 5);
call CanCan.getProfileInfo("cathy");
assert _ ~= opt record { rewards = 5 : nat };
call CanCan.getProfileInfo("fred");
assert _ ~= opt record { rewards = 5 : nat };

// remove superlike after viral events won't affect rewards
call CanCan.putSuperLike("cathy", "bob-fish0-0", false);
call CanCan.getProfileInfo("cathy");
assert _ ~= opt record { rewards = 5 : nat };
