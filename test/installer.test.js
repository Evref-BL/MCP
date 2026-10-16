import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";
import test from "node:test";
import { fileURLToPath } from "node:url";
import { install, installGuidance } from "../node/index.js";

function temporaryProject() {
  return fs.mkdtempSync(path.join(os.tmpdir(), "pharo-mcp-"));
}

function removeProject(project) {
  fs.rmSync(project, { recursive: true, force: true });
}

const hosts = {
  claude: { directory: ".claude", guide: "CLAUDE.md", configuration: ".mcp.json" },
  codex: { directory: ".codex", guide: "AGENTS.md", configuration: ".codex/config.toml" },
  opencode: { directory: ".opencode", guide: "AGENTS.md", configuration: "opencode.json" },
};

const userReferences = [
  "getting-started.md",
  "safety-and-ecosystem.md",
  "source-vs-live-image.md",
  "tool-reference.md",
  "troubleshooting.md",
  "using-pharo-mcp.md",
];

for (const [host, { directory, guide }] of Object.entries(hosts)) {
  test(`installGuidance installs ${host} assets without direct MCP configuration`, () => {
    const project = temporaryProject();
    try {
      fs.writeFileSync(path.join(project, guide), "# Existing instructions\n");

      const result = installGuidance({ host, cwd: project });

      assert.equal(result.host, host);
      assert.ok(fs.existsSync(path.join(project, directory, "pharo.AGENTS.md")));
      assert.ok(fs.existsSync(path.join(project, directory, "skills", "pharo-project-load", "SKILL.md")));
      assert.ok(fs.existsSync(path.join(project, directory, "pharo-references", "pharo-coding-rules.md")));
      for (const reference of userReferences) {
        assert.ok(fs.existsSync(path.join(project, directory, "pharo-references", reference)));
      }
      assert.doesNotMatch(fs.readFileSync(path.join(project, directory, "pharo.AGENTS.md"), "utf8"), /https?:\/\//);
      assert.match(fs.readFileSync(path.join(project, guide), "utf8"), new RegExp(`${directory.replace(".", "\\.")}/pharo\\.AGENTS\\.md`));
      assert.equal(fs.existsSync(path.join(project, "pharo-skills")), false);
      assert.equal(fs.existsSync(path.join(project, "pharo-references")), false);
      assert.equal(fs.existsSync(path.join(project, ".mcp.json")), false);
    } finally {
      removeProject(project);
    }
  });
}

for (const [host, { configuration }] of Object.entries(hosts)) {
  test(`install adds ${host} direct MCP configuration`, () => {
    const project = temporaryProject();
    try {
      install({ host, cwd: project });

      const content = fs.readFileSync(path.join(project, configuration), "utf8");
      assert.match(content, /127\.0\.0\.1:4000/);
      if (configuration.endsWith(".json")) {
        assert.doesNotThrow(() => JSON.parse(content));
      }
    } finally {
      removeProject(project);
    }
  });
}

test("install is idempotent", () => {
  const project = temporaryProject();
  try {
    install({ host: "codex", cwd: project });
    install({ host: "codex", cwd: project });
  } finally {
    removeProject(project);
  }
});

test("install refuses an existing direct MCP configuration before writing guidance", () => {
  const project = temporaryProject();
  try {
    fs.mkdirSync(path.join(project, ".codex"));
    fs.writeFileSync(path.join(project, ".codex/config.toml"), "[mcp_servers.other]\n");

    assert.throws(() => install({ host: "codex", cwd: project }), /Refusing to replace/);
    assert.equal(fs.existsSync(path.join(project, "AGENTS.md")), false);
  } finally {
    removeProject(project);
  }
});

test("CLI installs into the current directory", () => {
  const project = temporaryProject();
  try {
    const cli = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../bin/pharo-mcp.js");
    const result = spawnSync(process.execPath, [cli, "install", "--host", "opencode"], {
      cwd: project,
      encoding: "utf8",
      env: { ...process.env },
    });
    assert.equal(result.status, 0, result.stderr);
    assert.ok(fs.existsSync(path.join(project, "opencode.json")));
    assert.ok(fs.existsSync(path.join(project, ".opencode/skills/pharo-project-load/SKILL.md")));
  } finally {
    removeProject(project);
  }
});
