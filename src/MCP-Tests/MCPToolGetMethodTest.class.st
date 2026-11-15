"
Tests the method_get tool.
"
Class {
	#name : 'MCPToolGetMethodTest',
	#superclass : 'MCPToolTestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'tests' }
MCPToolGetMethodTest >> testGetMethodMissingClassSuggestsClassNames [

	| error result |
	result := self callToolWith: {
			          (#class -> 'MCPToolGetMethodTestMissingClass').
			          (#selector -> 'value') } asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #errorCode) equals: 'ClassNotFound'.
	self assert: (error at: #class) equals: 'MCPToolGetMethodTestMissingClass'.
	self assert: (error at: #selector) equals: 'value'.
	self assert: ((error at: #suggestions) includes: 'MCPToolGetMethodTest').
	self assert: ((error at: #suggestions) allSatisfy: [ :each | each isString ]).
	self assert: ((error at: #message) includesSubstring: 'Class MCPToolGetMethodTestMissingClass does not exist')
]

{ #category : 'tests' }
MCPToolGetMethodTest >> testGetMethodOfAClassWrittenWithItsSide [
	"Agents copy Foo class from MCP's own answers, so it names the class side, with a bare selector or a reference."

	#( 'readClassSide' 'MCPToolGetMethodTestTarget class>>readClassSide' ) do: [ :selector |
			| result |
			result := self callToolWith: {
					          (#class -> 'MCPToolGetMethodTestTarget class').
					          (#selector -> selector) } asDictionary.
			self deny: (self resultIndicatesError: result) description: [ self summaryFrom: result ].
			self assert: (self summaryFrom: result) equals: 'Got method MCPToolGetMethodTestTarget class>>readClassSide.' ]
]

{ #category : 'tests' }
MCPToolGetMethodTest >> testGetMethodOfAClassWrittenWithItsSideRefusesSideInstance [

	| error result |
	result := self callToolWith: {
			          (#class -> 'MCPToolGetMethodTestTarget class').
			          (#side -> 'instance').
			          (#selector -> 'readClassSide') } asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #errorCode) equals: 'ClassSideConflict'.
	self assert: (error at: #class) equals: 'MCPToolGetMethodTestTarget'.
	self assert: (error at: #side) equals: 'instance'.
	self
		assert: (error at: #message)
		equals:
		'MCPToolGetMethodTestTarget class names the class side, but side is instance. Pass class MCPToolGetMethodTestTarget, with side class or instance.'
]

{ #category : 'tests' }
MCPToolGetMethodTest >> testGetMethodReturnsInstanceSideVariableContext [

	| classVariable data globalVariable instanceVariable result selfVariable |
	result := self callToolWith: {
			          (#class -> 'MCPToolGetMethodTestTarget').
			          (#selector -> 'readInstanceWith:').
			          (#includeVariableDetails -> true) } asDictionary.
	data := self dataFrom: result.
	instanceVariable := self variableNamed: 'instanceCounter' in: (data at: #variableReferences).
	classVariable := self variableNamed: 'SharedLimit' in: (data at: #variableReferences).
	globalVariable := self variableNamed: 'OrderedCollection' in: (data at: #variableReferences).
	selfVariable := self variableNamed: 'self' in: (data at: #variableReferences).
	self deny: (result at: #isError ifAbsent: [ false ]).
	self deny: (self resultIndicatesError: result).
	self assert: (data at: #protocol) equals: 'reading'.
	self assert: (instanceVariable at: #kind) equals: 'instanceVariable'.
	self assert: (instanceVariable at: #ownerName) equals: 'MCPToolGetMethodTestTarget'.
	self assert: (classVariable at: #kind) equals: 'classVariable'.
	self assert: (globalVariable at: #kind) equals: 'class'.
	self assert: (globalVariable at: #ownerName) equals: 'Smalltalk globals'.
	self assert: (selfVariable at: #kind) equals: 'self'.
	self assert: (data at: #variableReferences) size equals: 7.
	self assert: ((data at: #variableReferences) allSatisfy: [ :each |
			 #( #sourceIntervals #external #declaredInMethod ) noneSatisfy: [ :key | each includesKey: key ] ]).
	self assert: ((data at: #source) includesSubstring: String cr asString).
	self assert: ((data at: #source) includesSubstring: 'instanceCounter ifNil: [ SharedLimit ]').
	self deny: (data includesKey: #class).
	self deny: (data includesKey: #selector).
	self deny: (data includesKey: #side).
	self deny: (data includesKey: #arguments).
	self deny: (data includesKey: #temporaryNames).
	self deny: (data includesKey: #variableDetailsIncluded).
	self deny: (data includesKey: #variableReferenceCount).
	self deny: (data includesKey: #externalVariableCount).
	self deny: (data includesKey: #externalVariableReferences)
]

{ #category : 'tests' }
MCPToolGetMethodTest >> testGetMethodReturnsStructuredErrorForMissingSelector [

	| error result structured |
	result := self callToolWith: {
			          (#class -> 'MCPToolGetMethodTestTarget').
			          (#selector -> 'doesNotExist') } asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'MethodNotFound'.
	self assert: (error at: #class) equals: 'MCPToolGetMethodTestTarget'.
	self assert: (error at: #selector) equals: 'doesNotExist'.
	self assert: (error includesKey: #side).
	self assert: (error at: #side) equals: 'instance'.
	self assert: ((error at: #message) includesSubstring: 'Method MCPToolGetMethodTestTarget>>doesNotExist does not exist.')
]

{ #category : 'tests' }
MCPToolGetMethodTest >> testGetMethodSuggestsExactOppositeSideSelector [

	| error result suggestions |
	result := self callToolWith: {
			          (#class -> 'MCPToolGetMethodTestTarget').
			          (#selector -> 'readClassSide') } asDictionary.
	error := self errorFrom: result.
	suggestions := error at: #suggestions.
	self assert: (result at: #isError).
	self assert: (error at: #errorCode) equals: 'MethodNotFound'.
	self assert: suggestions size equals: 1.
	self assert: (suggestions first at: #class) equals: 'MCPToolGetMethodTestTarget'.
	self assert: (suggestions first at: #side) equals: 'class'.
	self assert: (suggestions first at: #selector) equals: 'readClassSide'
]

{ #category : 'tests' }
MCPToolGetMethodTest >> testGetMethodSupportsClassSideContext [

	| classInstanceVariable data result thisContextVariable |
	result := self callToolWith: {
			          (#class -> 'MCPToolGetMethodTestTarget').
			          (#selector -> 'readClassSide').
			          (#side -> 'class').
			          (#includeVariableDetails -> true) } asDictionary.
	data := self dataFrom: result.
	classInstanceVariable := self variableNamed: 'classCounter' in: (data at: #variableReferences).
	thisContextVariable := self variableNamed: 'thisContext' in: (data at: #variableReferences).
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (classInstanceVariable at: #kind) equals: 'classInstanceVariable'.
	self assert: (classInstanceVariable at: #ownerName) equals: 'MCPToolGetMethodTestTarget class'.
	self assert: (thisContextVariable at: #kind) equals: 'thisContext'.
	self assert: (thisContextVariable at: #ownerName) equals: 'execution context'.
	self assert: ((data at: #variableReferences) allSatisfy: [ :each |
			 #( #sourceIntervals #external #declaredInMethod ) noneSatisfy: [ :key | each includesKey: key ] ]).
	self assert: ((data at: #source) includesSubstring: String cr asString).
	self assert: data keys asSet equals: #( protocol source variableReferences ) asSet
]

{ #category : 'tests' }
MCPToolGetMethodTest >> testNamesNoTraitForAMethodTheClassOverrides [

	| data result |
	result := self callToolWith: {
			          (#class -> 'MCPToolMethodSearchTraitOverrider').
			          (#selector -> 'mcpTraitFixtureValue') } asDictionary.
	data := self dataFrom: result.
	self assert: ((data at: #source) includesSubstring: 'overridden').
	self deny: (data includesKey: #trait)
]

{ #category : 'tests' }
MCPToolGetMethodTest >> testNamesTheTraitAMethodIsInstalledFrom [

	| data result text |
	result := self callToolWith: {
			          (#class -> 'MCPToolMethodSearchTraitUser').
			          (#selector -> 'mcpTraitFixtureValue') } asDictionary.
	data := self dataFrom: result.
	text := (result at: #content) first at: #text.
	self assert: (data at: #trait) equals: 'TMCPToolMethodSearchFixture'.
	self assert: (text includesSubstring: 'trait: TMCPToolMethodSearchFixture')
]

{ #category : 'tests' }
MCPToolGetMethodTest >> testToolRequiresClassNameAndSelectorInSchema [

	self assert: MCPToolGetMethod new inputSchema required asSet equals: #( 'selector' ) asSet
]

{ #category : 'tests' }
MCPToolGetMethodTest >> testUnreadableReferenceTeachesTheSyntaxAndTheClassArgument [
	"method_get has a class argument for a bare selector, which the help names as the schema spells it."

	| error result |
	result := self callToolWith: { (#selector -> 'MCPToolGetMethodTestTarget>>') } asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #errorCode) equals: 'MethodReferenceUnreadable'.
	self
		assert: (error at: #message)
		equals:
		'MCPToolGetMethodTestTarget>> does not name a method. Write a method as Class>>selector, or Class class>>selector for the class side. A bare selector works too when class is given.'
]

{ #category : 'private - calling' }
MCPToolGetMethodTest >> toolName [

	^ 'method_get'
]

{ #category : 'private' }
MCPToolGetMethodTest >> variableNamed: aName in: variableReferences [

	^ variableReferences detect: [ :each | (each at: #name) = aName ] ifNone: [ self fail: 'Missing variable summary for ' , aName ]
]
