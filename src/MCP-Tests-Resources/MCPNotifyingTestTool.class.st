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
	"A fixture is not a tool anyone asked for, and MCP's default group loads its own tests. It used to call itself abstract to stay out of the catalog, which was a lie: the tests instantiate it."

	^ false
]

{ #category : 'metadata' }
MCPNotifyingTestTool class >> toolName [

	^ 'notifying-test-tool'
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
		  executeParsedRequestFrom: aRequest
		  do: [ :parsedRequest |
				  self
					  successResultText: 'Signaled a notification.'
					  data: { (#resumedWith -> MCPToolNestedNotification signal) } asDictionary ]
		  onError: [ :error :parsedRequest | self errorResultFor: error ]
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
