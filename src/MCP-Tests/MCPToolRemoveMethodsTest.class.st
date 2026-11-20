"
Tests the method_remove tool.
"
Class {
	#name : 'MCPToolRemoveMethodsTest',
	#superclass : 'MCPToolTestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'private' }
MCPToolRemoveMethodsTest >> classBatchArguments [

	^ {
		  (#class -> 'MCPToolRemoveMethodsTestTarget').
		  (#side -> 'class').
		  (#selector -> self classBatchSelectors) } asDictionary
]

{ #category : 'private' }
MCPToolRemoveMethodsTest >> classBatchSelectors [

	^ {
		  self firstClassBatchSelectorString.
		  self secondClassBatchSelectorString } asArray
]

{ #category : 'private' }
MCPToolRemoveMethodsTest >> firstClassBatchMethodSource [

	^ String streamContents: [ :stream |
		  stream << self firstClassBatchSelectorString << ' ^ self ' << self secondClassBatchSelectorString << ' + 1' ]
]

{ #category : 'private' }
MCPToolRemoveMethodsTest >> firstClassBatchSelector [

	^ self firstClassBatchSelectorString asSymbol
]

{ #category : 'private' }
MCPToolRemoveMethodsTest >> firstClassBatchSelectorString [

	^ String streamContents: [ :stream | stream << 'first' << 'Class' << 'Batch' << 'Removal' ]
]

{ #category : 'private' }
MCPToolRemoveMethodsTest >> firstInstanceBatchMethodSource [

	^ String streamContents: [ :stream |
		  stream << self firstInstanceBatchSelectorString << ' ^ self ' << self secondInstanceBatchSelectorString << ' + 1' ]
]

{ #category : 'private' }
MCPToolRemoveMethodsTest >> firstInstanceBatchSelector [

	^ self firstInstanceBatchSelectorString asSymbol
]

{ #category : 'private' }
MCPToolRemoveMethodsTest >> firstInstanceBatchSelectorString [

	^ String streamContents: [ :stream | stream << 'first' << 'Batch' << 'Removal' ]
]

{ #category : 'private' }
MCPToolRemoveMethodsTest >> firstTextFrom: aResult [

	^ (aResult at: #content) first at: #text
]

{ #category : 'private' }
MCPToolRemoveMethodsTest >> instanceBatchArguments [

	^ {
		  (#class -> 'MCPToolRemoveMethodsTestTarget').
		  (#side -> 'instance').
		  (#selector -> self instanceBatchSelectors) } asDictionary
]

{ #category : 'private' }
MCPToolRemoveMethodsTest >> instanceBatchSelectors [

	^ {
		  self firstInstanceBatchSelectorString.
		  self secondInstanceBatchSelectorString } asArray
]

{ #category : 'private' }
MCPToolRemoveMethodsTest >> missingSelectorString [

	^ String streamContents: [ :stream | stream << 'definitely' << 'Missing' << 'Selector' ]
]

{ #category : 'private' }
MCPToolRemoveMethodsTest >> protectedMethodSource [

	^ self protectedSelectorString , ' ^ 5'
]

{ #category : 'private' }
MCPToolRemoveMethodsTest >> protectedSelector [

	^ self protectedSelectorString
]

{ #category : 'private' }
MCPToolRemoveMethodsTest >> protectedSelectorString [

	^ String streamContents: [ :stream | stream << 'externally' << 'Referenced' << 'Batch' << 'Removal' ]
]

{ #category : 'private' }
MCPToolRemoveMethodsTest >> protectedSelectorSymbol [

	^ self protectedSelectorString asSymbol
]

{ #category : 'private' }
MCPToolRemoveMethodsTest >> restoreFixtureMethods [

	self ensureMethodSource: self firstInstanceBatchMethodSource protocol: 'tests' on: MCPToolRemoveMethodsTestTarget.
	self ensureMethodSource: self secondInstanceBatchMethodSource protocol: 'tests' on: MCPToolRemoveMethodsTestTarget.
	self ensureMethodSource: self protectedMethodSource protocol: 'tests' on: MCPToolRemoveMethodsTestTarget.
	self ensureMethodSource: self firstClassBatchMethodSource protocol: 'tests' on: MCPToolRemoveMethodsTestTarget classSide.
	self ensureMethodSource: self secondClassBatchMethodSource protocol: 'tests' on: MCPToolRemoveMethodsTestTarget classSide.
	self ensureMethodSource: self senderMethodSource protocol: 'tests' on: MCPToolRemoveMethodsTestSender
]

{ #category : 'private' }
MCPToolRemoveMethodsTest >> secondClassBatchMethodSource [

	^ self secondClassBatchSelectorString , ' ^ 7'
]

{ #category : 'private' }
MCPToolRemoveMethodsTest >> secondClassBatchSelector [

	^ self secondClassBatchSelectorString asSymbol
]

{ #category : 'private' }
MCPToolRemoveMethodsTest >> secondClassBatchSelectorString [

	^ String streamContents: [ :stream | stream << 'second' << 'Class' << 'Batch' << 'Removal' ]
]

{ #category : 'private' }
MCPToolRemoveMethodsTest >> secondInstanceBatchMethodSource [

	^ self secondInstanceBatchSelectorString , ' ^ 2'
]

{ #category : 'private' }
MCPToolRemoveMethodsTest >> secondInstanceBatchSelector [

	^ self secondInstanceBatchSelectorString asSymbol
]

{ #category : 'private' }
MCPToolRemoveMethodsTest >> secondInstanceBatchSelectorString [

	^ String streamContents: [ :stream | stream << 'second' << 'Batch' << 'Removal' ]
]

{ #category : 'private' }
MCPToolRemoveMethodsTest >> senderMethodSource [

	^ 'sendProtectedRemovalTarget ^ MCPToolRemoveMethodsTestTarget new ' , self protectedSelectorString
]

{ #category : 'running' }
MCPToolRemoveMethodsTest >> setUp [

	super setUp.
	self restoreFixtureMethods
]

{ #category : 'running' }
MCPToolRemoveMethodsTest >> tearDown [

	self restoreFixtureMethods.
	super tearDown
]

{ #category : 'tests' }
MCPToolRemoveMethodsTest >> testAClassWrittenWithItsSideAndSideInstanceRemovesNothing [

	| error result |
	result := self callToolWith: {
			          (#class -> 'MCPToolRemoveMethodsTestTarget class').
			          (#side -> 'instance').
			          (#selector -> self classBatchSelectors) } asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #errorCode) equals: 'ClassSideConflict'.
	self assert: (error at: #side) equals: 'instance'.
	self assert: (MCPToolRemoveMethodsTestTarget classSide includesSelector: self firstClassBatchSelector)
]

{ #category : 'tests' }
MCPToolRemoveMethodsTest >> testAMethodNamedForItsSelfSendIsNotNamedAgain [
	"Nothing implements the selector any more, but its only sender is already named for sending it to self."

	| result |
	result := self callToolWith: {
			          (#class -> 'MCPToolRemoveMethodsTestTarget').
			          (#side -> 'class').
			          (#selector -> { self secondClassBatchSelectorString }) } asDictionary.
	self
		assert: (self summaryFrom: result)
		equals: ('Removed MCPToolRemoveMethodsTestTarget class>>{1}.' format: { self secondClassBatchSelectorString }).
	self
		assert: (self warningsFrom: result) asArray
		equals:
			{ ('MCPToolRemoveMethodsTestTarget class>>{1} still sends {2} to self, which MCPToolRemoveMethodsTestTarget class no longer understands.'
				 format: {
						 self firstClassBatchSelectorString.
						 self secondClassBatchSelectorString }) }
]

{ #category : 'tests' }
MCPToolRemoveMethodsTest >> testAMissingClassIsSaidByTheLookup [

	| error result |
	result := self callToolWith: {
			          (#class -> 'MCPToolRemoveMethodsTestMissingClass').
			          (#selector -> self firstInstanceBatchSelectorString) } asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #errorCode) equals: 'ClassNotFound'.
	self assert: (error at: #class) equals: 'MCPToolRemoveMethodsTestMissingClass'.
	self assert: ((error at: #message) beginsWith: 'Class MCPToolRemoveMethodsTestMissingClass does not exist.').
	self deny: ((error at: #message) includesSubstring: 'SystemEnvironment')
]

{ #category : 'tests' }
MCPToolRemoveMethodsTest >> testDefaultsToRemovingInstanceSideMethodsWhenClassSideIsOmitted [

	| result |
	result := self callToolWith: {
			          (#class -> 'MCPToolRemoveMethodsTestTarget').
			          (#selector -> self instanceBatchSelectors) } asDictionary.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self deny: (MCPToolRemoveMethodsTestTarget includesSelector: self firstInstanceBatchSelector).
	self deny: (MCPToolRemoveMethodsTestTarget includesSelector: self secondInstanceBatchSelector)
]

{ #category : 'tests' }
MCPToolRemoveMethodsTest >> testForceRemovesSuperOnlyOverride [

	| result |
	self ensureMethodSource: 'printString ^ super printString' protocol: 'tests' on: MCPToolRemoveMethodsTestTarget.
	[
		result := self callToolWith: {
				          (#class -> 'MCPToolRemoveMethodsTestTarget').
				          (#side -> 'instance').
				          (#selector -> #( 'printString' )) } asDictionary.
		self deny: (result at: #isError ifAbsent: [ false ]).
		self deny: (MCPToolRemoveMethodsTestTarget includesSelector: #printString) ] ensure: [
		self removeSelector: #printString from: MCPToolRemoveMethodsTestTarget ]
]

{ #category : 'tests' }
MCPToolRemoveMethodsTest >> testRemovesBatchOfClassSideMethods [

	| result |
	result := self callToolWith: self classBatchArguments.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self deny: (MCPToolRemoveMethodsTestTarget classSide includesSelector: self firstClassBatchSelector).
	self deny: (MCPToolRemoveMethodsTestTarget classSide includesSelector: self secondClassBatchSelector)
]

{ #category : 'tests' }
MCPToolRemoveMethodsTest >> testRemovesBatchOfInstanceMethods [

	| result |
	result := self callToolWith: self instanceBatchArguments.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self deny: (MCPToolRemoveMethodsTestTarget includesSelector: self firstInstanceBatchSelector).
	self deny: (MCPToolRemoveMethodsTestTarget includesSelector: self secondInstanceBatchSelector)
]

{ #category : 'tests' }
MCPToolRemoveMethodsTest >> testRemovesClassSideMethodsOfAClassWrittenWithItsSide [
	"Foo class names the class side, as Pharo prints it and as MCP's own answers print it."

	| result |
	result := self callToolWith: {
			          (#class -> 'MCPToolRemoveMethodsTestTarget class').
			          (#selector -> self classBatchSelectors) } asDictionary.
	self deny: (result at: #isError ifAbsent: [ false ]) description: [ self firstTextFrom: result ].
	self assert: ((self firstTextFrom: result) includesSubstring: 'MCPToolRemoveMethodsTestTarget class:').
	self deny: ((self firstTextFrom: result) includesSubstring: 'class class').
	self deny: (MCPToolRemoveMethodsTestTarget classSide includesSelector: self firstClassBatchSelector).
	self deny: (MCPToolRemoveMethodsTestTarget classSide includesSelector: self secondClassBatchSelector)
]

{ #category : 'tests' }
MCPToolRemoveMethodsTest >> testRemovesMethodsEvenWhenExternalSendersExistAndWarns [
	"Senders do not stop a removal. Once nothing in the image implements the selector, the answer names the methods that still send it."

	| result |
	result := self callToolWith: {
			          (#class -> 'MCPToolRemoveMethodsTestTarget').
			          (#side -> 'instance').
			          (#selector -> { self protectedSelector }) } asDictionary.
	self deny: (self resultIndicatesError: result).
	self deny: (MCPToolRemoveMethodsTestTarget includesSelector: self protectedSelectorSymbol).
	self
		assert: (self warningsFrom: result) asArray
		equals:
			{ ('1 method still sends {1}, which nothing in the image implements now: MCPToolRemoveMethodsTestSender>>sendProtectedRemovalTarget.'
				 format: { self protectedSelectorString }) }.
	self assert: ((self firstTextFrom: result) includesSubstring: 'Warning: 1 method still sends')
]

{ #category : 'tests' }
MCPToolRemoveMethodsTest >> testRemovingAMethodInstalledFromATraitStopsAndNamesTheTrait [

	| error result |
	result := self callToolWith: {
			          (#class -> 'MCPToolMethodSearchTraitUser').
			          (#selector -> #( 'mcpTraitFixtureValue' )) } asDictionary.
	error := self errorFrom: result.
	self assert: (self resultIndicatesError: result).
	self assert: (error at: #errorCode) equals: 'MethodInstalledFromTrait'.
	self assert: (error at: #trait) equals: 'TMCPToolMethodSearchFixture'.
	self assert: (error at: #origin) equals: 'TMCPToolMethodSearchFixture>>mcpTraitFixtureValue'.
	self assert: ((error at: #howToProceed) includesSubstring: 'has no method of its own to remove').
	self assert: (MCPToolMethodSearchTraitUser >> #mcpTraitFixtureValue) isFromTrait
]

{ #category : 'tests' }
MCPToolRemoveMethodsTest >> testRemovingAMethodOthersStillImplementWarnsOfNothing [
	"The class still understands printString from above it, so its own send of it keeps a method, and the image still implements it."

	| result |
	self ensureMethodSource: 'printString ^ super printString' protocol: 'tests' on: MCPToolRemoveMethodsTestTarget.
	self ensureMethodSource: 'describe ^ self printString' protocol: 'tests' on: MCPToolRemoveMethodsTestTarget.
	[
		result := self callToolWith: {
				          (#class -> 'MCPToolRemoveMethodsTestTarget').
				          (#selector -> #( 'printString' )) } asDictionary.
		self deny: (self resultIndicatesError: result).
		self deny: (MCPToolRemoveMethodsTestTarget includesSelector: #printString).
		self assertEmpty: (self warningsFrom: result) ] ensure: [
			self removeSelector: #printString from: MCPToolRemoveMethodsTestTarget.
			self removeSelector: #describe from: MCPToolRemoveMethodsTestTarget ]
]

{ #category : 'tests' }
MCPToolRemoveMethodsTest >> testRemovingWarnsOfSelfSendsTheClassNoLongerUnderstands [
	"Other classes implement asUppercase, so nothing is said of the image, but the class still sends it to self and no longer understands it."

	| result |
	self ensureMethodSource: 'asUppercase ^ ''FIVE''' protocol: 'tests' on: MCPToolRemoveMethodsTestTarget.
	self ensureMethodSource: 'shout ^ self asUppercase' protocol: 'tests' on: MCPToolRemoveMethodsTestTarget.
	[
		result := self callToolWith: {
				          (#class -> 'MCPToolRemoveMethodsTestTarget').
				          (#selector -> #( 'asUppercase' )) } asDictionary.
		self deny: (self resultIndicatesError: result).
		self
			assert: (self warningsFrom: result) asArray
			equals:
			#( 'MCPToolRemoveMethodsTestTarget>>shout still sends asUppercase to self, which MCPToolRemoveMethodsTestTarget no longer understands.' ) ]
		ensure: [
				self removeSelector: #asUppercase from: MCPToolRemoveMethodsTestTarget.
				self removeSelector: #shout from: MCPToolRemoveMethodsTestTarget ]
]

{ #category : 'tests' }
MCPToolRemoveMethodsTest >> testRemovingWarnsOfSendsItsSubclassesStillMake [
	"A subclass's send to super loses the method too, while its send to self still reaches its own override."

	| childName result |
	childName := 'MCPToolRemoveMethodsTestTargetChild'.
	self ensureMethodSource: 'asUppercase ^ ''FIVE''' protocol: 'tests' on: MCPToolRemoveMethodsTestTarget.
	self ensureMethodSource: 'shout ^ self asUppercase' protocol: 'tests' on: MCPToolRemoveMethodsTestTarget.
	self
		createClassNamed: childName
		superclassName: MCPToolRemoveMethodsTestTarget name
		slots: #(  )
		classSlots: #(  ).
	[
		self ensureMethodSource: 'asUppercase ^ ''five''' protocol: 'tests' on: (self classNamed: childName).
		self ensureMethodSource: 'louder ^ super asUppercase' protocol: 'tests' on: (self classNamed: childName).
		self ensureMethodSource: 'quieter ^ self asUppercase asLowercase' protocol: 'tests' on: (self classNamed: childName).
		result := self callToolWith: {
				          (#class -> 'MCPToolRemoveMethodsTestTarget').
				          (#selector -> #( 'asUppercase' )) } asDictionary.
		self
			assert: (self warningsFrom: result) asArray
			equals:
				{ ('MCPToolRemoveMethodsTestTarget>>shout and {1}>>louder still send asUppercase to self or super, which MCPToolRemoveMethodsTestTarget no longer understands.'
					 format: { childName }) } ] ensure: [
			self removeClassNamed: childName.
			self removeSelector: #asUppercase from: MCPToolRemoveMethodsTestTarget.
			self removeSelector: #shout from: MCPToolRemoveMethodsTestTarget ]
]

{ #category : 'tests' }
MCPToolRemoveMethodsTest >> testReturnsStructuredErrorWhenAnyMethodIsMissing [

	| error result structured |
	result := self callToolWith: {
			          (#class -> 'MCPToolRemoveMethodsTestTarget').
			          (#side -> 'instance').
			          (#selector -> {
				           self firstInstanceBatchSelectorString.
				           self missingSelectorString }) } asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'MethodNotFound'.
	self assert: (error at: #selector) equals: self missingSelectorString.
	self assert: (MCPToolRemoveMethodsTestTarget includesSelector: self firstInstanceBatchSelector)
]

{ #category : 'tests' }
MCPToolRemoveMethodsTest >> testSummaryNamesOneMethodAsAReference [
	"One method is named the way Pharo writes it; several are counted and listed after their class."

	self
		assert: (self summaryFrom: (self callToolWith: {
						  (#class -> 'MCPToolRemoveMethodsTestTarget').
						  (#selector -> { self firstInstanceBatchSelectorString }) } asDictionary))
		equals: ('Removed MCPToolRemoveMethodsTestTarget>>{1}.' format: { self firstInstanceBatchSelectorString }).
	self
		assert: (self summaryFrom: (self callToolWith: self classBatchArguments))
		equals: ('Removed 2 methods from MCPToolRemoveMethodsTestTarget class: {1}, {2}.' format: self classBatchSelectors)
]

{ #category : 'tests' }
MCPToolRemoveMethodsTest >> testToolRequiresSelectorsInSchema [

	| classSideProperty |
	classSideProperty := MCPToolRemoveMethods new inputSchema properties detect: [ :each | each name = 'side' ].
	self assert: MCPToolRemoveMethods new name equals: 'method_remove'.
	self assert: MCPToolRemoveMethods new inputSchema required asSet equals: #( 'class' 'selector' ) asSet.
	self assert: (classSideProperty extraProperties at: #default) equals: 'instance'
]

{ #category : 'tests' }
MCPToolRemoveMethodsTest >> testWarningsCountAndListTheMethodsTheyName [
	"A send to super alone says so, after one method sends; past ten methods, the first ten are listed and the rest counted."

	| methods tool warning |
	tool := MCPToolRemoveMethods new.
	warning := tool
		           hierarchySendWarningFor: #asUppercase
		           sends: (IdentityDictionary new
				            at: MCPToolRemoveMethodsTestTarget >> self firstInstanceBatchSelector put: (Set with: 'super');
				            yourself)
		           from: MCPToolRemoveMethodsTestTarget.
	self
		assert: warning
		equals:
			('MCPToolRemoveMethodsTestTarget>>{1} still sends asUppercase to super, which MCPToolRemoveMethodsTestTarget no longer understands.'
				 format: { self firstInstanceBatchSelectorString }).
	methods := (MCPToolRemoveMethodsTest localMethods asArray sort: [ :left :right | left selector <= right selector ]) first: 12.
	self assert: (tool listTextForMethods: methods) equals: (String streamContents: [ :stream |
				 (methods first: 10) do: [ :each | stream << 'MCPToolRemoveMethodsTest>>' << each selector ] separatedBy: [ stream << ', ' ].
				 stream << ', and 2 more' ])
]

{ #category : 'private - calling' }
MCPToolRemoveMethodsTest >> toolName [

	^ 'method_remove'
]
