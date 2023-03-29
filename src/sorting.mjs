import { promises as fs } from "fs";

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
  if (!path.endsWith("/")) {
    path = path + "/";
  }
  for await (const file of getFiles(path)) {
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
