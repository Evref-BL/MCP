import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const hosts = {
  claude: {
    directory: ".claude",
    guide: "CLAUDE.md",
    configuration: [".claude/mcp.json", ".mcp.json"],
  },
  codex: {
    directory: ".codex",
    guide: "AGENTS.md",
    configuration: [".codex/config.toml", ".codex/config.toml"],
  },
  opencode: {
    directory: ".opencode",
    guide: "AGENTS.md",
    configuration: [".opencode/opencode.json", "opencode.json"],
  },
};

const managedBlock = {
  begin: "<!-- pharo-mcp:begin -->",
  end: "<!-- pharo-mcp:end -->",
};

export function templateDirectory() {
  return path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../templates");
}

function hostConfiguration(host) {
  const configuration = hosts[host];
  if (!configuration) {
    throw new Error(`Unknown agent host: ${host}. Use claude, codex, or opencode.`);
  }
  return configuration;
}

function filesIn(directory) {
  return fs.readdirSync(directory, { withFileTypes: true }).flatMap((entry) => {
    const source = path.join(directory, entry.name);
    return entry.isDirectory() ? filesIn(source) : [source];
  });
}

function directoryPlan(sourceRelativePath, targetRelativePath, host) {
  const sourceDirectory = path.join(templateDirectory(), sourceRelativePath);
  return filesIn(sourceDirectory).filter((source) =>
    host === "codex" || !source.endsWith(`${path.sep}agents${path.sep}openai.yaml`)
  ).map((source) => ({
    source,
    target: path.join(targetRelativePath, path.relative(sourceDirectory, source)),
  }));
}

function filePlan(sourceRelativePath, targetRelativePath) {
  return [{
    source: path.join(templateDirectory(), sourceRelativePath),
    target: targetRelativePath,
  }];
}

function guidancePlan(configuration, host) {
  return [
    ...filePlan("pharo.AGENTS.md", path.join(configuration.directory, "pharo.AGENTS.md")),
    ...directoryPlan("pharo-skills", path.join(configuration.directory, "skills"), host),
    ...directoryPlan("pharo-references", path.join(configuration.directory, "pharo-references")),
  ];
}

function fullPlan(configuration, host) {
  const [source, target] = configuration.configuration;
  return [...guidancePlan(configuration, host), ...filePlan(source, target)];
}

function absolutePlan(cwd, plan) {
  return plan.map(({ source, target }) => ({ source, target: path.resolve(cwd, target) }));
}

function assertCompatible(plan) {
  for (const { source, target } of plan) {
    if (!fs.existsSync(target)) {
      continue;
    }
    if (!fs.statSync(target).isFile() || !fs.readFileSync(source).equals(fs.readFileSync(target))) {
      throw new Error(`Refusing to replace existing file: ${target}`);
    }
  }
}

function copyMissing(plan) {
  for (const { source, target } of plan) {
    if (fs.existsSync(target)) {
      continue;
    }
    fs.mkdirSync(path.dirname(target), { recursive: true });
    fs.copyFileSync(source, target);
    fs.chmodSync(target, fs.statSync(source).mode & 0o777);
  }
}

function bridgeContent(directory) {
  return `${managedBlock.begin}\nWhen the task uses Pharo, read \`${directory}/pharo.AGENTS.md\` before acting.\n${managedBlock.end}\n`;
}

function updatedGuide(current, block) {
  const starts = current.includes(managedBlock.begin);
  const ends = current.includes(managedBlock.end);
  if (starts !== ends) {
    throw new Error("The existing Pharo MCP instruction block is incomplete.");
  }
  if (starts) {
    const expression = new RegExp(`${managedBlock.begin}[\\s\\S]*?${managedBlock.end}\\n?`);
    return current.replace(expression, block);
  }
  return current ? `${current.trimEnd()}\n\n${block}` : block;
}

function guidePlan(cwd, configuration) {
  const target = path.join(cwd, configuration.guide);
  const current = fs.existsSync(target) ? fs.readFileSync(target, "utf8") : "";
  return { target, content: updatedGuide(current, bridgeContent(configuration.directory)) };
}

function writeGuide({ target, content }) {
  fs.mkdirSync(path.dirname(target), { recursive: true });
  fs.writeFileSync(target, content);
}

function prepare(options, direct) {
  const cwd = path.resolve(options.cwd ?? process.cwd());
  const configuration = hostConfiguration(options.host);
  const plan = absolutePlan(cwd, direct ? fullPlan(configuration, options.host) : guidancePlan(configuration, options.host));
  const guide = guidePlan(cwd, configuration);
  assertCompatible(plan);
  return { configuration, cwd, guide, plan };
}

function apply(options, direct) {
  const { configuration, cwd, guide, plan } = prepare(options, direct);
  copyMissing(plan);
  writeGuide(guide);
  return { cwd, host: options.host, directory: configuration.directory };
}

export function installGuidance(options) {
  return apply(options, false);
}

export function install(options) {
  return apply(options, true);
}
