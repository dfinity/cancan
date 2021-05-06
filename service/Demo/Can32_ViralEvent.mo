import Demo "../../backend/Demo";

module {
  public let demoScript : [Demo.Command] = [
    #reset(#script 0), // clear CanCan state and set timeMode to #script.
    #createTestData{
      users  = ["alice", "bob",
                "cathy", "dex", "esther"];
      videos = [
        ("alice", "dog0"),
        ("alice", "dog1"),
        ("alice", "dog2"),
        ("alice", "dog3"),
        ("alice", "dog4"),

        ("bob", "fish0"),
        ("bob", "fish1"),
        ("bob", "fish2"),
        ("bob", "fish3"),
        ("bob", "fish4"),
        
        ("cathy", "bunny0"),
        ("cathy", "bunny1"),
        ("cathy", "bunny2"),
        ("cathy", "bunny3"),
        ("cathy", "bunny4"),
        
        ("dexter", "hampster0"),
        ("dexter", "hampster1"),
        ("dexter", "hampster2"),
        ("dexter", "hampster3"),
        ("dexter", "hampster4"),
        
        ("esther", "weasel0"),
        ("esther", "weasel1"),
        ("esther", "weasel2"),
        ("esther", "weasel3"),
        ("esther", "weasel4"),
      ];
    },
    #putSuperLike{
      userId  = "alice";
      videoId = "bob-fish0-0";
      superLikes = true;
    },
    #putSuperLike{
      userId  = "bob";
      videoId = "bob-fish0-0";
      superLikes = true;
    },
    #putSuperLike{
      userId  = "cathy";
      videoId = "bob-fish0-0";
      superLikes = true;
    },
    #putSuperLike{
      userId  = "dexter";
      videoId = "bob-fish0-0";
      superLikes = true;
    },
    #assertVideoVirality{
      videoId = "bob-fish0-0";
      isViral = false;
    },
    #putSuperLike{
      userId  = "esther";
      videoId = "bob-fish0-0";
      superLikes = true;
    },
    #assertVideoVirality{
      videoId = "bob-fish0-0";
      isViral = true;
    },
  ];
}
