Class {
	#name : 'MCPToolEditMethodTestSender',
	#superclass : 'Object',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'tests' }
MCPToolEditMethodTestSender >> callClassTarget [ ^ MCPToolEditMethodTestTarget buildValue: 'value'
]

{ #category : 'tests' }
MCPToolEditMethodTestSender >> callInstanceTarget [ ^ MCPToolEditMethodTestTarget new combine: 'first' with: 'second'
]
