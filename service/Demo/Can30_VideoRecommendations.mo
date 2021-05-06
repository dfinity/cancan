import Demo "../../backend/Demo";
import Types "../../backend/Types";

module {
  public let allVideos : [Types.VideoId] = [
    "alice-dog-0",
    "bob-fish-0",
    "cathy-bunny-0",
    "dexter-hampster-0",
    "esther-weasel-0",
  ];

  public let demoScript : [Demo.Command] = [
    #reset(#script 0), // clear CanCan state and set timeMode to #script.
    #createTestData{
      users  = ["alice", "bob",
                "cathy", "dex", "esther"];
      videos = [
        ("alice", "dog"),
        ("bob", "fish"),
        ("cathy", "bunny"),
        ("dexter", "hampster"),
        ("esther", "weasel"),
      ];
    },
    #putProfileFollow{
      userId = "alice";
      toFollow = "cathy";
      follows = true;
    },
    #putProfileFollow{
      userId = "cathy";
      toFollow = "alice";
      follows = true;
    },
    #assertVideoFeed{
      userId = "alice";
      limit = ?1;
      videosPred =
        #equals(["cathy-bunny-0"]);
    },
    #assertVideoFeed{
      userId = "cathy";
      limit = ?1;
      videosPred =
        #equals(["alice-dog-0"]);
    },
    #assertVideoFeed{
      userId = "alice";
      limit = null;
      videosPred =
        #containsAll allVideos;
    },
    #assertVideoFeed{
      userId = "bob";
      limit = null;
      videosPred =
        #containsAll allVideos;
    },
  ];
}
