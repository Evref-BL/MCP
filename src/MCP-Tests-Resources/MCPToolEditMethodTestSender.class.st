Class {
	#name : 'MCPToolEditMethodTestSender',
	#superclass : 'Object',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'tests' }
MCPToolEditMethodTestSender >> callClassTarget [ ^ MCPToolEditMethodTestTarget buildValue: 'value'
]

{ #category : 'tests' }
MCPToolEditMethodTestSender >> callInstanceTarget [ ^ MCPToolEditMethodTestTarget new combine: 'first' with: 'second'
]
