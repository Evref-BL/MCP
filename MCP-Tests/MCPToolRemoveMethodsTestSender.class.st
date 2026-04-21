Class {
	#name : 'MCPToolRemoveMethodsTestSender',
	#superclass : 'Object',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'tests' }
MCPToolRemoveMethodsTestSender >> sendProtectedRemovalTarget [

	^ MCPToolRemoveMethodsTestTarget new externallyReferencedBatchRemoval
]
