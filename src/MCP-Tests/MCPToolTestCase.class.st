Class {
	#name : 'MCPToolTestCase',
	#superclass : 'MCPToolAPITestCase',
	#category : 'MCP-Tests-Tools',
	#package : 'MCP-Tests',
	#tag : 'Tools'
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
