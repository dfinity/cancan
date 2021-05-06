#!/usr/bin/env node

import path from "path";
import fs from "fs";
import { HttpAgent, Actor } from "@dfinity/agent";
import _SERVICE from "../src/utils/canister/typings";

const dfxConfig = require("../dfx.json");

const { DFX_NETWORK = "local" } = process.env;

const outputRoot = path.join(
  process.cwd(),
  ".dfx",
  DFX_NETWORK,
  "canisters",
  "CanCan",
  "CanCan.js"
);

const INDEX = parseInt(process.argv[2], 10) ?? 0;

const encodeArrayBuffer = (file) => Array.from(new Uint8Array(file));

const MAX_CHUNK_SIZE = 1024 * 500; // 500kb
interface Video {
  userId: string;
  name: string;
  createdAt: number;
  caption: string;
  tags: string[];
  likes: string[];
}

const { idlFactory, canisterId } = require(outputRoot);

// @ts-ignore
globalThis.window = {
  // @ts-ignore
  location: { protocol: "http:" },
};
globalThis.window.fetch = require("node-fetch");
globalThis.fetch = require("node-fetch");

export const canister = Actor.createActor<_SERVICE>(idlFactory, {
  agent: new HttpAgent({ host: dfxConfig.networks.local.bind }),
  canisterId,
});
const assetPath = path.resolve(__dirname, "data/videos");

// Make the magic happen:

new Promise(() => {
  if (INDEX === 1) {
    try {
      seedProfiles().then(() => {
        process.exit(0);
      });
    } catch (error) {
      process.exit(1);
    }
  } else {
    seedVideos();
  }
}).finally(() => {
  process.exit(0);
});

async function seedProfiles() {
  const { profiles } = generateSeedData();
  console.info("Creating test profiles...");
  try {
    console.time("Test profiles created in");
    const profileNames = profiles.map((profile) => profile.userName);
    await canister.createTestData(profileNames.slice(1), []);

    // set up followings
    profiles.forEach((profile) => {
      profile.following.forEach((followedUser) => {
        canister.putProfileFollow(followedUser, profile.userName, true);
      });
    });
    console.timeEnd("Test profiles created in");
  } catch (error) {
    console.error("Failed to create test profiles.", error);
  }
}

async function seedVideos() {
  const { videos } = generateSeedData();

  try {
    // upload default videos
    videos.forEach(uploadVideo);
  } catch (error) {
    console.error("Failed to create test videos.", error);
  }
}

async function uploadVideo(video) {
  const pathname = path.resolve(__dirname, assetPath, video.name, video.name);
  const videoFilePath = `${pathname}.mp4`;
  const videoPicPath = `${pathname}.jpg`;

  console.time(`Created video ${video.name}`);
  const videoChunks = chunkFile(videoFilePath);
  const videoIdResponse = await canister.createVideo({
    ...video,
    chunkCount: videoChunks.length,
  });
  console.timeEnd(`Created video ${video.name}`);

  const videoId = videoIdResponse[0] as string;

  console.time(`Stored video ${video.name}`);
  await Promise.all(
    videoChunks.map((chunk, chunkIndex) =>
      canister.putVideoChunk(videoId, chunkIndex + 1, chunk)
    )
  );
  console.timeEnd(`Stored video ${video.name}`);

  // upload png
  console.time(`Stored video thumbnail for ${video.name}`);
  const videoPicFile = fs.readFileSync(videoPicPath);
  const videoPicArray = videoPicFile.buffer.slice(0);
  const picAsNat = encodeArrayBuffer(videoPicArray);
  await canister.putVideoPic(videoId, [picAsNat]);
  console.timeEnd(`Stored video thumbnail for ${video.name}`);
}

function chunkFile(filePath) {
  const file = fs.readFileSync(filePath);
  const fileStats = fs.statSync(filePath);
  const fileSize = fileStats.size;

  let chunk = 1;
  const chunks: number[][] = [];
  for (
    let byteStart = 0;
    byteStart < fileSize;
    byteStart += MAX_CHUNK_SIZE, chunk++
  ) {
    const videoSlice = file.buffer.slice(
      byteStart,
      Math.min(fileSize, byteStart + MAX_CHUNK_SIZE)
    );
    const sliceToNat = encodeArrayBuffer(videoSlice);
    chunks.push(sliceToNat);
  }

  return chunks;
}

function generateSeedData() {
  const userNames = [
    "tham",
    "Alana",
    "Brandon",
    "Charlotte",
    "Damien",
    "Etta",
    "Freddie",
    "Genevieve",
    "Hank",
    "Isabel",
    "Janette",
  ];
  const videoNames = ["happy_dog", "groovin", "jump", "lake", "pool"];
  const captions = [
    "This video is so good",
    "I can't believe I caught this!",
    "Really something else",
    "LOL I'm totally like this",
    "Hmm... I don't think this is real",
  ];
  const tags = [
    "cat",
    "dog",
    "peace",
    "dance",
    "swim",
    "bounce",
    "water",
    "crazy",
  ];

  const profiles = userNames.map((name, index) => {
    const otherUsers = [...userNames];
    otherUsers.splice(index, 1);

    return {
      userName: name,
      following: multiSample(otherUsers),
    };
  });

  const videos: Video[] = [];
  videos.push(createVideo(userNames, videoNames, captions, tags));

  return { profiles, videos };
}

function createVideo(
  userNames: string[],
  videoNames: string[],
  captions: string[],
  _tags: string[]
): Video {
  const userId = sample(userNames);
  const name = videoNames[INDEX % videoNames.length];
  const caption = sample(captions);
  const tags = multiSample(_tags);
  const likes = multiSample(userNames);
  return {
    userId,
    name,
    caption,
    tags,
    likes,
    createdAt: Date.now(),
  };
}

function randomize(num) {
  return Math.floor(Math.random() * num);
}
function sample(array) {
  return array[randomize(array.length)];
}
function multiSample(array) {
  const tempArray = [...array];
  const numToRemove = randomize(array.length);
  for (let i = 0; i < numToRemove; i++) {
    tempArray.splice(randomize(array.length), 1);
  }
  return tempArray;
}
