[![Pharo version](https://img.shields.io/badge/Pharo-12%20%7C%2013%20%7C%2014-%23aac9ff.svg)](https://github.com/pharo-project/Pharo)
![Build Info](https://github.com/Evref-BL/MCP/workflows/CI/badge.svg)
[![Coverage Status](https://coveralls.io/repos/github/Evref-BL/MCP/badge.svg?branch=main)](https://coveralls.io/github/Evref-BL/MCP?branch=main)

# Model Context Protocol (MCP) Server for Pharo Smalltalk

## Overview

This repository provides an implementation of a Model Context Protocol (MCP) server in Pharo Smalltalk. The server exposes a set of tools and capabilities for interacting with the Pharo image via HTTP.

## Supported Pharo Versions

MCP supports Pharo 12, Pharo 13, and Pharo 14. Mainline development targets the Pharo 13 API surface; the project uses PharoCompatibility to keep the supported version range loadable and tested.

## Installation

### Smalltalk part

1. **Install Pharo**

 Download and install [Pharo](https://pharo.org/download). This project currently supports Pharo 12, Pharo 13, and Pharo 14.

2. **Load the MCP Project**

 Open your Pharo image and load the MCP project. To load MCP directly in an image, use this snippet in a Playground or Workspace:

 ```smalltalk
 Metacello new
    baseline: 'MCP';
    repository: 'github://Evref-BL/MCP:main/src';
    load.
 ```

 To add MCP as a dependency of another project, reference the MCP baseline from that project's baseline:

 ```smalltalk
 spec
    baseline: 'MCP'
    with: [ spec repository: 'github://Evref-BL/MCP:main/src' ].
 ```

### Starting the Server

To start the MCP HTTP server, launch the Pharo image and execute code like this in a Playground or Workspace:

 ```smalltalk
 mcp := MCP new.
 mcp port: 4000.
 mcp start.
 ```

This starts the MCP server on port 4000. You can use another available port if 4000 conflicts with another service.

> The server will only run as long as the Pharo image is running. You must keep the image open for the server to remain available.

In a graphical Pharo image, inspect the `mcp` object and open the Dashboard tab to monitor the server and control its lifecycle.

### Codex part

If you want to use Codex to manipulate Pharo, create an empty folder and copy inside it [user/codex/.codex](user/codex/.codex) as `.codex` and [user/AGENTS.md](user/AGENTS.md) as `AGENTS.md`.
It will give Codex the default configuration of the MCP server on port 4000. If you started the server on another port, update the copied `.codex/config.toml` accordingly.

### OpenCode part

If you want to use opencode to manipulate Pharo, you can follow these steps:
1. Go to the configuration folder of opencode: open ~/.config/opencode/
2. Edit file: opencode.json to add the below:
```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "pharo": {
      "type": "remote",
      "url": "http://127.0.0.1:4000",
      "enabled": true
    }
  }
}
```
3. Close opencode and reopen it. You should see in the left bottom corner a green pointer for MCP indicating that opencode is connected to the MCP server. Make sure you started it in Pharo first. <img width="150" height="50" alt="Screenshot 2026-04-16 at 10 11 48 AM (2)" src="https://github.com/user-attachments/assets/6f50c4d9-ad34-441e-bdfe-7880c7f3b30b" />
4. For more details about connected MCPs you can check the command `/mcps`. <img width="600" height="530" alt="Screenshot 2026-04-16 at 10 11 59 AM (2)" src="https://github.com/user-attachments/assets/bc851534-e494-49fd-8bd7-b9c23c3ecd13" />
5. You can follow this [documentation](https://opencode.ai/docs/mcp-servers/) to get more updates/explanation.

## Usage

Once the server is started, AI clients interact with it via HTTP requests on the configured port (default: 4000).
