# MCP (Model Context Protocol) Server for Pharo Smalltalk

## Overview

This repository provides an implementation of an MCP (Model Context Protocol) server in Pharo Smalltalk. The server exposes a set of tools and capabilities for interacting with the Pharo image via HTTP.

## Installation

### Smalltalk part

1. **Install Pharo**

 Download and install the latest version of [Pharo](https://pharo.org/download). Follow the instructions for your operating system.

2. **Load the MCP Project**

 Open your Pharo image and load the MCP project. You can use the following snippet in a Playground or directly in the Pharo environment (adapt as needed for your loading method):

 ```smalltalk
 Metacello new
    baseline: 'MCP';
    repository: 'github://Evref-BL/MCP:main/src';
    load.
 ```

### Starting the Server

To start the MCP HTTP server, you must launch the Pharo image and execute the following code in a Playground or Workspace:

 ```smalltalk
 mcp := MCP new.
 mcp server port: 4000.
 mcp start.
 ```

This will start the MCP server on port 4000.

> The server will only run as long as the Pharo image is running. You must keep the image open for the server to remain available.

### Codex part

If you want to use codex to manipulate Pharo. Codex is made to interact by default with files.
So we advice you to create an empty folder and copy inside it the [.codex](.codex) folder of this repository as well as the AGENTS file.
It will give to codex the default configuration of the MCP server.

## Usage

Once the server is started, AI interact with it via HTTP requests on the configured port (default: 4000).

