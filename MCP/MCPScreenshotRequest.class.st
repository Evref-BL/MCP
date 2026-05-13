"
Parsed request for the screenshot tool.

For now the only supported target is the whole Morphic world. The target/targetIdentifier shape is deliberate so the tool can later address specific presenters, windows, or morphs without changing the command boundary.
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
	targetIdentifier := identifierString.
	^ self
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
