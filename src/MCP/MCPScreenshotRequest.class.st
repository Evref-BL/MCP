"
Parsed request for the screenshot tool.

The current tool accepts the world target. targetIdentifier is optional and ignored for world captures.
"
Class {
	#name : 'MCPScreenshotRequest',
	#superclass : 'Object',
	#instVars : [
		'target',
		'targetIdentifier'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPScreenshotRequest class >> fromRequest: aRequest tool: aTool [

	^ self new
		  initializeTarget:
		  (aRequest stringArgumentNamed: 'target' default: 'world')
		  targetIdentifier:
		  (aRequest stringArgumentNamed: 'targetIdentifier')
]

{ #category : 'initialization' }
MCPScreenshotRequest >> initializeTarget: targetString targetIdentifier: identifierString [

	target := targetString ifNil: [ 'world' ].
	targetIdentifier := identifierString
]

{ #category : 'testing' }
MCPScreenshotRequest >> isWorldTarget [

	^ self target = 'world'
]

{ #category : 'accessing' }
MCPScreenshotRequest >> target [

	^ target ifNil: [ 'world' ]
]

{ #category : 'accessing' }
MCPScreenshotRequest >> targetIdentifier [

	^ targetIdentifier
]
