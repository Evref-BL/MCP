"
MCP tool that answers what is on screen as a tree of nodes.

It is read-only, and it is the cheap counterpart of screen_capture: text a caller can search and assert on, for the price of a few hundred tokens rather than an image.
"
Class {
	#name : 'MCPToolReadScreen',
	#superclass : 'MCPTool',
	#traits : 'TMCPUserInterfaceTool',
	#classTraits : 'TMCPUserInterfaceTool classTrait',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolReadScreen class >> groupName [

	^ self uiGroupName
]

{ #category : 'metadata' }
MCPToolReadScreen class >> toolName [

	^ 'screen_read'
]

{ #category : 'metadata' }
MCPToolReadScreen >> additionalKeywords [

	^ #( 'ui' 'screen' 'window' 'morph' 'spec' 'presenter' )
]

{ #category : 'metadata' }
MCPToolReadScreen >> annotations [

	^ MCPStructureToolAnnotations readOnly
]

{ #category : 'metadata' }
MCPToolReadScreen >> buildInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  self windowSchemaProperty.
				  ((self schemaPropertyNamed: 'depth' type: 'integer' description: 'How deep to walk what the target contains.')
					   default: self defaultDepth;
					   minimum: 0;
					   maximum: self maximumDepth;
					   yourself) };
		  required: #(  );
		  yourself
]

{ #category : 'executing' }
MCPToolReadScreen >> commandForRequest: readRequest [

	^ MCPReadScreenCommand tool: self request: readRequest morph: (self targetMorphNamed: readRequest window)
]

{ #category : 'metadata' }
MCPToolReadScreen >> defaultDepth [
	"Deep enough to reach the presenters inside a window without walking every widget in it."

	^ 3
]

{ #category : 'metadata' }
MCPToolReadScreen >> description [

	^ 'Answer what is on screen as a tree: the open windows, or one window named by its title with the Spec presenters or morphs inside it. Text a caller can search and assert on, for a fraction of what a screenshot costs.'
]

{ #category : 'executing' }
MCPToolReadScreen >> errorResultForError: anError [

	^ anError
		  mcpCommandErrorDo: [ :commandError | self errorResultText: commandError messageText details: commandError structuredDetails ]
		  otherwise: [ :toolError |
		  self errorResultText: (self failureMessageFor: toolError) details: (self errorDetailsFor: toolError) ]
]

{ #category : 'executing' }
MCPToolReadScreen >> executeWithRequest: request [

	^ self
		  executeParsedRequestFrom: request
		  do: [ :readRequest |
				  | commandResult |
				  commandResult := (self commandForRequest: readRequest) execute.
				  self successResultText: (self successSummaryForResult: commandResult) data: commandResult asDictionary ]
		  onError: [ :error :ignored | self errorResultForError: error ]
]

{ #category : 'private - results' }
MCPToolReadScreen >> keyOrder [
	"What a node is, then what it is called, then where it sits. Children come last, as the only part that is not one line."

	^ #( class title bounds visible )
]

{ #category : 'executing' }
MCPToolReadScreen >> keysStatedInSummary [
	"The summary names the target and counts the nodes, so repeating either says it twice."

	^ #( target nodes )
]

{ #category : 'metadata' }
MCPToolReadScreen >> maximumDepth [

	^ 10
]

{ #category : 'executing' }
MCPToolReadScreen >> parsedRequestFromToolRequest: request [

	^ MCPReadScreenRequest fromRequest: request tool: self
]

{ #category : 'executing' }
MCPToolReadScreen >> successSummaryForResult: aResult [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Read ';
				  nextPutAll: aResult target;
				  nextPutAll: ', ';
				  print: aResult nodeCount;
				  nextPutAll: ' nodes.' ]
]

{ #category : 'metadata' }
MCPToolReadScreen >> title [

	^ 'Read Screen'
]
