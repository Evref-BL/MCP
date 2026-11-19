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
MCPToolGetMethodTest >> testGetMethodAnswersAnInheritedMethodInABatch [
	"Each target of a call is looked up on its own, so one the class inherits is answered beside one it has."

	| entries result |
	result := self callToolWith:
		          { (#selector -> #( 'MCPToolHierarchyTestChild>>hierarchyProbe' 'MCPToolHierarchyTestChild>>hierarchyTarget' )) }
			          asDictionary.
	self assert: (self summaryFrom: result) equals: 'Got 2 of 2 methods.'.
	entries := (self dataFrom: result) at: #results.
	self deny: (entries first includesKey: #inheritedFrom).
	self assert: ((entries first at: #source) includesSubstring: '''child''').
	self assert: (entries second at: #inheritedFrom) equals: 'MCPToolHierarchyTestBase'.
	self assert: ((entries second at: #source) includesSubstring: '''base-target''')
]

{ #category : 'tests' }
MCPToolGetMethodTest >> testGetMethodAnswersAnInheritedMethodWhereItIsDefined [
	"A class with no method of its own for a selector may still understand it: the method a send would run is answered, named in the class that defines it, on either side."

	| data result |
	result := self callToolWith: { (#selector -> 'MCPToolHierarchyTestChild>>baseHierarchySender') } asDictionary.
	self deny: (self resultIndicatesError: result) description: [ self summaryFrom: result ].
	self
		assert: (self summaryFrom: result)
		equals: 'Got method MCPToolHierarchyTestBase>>baseHierarchySender, which MCPToolHierarchyTestChild inherits.'.
	data := self dataFrom: result.
	self assert: (data at: #inheritedFrom) equals: 'MCPToolHierarchyTestBase'.
	self assert: ((data at: #source) beginsWith: 'baseHierarchySender').
	result := self callToolWith: { (#selector -> 'MCPToolRunTestsInheritingTarget class>>isAbstract') } asDictionary.
	self
		assert: (self summaryFrom: result)
		equals: 'Got method MCPToolRunTestsAbstractTarget class>>isAbstract, which MCPToolRunTestsInheritingTarget class inherits.'.
	self assert: ((self dataFrom: result) at: #inheritedFrom) equals: 'MCPToolRunTestsAbstractTarget class'.
	result := self callToolWith: { (#selector -> 'MCPToolGetMethodTestTarget class>>new') } asDictionary.
	self assert: (self summaryFrom: result) equals: 'Got method Behavior>>new, which MCPToolGetMethodTestTarget class inherits.'.
	self assert: ((self dataFrom: result) at: #inheritedFrom) equals: 'Behavior'
]

{ #category : 'tests' }
MCPToolGetMethodTest >> testGetMethodMissSaysWhereTheClassMethodsAreListed [
	"A selector the class does not have, such as a guess at a wildcard, is refused with the tool that lists the methods it does have."

	| error result |
	result := self callToolWith: {
			          (#class -> 'MCPToolGetMethodTestTarget').
			          (#selector -> '*') } asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #errorCode) equals: 'MethodNotFound'.
	self
		assert: (error at: #message)
		equals:
		'Method MCPToolGetMethodTestTarget>>* does not exist. method_search with scope.classes lists the methods of MCPToolGetMethodTestTarget.'
]

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
MCPToolGetMethodTest >> testGetMethodReadsABareSelectorOnTheClassSideWhenOnlyItUnderstandsIt [
	"A bare selector given no side that neither side has a method of its own for, and only the class side understands, is read there, inherited."

	| result |
	result := self callToolWith: {
			          (#class -> 'MCPToolGetMethodTestTarget').
			          (#selector -> 'new') } asDictionary.
	self deny: (self resultIndicatesError: result) description: [ self summaryFrom: result ].
	self
		assert: (self summaryFrom: result)
		equals:
		'Got method Behavior>>new, which MCPToolGetMethodTestTarget class inherits. It is on the class side, the only side that has it.'
]

{ #category : 'tests' }
MCPToolGetMethodTest >> testGetMethodReadsABareSelectorOnTheOnlySideThatHasIt [
	"A bare selector given no side that only the class side has names one method, so it is read there, with its variables, and the answer says which side it is on."

	| data result |
	result := self callToolWith: {
			          (#class -> 'MCPToolGetMethodTestTarget').
			          (#selector -> 'readClassSide').
			          (#includeVariableDetails -> true) } asDictionary.
	self deny: (self resultIndicatesError: result) description: [ self summaryFrom: result ].
	self
		assert: (self summaryFrom: result)
		equals: 'Got method MCPToolGetMethodTestTarget class>>readClassSide. It is on the class side, the only side that has it.'.
	data := self dataFrom: result.
	self assert: ((data at: #source) beginsWith: 'readClassSide').
	self
		assert: ((self variableNamed: 'classCounter' in: (data at: #variableReferences)) at: #ownerName)
		equals: 'MCPToolGetMethodTestTarget class'
]

{ #category : 'tests' }
MCPToolGetMethodTest >> testGetMethodReadsAnInheritedMethodsVariablesWhereItIsDefined [
	"An inherited method's variables are those of the class that defines it, which is where self is bound when it runs."

	| data result |
	result := self callToolWith: {
			          (#selector -> 'MCPToolHierarchyTestChild>>baseHierarchySender').
			          (#includeVariableDetails -> true) } asDictionary.
	data := self dataFrom: result.
	self assert: ((self variableNamed: 'self' in: (data at: #variableReferences)) at: #ownerName) equals: 'MCPToolHierarchyTestBase'
]

{ #category : 'tests' }
MCPToolGetMethodTest >> testGetMethodReadsTheClassSideOfASelectorTheInstanceSideOnlyInherits [
	"A method of its own comes before one inherited, so a bare selector given no side that the class side has and the instance side only inherits is read on the class side. The answer names the inherited one, in case it was meant."

	| result |
	result := self callToolWith: {
			          (#class -> 'MCPToolRunTestsTimeLimitTarget').
			          (#selector -> 'defaultTimeLimit') } asDictionary.
	self deny: (self resultIndicatesError: result) description: [ self summaryFrom: result ].
	self
		assert: (self summaryFrom: result)
		equals:
		'Got method MCPToolRunTestsTimeLimitTarget class>>defaultTimeLimit. It is on the class side, the only side that has one of its own. The instance side inherits TestCase>>defaultTimeLimit.'.
	self assert: (((self dataFrom: result) at: #source) beginsWith: 'defaultTimeLimit')
]

{ #category : 'tests' }
MCPToolGetMethodTest >> testGetMethodReferenceKeepsItsSide [
	"A reference names its side, so one to the instance side that only the class side has is a miss. The match it names is the next step, so the miss says nothing more."

	| error result |
	result := self callToolWith: { (#selector -> 'MCPToolGetMethodTestTarget>>readClassSide') } asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #errorCode) equals: 'MethodNotFound'.
	self assert: (error at: #side) equals: 'instance'.
	self
		assert: (error at: #message)
		equals:
		'Method MCPToolGetMethodTestTarget>>readClassSide does not exist. Exact matches: MCPToolGetMethodTestTarget class>>readClassSide.'
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
MCPToolGetMethodTest >> testGetMethodStaysOnTheInstanceSideWhenBothSidesHaveTheSelector [
	"A bare selector given no side that the instance side has is read there, with no note, though the class side has one too."

	| result |
	result := self callToolWith: {
			          (#class -> 'MCPToolMethodSearchReferenceFixture').
			          (#selector -> 'sharedTarget') } asDictionary.
	self deny: (self resultIndicatesError: result) description: [ self summaryFrom: result ].
	self assert: (self summaryFrom: result) equals: 'Got method MCPToolMethodSearchReferenceFixture>>sharedTarget.'.
	self assert: (((self dataFrom: result) at: #source) includesSubstring: 'instance-target')
]

{ #category : 'tests' }
MCPToolGetMethodTest >> testGetMethodSuggestsExactOppositeSideSelector [
	"A side the call gives is kept, so a selector only the other side has is a miss that names it."

	| error result suggestions |
	result := self callToolWith: {
			          (#class -> 'MCPToolGetMethodTestTarget').
			          (#selector -> 'readClassSide').
			          (#side -> 'instance') } asDictionary.
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
	self assert: (self summaryFrom: result) equals: 'Got method MCPToolGetMethodTestTarget class>>readClassSide.'.
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

{ #category : 'tests' }
MCPToolGetMethodTest >> testVariableDetailsReadByName [
	"A variable record opens with its name and leaves out the binding class its kind already says; an argument or a temporary, which the method defines itself, names no owner. The data keeps the binding class."

	| argument data lines result |
	result := self callToolWith: {
			          (#class -> 'MCPToolGetMethodTestTarget').
			          (#selector -> 'readInstanceWith:').
			          (#includeVariableDetails -> true) } asDictionary.
	data := self dataFrom: result.
	argument := self variableNamed: 'anArgument' in: (data at: #variableReferences).
	self assert: (argument at: #kind) equals: 'argument'.
	self assert: (argument includesKey: #bindingClass).
	self deny: (argument includesKey: #ownerName).
	self deny: ((self variableNamed: 'local' in: (data at: #variableReferences)) includesKey: #ownerName).
	lines := ((result at: #content) first at: #text) lines.
	self assert: (lines includes: '  anArgument kind=argument referenceCount=2').
	self assert: (lines includes: '  local kind=temporary referenceCount=3').
	self assert: (lines includes: '  instanceCounter kind=instanceVariable ownerName=MCPToolGetMethodTestTarget referenceCount=1').
	self deny: (lines anySatisfy: [ :each | each includesSubstring: 'bindingClass=' ])
]

{ #category : 'private - calling' }
MCPToolGetMethodTest >> toolName [

	^ 'method_get'
]

{ #category : 'private' }
MCPToolGetMethodTest >> variableNamed: aName in: variableReferences [

	^ variableReferences detect: [ :each | (each at: #name) = aName ] ifNone: [ self fail: 'Missing variable summary for ' , aName ]
]
