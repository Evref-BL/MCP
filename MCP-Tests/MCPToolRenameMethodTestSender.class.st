Class {
	#name : 'MCPToolRenameMethodTestSender',
	#superclass : 'Object',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'tests' }
MCPToolRenameMethodTestSender >> callClassTarget [ ^ MCPToolRenameMethodTestTarget buildValue: 'value'
]

{ #category : 'tests' }
MCPToolRenameMethodTestSender >> callInstanceTarget [ ^ MCPToolRenameMethodTestTarget new combine: 'first' with: 'second'
]
