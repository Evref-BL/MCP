"
Fixture class that receives generated methods during method mutation tests.
"
Class {
	#name : 'MCPToolMethodMutationTestTarget',
	#superclass : 'Object',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'tests' }
MCPToolMethodMutationTestTarget class >> buildValue: aString [ ^ 'Class-' , aString
]

{ #category : 'tests' }
MCPToolMethodMutationTestTarget class >> classProtocolTarget [ ^ 7
]

{ #category : 'tests' }
MCPToolMethodMutationTestTarget >> combine: first with: second [ ^ first , '-' , second
]

{ #category : 'tests' }
MCPToolMethodMutationTestTarget >> instanceProtocolTarget [ ^ 41
]
