"
Parsed request for the screenshot tool.

It carries the title of the window to capture, or nothing when the caller means the whole world.
"
Class {
	#name : 'MCPScreenshotRequest',
	#superclass : 'Object',
	#instVars : [
		'window'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPScreenshotRequest class >> fromRequest: aRequest tool: aTool [

	^ self new initializeWindow: (aRequest stringArgumentNamed: 'window')
]

{ #category : 'initialization' }
MCPScreenshotRequest >> initializeWindow: aTitle [

	window := aTitle
]

{ #category : 'accessing' }
MCPScreenshotRequest >> targetLabel [
	"What the capture is of, for the summary and the structured result."

	^ window ifNil: [ 'world' ]
]

{ #category : 'accessing' }
MCPScreenshotRequest >> window [
	"The window title the caller named, or nil when they named none and mean the world."

	^ window
]
