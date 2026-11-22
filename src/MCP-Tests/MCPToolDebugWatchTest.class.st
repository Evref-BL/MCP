"
Tests debug_watch: what it records, what it answers when the watched code fails, and that it leaves no probe behind and the links it did not set in place.
"
Class {
	#name : 'MCPToolDebugWatchTest',
	#superclass : 'MCPToolAPITestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'private - classes' }
MCPToolDebugWatchTest >> fixtureClassNames [

	^ #( #MCPDebugWatchTestLinkTarget )
]

{ #category : 'private' }
MCPToolDebugWatchTest >> seriesFor: aMethodName watching: aVariableName in: data [

	^ (data at: #watched)
		  detect: [ :each | (each at: #method) = aMethodName and: [ (each at: #watching) = aVariableName ] ]
		  ifNone: [ nil ]
]

{ #category : 'tests' }
MCPToolDebugWatchTest >> testAProcessLeftInAWatchedMethodFinishesItAfterTheWatch [
	"A probe sits in a method any process may run. One still in the method when the watch ends runs into the probe after its removal, where Pharo's hit announcement asks the frame's source node, which the method no longer gives: the failure, in a process with no handler, quit a headless image. This process waits in an assignment the watch probes, entered once the probes are in."

	| gate done probed answer data |
	gate := Semaphore new.
	done := Semaphore new.
	probed := false.
	[
		[ (MCPDebugWatchTestTarget >> #sumOf:) hasMetaLinks or: [ gate isSignaled ] ] whileFalse: [ (Delay forMilliseconds: 1) wait ].
		answer := [
			          MCPDebugWatchTestTarget new sumOf: {
					          1.
					          [
						          probed := thisContext sender compiledCode method hasMetaLinks.
						          gate wait.
						          2 ] } ]
			          on: Error
			          do: [ :error | error ].
		done signal ] fork.
	data := [
		        self dataFrom: (self watchWith: {
					         (#method -> 'MCPDebugWatchTestTarget>>sumOf:').
					         (#variable -> 'total').
					         (#run -> '(Delay forMilliseconds: 50) wait. MCPDebugWatchTestTarget new sumOf: #( 1 2 )') } asDictionary) ] ensure: [
		        gate signal ].
	self deny: (done waitTimeoutSeconds: 5).
	self assert: probed.
	self assert: answer equals: 3.
	self assert: (data at: #result) equals: '3'.
	self deny: (MCPDebugWatchTestTarget >> #sumOf:) hasMetaLinks
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
MCPToolDebugWatchTest >> testKeepsALinkSetElsewhereThatWaitsOnAVariable [
	"A link on a variable no method uses yet holds no node, and waits in Pharo's link installer for the methods still to come."

	| target link |
	target := self
		          createClassNamed: self fixtureClassNames first
		          superclassName: 'Object'
		          slots: #( unused )
		          classSlots: #(  ).
	link := MetaLink new.
	target link: link toVariableNamed: #unused option: #write.
	[
		self watchWith: {
				(#method -> 'MCPDebugWatchTestTarget>>sumTo:').
				(#run -> 'MCPDebugWatchTestTarget new sumTo: 1') } asDictionary.
		self ensureMethodSource: 'writeUnused unused := 1' protocol: 'fixtures' on: target.
		self assert: (target >> #writeUnused) hasMetaLinks ] ensure: [ link uninstall ]
]

{ #category : 'tests' }
MCPToolDebugWatchTest >> testLeavesNoProbeBehindWhenTheWatchedCodeFails [

	| registry linkedElsewhere |
	registry := MetaLink linkInstaller linksRegistry.
	linkedElsewhere := MetaLink allInstances anySatisfy: [ :each | each hasNodes or: [ registry hasPermaLinks: each ] ].
	self watchWith: {
			(#method -> 'MCPDebugWatchTestTarget>>failingSumTo:').
			(#variable -> 'total').
			(#run -> 'MCPDebugWatchTestTarget new failingSumTo: 3') } asDictionary.
	self deny: (MCPDebugWatchTestTarget >> #failingSumTo:) hasMetaLinks.
	"Nor the link installer the probes made, which would go on reading every method the image changes, unless a link set elsewhere keeps it."
	linkedElsewhere ifFalse: [ self assert: (MetaLink instVarNamed: #linkInstaller) isNil ]
]

{ #category : 'tests' }
MCPToolDebugWatchTest >> testNamesSeveralMethodsAndVariablesInOneCall [

	| data |
	data := self dataFrom: (self watchWith: {
				         (#method -> #( 'MCPDebugWatchTestTarget>>sumTo:' 'MCPDebugWatchTestTarget class>>doubleOf:' )).
				         (#variable -> #( 'total' 'doubled' )).
				         (#run -> 'MCPDebugWatchTestTarget new sumTo: 2. MCPDebugWatchTestTarget doubleOf: 5') } asDictionary).
	self assert: (self seriesFor: 'MCPDebugWatchTestTarget>>sumTo:' watching: 'total' in: data) isNotNil.
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
	"debug_watch has no class argument, so the help mentions none."

	| result |
	result := self watchWith: {
			          (#method -> 'not a method').
			          (#run -> '1') } asDictionary.
	self assert: (self resultIndicatesError: result).
	self assert:
		((self summaryFrom: result) endsWith: 'Write a method as Class>>selector, or Class class>>selector for the class side.')
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

{ #category : 'tests' }
MCPToolDebugWatchTest >> testWatchedCodeGetsTheDefaultActionOfANotificationTheBoundaryRefuses [
	"The watched code is the caller's, not a change of the tool's, so a notification the boundary refuses to resume gets its default action there, as it would with no tool calling."

	| data result series |
	result := self watchWith: {
			          (#method -> 'MCPDebugWatchTestTarget>>sumTo:').
			          (#run -> 'MCPDebugWatchTestTarget new sumTo: 2. MCPToolRefusedNotification signal') } asDictionary.
	self deny: (self resultIndicatesError: result).
	data := self dataFrom: result.
	self assert: (data at: #result) equals: '#mcpDefaultAction'.
	series := self seriesFor: 'MCPDebugWatchTestTarget>>sumTo:' watching: 'n' in: data.
	self assert: (series at: #values) equals: #( '2' )
]

{ #category : 'tests' }
MCPToolDebugWatchTest >> testWatchesAMethodItsOwnProbeSends [
	"Compiling a probe's script sends yourself, and other processes send it too: the probe fired again inside its own work without end, and a process it fired in before its script was set failed, which quits a headless image."

	| data result |
	result := self watchWith: {
			          (#method -> 'Object>>yourself').
			          (#run -> '3 yourself') } asDictionary.
	self deny: (self resultIndicatesError: result).
	data := self dataFrom: result.
	self assert: (data at: #result) equals: '3'.
	self assert: (((self seriesFor: 'Object>>yourself' watching: 'self' in: data) at: #values) includes: '3').
	self deny: (Object >> #yourself) hasMetaLinks
]

{ #category : 'tests' }
MCPToolDebugWatchTest >> testWatchesMethodsOfOneStatement [
	"A method of one statement has the interval of its body, which cannot carry a probe, and Pharo refuses one after a return: a method answering an argument or self, or sending one message, failed with Pharo's own error."

	| data |
	data := self dataFrom: (self watchWith: {
				         (#method
				          -> #( 'MCPDebugWatchTestTarget class>>echo:' 'MCPDebugWatchTestTarget>>itself' 'MCPDebugWatchTestTarget>>print:' )).
				         (#run -> 'MCPDebugWatchTestTarget echo: 7. MCPDebugWatchTestTarget new itself; print: 5') } asDictionary).
	self assert: ((self seriesFor: 'MCPDebugWatchTestTarget class>>echo:' watching: 'n' in: data) at: #values) equals: #( '7' ).
	self
		assert: ((self seriesFor: 'MCPDebugWatchTestTarget>>itself' watching: 'self' in: data) at: #values)
		equals: #( 'a MCPDebugWatchTestTarget' ).
	self assert: ((self seriesFor: 'MCPDebugWatchTestTarget>>print:' watching: 'n' in: data) at: #values) equals: #( '5' )
]

{ #category : 'private' }
MCPToolDebugWatchTest >> watchWith: someArguments [

	^ self callToolNamed: 'debug_watch' withArguments: someArguments
]
