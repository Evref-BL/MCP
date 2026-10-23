"
Tests debug_watch: what it records, what it answers when the watched code fails, and that it leaves no probe behind.
"
Class {
	#name : 'MCPToolDebugWatchTest',
	#superclass : 'MCPToolAPITestCase',
	#category : 'MCP-Tests-Tools',
	#package : 'MCP-Tests',
	#tag : 'Tools'
}

{ #category : 'private' }
MCPToolDebugWatchTest >> installedDebugPointCount [

	^ DebugPoint all size
]

{ #category : 'private' }
MCPToolDebugWatchTest >> seriesFor: aMethodName watching: aVariableName in: data [

	^ (data at: #watched)
		  detect: [ :each | (each at: #method) = aMethodName and: [ (each at: #watching) = aVariableName ] ]
		  ifNone: [ nil ]
]

{ #category : 'private' }
MCPToolDebugWatchTest >> watchWith: someArguments [

	^ self callToolNamed: 'debug_watch' withArguments: someArguments
]

{ #category : 'tests' }
MCPToolDebugWatchTest >> testEntryWatchRecordsTheArgumentsOfEveryCall [

	| data series |
	data := self dataFrom: (self watchWith: {
				         (#method -> 'MCPDebugWatchTestTarget>>sumTo:').
				         (#run -> 'MCPDebugWatchTestTarget new sumTo: 2. MCPDebugWatchTestTarget new sumTo: 5') } asDictionary).
	series := self seriesFor: 'MCPDebugWatchTestTarget>>sumTo:' watching: 'n' in: data.
	self deny: series isNil.
	self assert: (series at: #values) equals: #( '2' '5' )
]

{ #category : 'tests' }
MCPToolDebugWatchTest >> testLeavesNoProbeBehindWhenTheWatchedCodeFails [

	| before |
	before := self installedDebugPointCount.
	self watchWith: {
			(#method -> 'MCPDebugWatchTestTarget>>failingSumTo:').
			(#variable -> 'total').
			(#run -> 'MCPDebugWatchTestTarget new failingSumTo: 3') } asDictionary.
	self assert: self installedDebugPointCount equals: before
]

{ #category : 'tests' }
MCPToolDebugWatchTest >> testNamesSeveralMethodsAndVariablesInOneCall [

	| data |
	data := self dataFrom: (self watchWith: {
				         (#method -> #( 'MCPDebugWatchTestTarget>>sumTo:' 'MCPDebugWatchTestTarget class>>doubleOf:' )).
				         (#variable -> #( 'total' 'doubled' )).
				         (#run -> 'MCPDebugWatchTestTarget new sumTo: 2. MCPDebugWatchTestTarget doubleOf: 5') } asDictionary).
	self assert: (self seriesFor: 'MCPDebugWatchTestTarget>>sumTo:' watching: 'total' in: data) notNil.
	self
		assert: ((self seriesFor: 'MCPDebugWatchTestTarget class>>doubleOf:' watching: 'doubled' in: data) at: #values)
		equals: #( '5' '10' ).
	"A variable that no assignment in a method mentions simply has no series there."
	self assert: (self seriesFor: 'MCPDebugWatchTestTarget>>sumTo:' watching: 'doubled' in: data) isNil
]

{ #category : 'tests' }
MCPToolDebugWatchTest >> testRecordsEveryAssignmentToAWatchedVariable [

	| data series |
	data := self dataFrom: (self watchWith: {
				         (#method -> 'MCPDebugWatchTestTarget>>sumTo:').
				         (#variable -> 'total').
				         (#run -> 'MCPDebugWatchTestTarget new sumTo: 3') } asDictionary).
	series := self seriesFor: 'MCPDebugWatchTestTarget>>sumTo:' watching: 'total' in: data.
	self deny: series isNil.
	self assert: (series at: #values) equals: #( '0' '1' '3' '6' ).
	self assert: (data at: #result) equals: '6'
]

{ #category : 'tests' }
MCPToolDebugWatchTest >> testReportsTheFailureOfTheWatchedCodeAsItsResult [

	| data series |
	data := self dataFrom: (self watchWith: {
				         (#method -> 'MCPDebugWatchTestTarget>>failingSumTo:').
				         (#variable -> 'total').
				         (#run -> 'MCPDebugWatchTestTarget new failingSumTo: 3') } asDictionary).
	self assert: ((data at: #result) includesSubstring: 'ZeroDivide').
	series := self seriesFor: 'MCPDebugWatchTestTarget>>failingSumTo:' watching: 'total' in: data.
	self assert: (series at: #values) equals: #( '0' '1' '3' '6' )
]

{ #category : 'tests' }
MCPToolDebugWatchTest >> testUnreadableMethodReferenceTeachesTheSyntax [

	| result |
	result := self watchWith: { (#method -> 'not a method'). (#run -> '1') } asDictionary.
	self assert: (self resultIndicatesError: result).
	self assert: ((self summaryFrom: result) includesSubstring: 'Class>>selector')
]

{ #category : 'tests' }
MCPToolDebugWatchTest >> testVariableNoMethodAssignsIsAnError [

	| result |
	result := self watchWith: {
			          (#method -> 'MCPDebugWatchTestTarget>>sumTo:').
			          (#variable -> 'noSuchVariable').
			          (#run -> '1') } asDictionary.
	self assert: (self resultIndicatesError: result).
	self assert: ((self summaryFrom: result) includesSubstring: 'None of the named variables')
]
