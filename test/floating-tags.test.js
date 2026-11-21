import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { execFileSync, spawnSync } from "node:child_process";
import test from "node:test";
import { fileURLToPath } from "node:url";

const script = fileURLToPath(new URL("../.github/scripts/move-floating-tags.sh", import.meta.url));

test("floating tags advance within their lines without following older or prerelease tags", (t) => {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), "mcp-floating-tags-"));
  t.after(() => fs.rmSync(directory, { recursive: true, force: true }));
  const remote = path.join(directory, "remote.git");
  const checkout = path.join(directory, "checkout");
  const git = (...args) => execFileSync("git", args, { cwd: checkout, encoding: "utf8", stdio: ["ignore", "pipe", "pipe"] }).trim();
  fs.mkdirSync(checkout);
  execFileSync("git", ["init", "--bare", remote], { stdio: "ignore" });
  git("init");
  git("config", "user.name", "Test");
  git("config", "user.email", "test@example.invalid");
  git("remote", "add", "origin", remote);

  function release(tag, annotated = false) {
    git("commit", "--allow-empty", "-m", tag);
    git("tag", ...(annotated ? ["-a", "-m", tag] : []), tag);
    git("push", "origin", `refs/tags/${tag}`);
    return git("rev-parse", "HEAD");
  }
  const move = (tag) => execFileSync("bash", [script, tag], { cwd: checkout, stdio: "pipe" });
  const target = (tag) => execFileSync("git", ["--git-dir", remote, "rev-parse", `refs/tags/${tag}`], { encoding: "utf8" }).trim();
  const remoteTags = () => git("ls-remote", "--tags", "origin");

  const first = release("v4.0.0");
  const patch = release("v4.0.2");
  const minor = release("v4.1.0");
  const latest = release("v4.10.0", true);
  release("v4.99.0-rc.1");
  release("v5.0.0-rc.1");

  move("v4.10.0");
  assert.equal(target("v4.x.x"), latest);
  assert.equal(target("v4.10.x"), latest);
  move("v4.0.2");
  assert.equal(target("v4.0.x"), patch);
  assert.equal(target("v4.x.x"), latest);
  move("v4.1.0");
  assert.equal(target("v4.1.x"), minor);
  assert.equal(target("v4.x.x"), latest);

  const before = remoteTags();
  for (const tag of ["v4.0.0", "v4.10.0", "v4.99.0-rc.1", "v5.0.0-rc.1", "v4.x.x", "main"]) move(tag);
  assert.equal(remoteTags(), before);
  assert.equal(target("v4.0.0"), first);

  const next = release("v4.10.1");
  move("v4.10.1");
  assert.equal(target("v4.x.x"), next);
  assert.equal(target("v4.10.x"), next);
  move("v4.10.0");
  assert.equal(target("v4.x.x"), next);
  assert.equal(target("v4.10.x"), next);

  const after = remoteTags();
  const missing = spawnSync("bash", [script, "v9.0.0"], { cwd: checkout });
  assert.notEqual(missing.status, 0);
  assert.equal(remoteTags(), after);

  const concurrent = release("v4.10.2");
  git("tag", "--delete", "v4.10.2");
  for (const tag of ["v4.x.x", "v4.10.x"]) {
    execFileSync("git", ["--git-dir", remote, "update-ref", `refs/tags/${tag}`, concurrent]);
  }
  const raced = spawnSync("bash", [script, "v4.10.1"], { cwd: checkout });
  assert.notEqual(raced.status, 0);
  assert.equal(target("v4.x.x"), concurrent);
  assert.equal(target("v4.10.x"), concurrent);
});
