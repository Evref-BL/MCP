Class {
	#name : 'MCPToolAPITestCase',
	#superclass : 'MCPTestCase',
	#category : 'MCP-Tests-Tools',
	#package : 'MCP-Tests',
	#tag : 'Tools'
}

{ #category : 'testing' }
MCPToolAPITestCase class >> isAbstract [

	^ self = MCPToolAPITestCase or: [ super isAbstract ]
]

{ #category : 'private - calling' }
MCPToolAPITestCase >> aroundToolCall: aBlock [

	^ aBlock value
]

{ #category : 'private - calling' }
MCPToolAPITestCase >> callToolNamed: aToolName withArguments: someArguments [

	^ self aroundToolCall: [
		  MCP new rpcToolCall: aToolName withParams: someArguments ]
]

{ #category : 'private - results' }
MCPToolAPITestCase >> dataFrom: aResult [

	^ (self structuredContentFrom: aResult) at: #data
]

{ #category : 'private - results' }
MCPToolAPITestCase >> errorFrom: aResult [

	^ (self structuredContentFrom: aResult) at: #error
]

{ #category : 'private - results' }
MCPToolAPITestCase >> structuredContentFrom: aResult [

	^ aResult at: #structuredContent
]

{ #category : 'private - results' }
MCPToolAPITestCase >> summaryFrom: aResult [

	^ (self structuredContentFrom: aResult) at: #summary
]

{ #category : 'private - results' }
MCPToolAPITestCase >> warningsFrom: aResult [

	^ (self structuredContentFrom: aResult) at: #warnings
]
