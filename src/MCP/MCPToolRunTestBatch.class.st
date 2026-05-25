Class {
	#name : 'MCPToolRunTestBatch',
	#superclass : 'MCPToolRunTestsOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolRunTestBatch >> defaultName [

	^ 'run-test-batch'
]

{ #category : 'defaults' }
MCPToolRunTestBatch >> defaultTitle [

	^ 'Run Test Batch'
]

{ #category : 'defaults' }
MCPToolRunTestBatch >> operationDescription [

	^ 'Run test classes or selected test methods as a batch.'
]

{ #category : 'defaults' }
MCPToolRunTestBatch >> testOperation [

	^ 'run'
]
