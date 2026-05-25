Class {
	#name : 'MCPToolRunTestCoverage',
	#superclass : 'MCPToolRunTestsOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolRunTestCoverage >> defaultName [

	^ 'run-test-coverage'
]

{ #category : 'defaults' }
MCPToolRunTestCoverage >> defaultTitle [

	^ 'Run Test Coverage'
]

{ #category : 'defaults' }
MCPToolRunTestCoverage >> operationDescription [

	^ 'Run tests while collecting method and node coverage for an explicit coverage scope.'
]

{ #category : 'private - schema' }
MCPToolRunTestCoverage >> requiredInputPropertyNames [

	^ #( 'tests' 'coverage' )
]

{ #category : 'defaults' }
MCPToolRunTestCoverage >> testOperation [

	^ 'coverage'
]
