"
Command that captures a Morphic screenshot and packages it as MCP image content.

The command currently supports the whole world target. It routes capture through a target dispatch method and a form provider so later presenter/window/morph targets can be added without changing the tool execution contract.
"
Class {
	#name : 'MCPScreenshotCommand',
	#superclass : 'Object',
	#instVars : [
		'tool',
		'request',
		'formProvider'
	],
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPScreenshotCommand class >> tool: aTool request: aRequest [

	^ self
		  tool: aTool
		  request: aRequest
		  formProvider: [ self new captureWorldForm ]
]

{ #category : 'instance creation' }
MCPScreenshotCommand class >> tool: aTool request: aRequest formProvider: aBlock [

	^ self new
		  initializeTool: aTool
		  request: aRequest
		  formProvider: aBlock
]

{ #category : 'private' }
MCPScreenshotCommand >> captureWorldForm [
	"Capture the active Morphic world as a Form."

	| world |
	world := self currentWorld.
	world ifNil: [
		Error signal: 'No Morphic world is available to capture.' ].
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
	"Dispatch screenshot capture by target. Only the whole world is supported for now."

	request isWorldTarget ifTrue: [ ^ self formProvider value ].
	Error signal: 'Unsupported screenshot target: ' , request target
]

{ #category : 'accessing' }
MCPScreenshotCommand >> formProvider [

	^ formProvider
]

{ #category : 'initialization' }
MCPScreenshotCommand >> initializeTool: aTool request: aRequest formProvider: aBlock [

	tool := aTool.
	request := aRequest.
	formProvider := aBlock.
	^ self
]

{ #category : 'accessing' }
MCPScreenshotCommand >> request [

	^ request
]

{ #category : 'accessing' }
MCPScreenshotCommand >> tool [

	^ tool
]
