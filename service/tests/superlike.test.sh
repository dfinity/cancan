#!ic-repl -r http://localhost:8000

load "prelude.repl";
call CanCan.doDemo(vec {
  variant { putSuperLike = record {
    userId = "alice";
    videoId = "bob-fish0-0";
    superLikes = true;
  }};
  variant { putSuperLike = record {
    userId = "alice";
    videoId = "bob-fish1-0";
    superLikes = true;
  }};
  variant { putSuperLike = record {
    userId = "alice";
    videoId = "bob-fish2-0";
    superLikes = true;
  }};
  variant { putSuperLike = record {
    userId = "alice";
    videoId = "bob-fish3-0";
    superLikes = true;
  }};
  variant { putSuperLike = record {
    userId = "alice";
    videoId = "bob-fish4-0";
    superLikes = true;
  }};
  variant { putSuperLike = record {
    userId = "alice";
    videoId = "bob-fish5-0";
    superLikes = true;
  }};
  variant { putSuperLike = record {
    userId = "alice";
    videoId = "alice-dog0-0";
    superLikes = true;
  }};
  variant { putSuperLike = record {
    userId = "alice";
    videoId = "alice-dog1-0";
    superLikes = true;
  }};
  variant { putSuperLike = record {
    userId = "alice";
    videoId = "alice-dog2-0";
    superLikes = true;
  }};
  variant { putSuperLike = record {
    userId = "alice";
    videoId = "alice-dog3-0";
    superLikes = true;
  }};
});
// exceed 10 superlikes
call CanCan.getSuperLikeValidNow("alice", "alice-dog4-0");
assert _ == opt false;

// okay to like an already liked video
call CanCan.getSuperLikeValidNow("alice", "alice-dog2-0");
assert _ == opt true;

// remove a superlike
call CanCan.putSuperLike("alice", "bob-fish5-0", false);
call CanCan.getSuperLikeValidNow("alice", "alice-dog4-0");
assert _ == opt true;
call CanCan.putSuperLike("alice", "alice-dog4-0", true);
assert _ == opt null;

// exceed quota again
call CanCan.getSuperLikeValidNow("alice", "bob-fish5-0");
assert _ == opt false;
