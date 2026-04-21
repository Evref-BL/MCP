Class {
	#name : 'MCPToolRenameMethodTestTarget',
	#superclass : 'Object',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'tests' }
MCPToolRenameMethodTestTarget class >> buildValue: aString [ ^ 'Class-' , aString
]

{ #category : 'tests' }
MCPToolRenameMethodTestTarget >> combine: first with: second [ ^ first , '-' , second
]
