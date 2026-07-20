"
MCP tool that captures the active Morphic world and returns it as native MCP image content.

The tool is read-only. A successful call produces a text summary, a PNG image content block, and structured metadata describing the captured image dimensions and MIME type.
"
Class {
	#name : 'MCPToolCaptureScreenshot',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolCaptureScreenshot class >> groupName [

	^ self uiGroupName
]

{ #category : 'metadata' }
MCPToolCaptureScreenshot class >> toolName [

	^ 'screenshot_capture'
]

{ #category : 'metadata' }
MCPToolCaptureScreenshot >> additionalKeywords [

	^ #( 'screenshot' 'capture' 'window' 'display' 'world' 'ui' )
]

{ #category : 'metadata' }
MCPToolCaptureScreenshot >> annotations [

	^ MCPStructureToolAnnotations readOnly
]

{ #category : 'metadata' }
MCPToolCaptureScreenshot >> buildInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: { (self
				   stringEnumSchemaPropertyNamed: 'target'
				   description:
					   'The screenshot target. The only accepted value is world.'
				   values: #( 'world' )
				   default: 'world') };
		  required: #(  );
		  yourself
]

{ #category : 'metadata' }
MCPToolCaptureScreenshot >> buildOutputSchema [

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

{ #category : 'private - execution' }
MCPToolCaptureScreenshot >> commandForRequest: screenshotRequest [

	^ MCPScreenshotCommand tool: self request: screenshotRequest
]

{ #category : 'metadata' }
MCPToolCaptureScreenshot >> description [

	^ 'Capture the active Morphic world and return it as MCP image content.'
]

{ #category : 'executing' }
MCPToolCaptureScreenshot >> executeWithRequest: request [

	^ self
		  executeParsedRequestFrom: request
		  do: [ :screenshotRequest |
				  | commandResult structuredContent summary |
				  commandResult := (self commandForRequest: screenshotRequest) execute.
				  summary := self successSummaryForResult: commandResult.
				  structuredContent := Dictionary new
					                       at: #status put: 'ok';
					                       at: #summary put: summary;
					                       at: #data put: commandResult asDictionary;
					                       yourself.
				  MCPStructureCallToolResult
					  content: {
							  (self textContent: summary).
							  commandResult imageContent }
					  structuredContent: structuredContent ]
		  onError: [ :error :ignored | self errorResultText: (self failureMessageFor: error) details: (self errorDetailsFor: error) ]
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

{ #category : 'metadata' }
MCPToolCaptureScreenshot >> title [

	^ 'Capture Screenshot'
]
