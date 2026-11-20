"
Test-only MCP tool that signals a notification so the shared tool boundary can be exercised without relying on a tool that handles notifications itself.
"
Class {
	#name : 'MCPNotifyingTestTool',
	#superclass : 'MCPTool',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'testing' }
MCPNotifyingTestTool class >> shouldAutoRegister [
	"A fixture is not a tool anyone asked for, and MCP's default group loads its own tests, so every fixture says so itself rather than relying on the package it sits in."

	^ false
]

{ #category : 'metadata' }
MCPNotifyingTestTool class >> toolName [

	^ 'notifying_test_tool'
]

{ #category : 'metadata' }
MCPNotifyingTestTool >> buildInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: #(  );
		  required: #(  );
		  additionalProperties: false;
		  yourself
]

{ #category : 'metadata' }
MCPNotifyingTestTool >> description [

	^ 'Signals a notification for MCP tool-call notification handling tests.'
]

{ #category : 'executing' }
MCPNotifyingTestTool >> executeWithRequest: aRequest [

	^ self
		  executeRequest: aRequest
		  do: [
		  self successResultText: 'Signaled a notification.' data: { (#resumedWith -> MCPToolNestedNotification signal) } asDictionary ]
		  onError: [ :error | self errorResultFor: error ]
]

{ #category : 'metadata' }
MCPNotifyingTestTool >> groupName [

	^ 'plugins'
]

{ #category : 'testing' }
MCPNotifyingTestTool >> shouldRecordObservability [

	^ false
]

{ #category : 'metadata' }
MCPNotifyingTestTool >> title [

	^ 'Notifying Test Tool'
]
