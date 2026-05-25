Class {
	#name : 'MCPInspectToolCommand',
	#superclass : 'Object',
	#instVars : [
		'tool',
		'request'
	],
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPInspectToolCommand class >> tool: aTool request: aRequest [

	^ self new
		  tool: aTool;
		  request: aRequest;
		  yourself
]

{ #category : 'executing' }
MCPInspectToolCommand >> execute [

	| inspectedTool |
	inspectedTool := MCPToolRegistry
		                 toolNamed: request toolName
		                 ifAbsent: [
		                 Error signal:
			                 'Unknown MCP tool: ' , request toolName ].
	^ { (#tool -> (MCPToolRegistry inspectionForTool: inspectedTool)) }
		  asDictionary
]

{ #category : 'accessing' }
MCPInspectToolCommand >> request [

	^ request
]

{ #category : 'accessing' }
MCPInspectToolCommand >> request: anObject [

	request := anObject
]

{ #category : 'accessing' }
MCPInspectToolCommand >> tool [

	^ tool
]

{ #category : 'accessing' }
MCPInspectToolCommand >> tool: anObject [

	tool := anObject
]
