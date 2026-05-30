"
Returns full metadata and schemas for one catalog tool.

This command is the second step of the discoverable-tool flow: after discovery gives a candidate name, inspect-tool exposes the exact contract needed for a safe call.
"
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
			                 'Unknown MCP tool: ' , request toolName ]
		                 usingPolicy: tool toolExposurePolicy.
	^ { (#tool -> (MCPToolRegistry
		    inspectionForTool: inspectedTool
		    usingPolicy: tool toolExposurePolicy)) } asDictionary
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
