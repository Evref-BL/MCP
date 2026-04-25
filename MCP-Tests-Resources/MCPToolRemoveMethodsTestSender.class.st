Class {
	#name : 'MCPToolRemoveMethodsTestSender',
	#superclass : 'Object',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'tests' }
MCPToolRemoveMethodsTestSender >> sendProtectedRemovalTarget [

	^ MCPToolRemoveMethodsTestTarget new externallyReferencedBatchRemoval
]
