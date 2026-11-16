"
Abstract base for MCP debugger tools.

It holds the call and error wrapper the debugger tools share, while subclasses provide their schemas, public metadata and resultFor:, what they answer to a call.
"
Class {
	#name : 'MCPToolDebug',
	#superclass : 'MCPTool',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
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

	^ self executeRequest: request do: [ self resultFor: request ] onError: [ :error | self errorResultForDebugError: error ]
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

{ #category : 'executing' }
MCPToolDebug >> resultFor: request [
	"The answer to a call whose arguments the schema has checked."

	self subclassResponsibility
]
