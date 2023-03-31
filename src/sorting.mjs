import { promises as fs } from "fs";
import fsSync from "fs";

import { List } from "../gleam_stdlib/gleam.mjs";
import { is_ok, unwrap } from "../gleam_stdlib/gleam/result.mjs";

/// Thank you stack overflow https://stackoverflow.com/a/64385468
async function* getFiles(path = `./`) {
  const entries = await fs.readdir(path, { withFileTypes: true });

  for (let file of entries) {
    if (file.isDirectory()) {
      yield* getFiles(`${path}${file.name}/`);
    } else {
      yield { ...file, path: path + file.name };
    }
  }
}

export async function sort(path, func) {
  if (!path.endsWith("/") && !path.endsWith(".gleam")) {
    path = path + "/";
  }

  let files;
  if (!path.endsWith(".gleam")) {
    files = [];

    for await (const file of getFiles(path)) {
      files.push(file);
    }
  } else {
    files = [{ name: path, path: "./" + path }];
  }

  for (let file of files) {
    if (!file.name.endsWith(".gleam")) {
      continue;
    }
    let contents = await fs.readFile(file.path, "utf-8");

    let result = func(contents);

    if (is_ok(result)) {
      fs.writeFile(file.path, unwrap(result));
    }
  }
}

export function getArgs() {
  return List.fromArray(process.argv.slice(2));
}

export function dirExists(path) {
  return fsSync.existsSync(path);
}

export function exit(code) {
  process.exit(code);
}
