"
Abstract fixture test case whose suite holds the tests of its subclasses.
"
Class {
	#name : 'MCPToolRunTestsAbstractTarget',
	#superclass : 'TestCase',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'testing' }
MCPToolRunTestsAbstractTarget class >> isAbstract [

	^ self == MCPToolRunTestsAbstractTarget
]

{ #category : 'tests' }
MCPToolRunTestsAbstractTarget >> testInherited [
	"This is a fixture test method, intentionally exercised by MCP test-running tool tests through the subclasses that inherit it."

	self assert: true
]
