"
Command that captures a screenshot Form and packages it as MCP image content.

It supports the world target and uses an injectable form provider so tests can exercise PNG packaging without reading the live Morphic world.
"
Class {
	#name : 'MCPScreenshotCommand',
	#superclass : 'MCPToolRequestCommand',
	#instVars : [
		'formProvider'
	],
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPScreenshotCommand class >> tool: aTool request: aRequest [

	^ self new initializeTool: aTool request: aRequest formProvider: nil
]

{ #category : 'instance creation' }
MCPScreenshotCommand class >> tool: aTool request: aRequest formProvider: aBlock [

	^ self new initializeTool: aTool request: aRequest formProvider: aBlock
]

{ #category : 'private' }
MCPScreenshotCommand >> captureWorldForm [
	"Capture the active Morphic world as a Form."

	| world |
	world := self currentWorld.
	world ifNil: [ Error signal: 'No Morphic world is available to capture.' ].
	^ world imageForm
]

{ #category : 'executing' }
MCPScreenshotCommand >> execute [

	| form imageContent |
	form := self formForRequest.
	imageContent := MCPStructureImageContent pngFromForm: form.
	^ MCPScreenshotResult
		  target: request target
		  width: form width
		  height: form height
		  imageContent: imageContent
]

{ #category : 'private' }
MCPScreenshotCommand >> formForRequest [
	"Dispatch screenshot capture by target. Only the world target is accepted."

	request isWorldTarget ifTrue: [ ^ self formProvider value ].
	Error signal: 'Unsupported screenshot target: ' , request target
]

{ #category : 'accessing' }
MCPScreenshotCommand >> formProvider [

	^ formProvider
]

{ #category : 'initialization' }
MCPScreenshotCommand >> initializeTool: aTool request: aRequest formProvider: aBlock [

	super initializeTool: aTool request: aRequest.
	formProvider := aBlock ifNil: [ [ self captureWorldForm ] ]
]
