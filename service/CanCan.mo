import Access "../backend/Access";
import Array "mo:base/Array";
import Hash "mo:base/Hash";
import Base "../backend/Base";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Demo "../backend/Demo";
import DemoCan30 "Demo/Can30_VideoRecommendations";
import DemoCan32 "Demo/Can32_ViralEvent";
import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import List "mo:base/List";
import Nat "mo:base/Nat";
import Option "mo:base/Option";
import P "mo:base/Prelude";
import Param "../backend/Param";
import Prelude "mo:base/Prelude";
import Principal "mo:base/Principal";
import Rel "../backend/Rel";
import RelObj "../backend/RelObj";
import State "../backend/State";
import Text "mo:base/Text";
import Time "mo:base/Time";
import TrieMap "mo:base/TrieMap";
import Types "../backend/Types";

shared ({caller = initPrincipal}) actor class CanCan () /* : Types.Service */ {

  public type ProfileInfo = Types.ProfileInfo;
  public type ProfileInfoPlus = Types.ProfileInfoPlus;
  public type ProfilePic = Types.ProfilePic;
  public type Timestamp = Types.Timestamp;
  public type UserId = Types.UserId;
  public type VideoId = Types.VideoId;
  public type ChunkId = Types.ChunkId;
  public type ChunkData = Types.ChunkData;
  public type VideoInfo = Types.VideoInfo;
  public type VideoInit = Types.VideoInit;
  public type VideoPic = Types.VideoPic;
  public type VideoResult = Types.VideoResult;
  public type VideoResults = Types.VideoResults;

  var state = State.empty({ admin = initPrincipal });

  /*public query*/ func getState() : async State.StateShared {
    State.share(state)
  };

  /*public*/ func setState(st : State.StateShared) : async () {
    state := State.fromShared(st);
  };

  public query func checkUsernameAvailable(userName_ : Text): async Bool {
    switch (state.profiles.get(userName_)) {
      case (?_) { /* error -- ID already taken. */ false };
      case null { /* ok, not taken yet. */ true };
    }
  };

  /// null means that the principal is unrecognized,
  /// otherwise, returns a non-empty array of usernames.
  public shared(msg) func getUserNameByPrincipal(p:Principal) : async ?[Text] {
    if ( msg.caller == p ) {
      ?state.access.userPrincipal.get1(p)
    } else {
      // access control check fails; do not reveal username of p.
      null
    }
  };

  /// log the given event kind, with a unique ID and current time
  func logEvent(ek : State.Event.EventKind) {
    state.eventLog.add({
                         id = state.eventCount ;
                         time = timeNow_() ;
                         kind = ek
                       });
    state.eventCount += 1;
  };

  // responsible for adding metadata from the user to the state.
  // a null principal means that the username has no valid callers (yet), and the admin
  // must relate one or more principals to it.
  func createProfile_(userName_ : Text, p: ?Principal, pic_ : ?ProfilePic) : ?() {
    switch (state.profiles.get(userName_)) {
      case (?_) { /* error -- ID already taken. */ null };
      case null { /* ok, not taken yet. */
        let now = timeNow_();
        state.profiles.put(userName_, {
            userName = userName_ ;
            createdAt = now ;
        });
        // rewards init invariant: rewards is initialized to zero (is non-null).
        state.rewards.put(userName_, 0);
        logEvent(#createProfile({userName=userName_; pic=pic_}));
        state.access.userRole.put(userName_, #user);
        switch p {
          case null { }; // no related principals, yet.
          case (?p) { state.access.userPrincipal.put(userName_, p); }
        };
        // success
        ?()
      };
    }
  };

  func accessCheck(caller : Principal, action : Types.UserAction, target : Types.ActionTarget) : ?() {
    state.access.check(timeNow_(), caller, action, target)
  };

  public shared(msg) func createProfile(userName : Text, pic : ?ProfilePic) : async ?ProfileInfoPlus {
    do ? {
      accessCheck(msg.caller, #create, #user userName)!;
      createProfile_(userName, ?msg.caller, pic)!;
      // return the full profile info
      getProfilePlus_(?userName, userName)! // self-view
    }
  };

  var timeMode : {#ic ; #script} =
    switch (Param.timeMode) {
     case (#ic) #ic;
     case (#script _) #script
    };

  var scriptTime : Int = 0;

  func timeNow_() : Int {
    switch timeMode {
      case (#ic) { Time.now() };
      case (#script) { scriptTime };
    }
  };

  public shared(msg) func scriptTimeTick() : async ?() {
    do ? {
      accessCheck(msg.caller, #admin, #all)!;
      assert (timeMode == #script);
      scriptTime := scriptTime + 1;
    }
  };

  func reset_( mode : { #ic ; #script : Int } ) {
    setTimeMode_(mode);
    state := State.empty({ admin = state.access.admin });
  };

  public shared(msg) func reset( mode : { #ic ; #script : Int } ) : async ?() {
    do ? {
      accessCheck(msg.caller, #admin, #all)!;
      reset_(mode)
    }
  };

  func setTimeMode_( mode : { #ic ; #script : Int } ) {
    switch mode {
      case (#ic) { timeMode := #ic };
      case (#script st) { timeMode := #script ; scriptTime := st };
    }
  };

  public shared(msg) func setTimeMode( mode : { #ic ; #script : Int } ) : async ?() {
    do ? {
      accessCheck(msg.caller, #admin, #all)!;
      setTimeMode_(mode)
    }
  };

  func getProfileInfo_(target : UserId) : ?ProfileInfo {
    do ? {
      let profile = state.profiles.get(target)!;
      let following_ = state.follows.get0(target);
      let followers_ = state.follows.get1(target);
      let likes_ = state.likes.get0(target);
      let superLikes_ = state.superLikes.get0(target);
      let uploaded_ = state.uploaded.get0(target);
      let rewards_ = state.rewards.get(target)!;
      let abuseFlagCount_ = state.abuseFlagVideos.get1Size(target);
      {
        userName = profile.userName ;
        followers = filterOutAbuseUsers(followers_)! ;
        following = filterOutAbuseUsers(following_)! ;
        likedVideos = filterOutAbuseVideos(likes_)! ;
        superLikedVideos = filterOutAbuseVideos(superLikes_)! ;
        uploadedVideos = filterOutAbuseVideos(uploaded_)! ;
        hasPic = false ;
        rewards = rewards_;
        abuseFlagCount = abuseFlagCount_ ;
      }
    }
  };

  public query(msg) func getProfileInfo(userId : UserId) : async ?ProfileInfo {
    do ? {
      accessCheck(msg.caller, #view, #user userId)!;
      getProfileInfo_(userId)!
    }
  };

  /// "Deeper" version of ProfileInfo.
  ///
  /// Gives Video- and ProfileInfos instead of merely Ids in the results.
  ///
  /// The optional "caller" UserId personalizes the resulting record for
  /// various cases:
  /// - When caller is not given, less information is non-null in result.
  /// - When calling user is viewing their own profile,
  ///   gives private and quasi-private info to them about their allowances.
  /// - When calling user is viewing profile of another user,
  ///   gives private info about super likes / abuse flags toward that use.
  public query(msg) func getProfilePlus(caller: ?UserId, target: UserId): async ?ProfileInfoPlus {
    do ? {
      accessCheck(msg.caller, #view, #user target)!;
      switch caller {
        case null { getProfilePlus_(null, target)! };
        case (?callerUserName) {
               // has private access to our caller view?
               accessCheck(msg.caller, #update, #user callerUserName)!;
               getProfilePlus_(?callerUserName, target)!
             };
      }
    }
  };

  func filterOutAbuseVideos(videos: [VideoId]) : ?[VideoId] {
    do ? {
      let nonAbuse = Buffer.Buffer<VideoId>(0);
      for (v in videos.vals()) {
        let flags = state.abuseFlagVideos.get1Size(v);
        if (flags < Param.contentModerationThreshold) {
          nonAbuse.add(v)
        }
      };
      nonAbuse.toArray()
    }
  };

  func filterOutAbuseUsers(users: [UserId]) : ?[UserId] {
    do ? {
      let nonAbuse = Buffer.Buffer<UserId>(0);
      for (u in users.vals()) {
        let flags = state.abuseFlagUsers.get1Size(u);
        if (flags < Param.contentModerationThreshold) {
          nonAbuse.add(u)
        }
      };
      nonAbuse.toArray()
    }
  };

  func getNonAbuseVideos(caller: ?UserId, videos: [VideoId]) : ?[VideoInfo] {
    do ? {
      let nonAbuse = Buffer.Buffer<VideoInfo>(0);
      for (v in videos.vals()) {
        let flags = state.abuseFlagVideos.get1Size(v);
        if (flags < Param.contentModerationThreshold) {
          nonAbuse.add(getVideoInfo_(caller, v)!)
        }
      };
      nonAbuse.toArray()
    }
  };

  func getNonAbuseProfiles(users: [UserId]) : ?[ProfileInfo] {
    do ? {
      let nonAbuse = Buffer.Buffer<ProfileInfo>(0);
      for (u in users.vals()) {
        let flags = state.abuseFlagUsers.get1Size(u);
        if (flags < Param.contentModerationThreshold) {
          nonAbuse.add(getProfileInfo_(u)!)
        }
      };
      nonAbuse.toArray()
    }
  };

  func computeAllowance_(limitPerRecentDuration : Nat,
                         collectEvent : State.Event.Event -> Bool,
  ) : Types.AllowanceBalance {
    if (limitPerRecentDuration == 0) {
      #zeroForever
    } else {
      let now = timeNow_();
      let matches = collectLogMatches(collectEvent);
      if (matches.size() < limitPerRecentDuration) {
        #nonZero (limitPerRecentDuration - matches.size()) // total remaining.
      } else {
        // assert invariant: we do not exceed the limit.
        assert matches.size() == limitPerRecentDuration;
        let leastRecentTime = matches[matches.size() - 1].time;
        #zeroUntil (leastRecentTime + Param.recentPastDuration) // total wait.
      }
    }
  };

  // targetId -- for hashing the targets of abuse flags
  func targetText(target : Types.ActionTarget) : Text {
    switch target {
    case (#video(i)) "#video=" # i;
    case (#user(i)) "#user=" # i;
    case _ { loop { assert false } };
    }
  };

  // targetHash -- for collecting sets of targets, and doing set operations.
  func targetHash(target : Types.ActionTarget) : Hash.Hash {
    Text.hash(targetText(target))
  };

  func targetEqual(targ1 : Types.ActionTarget, targ2 : Types.ActionTarget) : Bool {
    targ1 == targ2
  };

  func getUserAllowances_(user: UserId) : Types.UserAllowances {
    {
      abuseFlags = do {
        let targets = TrieMap.TrieMap<Types.ActionTarget, Bool>(targetEqual, targetHash);
        computeAllowance_(
          Param.maxRecentAbuseFlags,
          // true when we INCLUDE an event in the total
          func (ev: State.Event.Event) : Bool {
            switch (ev.kind) {
            case (#abuseFlag(af)) {
                   if (af.reporter != user) { return false };
                   switch (targets.get(af.target)) {
                     case null {
                            targets.put(af.target, af.flag);
                            af.flag
                          };
                     case (?b) { b }
                   }};
            case _ { false };
            }
          },
        )};

      superLikes = do {
        let targets = TrieMap.TrieMap<Types.ActionTarget, Bool>(targetEqual, targetHash);
        computeAllowance_(
          Param.maxRecentSuperLikes,
          func (ev: State.Event.Event) : Bool {
            switch (ev.kind) {
            case (#superLikeVideo(slv)) {
                   if (slv.source != user) { return false };
                   switch (targets.get(#video(slv.target))) {
                     case null {
                            targets.put(#video(slv.target), slv.superLikes);
                            slv.superLikes
                          };
                     case (?b) { b }
                   }};
            case _ { false };
            }
            }
        )};
    }
  };

  func getProfilePlus_(caller: ?UserId, userId: UserId): ?ProfileInfoPlus {
    do ? {
      let profile = state.profiles.get(userId)!;
      {
        userName = profile.userName;
        following = getNonAbuseProfiles(state.follows.get0(userId))!;
        followers = getNonAbuseProfiles(state.follows.get1(userId))!;
        likedVideos = getNonAbuseVideos(caller, state.likes.get0(userId))!;
        uploadedVideos = getNonAbuseVideos(caller, state.uploaded.get0(userId))!;
        hasPic = false;
        rewards = state.rewards.get(userId)!;
        abuseFlagCount = state.abuseFlagUsers.get1Size(userId) ; // count total for userId.
        viewerHasFlagged = do ? { // if caller is non-null,
          state.abuseFlagUsers.isMember(caller!, userId) ; // check if we are there.
        };
        allowances = do ? { if (caller! == userId) {
          getUserAllowances_(caller!)
        } else { null! } };
      }
    }
  };

  public query(msg) func getProfiles() : async ?[ProfileInfo] {
    do ? {
      accessCheck(msg.caller, #admin, #all)!;
      let b = Buffer.Buffer<ProfileInfo>(0);
      for ((p, _) in state.profiles.entries()) {
        b.add(getProfileInfo_(p)!)
      };
      b.toArray()
    }
  };

  public query(msg) func getVideos() : async ?[VideoInfo] {
    do ? {
      accessCheck(msg.caller, #admin, #all)!;
      let b = Buffer.Buffer<VideoInfo>(0);
      for ((v, _) in state.videos.entries()) {
        b.add(getVideoInfo_(null, v)!)
      };
      b.toArray()
    }
  };

  public query(msg) func getProfilePic(userId : UserId) : async ?ProfilePic {
    do ? {
      accessCheck(msg.caller, #view, #user userId)!;
      state.profilePics.get(userId)!
    }
  };

  public shared(msg) func putRewards(
    receiver : UserId,
    amount : Nat
  ) : async ?() {
    do ? {
      accessCheck(msg.caller, #admin, #user receiver)!;
      let bal = state.rewards.get(receiver)!;
      state.rewards.put(receiver, bal + amount);
    }
  };

  public shared(msg) func putRewardTransfer(
    sender : UserId,
    receiver : UserId,
    amount : Nat
  ) : async ?() {
    do ? {
      accessCheck(msg.caller, #update, #user sender)!;
      putRewardTransfer_(sender, receiver, amount)!
    }
  };

  func putRewardTransfer_(sender : UserId,
                          receiver : UserId, amount : Nat) : ?() {
    do ? {
      let balSrc = state.rewards.get(sender)!;
      let balTgt = state.rewards.get(receiver)!;
      if (balSrc >= amount) {
        state.rewards.put(sender, balSrc - amount);
        state.rewards.put(receiver, balTgt + amount);

        logEvent(#rewardPointTransfer({sender = sender; receiver = receiver; amount = amount}));
        state.messages.put(receiver,
           { id = state.eventCount;
             time = timeNow_();
             event = #transferReward {
               rewards = amount;
             }
           });

      } else { return null }
    }
  };

  public shared(msg) func putProfilePic(userId : UserId, pic : ?ProfilePic) : async ?() {
    do ? {
      accessCheck(msg.caller, #update, #user userId)!;
      switch pic {
      case (?pic) { state.profilePics.put(userId, pic) };
      case null { ignore state.profilePics.remove(userId) };
      }
    }
  };

  func getVideoResult(i : VideoId) : ?VideoResult {
    do ? {
      (getVideoInfo_(null, i)!, state.videoPics.get(i))
    }
  };

  func getUserUploaded(userId : UserId, limit : ?Nat) : ?VideoResults {
    do ? {
      let buf = Buffer.Buffer<VideoResult>(0);
      for (vid in state.uploaded.get0(userId).vals()) {
        buf.add((getVideoResult vid)!)
      };
      buf.toArray()
    }
  };

  func getFeedVideos_(userId : UserId, limit : ?Nat) : ?VideoResults {
    do ? {
      let vids = HashMap.HashMap<Text, ()>(0, Text.equal, Text.hash);
      let _ = state.profiles.get(userId)!; // assert userId exists
      let buf = Buffer.Buffer<VideoResult>(0);
      let followIds = state.follows.get0(userId);
      label loopFollows
      for (i in followIds.vals()) {
        switch limit { case null { }; case (?l) { if (buf.size() == l) { break loopFollows } } };
        let vs = getUserUploaded(i, limit)!;
        for ((vi, vp) in vs.vals()) {
          if (vids.get(vi.videoId) == null) {
            vids.put(vi.videoId, ());
            buf.add((vi, vp));
          }
        }
      };
      label loopAll
      for ((vid, v) in state.videos.entries()) {
        switch limit { case null { }; case (?l) { if (buf.size() == l) { break loopAll } } };
        if (vids.get(vid) == null) {
            vids.put(vid, ());
            let vPic = state.videoPics.get(vid);
            let vi = getVideoInfo_(?userId, vid)!;
            buf.add((vi, vPic));
        }
      };
      buf.toArray()
    }
  };

  public query(msg) func getFeedVideos(userId : UserId, limit : ?Nat) : async ?VideoResults {
    do ? {
      // privacy check: because we personalize the feed (example is abuse flag information).
      accessCheck(msg.caller, #update, #user userId)!;
      getFeedVideos_(userId, limit)!
    }
  };

  public query(msg) func getProfileVideos(i : UserId, limit : ?Nat) : async ?VideoResults {
    do ? {
      accessCheck(msg.caller, #view, #user i)!;
      let buf = Buffer.Buffer<VideoResult>(0);
      let vs = getUserUploaded(i, limit)!;
      for (v in vs.vals()) {
        buf.add(v)
      };
      buf.toArray()
    }
  };

  public query(msg) func getSearchVideos(userId : UserId, terms : [Text], limit : ?Nat) : async ?VideoResults {
    do ? {
      accessCheck(msg.caller, #view, #user userId)!;
      getFeedVideos_(userId, limit)!;
    }
  };

  // check if adding the source-target pair "now" in the log is valid.
  // needed here (backend logic) and by front-end logic, when rendering enabled/disabled button status for superLike controls.
  func getSuperLikeValidNow_(source : UserId, target : VideoId) : Bool {
    let notRecent = timeNow_() - Param.recentPastDuration;
    let superLiked = HashMap.HashMap<Text, Bool>(0, Text.equal, Text.hash);
    superLiked.put(target, true);
    var count = 1;

    label hugeLog
    for (ev in state.eventLog.revVals()) {
      if(ev.time <= notRecent){ break hugeLog };
      switch (ev.kind) {
        case (#superLikeVideo(sl)) {
               if(sl.source == source and superLiked.get(sl.target) == null){
                   superLiked.put(sl.target, sl.superLikes);
                   if (sl.superLikes) {
                       count += 1;
                   };
               }
             };
        case _ { };
      };
    };

    count <= Param.maxRecentSuperLikes;
  };

  func videoIsViral(videoId : VideoId) : Bool {
    Option.isSome(do ? {
          let v = state.videos.get(videoId)!;
          v.viralAt!
    })
  };

  /// Collect "recent events" that match from the log.
  ///
  /// Visits events and orders array as most-to-least recent matching events.
  /// (Most recent match is first visited and first in output, if any.
  /// Least recent match is last visited and last in output, if any.)
  ///
  /// Generalizes checkEmitVideoViral_.
  ///
  /// This is "efficient enough" because we never check the full log,
  /// and we intend to accelerate this operation further with
  /// more pre-emptive caching of what we learn from doing this linear scan.
  /// (Util this linear scan is too slow, let's avoid the complexity of more caching.)
  func collectLogMatches(
    collectEvent : State.Event.Event -> Bool,
  ) : [State.Event.Event] {
    let now = timeNow_();
    let notRecent = now - Param.recentPastDuration;
    let matches = Buffer.Buffer<State.Event.Event>(0);
    label hugeLog
    for (ev in state.eventLog.revVals()) {
      if(ev.time <= notRecent){ break hugeLog };
      if (collectEvent(ev)) {
        matches.add(ev)
      }
    };
    matches.toArray()
  };

  // check if we need to emit viral video signal to CanCan logic.
  func checkEmitVideoViral_(video : VideoId) {
    let vinfo = Option.unwrap(state.videos.get(video));
    if (Option.isSome(vinfo.viralAt)) {
        return;
    };

    let now = timeNow_();
    let notRecent = now - Param.recentPastDuration;
    let superLiked = HashMap.HashMap<Text, Bool>(0, Text.equal, Text.hash);
    let superLikers = Buffer.Buffer<State.Event.ViralVideoSuperLiker>(0);

    label hugeLog
    for (ev in state.eventLog.revVals()) {
      if(ev.time <= notRecent){ break hugeLog };
      switch (ev.kind) {
        case (#superLikeVideo(sl)) {
               if(sl.target == video and superLiked.get(sl.source) == null) {
                   superLiked.put(sl.source, sl.superLikes);
                   // The last sl.superLikes decide whether the user eventually liked the video or not
                   if (sl.superLikes) {
                       superLikers.add({ user = sl.source ; time = ev.time });
                   };
               }
             };
        case _ { };
      };
    };

    if(superLikers.size() >= Param.superLikeViralThreshold) {
        state.videos.put(video,
                         {
                             userId = vinfo.userId ;
                             uploadedAt = vinfo.uploadedAt ;
                             viewCount = vinfo.viewCount ;
                             createdAt = vinfo.createdAt ;
                             viralAt = ?now;
                             caption = vinfo.caption ;
                             tags = vinfo.tags ;
                             name = vinfo.name ;
                             chunkCount = vinfo.chunkCount ;
                         });
        /*
        state.eventLog.add({time=now;
                            kind=#emitSignal(
                              #viralVideo{
                                  video=video;
                                  uploader=vinfo.userId;
                                  superLikers=superLikers.toArray()}
                            )});*/
        let score = Option.get(state.rewards.get(vinfo.userId), 0);
        state.rewards.put(vinfo.userId, score + Param.rewardsForUploader);
        state.eventCount += 1;
        state.messages.put(vinfo.userId,
                           { id = state.eventCount;
                             time = now;
                             event = #uploadReward {
                                 rewards = Param.rewardsForUploader;
                                 videoId = video;
                             }
                           });
        for (id in superLikers.vals()) {
            let score = Option.get(state.rewards.get(id.user), 0);
            state.rewards.put(id.user, score + Param.rewardsForSuperliker);
            state.eventCount += 1;
            state.messages.put(id.user,
                               { id = state.eventCount;
                                 time = now;
                                 event = #superlikerReward {
                                     rewards = Param.rewardsForSuperliker;
                                     videoId = video;
                                 }
                               });
        };
    }
  };

  public query(msg) func getMessages(user: UserId) : async ?[Types.Message] {
    do ? {
      accessCheck(msg.caller, #view, #user user)!;
      state.messages.get0(user)
    }
  };

  public query(msg) func isDropDay() : async ?Bool {
    do ? {
      accessCheck(msg.caller, #view, #pubView)!;
      let now = timeNow_();
      now % (Param.dropDayDuration + Param.dropDayNextDuration) < Param.dropDayDuration
    }
  };

  public query(msg) func getSuperLikeValidNow(source : UserId, target : VideoId) : async ?Bool {
    do ? {
      accessCheck(msg.caller, #view, #user target)!;
      getSuperLikeValidNow_(source, target)
    }
  };

  public query(msg) func getIsSuperLiker(source : UserId, target : VideoId) : async ?Bool {
    do ? {
      accessCheck(msg.caller, #view, #user target)!;
      state.superLikes.isMember(source, target)
    }
  };

  func putSuperLike_(userId : UserId, videoId : VideoId, superLikes_ : Bool) : ?() {
    do ? {
      let _ = state.videos.get(videoId)!; // assert that the videoId is valid
      if superLikes_ {
        if (getSuperLikeValidNow_(userId, videoId)) {
          state.superLikes.put(userId, videoId);
          logEvent(#superLikeVideo({ source = userId ;
                                     target = videoId ;
                                     superLikes = true }
                   ));
          checkEmitVideoViral_(videoId);
        } else {
          logEvent(#superLikeVideoFail({ source = userId ;
                                         target = videoId }));
          return null // fail
        }
      } else {
        state.superLikes.delete(userId, videoId);
        logEvent(#superLikeVideo({ source = userId ;
                                   target = videoId ;
                                   superLikes = false }));
      }
    }
  };

  public shared(msg) func putSuperLike
    (userId : UserId, videoId : VideoId, willSuperLike : Bool) : async ?() {
    do ? {
      accessCheck(msg.caller, #update, #user userId)!;
      putSuperLike_(userId, videoId, willSuperLike)!
    }
  };

  public shared(msg) func putProfileVideoLike
    (userId : UserId, videoId : VideoId, willLike_ : Bool) : async ?() {
    do ? {
      accessCheck(msg.caller, #update, #user userId)!;
      if willLike_ {
        state.likes.put(userId, videoId);
      } else {
        state.likes.delete(userId, videoId)
      };
      logEvent(#likeVideo({ source = userId ;
                            target = videoId ;
                            likes = willLike_ }));
    }
  };

  func putProfileFollow_
    (userId : UserId, followedBy : UserId, follows : Bool) : ?() {
    if (userId == followedBy) { return null };
    if follows {
      state.follows.put(userId, followedBy)
    } else {
      state.follows.delete(userId, followedBy)
    };
    ?()
  };

  public shared(msg) func putProfileFollow
    (userId : UserId, toFollow : UserId, follows : Bool) : async ?() {
    do ? {
      accessCheck(msg.caller, #update, #user userId)!;
      putProfileFollow_(userId, toFollow, follows)!
    }
  };

  // internal function for adding metadata
  func createVideo_(i : VideoInit) : ?VideoId {
    let now = timeNow_();
    let videoId = i.userId # "-" # i.name # "-" # (Int.toText(now));
    switch (state.videos.get(videoId)) {
    case (?_) { /* error -- ID already taken. */ null };
    case null { /* ok, not taken yet. */
           state.videos.put(videoId,
                            {
                              videoId = videoId;
                              userId = i.userId ;
                              name = i.name ;
                              createdAt = i.createdAt ;
                              uploadedAt = now ;
                              viralAt = null ;
                              caption =  i.caption ;
                              chunkCount = i.chunkCount ;
                              tags = i.tags ;
                              viewCount = 0 ;
                            });
           state.uploaded.put(i.userId, videoId);
           logEvent(#createVideo({info = i}));
           ?videoId
         };
    }
  };

  public shared(msg) func createVideo(i : VideoInit) : async ?VideoId {
    do ? {
      accessCheck(msg.caller, #update, #user(i.userId))!;
      createVideo_(i)!
    }
  };

  func getVideoInfo_ (caller : ?UserId, videoId : VideoId) : ?VideoInfo {
    do ? {
      let v = state.videos.get(videoId)!;
      {
        videoId = videoId;
        pic = state.videoPics.get(videoId);
        userId = v.userId ;
        createdAt = v.createdAt ;
        uploadedAt = v.uploadedAt ;
        viralAt = v.viralAt ;
        caption = v.caption ;
        tags = v.tags ;
        likes = state.likes.get1(videoId);
        superLikes = state.superLikes.get1(videoId);
        viewCount = v.viewCount ;
        name = v.name ;
        chunkCount = v.chunkCount ;
        // This implementation makes public all users who flagged every video,
        // but if that information should be kept private, get video info
        // could return just whether the calling user flagged it.
        viewerHasFlagged = do ? {
          state.abuseFlagVideos.isMember(caller!, videoId) ;
        };
        abuseFlagCount = state.abuseFlagVideos.get1Size(videoId);
      }
    }
  };

  public query(msg) func getVideoInfo (caller : ?UserId, target : VideoId) : async ?VideoInfo {
    do ? {
      accessCheck(msg.caller, #view, #video target)!;
      switch caller {
        case null { getVideoInfo_(null, target)! };
        case (?callerUserName) {
               // has private access to our caller view?
               accessCheck(msg.caller, #update, #user callerUserName)!;
               getVideoInfo_(?callerUserName, target)!
             };
      }
    }
  };

  public query(msg) func getVideoPic(videoId : VideoId) : async ?VideoPic {
    do ? {
      accessCheck(msg.caller, #view, #video videoId)!;
      state.videoPics.get(videoId)!
    }
  };

  public shared(msg) func putVideoInfo(videoId : VideoId, videoInit : VideoInit) : async ?() {
    do ? {
      accessCheck(msg.caller, #update, #video videoId)!;
      let i = videoInit ;
      let v = state.videos.get(videoId)!;
      state.videos.put(videoId,
                       {
                         // some fields are "immutable", regardless of caller data:
                         userId = v.userId ;
                         uploadedAt = v.uploadedAt ;
                         viewCount = v.viewCount ;
                         videoId = videoId ;
                         // -- above uses old data ; below is from caller --
                         createdAt = i.createdAt ;
                         viralAt = null;
                         caption = i.caption ;
                         tags = i.tags ;
                         name = i.name ;
                         chunkCount = i.chunkCount ;
                       })
    }
  };

  /// An abuse flag for a video occurs when a reporting user
  /// sets or clears the abuse toggle in their UI for the video.
  public shared (msg) func putAbuseFlagVideo
    (reporter : UserId, target : VideoId, abuseFlag : Bool) : async ?() {
    do ? {
      accessCheck(msg.caller, #update, #user reporter)!;
      logEvent(#abuseFlag({ reporter = reporter ;
                            target = #video(target);
                            flag = abuseFlag }));
      if abuseFlag {
        state.abuseFlagVideos.put(reporter, target)
      } else {
        state.abuseFlagVideos.delete(reporter, target)
      };
    }
  };

  /// An abuse flag for a user occurs when a reporting user
  /// sets or clears the abuse toggle in their UI for the target user.
  public shared(msg) func putAbuseFlagUser
    (reporter : UserId, target : UserId, abuseFlag : Bool) : async ?() {
    do ? {
      accessCheck(msg.caller, #update, #user reporter)!;
      logEvent(#abuseFlag({ reporter = reporter ;
                            target = #user(target);
                            flag = abuseFlag }));
      if abuseFlag {
        state.abuseFlagUsers.put(reporter, target)
      } else {
        state.abuseFlagUsers.delete(reporter, target)
      }
    }
  };

  public shared(msg) func putVideoPic(videoId : VideoId, pic : ?VideoPic) : async ?() {
    do ? {
      accessCheck(msg.caller, #update, #video videoId)!;
      switch pic {
      case (?pic) { state.videoPics.put(videoId, pic) };
      case null {
             switch (state.videoPics.remove(videoId)) {
             case null { /* not found */ return null };
             case _ { /* found and removed. */ };
             }
           };
      }
    }
  };

  func chunkId(videoId : VideoId, chunkNum : Nat) : ChunkId {
    videoId # (Nat.toText(chunkNum))
  };

  public shared(msg) func putVideoChunk
    (videoId : VideoId, chunkNum : Nat, chunkData : [Nat8]) : async ?()
  {
    do ? {
      accessCheck(msg.caller, #update, #video videoId)!;
      state.chunks.put(chunkId(videoId, chunkNum), chunkData);
    }
  };

  public query(msg) func getVideoChunk(videoId : VideoId, chunkNum : Nat) : async ?[Nat8] {
    do ? {
      accessCheck(msg.caller, #view, #video videoId)!;
      state.chunks.get(chunkId(videoId, chunkNum))!
    }
  };

  func createTestData_(users : [UserId], videos : [(UserId, VideoId)]) : ?() {
    do ? {
      for (u in users.vals()) {
        createProfile_(u, null, null)!;
      };
      for ((u, v) in videos.vals()) {
        let _ = createVideo_(
          {userId = u ;
           name = v ;
           createdAt = timeNow_() ;
           chunkCount = 0;
           caption = "";
           tags = [ ];})!;
      };
    }
  };

  public shared(msg) func createTestData(users : [UserId], videos : [(UserId, VideoId)]) : async ?() {
    do ? {
      accessCheck(msg.caller, #admin, #all)!;
      createTestData_(users, videos)!
    }
  };

  public shared(msg) func putTestFollows(follows : [(UserId, UserId)]) : async ?() {
    do ? {
      accessCheck(msg.caller, #admin, #all)!;
      for ((u, v) in follows.vals()) {
        let _ = putProfileFollow_(u, v, true)!;
      }
    }
  };

  public query(msg) func getEventLog() : async ?[State.Event.Event] {
    do ? {
      accessCheck(msg.caller, #admin, #all)!;
      Iter.toArray(state.eventLog.vals())
    }
  };

  public query(msg) func getAccessLog() : async ?[Access.Log.Event.Event] {
    do ? {
      accessCheck(msg.caller, #admin, #all)!;
      Iter.toArray(state.access.log.vals())
    }
  };

  func doDemo_(script : [Demo.Command]) : Demo.Trace {
    let trace = Buffer.Buffer<Demo.TraceCommand>(0);
    let r = do ? {
      for (cmd in script.vals()) {
        switch cmd {
        case (#reset(tm)) {
               reset_(tm); // discards trace
               trace.add({ command = cmd ;
                           result = #ok });
             };
        case (#createTestData(td)) {
               let _ = createTestData_(td.users, td.videos)!;
               trace.add({ command = cmd ;
                           result = #ok });
             };
        case (#putSuperLike(sl)) {
               let _ = putSuperLike_(sl.userId, sl.videoId, sl.superLikes)!;
               trace.add({ command = cmd ;
                           result = #ok });
             };
        case (#putProfileFollow(pf)) {
               let _ = putProfileFollow_(pf.userId, pf.toFollow, pf.follows)!;
               trace.add({ command = cmd ;
                           result = #ok });
             };
        case (#assertVideoFeed(vp)) {
               let vs : [VideoResult] = getFeedVideos_(vp.userId, vp.limit)!;
               let ids = Array.map<VideoResult, VideoId>
               (vs, func(vr : VideoResult) : VideoId { vr.0.videoId });
               let b = switch (vp.videosPred) {
                 case (#equals(expected)) {
                        Array.equal<VideoId>(ids, expected, Text.equal)
                      };
                 case (#containsAll(members)) {
                        Base.Array.containsAll<VideoId>(ids, members, Text.equal)
                      };
               };
               if b {
                 trace.add({ command = cmd ;
                             result = #ok });
               } else {
                 trace.add({ command = cmd ;
                             result = #err "video feed assertion failed"});
               }
             };
        case (#assertVideoVirality(avv)) {
               if (videoIsViral(avv.videoId) == avv.isViral) {
                 trace.add({ command = cmd ;
                             result = #ok });
               } else {
                 trace.add({ command = cmd ;
                             result = #err "viral assertion failed"});
               }
             };
        case (#putRewardTransfer(sra)) {
              switch (putRewardTransfer_(sra.sender, sra.receiver, sra.amount)) {
                case null {
                   trace.add({ command = cmd ;
                               result = #err "insufficient rewards"});
                };
                case (?()) {
                   trace.add({ command = cmd ;
                               result = #ok });
                }
              }
           };
        };
      };
    };
    // from option monad (above) to trace monad (below)
    let t = trace.toArray();
    switch r {
    case null { { status = #err ; trace = t } };
    case _ { { status = #ok ; trace = t } };
    }
  };

  public shared(msg) func doDemo(script : [Demo.Command]) : async ?Demo.Trace {
    do ? {
      accessCheck(msg.caller, #admin, #all)!;
      doDemo_(script)
    }
  };
}
