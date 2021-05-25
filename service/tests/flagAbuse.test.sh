#!ic-repl -r http://localhost:8000

// Test scenario.
//
//
// Alice and bob each (eventually) flag bob's video for abuse.
///
// The current content moderation threshold is set at 2.
// We say "enough*" below to refer to this threshold.
//
// BE behavior we are testing:
//
// When a video has enough* abuse flags from distinct users, it is redacted.
//
// Likewise, a user can be flagged; if flagged by enough* distinct users,
// they are redacted from lists of likers and followers, etc.
//
// We are testing the video redaction here.

load "preludeTiny.repl";

call CanCan.getProfileInfo("bob");
assert _ ~= opt record { uploadedVideos = vec { "bob-fish0-0" } };
call CanCan.getVideoInfo(opt "bob", "bob-fish0-0");
assert _ ~= opt record { abuseFlagCount = 0 : nat };

//
// Alice flags bob's fish0 video.
//
call CanCan.putAbuseFlagVideo("alice", "bob-fish0-0", true);
call CanCan.getProfileInfo("bob");
assert _ ~= opt record { uploadedVideos = vec { "bob-fish0-0" } };
call CanCan.getVideoInfo(opt "bob", "bob-fish0-0");
assert _ ~= opt record { abuseFlagCount = 1 : nat };

//
// Alice cannot add more than a single flag.
// After her second attempt, nothing changes.
//
call CanCan.putAbuseFlagVideo("alice", "bob-fish0-0", true);
call CanCan.getProfileInfo("bob");
assert _ ~= opt record { uploadedVideos = vec { "bob-fish0-0" } };
call CanCan.getVideoInfo(opt "alice", "bob-fish0-0");
assert _ ~= opt record { abuseFlagCount = 1 : nat };

//
// Once bob also flags fish0, it has 2 flags,
// and is "redacted" from query results.
//
call CanCan.putAbuseFlagVideo("bob", "bob-fish0-0", true);
call CanCan.getProfileInfo("bob");
assert _ ~= opt record { uploadedVideos = vec { } }; /* REDACTED! */
call CanCan.getProfilePlus(opt "bob", "bob");
assert _ ~= opt record { uploadedVideos = vec { } }; /* REDACTED! */
call CanCan.getVideoInfo(opt "bob", "bob-fish0-0");
assert _ ~= opt record { abuseFlagCount = 2 : nat };
