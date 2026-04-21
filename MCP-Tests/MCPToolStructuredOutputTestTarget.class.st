Class {
	#name : 'MCPToolStructuredOutputTestTarget',
	#superclass : 'TestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
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
