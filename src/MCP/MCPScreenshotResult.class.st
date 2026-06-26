"
Result DTO produced by the screenshot command.

It keeps the MCP image content block separate from the structured metadata so tools can return a native image content block while still advertising target and dimensions through structuredContent.
"
Class {
	#name : 'MCPScreenshotResult',
	#superclass : 'MCPResult',
	#instVars : [
		'target',
		'width',
		'height',
		'imageContent'
	],
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPScreenshotResult class >> target: targetString width: widthInteger height: heightInteger imageContent: anImageContent [

	^ self new
		  initializeTarget: targetString
		  width: widthInteger
		  height: heightInteger
		  imageContent: anImageContent
]

{ #category : 'converting' }
MCPScreenshotResult >> asDictionary [

	^ {
		  (#target -> self target).
		  (#width -> self width).
		  (#height -> self height).
		  (#mimeType -> self imageContent mimeType) } asDictionary
]

{ #category : 'accessing' }
MCPScreenshotResult >> height [

	^ height
]

{ #category : 'accessing' }
MCPScreenshotResult >> imageContent [

	^ imageContent
]

{ #category : 'initialization' }
MCPScreenshotResult >> initializeTarget: targetString width: widthInteger height: heightInteger imageContent: anImageContent [

	target := targetString.
	width := widthInteger.
	height := heightInteger.
	imageContent := anImageContent.
	^ self
]

{ #category : 'accessing' }
MCPScreenshotResult >> target [

	^ target
]

{ #category : 'accessing' }
MCPScreenshotResult >> width [

	^ width
]
