Class {
	#name : 'MCPToolRemoveMethodTest',
	#superclass : 'TestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'private' }
MCPToolRemoveMethodTest >> callToolWith: someArguments [

	^ MCP new
		  rpcToolCall: 'pharo-remove-method'
		  withParams: someArguments
]

{ #category : 'private' }
MCPToolRemoveMethodTest >> dataFrom: aResult [

	^ (self structuredContentFrom: aResult) at: #data
]

{ #category : 'private' }
MCPToolRemoveMethodTest >> ensureMethodSource: aMethodSource protocol: aProtocol on: aBehavior [

	aBehavior compile: aMethodSource classified: aProtocol
]

{ #category : 'private' }
MCPToolRemoveMethodTest >> errorFrom: aResult [

	^ (self structuredContentFrom: aResult) at: #error
]

{ #category : 'private' }
MCPToolRemoveMethodTest >> removeSelector: aSelector from: aBehavior [

	(aBehavior includesSelector: aSelector) ifTrue: [
		aBehavior removeSelector: aSelector ]
]

{ #category : 'running' }
MCPToolRemoveMethodTest >> setUp [

	super setUp.
	self
		removeSelector: #instanceToRemove
		from: MCPToolRemoveMethodTestTarget.
	self
		removeSelector: #classToRemove
		from: MCPToolRemoveMethodTestTarget classSide.
	self
		removeSelector: #extensionToRemove
		from: MCPToolRemoveMethodTestTarget.
	self
		ensureMethodSource: 'instanceToRemove ^ 41'
		protocol: 'tests'
		on: MCPToolRemoveMethodTestTarget.
	self
		ensureMethodSource: 'classToRemove ^ 7'
		protocol: 'tests'
		on: MCPToolRemoveMethodTestTarget classSide.
	self
		ensureMethodSource: 'extensionToRemove ^ 99'
		protocol: '*MCP-Tests-Extensions'
		on: MCPToolRemoveMethodTestTarget
]

{ #category : 'private' }
MCPToolRemoveMethodTest >> structuredContentFrom: aResult [

	^ aResult at: #structuredContent
]

{ #category : 'running' }
MCPToolRemoveMethodTest >> tearDown [

	self
		removeSelector: #instanceToRemove
		from: MCPToolRemoveMethodTestTarget.
	self
		removeSelector: #classToRemove
		from: MCPToolRemoveMethodTestTarget classSide.
	self
		removeSelector: #extensionToRemove
		from: MCPToolRemoveMethodTestTarget.
	super tearDown
]

{ #category : 'tests' }
MCPToolRemoveMethodTest >> testRemovesClassSideMethod [

	| data result |
	result := self callToolWith: {
			          (#className -> 'MCPToolRemoveMethodTestTarget').
			          (#classSide -> true).
			          (#selector -> 'classToRemove') } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self deny:
		(MCPToolRemoveMethodTestTarget classSide includesSelector:
			 #classToRemove).
	self assert: (data at: #classSide).
	self
		assert: (data at: #methodReference)
		equals: 'MCPToolRemoveMethodTestTarget class>>classToRemove'
]

{ #category : 'tests' }
MCPToolRemoveMethodTest >> testRemovesExtensionMethod [

	| data result |
	result := self callToolWith: {
			          (#className -> 'MCPToolRemoveMethodTestTarget').
			          (#classSide -> false).
			          (#selector -> 'extensionToRemove') } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self deny:
		(MCPToolRemoveMethodTestTarget includesSelector: #extensionToRemove).
	self assert: (data at: #packageName) equals: 'MCP-Tests-Extensions'.
	self assert: (data at: #isExtension).
	self assert: (data at: #protocol) equals: '*MCP-Tests-Extensions'
]

{ #category : 'tests' }
MCPToolRemoveMethodTest >> testRemovesInstanceSideMethod [

	| data result |
	result := self callToolWith: {
			          (#className -> 'MCPToolRemoveMethodTestTarget').
			          (#classSide -> false).
			          (#selector -> 'instanceToRemove') } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self deny:
		(MCPToolRemoveMethodTestTarget includesSelector: #instanceToRemove).
	self
		assert: (data at: #className)
		equals: 'MCPToolRemoveMethodTestTarget'.
	self assert: (data at: #classSide) equals: false.
	self assert: (data at: #selector) equals: 'instanceToRemove'.
	self assert: (data at: #protocol) equals: 'tests'.
	self assert: (data at: #packageName) equals: 'MCP-Tests'.
	self deny: (data at: #isExtension).
	self
		assert: (data at: #methodReference)
		equals: 'MCPToolRemoveMethodTestTarget>>instanceToRemove'.
	self assert:
		((data at: #source) includesSubstring: 'instanceToRemove')
]

{ #category : 'tests' }
MCPToolRemoveMethodTest >> testReturnsStructuredErrorWhenMethodIsMissing [

	| error result structured |
	self
		removeSelector: #instanceToRemove
		from: MCPToolRemoveMethodTestTarget.
	result := self callToolWith: {
			          (#className -> 'MCPToolRemoveMethodTestTarget').
			          (#classSide -> false).
			          (#selector -> 'instanceToRemove') } asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #errorClass) equals: 'MethodNotFound'.
	self
		assert: (error at: #methodReference)
		equals: 'MCPToolRemoveMethodTestTarget>>instanceToRemove'
]

{ #category : 'tests' }
MCPToolRemoveMethodTest >> testToolRequiresSelectorInSchema [

	self
		assert: MCPToolRemoveMethod new inputSchema required asSet
		equals: #( 'className' 'classSide' 'selector' ) asSet
]
