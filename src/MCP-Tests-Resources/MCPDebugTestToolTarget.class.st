"
SUnit target used by debugger test-running tool tests.
"
Class {
	#name : 'MCPDebugTestToolTarget',
	#superclass : 'TestCase',
	#category : 'MCP-Tests-Resources-Tools',
	#package : 'MCP-Tests-Resources',
	#tag : 'Tools'
}

{ #category : 'fixtures' }
MCPDebugTestToolTarget >> debugTestFailingCase [
	"This is a fixture test method; the failure is intentional and exercised by MCP debugger test-running tool tests."

	self assert: 6 * 7 equals: 43
]

{ #category : 'fixtures' }
MCPDebugTestToolTarget >> debugTestPassingCase [
	"This is a fixture test method, intentionally exercised by MCP debugger test-running tool tests."

	self assert: 6 * 7 equals: 42
]

{ #category : 'running' }
MCPDebugTestToolTarget >> setUp [

	super setUp
]

{ #category : 'running' }
MCPDebugTestToolTarget >> tearDown [

	super tearDown
]
