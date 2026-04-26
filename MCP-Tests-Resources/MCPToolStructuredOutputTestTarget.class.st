Class {
	#name : 'MCPToolStructuredOutputTestTarget',
	#superclass : 'TestCase',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'tests' }
MCPToolStructuredOutputTestTarget >> testErrors [

	Error signal: 'boom error'
]

{ #category : 'tests' }
MCPToolStructuredOutputTestTarget >> testFails [

	self assert: false description: 'boom failure'
]

{ #category : 'tests' }
MCPToolStructuredOutputTestTarget >> testPasses [

	self assert: true
]
