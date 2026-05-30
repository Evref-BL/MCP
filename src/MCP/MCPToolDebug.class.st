"
Abstract base for MCP debugger tools.

It centralizes the parse/execute/result wrapper shared by focused debugger tools while subclasses provide request parsing, command creation, schemas, and public metadata.
"
Class {
	#name : 'MCPToolDebug',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'testing' }
MCPToolDebug class >> isAbstract [

	^ self = MCPToolDebug
]

{ #category : 'private - execution' }
MCPToolDebug >> commandForRequest: debugRequest [

	self subclassResponsibility
]

{ #category : 'private - errors' }
MCPToolDebug >> debugErrorDetailsFor: anError [

	(anError isKindOf: MCPCommandError) ifTrue: [
		^ anError structuredDetails ].
	^ self errorDetailsFor: anError
]

{ #category : 'private - errors' }
MCPToolDebug >> errorResultForDebugError: anError [

	^ self
		  errorResultText: (anError messageText
				   ifNil: [ anError asString ]
				   ifNotNil: [ :text | text asString ])
		  details: (self debugErrorDetailsFor: anError)
]

{ #category : 'executing' }
MCPToolDebug >> executeWithRequest: request [

	^ self
		  executeParsedRequestFrom: request
		  do: [ :debugRequest |
				  self resultForCommandResult:
					  (self commandForRequest: debugRequest) execute ]
		  onError: [ :error :ignored | self errorResultForDebugError: error ]
]

{ #category : 'private - execution' }
MCPToolDebug >> resultForCommandResult: commandResult [

	commandResult isError ifTrue: [
			^ self
				  errorResultText: commandResult summary
				  details: commandResult errorDetails ].
	^ self
		  successResultText: commandResult summary
		  data: commandResult data
		  warnings: commandResult warnings
]
