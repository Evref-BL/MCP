"
Common base class for MCP tool invocation tests.
"
Class {
	#name : 'MCPToolTestCase',
	#superclass : 'MCPToolAPITestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'testing' }
MCPToolTestCase class >> isAbstract [

	^ self = MCPToolTestCase or: [ super isAbstract ]
]

{ #category : 'private - calling' }
MCPToolTestCase >> callToolWith: someArguments [

	^ self callToolNamed: self toolName withArguments: someArguments
]

{ #category : 'private - calling' }
MCPToolTestCase >> toolName [

	self subclassResponsibility
]
