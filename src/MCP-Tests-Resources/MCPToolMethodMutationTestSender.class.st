"
Fixture class that sends selectors used by method mutation tests.
"
Class {
	#name : 'MCPToolMethodMutationTestSender',
	#superclass : 'Object',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'tests' }
MCPToolMethodMutationTestSender >> callClassTarget [ ^ MCPToolMethodMutationTestTarget buildValue: 'value'
]

{ #category : 'tests' }
MCPToolMethodMutationTestSender >> callInstanceTarget [ ^ MCPToolMethodMutationTestTarget new combine: 'first' with: 'second'
]
