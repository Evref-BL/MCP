"
Fixture test case used by test_run tests: each test sends a message its receiver does not understand, whose keywords or receiver say what was meant.
"
Class {
	#name : 'MCPToolRunTestsNotUnderstoodTarget',
	#superclass : 'TestCase',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'tests' }
MCPToolRunTestsNotUnderstoodTarget >> testRunsTwoMessagesTogether [
	"This is a fixture test method; the send is intentionally one message where two were meant, and exercised by MCP test-running tool tests."

	#( 3 1 2 ) asOrderedCollection sorted: [ :a :b | a < b ] collect: [ :each | each ]
]

{ #category : 'tests' }
MCPToolRunTestsNotUnderstoodTarget >> testSendsAnInstanceMessageToTheClass [
	"This is a fixture test method; sending an instance-side message to the class is intentional and exercised by MCP test-running tool tests."

	OrderedCollection addFirst: 1
]
