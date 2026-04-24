"
Command that runs validated test requests and returns aggregated test result DTO dictionaries.
"
Class {
	#name : 'MCPRunTestsCommand',
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
MCPRunTestsCommand class >> tool: aTool request: aRequest [

	^ self new initializeTool: aTool request: aRequest
]

{ #category : 'executing' }
MCPRunTestsCommand >> execute [

	| deadline validatedRequests |
	validatedRequests := tool validatedRequestsFrom: request testRequests.
	deadline := tool deadlineForTimeoutMilliseconds:
		            request timeoutMilliseconds.
	^ tool runValidatedRequests: validatedRequests deadline: deadline
]

{ #category : 'initialization' }
MCPRunTestsCommand >> initializeTool: aTool request: aRequest [

	tool := aTool.
	request := aRequest.
	^ self
]

{ #category : 'accessing' }
MCPRunTestsCommand >> request [

	^ request
]

{ #category : 'accessing' }
MCPRunTestsCommand >> tool [

	^ tool
]
