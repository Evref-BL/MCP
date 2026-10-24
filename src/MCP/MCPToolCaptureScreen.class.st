"
MCP tool that captures the Morphic world, or one open window, and returns it as native MCP image content.

The tool is read-only. A successful call produces a text summary, a PNG image content block, and structured metadata describing what was captured, its dimensions and its MIME type. Naming a window costs a fraction of the whole screen; screen_read costs less again when a picture is not what the question needs.
"
Class {
	#name : 'MCPToolCaptureScreen',
	#superclass : 'MCPTool',
	#traits : 'TMCPUserInterfaceTool',
	#classTraits : 'TMCPUserInterfaceTool classTrait',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolCaptureScreen class >> groupName [

	^ self uiGroupName
]

{ #category : 'metadata' }
MCPToolCaptureScreen class >> toolName [

	^ 'screen_capture'
]

{ #category : 'metadata' }
MCPToolCaptureScreen >> additionalKeywords [

	^ #( 'screenshot' 'capture' 'window' 'display' 'world' 'ui' )
]

{ #category : 'metadata' }
MCPToolCaptureScreen >> annotations [

	^ MCPStructureToolAnnotations readOnly
]

{ #category : 'metadata' }
MCPToolCaptureScreen >> buildInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: { self windowSchemaProperty };
		  required: #(  );
		  yourself
]

{ #category : 'private - execution' }
MCPToolCaptureScreen >> commandForRequest: screenshotRequest [

	^ MCPScreenshotCommand tool: self request: screenshotRequest morph: (self targetMorphNamed: screenshotRequest window)
]

{ #category : 'metadata' }
MCPToolCaptureScreen >> description [

	^ 'Capture the Morphic world, or one open window named by its title, and return it as MCP image content. One window costs a fraction of the whole screen.'
]

{ #category : 'private - results' }
MCPToolCaptureScreen >> errorResultForError: anError [
	"A window a caller named and that is not open is their mistake to correct, so it is answered as a command error with the open titles rather than as a stack trace."

	^ anError
		  mcpCommandErrorDo: [ :commandError | self errorResultText: commandError messageText details: commandError structuredDetails ]
		  otherwise: [ :toolError |
		  self errorResultText: (self failureMessageFor: toolError) details: (self errorDetailsFor: toolError) ]
]

{ #category : 'executing' }
MCPToolCaptureScreen >> executeWithRequest: request [

	^ self
		  executeParsedRequestFrom: request
		  do: [ :screenshotRequest |
				  | commandResult structuredContent summary |
				  commandResult := (self commandForRequest: screenshotRequest) execute.
				  summary := self successSummaryForResult: commandResult.
				  structuredContent := Dictionary new
					                       at: #summary put: summary;
					                       at: #data put: commandResult asDictionary;
					                       yourself.
				  MCPStructureCallToolResult
					  content: {
							  (self textContent: summary).
							  commandResult imageContent }
					  structuredContent: structuredContent ]
		  onError: [ :error :ignored | self errorResultForError: error ]
]

{ #category : 'private - request' }
MCPToolCaptureScreen >> parsedRequestFromToolRequest: request [

	^ MCPScreenshotRequest fromRequest: request tool: self
]

{ #category : 'private - results' }
MCPToolCaptureScreen >> successSummaryForResult: aScreenshotResult [

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
MCPToolCaptureScreen >> title [

	^ 'Capture Screenshot'
]
