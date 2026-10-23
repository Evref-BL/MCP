"
Abstract base for MCP debugger tools.

It centralizes the parse/execute/result wrapper the debugger tools share while subclasses provide request parsing, command creation, schemas, and public metadata.
"
Class {
	#name : 'MCPToolDebug',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolDebug class >> groupName [

	^ self debuggingGroupName
]

{ #category : 'testing' }
MCPToolDebug class >> isAbstract [

	^ self = MCPToolDebug
]

{ #category : 'metadata' }
MCPToolDebug >> additionalKeywords [

	^ #( 'debug' 'debugger' 'value' 'variable' 'frame' 'exception' )
]

{ #category : 'metadata' }
MCPToolDebug >> buildInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: self inputProperties;
		  required: self requiredInputProperties;
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - execution' }
MCPToolDebug >> commandForRequest: debugRequest [

	self subclassResponsibility
]

{ #category : 'private - errors' }
MCPToolDebug >> debugErrorDetailsFor: anError [

	^ anError mcpCommandErrorDo: [ :commandError | commandError structuredDetails ] otherwise: [ self errorDetailsFor: anError ]
]

{ #category : 'private - errors' }
MCPToolDebug >> errorResultForDebugError: anError [

	^ self
		  errorResultText: (anError messageText ifNil: [ anError asString ] ifNotNil: [ :text | text asString ])
		  details: (self debugErrorDetailsFor: anError)
]

{ #category : 'executing' }
MCPToolDebug >> executeWithRequest: request [

	^ self
		  executeParsedRequestFrom: request
		  do: [ :debugRequest | self resultForCommandResult: (self commandForRequest: debugRequest) execute ]
		  onError: [ :error :ignored | self errorResultForDebugError: error ]
]

{ #category : 'private - schema' }
MCPToolDebug >> inputProperties [

	^ #(  )
]

{ #category : 'private - results' }
MCPToolDebug >> redundantKeys [
	"The warnings are already read out above the payload."

	^ #( warnings )
]

{ #category : 'private - schema' }
MCPToolDebug >> requiredInputProperties [

	^ #(  )
]

{ #category : 'private - execution' }
MCPToolDebug >> resultForCommandResult: commandResult [

	commandResult isError ifTrue: [ ^ self errorResultText: commandResult summary details: commandResult errorDetails ].
	^ self successResultText: commandResult summary data: commandResult data warnings: commandResult warnings
]
