"
Parsed request for the screen reading tool.

It names the window to describe, or none for the whole world, and how deep to walk what is inside it.
"
Class {
	#name : 'MCPReadScreenRequest',
	#superclass : 'Object',
	#instVars : [
		'window',
		'depth'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPReadScreenRequest class >> fromRequest: aRequest tool: aTool [

	^ self new
		  initializeWindow: (aRequest stringArgumentNamed: 'window')
		  depth: (aRequest nonNegativeIntegerArgumentNamed: 'depth' default: aTool defaultDepth maximum: aTool maximumDepth)
]

{ #category : 'accessing' }
MCPReadScreenRequest >> depth [

	^ depth
]

{ #category : 'initialization' }
MCPReadScreenRequest >> initializeWindow: aTitle depth: anInteger [

	window := aTitle.
	depth := anInteger
]

{ #category : 'accessing' }
MCPReadScreenRequest >> targetLabel [

	^ window ifNil: [ 'world' ]
]

{ #category : 'accessing' }
MCPReadScreenRequest >> window [

	^ window
]
