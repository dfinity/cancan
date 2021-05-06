#!ic-repl -r http://localhost:9000

import CanCan = "rrkah-fqaaa-aaaaa-aaaaq-cai";

identity Alice;

call CanCan.createProfile("alice", null);
assert _ != (null : opt null);

call CanCan.createVideo(record
                        { userId = "alice" ;
                          name = "cat0" ;
                          createdAt = 202105041630;
                          caption = "cat";
                          tags = vec { };
                          chunkCount = 1 });
assert _ != (null : opt null);

identity Bob;

call CanCan.getProfileInfo("alice", null); // fail: no profile for bob yet.
assert _ == (null : opt null);

call CanCan.createProfile("bob", null); // ok.
assert _ != (null : opt null);

call CanCan.getProfileInfo("alice", null); // ok
assert _ != (null : opt null);

call CanCan.createVideo(record
                        { userId = "alice" ; // fail: bob is not the user alice
                          name = "cat1" ;
                          createdAt = 202105041630;
                          caption = "cat";
                          tags = vec { };
                          chunkCount = 1 });
assert _ == (null : opt null);
call CanCan.getVideoInfo("alice-cat0-0"); // ok
assert _ != (null : opt null);

call CanCan.putSuperLike("bob", "alice-cat0-0", true); // ok
assert _ != (null : opt null);

call CanCan.putSuperLike("alice", "alice-cat0-0", true); // fail: bob cannot superlike as alice
assert _ == (null : opt null);
