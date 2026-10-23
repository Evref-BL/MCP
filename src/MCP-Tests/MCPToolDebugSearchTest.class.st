"
Tests debug_search: what it reports about the debuggers open in the image, and that looking changes nothing.
"
Class {
	#name : 'MCPToolDebugSearchTest',
	#superclass : 'MCPToolAPITestCase',
	#category : 'MCP-Tests-Tools',
	#package : 'MCP-Tests',
	#tag : 'Tools'
}

{ #category : 'private' }
MCPToolDebugSearchTest >> debuggerNamed: aString [
	"A debugger on a session of its own, standing in for one a person opened."

	| exception session |
	exception := (OupsNullException fromSignallerContext: thisContext)
		             messageText: aString;
		             yourself.
	session := (DebugSession named: aString on: Processor activeProcess startedAt: thisContext)
		           exception: exception;
		           yourself.
	^ StDebugger on: session
]

{ #category : 'private' }
MCPToolDebugSearchTest >> entryNamed: aString in: data [

	^ (data at: #debuggers) detect: [ :each | (each at: #debugger) = aString ] ifNone: [ nil ]
]

{ #category : 'private' }
MCPToolDebugSearchTest >> searchWith: someArguments [

	^ self callToolNamed: 'debug_search' withArguments: someArguments
]

{ #category : 'tests' }
MCPToolDebugSearchTest >> testAnswersAnOpenDebuggerWithItsExceptionAndStack [

	| data entry debugger |
	debugger := self debuggerNamed: 'MCP searchable debugger'.
	data := self dataFrom: (self searchWith: Dictionary new).
	entry := self entryNamed: 'MCP searchable debugger' in: data.
	self deny: entry isNil.
	self assert: ((entry at: #exception) includesSubstring: 'MCP searchable debugger').
	self deny: (entry at: #stack) isEmpty.
	self assert: debugger notNil
]

{ #category : 'tests' }
MCPToolDebugSearchTest >> testLeavesTheDebuggersItFound [

	| before debugger |
	debugger := self debuggerNamed: 'MCP untouched debugger'.
	before := StDebugger allInstances size.
	self searchWith: Dictionary new.
	self assert: StDebugger allInstances size equals: before.
	self assert: debugger session exception messageText equals: 'MCP untouched debugger'
]

{ #category : 'tests' }
MCPToolDebugSearchTest >> testQueryKeepsOnlyTheMatchingDebuggers [

	| data wanted unwanted |
	wanted := self debuggerNamed: 'MCP wanted debugger'.
	unwanted := self debuggerNamed: 'MCP other debugger'.
	data := self dataFrom: (self searchWith: { (#query -> 'wanted') } asDictionary).
	self deny: (self entryNamed: 'MCP wanted debugger' in: data) isNil.
	self assert: (self entryNamed: 'MCP other debugger' in: data) isNil.
	self assert: wanted notNil.
	self assert: unwanted notNil
]
