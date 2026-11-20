"
Tests debug_search: what it reports about the debuggers open in the image, and that looking changes nothing.
"
Class {
	#name : 'MCPToolDebugSearchTest',
	#superclass : 'MCPToolAPITestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'private' }
MCPToolDebugSearchTest >> debuggerNamed: aString [
	"A debugger opened on a process of its own, standing in for one a person opened: closing a debugger terminates its process, which must not be the test's."

	| process exception session |
	process := [ ] newProcess.
	exception := (OupsNullException fromSignallerContext: process suspendedContext)
		             messageText: aString;
		             yourself.
	session := (DebugSession named: aString on: process startedAt: process suspendedContext)
		           exception: exception;
		           yourself.
	^ (StDebugger on: session)
		  open;
		  yourself
]

{ #category : 'private' }
MCPToolDebugSearchTest >> entryNamed: aString searchedWith: someArguments [

	^ ((self dataFrom: (self searchWith: someArguments)) at: #debuggers)
		  detect: [ :each | (each at: #debugger) = aString ]
		  ifNone: [ nil ]
]

{ #category : 'private' }
MCPToolDebugSearchTest >> searchWith: someArguments [

	^ self callToolNamed: 'debug_search' withArguments: someArguments
]

{ #category : 'tests' }
MCPToolDebugSearchTest >> testAnswersAMatchingOpenDebuggerWithItsExceptionAndStack [

	| debugger entry |
	debugger := self debuggerNamed: 'MCP searchable debugger'.
	[
		entry := self entryNamed: 'MCP searchable debugger' searchedWith: Dictionary new.
		self deny: entry isNil.
		self assert: ((entry at: #exception) includesSubstring: 'MCP searchable debugger').
		self deny: (entry at: #stack) isEmpty.
		self deny: (self entryNamed: 'MCP searchable debugger' searchedWith: { (#query -> 'searchable') } asDictionary) isNil.
		self assert: (self entryNamed: 'MCP searchable debugger' searchedWith: { (#query -> 'other') } asDictionary) isNil ] ensure: [
		debugger close ]
]

{ #category : 'tests' }
MCPToolDebugSearchTest >> testDebugResultDoesNotRepeatItsWarnings [

	| contentText |
	contentText := MCPToolDebugSearch new contentTextForStructuredContent: (Dictionary new
		               at: #summary put: 'One open debugger.';
		               at: #warnings put: { 'Careful.' };
		               at: #data put: (Dictionary new
				                at: #debuggers put: { (Dictionary new
						                 at: #debugger put: 'A debugger';
						                 at: #exception put: 'ZeroDivide: divide by zero';
						                 yourself) };
				                yourself);
		               yourself).
	self assert: (contentText includesSubstring: 'debugger="A debugger"').
	self assert: (contentText includesSubstring: 'Careful.').
	"The warnings are read out above the payload, so the payload does not name them again."
	self deny: (contentText includesSubstring: 'warnings')
]

{ #category : 'tests' }
MCPToolDebugSearchTest >> testLeavesTheDebuggersItFound [

	| debugger |
	debugger := self debuggerNamed: 'MCP untouched debugger'.
	[
		self searchWith: Dictionary new.
		self assert: debugger window isOpen.
		self deny: debugger session interruptedProcess isTerminated.
		self assert: debugger session exception messageText equals: 'MCP untouched debugger' ] ensure: [ debugger close ]
]

{ #category : 'tests' }
MCPToolDebugSearchTest >> testStackFramesReadOnePerLine [
	"A frame and its variables are one item of the stack: its variables stay under it, and the next frame starts its own line."

	| contentText |
	contentText := MCPToolDebugSearch new contentTextForStructuredContent: (Dictionary new
			                at: #summary put: '1 open debugger.';
			                at: #data put: { (#debuggers -> { {
						                 (#debugger -> 'ZeroDivide').
						                 (#exception -> 'ZeroDivide: divide by zero').
						                 (#stack -> {
								                  (String lf join: #( 'SmallInteger(Number)>>/' '   self=3' '   aNumber=0' )).
								                  'UndefinedObject>>DoIt' }) } asDictionary }) } asDictionary;
			                yourself).
	self
		assert: contentText lines
		equals: #( '1 open debugger.' 'debuggers:' '  debugger=ZeroDivide exception="ZeroDivide: divide by zero"'
			   '    stack:' '      SmallInteger(Number)>>/' '         self=3' '         aNumber=0' '      UndefinedObject>>DoIt' )
]
