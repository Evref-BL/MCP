Class {
	#name : 'MCPToolEditMethodTestTarget',
	#superclass : 'Object',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'tests' }
MCPToolEditMethodTestTarget class >> buildValue: aString [ ^ 'Class-' , aString
]

{ #category : 'tests' }
MCPToolEditMethodTestTarget class >> classProtocolTarget [ ^ 7
]

{ #category : 'tests' }
MCPToolEditMethodTestTarget >> combine: first with: second [ ^ first , '-' , second
]

{ #category : 'tests' }
MCPToolEditMethodTestTarget >> instanceProtocolTarget [ ^ 41
]
