"
MCP tool that captures a Morphic screenshot and returns it as native MCP image content.

The first implementation captures the whole world. The input request already carries a target shape so later versions can target presenters, windows, or morphs without changing the tool/command boundary.
"
Class {
	#name : 'MCPToolCaptureScreenshot',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'private - execution' }
MCPToolCaptureScreenshot >> commandForRequest: screenshotRequest [

	^ MCPScreenshotCommand tool: self request: screenshotRequest
]

{ #category : 'defaults' }
MCPToolCaptureScreenshot >> defaultDescription [

	^ 'Capture a screenshot from the Pharo image and return it as MCP image content. For now the only supported target is the whole Morphic world; the request shape is prepared for future presenter, window, or morph targets.'
]

{ #category : 'defaults' }
MCPToolCaptureScreenshot >> defaultIcons [

	^ { (self pngIconNamed: #smallScreenshot) }
]

{ #category : 'defaults' }
MCPToolCaptureScreenshot >> defaultInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  (self
					   stringEnumSchemaPropertyNamed: 'target'
					   description:
						   'The screenshot target. Currently only world is supported.'
					   values: #( 'world' )
					   default: 'world').
				  (MCPStructureProperties new
					   name: 'targetIdentifier';
					   type: 'string';
					   description:
						   'Reserved for future presenter, window, or morph targets.';
					   yourself) };
		  required: #(  );
		  yourself
]

{ #category : 'defaults' }
MCPToolCaptureScreenshot >> defaultName [

	^ 'capture-screenshot'
]

{ #category : 'defaults' }
MCPToolCaptureScreenshot >> defaultOutputSchema [

	^ self
		  standardOutputSchemaForDataProperties: {
				  (self
					   schemaPropertyNamed: 'target'
					   type: 'string'
					   description: 'The screenshot target that was captured.').
				  (self
					   schemaPropertyNamed: 'width'
					   type: 'integer'
					   description: 'The screenshot width in pixels.').
				  (self
					   schemaPropertyNamed: 'height'
					   type: 'integer'
					   description: 'The screenshot height in pixels.').
				  (self
					   schemaPropertyNamed: 'mimeType'
					   type: 'string'
					   description: 'The MIME type of the image content block.') }
		  required: #( 'target' 'width' 'height' 'mimeType' )
]

{ #category : 'defaults' }
MCPToolCaptureScreenshot >> defaultTitle [

	^ 'Capture Screenshot'
]

{ #category : 'executing' }
MCPToolCaptureScreenshot >> executeWithRequest: request [

	^ self
		  executeParsedRequestFrom: request
		  do: [ :screenshotRequest |
			  | commandResult summary |
			  commandResult := (self commandForRequest: screenshotRequest)
				                   execute.
			  summary := self successSummaryForResult: commandResult.
			  MCPStructureCallToolResult
				  content: {
						  (self textContent: summary).
						  commandResult imageContent }
				  structuredContent: {
						  (#status -> 'ok').
						  (#summary -> summary).
						  (#warnings -> #(  )).
						  (#data -> commandResult asDictionary) } asDictionary ]
		  onError: [ :error :ignored |
			  self
				  errorResultText: (self failureMessageFor: error)
				  details: (self errorDetailsFor: error) ]
]

{ #category : 'private - request' }
MCPToolCaptureScreenshot >> parsedRequestFromToolRequest: request [

	^ MCPScreenshotRequest fromRequest: request tool: self
]

{ #category : 'private - results' }
MCPToolCaptureScreenshot >> successSummaryForResult: aScreenshotResult [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Captured ';
			  nextPutAll: aScreenshotResult target;
			  nextPutAll: ' screenshot (';
			  print: aScreenshotResult width;
			  nextPutAll: 'x';
			  print: aScreenshotResult height;
			  nextPutAll: ').' ]
]
