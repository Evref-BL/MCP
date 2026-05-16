"
Validated run-tests selection.

It pairs the parsed test run request with the resolved test class that the command will execute.
"
Class {
	#name : 'MCPValidatedTestRunRequest',
	#superclass : 'Object',
	#instVars : [
		'testRunRequest',
		'testClass'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPValidatedTestRunRequest class >> request: aTestRunRequest testClass: aTestClass [

	^ self new initializeRequest: aTestRunRequest testClass: aTestClass
]

{ #category : 'converting' }
MCPValidatedTestRunRequest >> asDictionary [

	^ self testRunRequest asDictionary
]

{ #category : 'accessing' }
MCPValidatedTestRunRequest >> className [

	^ self testRunRequest className
]

{ #category : 'printing' }
MCPValidatedTestRunRequest >> displayName [

	^ self testRunRequest displayName
]

{ #category : 'testing' }
MCPValidatedTestRunRequest >> hasTestMethod [

	^ self testRunRequest hasTestMethod
]

{ #category : 'initialization' }
MCPValidatedTestRunRequest >> initializeRequest: aTestRunRequest testClass: aTestClass [

	testRunRequest := aTestRunRequest.
	testClass := aTestClass.
	^ self
]

{ #category : 'accessing' }
MCPValidatedTestRunRequest >> testClass [

	^ testClass
]

{ #category : 'accessing' }
MCPValidatedTestRunRequest >> testMethodName [

	^ self testRunRequest testMethodName
]

{ #category : 'accessing' }
MCPValidatedTestRunRequest >> testRunRequest [

	^ testRunRequest
]
