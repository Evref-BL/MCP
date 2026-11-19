"
MCP tool that captures the Morphic world, or one open window, and returns it as native MCP image content.

The tool is read-only. A successful call produces a text summary, a PNG image content block, and structured metadata describing what was captured, its dimensions and its MIME type. Naming a window costs a fraction of the whole screen; screen_read costs less again when a picture is not what the question needs.
"
Class {
	#name : 'MCPToolCaptureScreen',
	#superclass : 'MCPTool',
	#traits : 'TMCPUserInterfaceTool',
	#classTraits : 'TMCPUserInterfaceTool classTrait',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
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

	^ MCPStructureInputSchema properties: { self windowSchemaProperty } required: #(  )
]

{ #category : 'metadata' }
MCPToolCaptureScreen >> description [

	^ 'Capture the Morphic world, or one open window named by its title, and return it as MCP image content. One window costs a fraction of the whole screen.'
]

{ #category : 'executing' }
MCPToolCaptureScreen >> executeWithRequest: request [

	^ self
		  executeRequest: request
		  do: [
				  | window |
				  window := request stringArgumentNamed: 'window'.
				  self resultForCaptureOf: (self targetMorphNamed: window) window: window ]
		  onError: [ :error | self errorResultForError: error ]
]

{ #category : 'private - results' }
MCPToolCaptureScreen >> resultForCaptureOf: aMorph window: aTitleOrNil [
	"The capture as a PNG image content block, with what it shows, its size and its MIME type as structured content. What it shows is the window named, or the world when none is. Any morph can be captured, so a test needs no window open."

	| form imageContent summary target |
	target := aTitleOrNil ifNil: [ 'world' ].
	form := aMorph imageForm.
	imageContent := MCPStructureImageContent pngFromForm: form.
	summary := self successSummaryForTarget: target form: form.
	^ MCPStructureCallToolResult
		  content: {
				  (self textContent: summary).
				  imageContent }
		  structuredContent: (Dictionary new
				   at: #summary put: summary;
				   at: #data put: {
						   (#target -> target).
						   (#width -> form width).
						   (#height -> form height).
						   (#mimeType -> imageContent mimeType) } asDictionary;
				   yourself)
]

{ #category : 'private - results' }
MCPToolCaptureScreen >> successSummaryForTarget: aString form: aForm [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Captured ';
				  nextPutAll: aString;
				  nextPutAll: ' screenshot (';
				  print: aForm width;
				  nextPutAll: 'x';
				  print: aForm height;
				  nextPutAll: ').' ]
]

{ #category : 'metadata' }
MCPToolCaptureScreen >> title [

	^ 'Capture Screenshot'
]
