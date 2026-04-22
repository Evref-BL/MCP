Class {
	#name : 'MCPToolDescribeMethodTest',
	#superclass : 'TestCase',
	#category : 'MCP-Tests-Tests',
	#package : 'MCP-Tests',
	#tag : 'Tests'
}

{ #category : 'private' }
MCPToolDescribeMethodTest >> callToolWith: someArguments [

	^ MCP new
		  rpcToolCall: 'describe-method'
		  withParams: someArguments
]

{ #category : 'private' }
MCPToolDescribeMethodTest >> dataFrom: aResult [

	^ (self structuredContentFrom: aResult) at: #data
]

{ #category : 'private' }
MCPToolDescribeMethodTest >> errorFrom: aResult [

	^ (self structuredContentFrom: aResult) at: #error
]

{ #category : 'private' }
MCPToolDescribeMethodTest >> structuredContentFrom: aResult [

	^ aResult at: #structuredContent
]

{ #category : 'tests' }
MCPToolDescribeMethodTest >> testDescribeMethodReturnsInstanceSideVariableContext [

	| classVariable data globalVariable instanceVariable result selfVariable |
	result := self callToolWith: {
			          (#className -> 'MCPToolDescribeMethodTestTarget').
			          (#selector -> 'readInstanceWith:') } asDictionary.
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
	self assert: (data at: #side) equals: 'instance'.
	self assert: (data at: #protocol) equals: 'reading'.
	self assert: (data at: #argumentNames) equals: #( 'anArgument' ).
	self assert: (data at: #temporaryNames) equals: #( 'local' ).
	self assert: (instanceVariable at: #kind) equals: 'instanceVariable'.
	self
		assert: (instanceVariable at: #ownerName)
		equals: 'MCPToolDescribeMethodTestTarget'.
	self assert: (classVariable at: #kind) equals: 'classVariable'.
	self assert: (globalVariable at: #kind) equals: 'class'.
	self
		assert: (globalVariable at: #ownerName)
		equals: 'Smalltalk globals'.
	self assert: (selfVariable at: #kind) equals: 'self'.
	self assert: (data at: #externalVariableCount) equals: 4.
	self deny:
		((data at: #externalVariableReferences) anySatisfy: [ :each |
			 (each at: #name) = 'self' ]).
	self assert: ((data at: #variableReferences) allSatisfy: [ :each |
			 #( #sourceIntervals #external #declaredInMethod ) noneSatisfy: [
				 :key | each includesKey: key ] ]).
	self deny: ((data at: #source) includesSubstring: String cr asString).
	self deny:
		((data at: #source) includesSubstring: String tab asString).
	self assert: ((data at: #source) includesSubstring:
			 'instanceCounter ifNil: [ SharedLimit ]')
]

{ #category : 'tests' }
MCPToolDescribeMethodTest >> testDescribeMethodReturnsStructuredErrorForMissingSelector [

	| error result structured |
	result := self callToolWith: {
			          (#className -> 'MCPToolDescribeMethodTestTarget').
			          (#selector -> 'doesNotExist') } asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'. self assert: (error at: #errorCode) equals: 'MethodNotFound'.
	self
		assert: (error at: #className)
		equals: 'MCPToolDescribeMethodTestTarget'.
	self assert: (error at: #selector) equals: 'doesNotExist'.
	self assert: (error at: #side) equals: 'instance'.
	self assert: ((error at: #message) includesSubstring:
			 'Method MCPToolDescribeMethodTestTarget>>doesNotExist does not exist.')
]

{ #category : 'tests' }
MCPToolDescribeMethodTest >> testDescribeMethodSupportsClassSideContext [

	| classInstanceVariable data result thisContextVariable |
	result := self callToolWith: {
			          (#className -> 'MCPToolDescribeMethodTestTarget').
			          (#selector -> 'readClassSide').
			          (#side -> 'class') } asDictionary.
	data := self dataFrom: result.
	classInstanceVariable := self
		                         variableNamed: 'classCounter'
		                         in: (data at: #externalVariableReferences).
	thisContextVariable := self
		                       variableNamed: 'thisContext'
		                       in: (data at: #externalVariableReferences).
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #side) equals: 'class'.
	self
		assert: (classInstanceVariable at: #kind)
		equals: 'classInstanceVariable'.
	self
		assert: (classInstanceVariable at: #ownerName)
		equals: 'MCPToolDescribeMethodTestTarget class'.
	self assert: (thisContextVariable at: #kind) equals: 'thisContext'.
	self
		assert: (thisContextVariable at: #ownerName)
		equals: 'execution context'.
	self assert: ((data at: #variableReferences) allSatisfy: [ :each |
			 #( #sourceIntervals #external #declaredInMethod ) noneSatisfy: [
				 :key | each includesKey: key ] ]).
	self deny: ((data at: #source) includesSubstring: String cr asString).
	self deny:
		((data at: #source) includesSubstring: String tab asString).
	self
		assert: data keys asSet
		equals:
			#( className selector side protocol source argumentNames
			   temporaryNames variableReferenceCount externalVariableCount
			   variableReferences externalVariableReferences ) asSet
]

{ #category : 'tests' }
MCPToolDescribeMethodTest >> testToolRequiresClassNameAndSelectorInSchema [

	self
		assert: MCPToolDescribeMethod new inputSchema required asSet
		equals: #( 'className' 'selector' ) asSet
]

{ #category : 'private' }
MCPToolDescribeMethodTest >> variableNamed: aName in: variableReferences [

	^ variableReferences
		  detect: [ :each | (each at: #name) = aName ]
		  ifNone: [ self fail: 'Missing variable summary for ' , aName ]
]
