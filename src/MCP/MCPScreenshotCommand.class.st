"
Command that captures a Form and packages it as MCP image content.

It captures the morph it is given, which the tool resolves from what the caller named: the world, or one open window. A test can hand it any morph.
"
Class {
	#name : 'MCPScreenshotCommand',
	#superclass : 'MCPToolRequestCommand',
	#instVars : [
		'morph'
	],
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPScreenshotCommand class >> tool: aTool request: aRequest morph: aMorph [

	^ self new initializeTool: aTool request: aRequest morph: aMorph
]

{ #category : 'executing' }
MCPScreenshotCommand >> execute [

	| form imageContent |
	form := morph imageForm.
	imageContent := MCPStructureImageContent pngFromForm: form.
	^ MCPScreenshotResult
		  target: request targetLabel
		  width: form width
		  height: form height
		  imageContent: imageContent
]

{ #category : 'initialization' }
MCPScreenshotCommand >> initializeTool: aTool request: aRequest morph: aMorph [

	super initializeTool: aTool request: aRequest.
	morph := aMorph
]
