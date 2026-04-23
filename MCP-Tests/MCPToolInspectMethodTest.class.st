Class {
	#name : 'MCPToolInspectMethodTest',
	#superclass : 'MCPToolTestCase',
	#category : 'MCP-Tests-Tools',
	#package : 'MCP-Tests',
	#tag : 'Tools'
}

{ #category : 'tests' }
MCPToolInspectMethodTest >> testInspectMethodReturnsInstanceSideVariableContext [

	| classVariable data globalVariable instanceVariable result selfVariable |
	result := self callToolWith: {
			          (#className -> 'MCPToolInspectMethodTestTarget').
			          (#selector -> 'readInstanceWith:').
			          (#includeVariableDetails -> true) } asDictionary.
	data := self dataFrom: result.
	instanceVariable := self
		                    variableNamed: 'instanceCounter'
		                    in: (data at: #variableReferences).
	classVariable := self
		                 variableNamed: 'SharedLimit'
		                 in: (data at: #variableReferences).
	globalVariable := self
		                  variableNamed: 'OrderedCollection'
		                  in: (data at: #variableReferences).
	selfVariable := self
		                variableNamed: 'self'
		                in: (data at: #variableReferences).
	self deny: (result at: #isError ifAbsent: [ false ]).
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (data at: #protocol) equals: 'reading'.
	self assert: (instanceVariable at: #kind) equals: 'instanceVariable'.
	self
		assert: (instanceVariable at: #ownerName)
		equals: 'MCPToolInspectMethodTestTarget'.
	self assert: (classVariable at: #kind) equals: 'classVariable'.
	self assert: (globalVariable at: #kind) equals: 'class'.
	self
		assert: (globalVariable at: #ownerName)
		equals: 'Smalltalk globals'.
	self assert: (selfVariable at: #kind) equals: 'self'.
	self assert: (data at: #variableReferences) size equals: 7.
	self assert: ((data at: #variableReferences) allSatisfy: [ :each |
			 #( #sourceIntervals #external #declaredInMethod ) noneSatisfy: [
				 :key | each includesKey: key ] ]).
	self assert:
		((data at: #source) includesSubstring: String cr asString).
	self assert: ((data at: #source) includesSubstring:
			 'instanceCounter ifNil: [ SharedLimit ]').
	self deny: (data includesKey: #className).
	self deny: (data includesKey: #selector).
	self deny: (data includesKey: #side).
	self deny: (data includesKey: #argumentNames).
	self deny: (data includesKey: #temporaryNames).
	self deny: (data includesKey: #variableDetailsIncluded).
	self deny: (data includesKey: #variableReferenceCount).
	self deny: (data includesKey: #externalVariableCount).
	self deny: (data includesKey: #externalVariableReferences)
]

{ #category : 'tests' }
MCPToolInspectMethodTest >> testInspectMethodReturnsStructuredErrorForMissingSelector [

	| error result structured |
	result := self callToolWith: {
			          (#className -> 'MCPToolInspectMethodTestTarget').
			          (#selector -> 'doesNotExist') } asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'. self assert: (error at: #errorCode) equals: 'MethodNotFound'.
	self
		assert: (error at: #className)
		equals: 'MCPToolInspectMethodTestTarget'.
	self assert: (error at: #selector) equals: 'doesNotExist'.
	self assert: (error at: #side) equals: 'instance'.
	self assert: ((error at: #message) includesSubstring:
			 'Method MCPToolInspectMethodTestTarget>>doesNotExist does not exist.')
]

{ #category : 'tests' }
MCPToolInspectMethodTest >> testInspectMethodSupportsClassSideContext [

	| classInstanceVariable data result thisContextVariable |
	result := self callToolWith: {
			          (#className -> 'MCPToolInspectMethodTestTarget').
			          (#selector -> 'readClassSide').
			          (#side -> 'class').
			          (#includeVariableDetails -> true) } asDictionary.
	data := self dataFrom: result.
	classInstanceVariable := self
		                         variableNamed: 'classCounter'
		                         in: (data at: #variableReferences).
	thisContextVariable := self
		                       variableNamed: 'thisContext'
		                       in: (data at: #variableReferences).
	self deny: (result at: #isError ifAbsent: [ false ]).
	self
		assert: (classInstanceVariable at: #kind)
		equals: 'classInstanceVariable'.
	self
		assert: (classInstanceVariable at: #ownerName)
		equals: 'MCPToolInspectMethodTestTarget class'.
	self assert: (thisContextVariable at: #kind) equals: 'thisContext'.
	self
		assert: (thisContextVariable at: #ownerName)
		equals: 'execution context'.
	self assert: ((data at: #variableReferences) allSatisfy: [ :each |
			 #( #sourceIntervals #external #declaredInMethod ) noneSatisfy: [
				 :key | each includesKey: key ] ]).
	self assert:
		((data at: #source) includesSubstring: String cr asString).
	self
		assert: data keys asSet
		equals: #( protocol source variableReferences ) asSet
]

{ #category : 'tests' }
MCPToolInspectMethodTest >> testToolRequiresClassNameAndSelectorInSchema [

	self
		assert: MCPToolInspectMethod new inputSchema required asSet
		equals: #( 'className' 'selector' ) asSet
]

{ #category : 'private - calling' }
MCPToolInspectMethodTest >> toolName [

	^ 'inspect-method'
]

{ #category : 'private' }
MCPToolInspectMethodTest >> variableNamed: aName in: variableReferences [

	^ variableReferences
		  detect: [ :each | (each at: #name) = aName ]
		  ifNone: [ self fail: 'Missing variable summary for ' , aName ]
]
