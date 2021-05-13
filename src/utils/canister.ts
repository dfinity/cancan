/// <reference path="../react-app-env.d.ts" />

/*
 * This file wraps all of our canister interaction functions and makes sure they
 * return the expected values by massaging any data necessary.
 */

import { Principal } from "@dfinity/agent";

import {
  Message,
  ProfileInfoPlus,
  VideoInfo,
  VideoInit,
  VideoResults,
} from "./canister/typings";
import { unwrap } from "./index";
import { baseActor } from "./canister/actor";

const CanCan = baseActor;

export type Optional<Type> = [Type] | [];

export function getUserFromStorage(
  storage = window.localStorage,
  key: string
): ProfileInfoPlus | undefined {
  const lsUser = storage.getItem(key);
  if (lsUser) {
    return JSON.parse(lsUser, (k, v) => {
      if (k === "rewards") {
        return BigInt(v);
      }
      return v;
    }) as ProfileInfoPlus;
  } else {
    return undefined;
  }
}

export async function getUserNameByPrincipal(principal: Principal) {
  const icUserName = unwrap<string>(
    await CanCan.getUserNameByPrincipal(principal)
  )!;
  return icUserName;
}

export async function createUser(
  userId: string,
  principal?: Principal | null
): Promise<ProfileInfoPlus> {
  if (!principal) {
    throw Error("trying to create user without principal");
  }
  const profile = unwrap<ProfileInfoPlus>(
    await CanCan.createProfile(userId, [])
  );
  if (profile) {
    return profile;
  } else {
    throw Error("failed to create profile: " + JSON.stringify(profile));
  }
}

export async function findOrCreateUser(
  userId: string,
  principal: Principal,
  key: string
): Promise<ProfileInfoPlus> {
  const lsUSER = getUserFromStorage(undefined, key);
  if (lsUSER !== undefined) {
    return lsUSER;
  }

  const icUser = await getUserFromCanister(userId);
  if (icUser !== null) {
    return icUser;
  } else {
    try {
      createUser(userId, principal);
    } catch (error) {
      return Promise.reject(error);
    }
    throw Error("couldnt find or create user");
  }
}

export async function isDropDay(): Promise<boolean> {
  return Boolean(unwrap<boolean>(await CanCan.isDropDay()));
}

export async function getUserFromCanister(
  userId: string
): Promise<ProfileInfoPlus | null> {
  const icUser = unwrap<ProfileInfoPlus>(
    await CanCan.getProfilePlus([userId], userId)
  );
  if (icUser) {
    return icUser;
  } else {
    return null;
  }
}

export async function getSearchVideos(
  userId: string,
  terms: string[],
  limit: [] | [number] = [3]
): Promise<VideoInfo[]> {
  // @ts-ignore
  const videos = unwrap<VideoResults>(
    await CanCan.getSearchVideos(userId, terms, limit)
  );
  if (videos !== null) {
    const unwrappedVideos = videos.map((v) => v[0]);
    return unwrappedVideos;
  } else {
    return Promise.resolve([]);
  }
}

export async function getFeedVideos(userId: string): Promise<VideoInfo[]> {
  const videos = unwrap<VideoResults>(await CanCan.getFeedVideos(userId, []));
  if (videos !== null) {
    const unwrappedVideos = videos.map((v) => v[0]);
    return unwrappedVideos;
  } else {
    return Promise.resolve([]);
  }
}

export async function getVideoInfo(userId: string, videoId: string) {
  const videoInfo = unwrap(await CanCan.getVideoInfo([userId], videoId));
  if (videoInfo !== null) {
    return videoInfo;
  } else {
    throw Error("no video found with id: " + videoId);
  }
}
export async function getProfilePic(userId: string) {
  const profilePic = unwrap(await CanCan.getProfilePic(userId));
  return profilePic;
}

export async function createVideo(videoInit: VideoInit): Promise<string> {
  const videoId = unwrap<string>(await CanCan.createVideo(videoInit));
  if (videoId) {
    return videoId;
  } else {
    throw Error("failed to create video");
  }
}

export async function follow(
  userToFollow: string,
  follower: string,
  willFollow: boolean
) {
  try {
    await CanCan.putProfileFollow(userToFollow, follower, willFollow);
  } catch (error) {
    console.error(error);
  }
}

export async function like(user: string, videoId: string, willLike: boolean) {
  try {
    await CanCan.putProfileVideoLike(user, videoId, willLike);
  } catch (error) {
    console.error(error);
  }
}

export async function superLike(
  user: string,
  videoId: string,
  willSuperLike: boolean
) {
  try {
    await CanCan.putSuperLike(user, videoId, willSuperLike);
  } catch (error) {
    console.error(error);
  }
}

// Videos are stored as chunked byteArrays, and must be assembled once received
export async function getVideoChunks(videoInfo: VideoInfo): Promise<string> {
  const { videoId, chunkCount } = videoInfo;
  const chunkBuffers: Buffer[] = [];
  const chunksAsPromises: Array<Promise<Optional<number[]>>> = [];
  for (let i = 1; i <= Number(chunkCount.toString()); i++) {
    chunksAsPromises.push(CanCan.getVideoChunk(videoId, i));
  }
  const nestedBytes: number[][] = (await Promise.all(chunksAsPromises))
    .map(unwrap)
    .filter((v): v is number[] => v !== null);
  nestedBytes.forEach((bytes) => {
    const bytesAsBuffer = Buffer.from(new Uint8Array(bytes));
    chunkBuffers.push(bytesAsBuffer);
  });
  const videoBlob = new Blob([Buffer.concat(chunkBuffers)], {
    type: "video/mp4",
  });
  const vidURL = URL.createObjectURL(videoBlob);
  return vidURL;
}

export async function putVideoChunk(
  videoId: string,
  chunkNum: number,
  chunkData: number[]
) {
  return CanCan.putVideoChunk(videoId, chunkNum, chunkData);
}

export async function putVideoPic(videoId: string, file: number[]) {
  return CanCan.putVideoPic(videoId, [file]);
}

export async function getVideoPic(videoId: string): Promise<number[]> {
  const icResponse = await CanCan.getVideoPic(videoId);
  const pic = unwrap<number[]>(icResponse);
  if (pic !== null) {
    return pic;
  } else {
    throw Error("pic should not be empty");
  }
}

export function getLocationCanisterPrincipal(location: Location): Principal {
  const pattern = /(\.?((?:[a-z0-9]{5}-){4}[a-z0-9]{3})\..*)|(canisterId=([^$&]+))/;
  const match = location.href.match(pattern);
  if (!match) {
    throw new Error("Failed to parse url containing canisterId");
  }
  const [, , canisterId] = match;
  const canisterPrincipal = Principal.fromText(canisterId);
  return canisterPrincipal;
}

export async function checkUsername(username: string): Promise<boolean> {
  return await CanCan.checkUsernameAvailable(username);
}

export async function getMessages(username: string): Promise<Message[]> {
  const messages = await CanCan.getMessages(username);
  return messages;
}

export async function putRewardTransfer(
  sender: string,
  recipient: string,
  amount: BigInt
) {
  return await CanCan.putRewardTransfer(sender, recipient, amount);
}

export async function putAbuseFlagVideo(
  reporter: string,
  target: string,
  shouldFlag: boolean
) {
  return await CanCan.putAbuseFlagVideo(reporter, target, shouldFlag);
}
