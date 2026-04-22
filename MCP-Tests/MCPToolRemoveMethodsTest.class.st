Class {
	#name : 'MCPToolRemoveMethodsTest',
	#superclass : 'TestCase',
	#category : 'MCP-Tests-Tests',
	#package : 'MCP-Tests',
	#tag : 'Tests'
}

{ #category : 'private' }
MCPToolRemoveMethodsTest >> callToolWith: someArguments [

	^ MCP new
		  rpcToolCall: 'pharo-remove-methods'
		  withParams: someArguments
]

{ #category : 'private' }
MCPToolRemoveMethodsTest >> classBatchArguments [

	^ {
		  (#className -> 'MCPToolRemoveMethodsTestTarget').
		  (#classSide -> true).
		  (#selectors -> self classBatchSelectors) } asDictionary
]

{ #category : 'private' }
MCPToolRemoveMethodsTest >> classBatchSelectors [

	^ {
		  self firstClassBatchSelectorString.
		  self secondClassBatchSelectorString } asArray
]

{ #category : 'private' }
MCPToolRemoveMethodsTest >> dataFrom: aResult [

	^ (self structuredContentFrom: aResult) at: #data
]

{ #category : 'private' }
MCPToolRemoveMethodsTest >> ensureMethodSource: aMethodSource protocol: aProtocol on: aBehavior [

	aBehavior compile: aMethodSource classified: aProtocol
]

{ #category : 'private' }
MCPToolRemoveMethodsTest >> errorFrom: aResult [

	^ (self structuredContentFrom: aResult) at: #error
]

{ #category : 'private' }
MCPToolRemoveMethodsTest >> firstClassBatchMethodSource [

	^ self firstClassBatchSelectorString , ' ^ self '
	  , self secondClassBatchSelectorString , ' + 1'
]

{ #category : 'private' }
MCPToolRemoveMethodsTest >> firstClassBatchSelector [

	^ self firstClassBatchSelectorString asSymbol
]

{ #category : 'private' }
MCPToolRemoveMethodsTest >> firstClassBatchSelectorString [

	^ 'first' , 'Class' , 'Batch' , 'Removal'
]

{ #category : 'private' }
MCPToolRemoveMethodsTest >> firstInstanceBatchMethodSource [

	^ self firstInstanceBatchSelectorString , ' ^ self '
	  , self secondInstanceBatchSelectorString , ' + 1'
]

{ #category : 'private' }
MCPToolRemoveMethodsTest >> firstInstanceBatchSelector [

	^ self firstInstanceBatchSelectorString asSymbol
]

{ #category : 'private' }
MCPToolRemoveMethodsTest >> firstInstanceBatchSelectorString [

	^ 'first' , 'Batch' , 'Removal'
]

{ #category : 'private' }
MCPToolRemoveMethodsTest >> firstTextFrom: aResult [

	^ (aResult at: #content) first at: #text
]

{ #category : 'private' }
MCPToolRemoveMethodsTest >> instanceBatchArguments [

	^ {
		  (#className -> 'MCPToolRemoveMethodsTestTarget').
		  (#classSide -> false).
		  (#selectors -> self instanceBatchSelectors) } asDictionary
]

{ #category : 'private' }
MCPToolRemoveMethodsTest >> instanceBatchSelectors [

	^ {
		  self firstInstanceBatchSelectorString.
		  self secondInstanceBatchSelectorString } asArray
]

{ #category : 'private' }
MCPToolRemoveMethodsTest >> missingSelectorString [

	^ 'definitely' , 'Missing' , 'Selector'
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

	^ 'externally' , 'Referenced' , 'Batch' , 'Removal'
]

{ #category : 'private' }
MCPToolRemoveMethodsTest >> protectedSelectorSymbol [

	^ self protectedSelectorString asSymbol
]

{ #category : 'private' }
MCPToolRemoveMethodsTest >> removeSelector: aSelector from: aBehavior [

	(aBehavior includesSelector: aSelector) ifTrue: [
		aBehavior removeSelector: aSelector ]
]

{ #category : 'private' }
MCPToolRemoveMethodsTest >> restoreFixtureMethods [

	self
		removeSelector: self firstInstanceBatchSelector
		from: MCPToolRemoveMethodsTestTarget.
	self
		removeSelector: self secondInstanceBatchSelector
		from: MCPToolRemoveMethodsTestTarget.
	self
		removeSelector: self protectedSelectorSymbol
		from: MCPToolRemoveMethodsTestTarget.
	self
		removeSelector: self firstClassBatchSelector
		from: MCPToolRemoveMethodsTestTarget classSide.
	self
		removeSelector: self secondClassBatchSelector
		from: MCPToolRemoveMethodsTestTarget classSide.
	self
		ensureMethodSource: self firstInstanceBatchMethodSource
		protocol: 'tests'
		on: MCPToolRemoveMethodsTestTarget.
	self
		ensureMethodSource: self secondInstanceBatchMethodSource
		protocol: 'tests'
		on: MCPToolRemoveMethodsTestTarget.
	self
		ensureMethodSource: self protectedMethodSource
		protocol: 'tests'
		on: MCPToolRemoveMethodsTestTarget.
	self
		ensureMethodSource: self firstClassBatchMethodSource
		protocol: 'tests'
		on: MCPToolRemoveMethodsTestTarget classSide.
	self
		ensureMethodSource: self secondClassBatchMethodSource
		protocol: 'tests'
		on: MCPToolRemoveMethodsTestTarget classSide.
	self
		ensureMethodSource: self senderMethodSource
		protocol: 'tests'
		on: MCPToolRemoveMethodsTestSender
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

	^ 'second' , 'Class' , 'Batch' , 'Removal'
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

	^ 'second' , 'Batch' , 'Removal'
]

{ #category : 'private' }
MCPToolRemoveMethodsTest >> senderMethodSource [

	^ 'sendProtectedRemovalTarget ^ MCPToolRemoveMethodsTestTarget new '
	  , self protectedSelectorString
]

{ #category : 'running' }
MCPToolRemoveMethodsTest >> setUp [

	super setUp.
	self restoreFixtureMethods
]

{ #category : 'private' }
MCPToolRemoveMethodsTest >> structuredContentFrom: aResult [

	^ aResult at: #structuredContent
]

{ #category : 'running' }
MCPToolRemoveMethodsTest >> tearDown [

	self restoreFixtureMethods.
	super tearDown
]

{ #category : 'tests' }
MCPToolRemoveMethodsTest >> testForceRemovesMethodsEvenWhenExternalSendersExistAndWarns [

	| data result text |
	result := self callToolWith: {
			          (#className -> 'MCPToolRemoveMethodsTestTarget').
			          (#classSide -> false).
			          (#selectors -> { self protectedSelector }) } asDictionary.
	data := self dataFrom: result.
	text := self firstTextFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert:
		(text includesSubstring: 'Warning: this bypasses sender checks').
	self deny: (MCPToolRemoveMethodsTestTarget includesSelector:
			 self protectedSelectorSymbol).
	self assert: (MCPToolRemoveMethodsTestSender includesSelector:
			 #sendProtectedRemovalTarget).
	self
		should: [
		MCPToolRemoveMethodsTestSender new sendProtectedRemovalTarget ]
		raise: MessageNotUnderstood.
	self
		assert: (data at: #selectors)
		equals: { self protectedSelector } asArray.
	self
		assert: ((data at: #removedMethods) first at: #selector)
		equals: self protectedSelector.
	self
		assert: (data at: #removedMethods) first keys asSet
		equals: #( selector protocol packageName isExtension source ) asSet
]

{ #category : 'tests' }
MCPToolRemoveMethodsTest >> testRemovesBatchOfClassSideMethods [

	| data result |
	result := self callToolWith: self classBatchArguments.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self deny:
		(MCPToolRemoveMethodsTestTarget classSide includesSelector:
			 self firstClassBatchSelector).
	self deny:
		(MCPToolRemoveMethodsTestTarget classSide includesSelector:
			 self secondClassBatchSelector).
	self assert: (data at: #classSide).
	self assert: (data at: #selectors) equals: self classBatchSelectors
]

{ #category : 'tests' }
MCPToolRemoveMethodsTest >> testRemovesBatchOfInstanceMethods [

	| data removedMethods result |
	result := self callToolWith: self instanceBatchArguments.
	data := self dataFrom: result.
	removedMethods := data at: #removedMethods.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self deny: (MCPToolRemoveMethodsTestTarget includesSelector:
			 self firstInstanceBatchSelector).
	self deny: (MCPToolRemoveMethodsTestTarget includesSelector:
			 self secondInstanceBatchSelector).
	self
		assert: (data at: #className)
		equals: 'MCPToolRemoveMethodsTestTarget'.
	self assert: (data at: #classSide) equals: false.
	self
		assert: (data at: #selectors)
		equals: self instanceBatchSelectors.
	self assert: removedMethods size equals: 2.
	self
		assert: (removedMethods first at: #selector)
		equals: self firstInstanceBatchSelectorString.
	self
		assert: (removedMethods second at: #selector)
		equals: self secondInstanceBatchSelectorString.
	self assert: (removedMethods allSatisfy: [ :each |
			 each keys asSet
			 = #( selector protocol packageName isExtension source ) asSet ])
]

{ #category : 'tests' }
MCPToolRemoveMethodsTest >> testReturnsStructuredErrorWhenAnyMethodIsMissing [

	| error result structured |
	result := self callToolWith: {
			          (#className -> 'MCPToolRemoveMethodsTestTarget').
			          (#classSide -> false).
			          (#selectors -> {
				           self firstInstanceBatchSelectorString.
				           self missingSelectorString }) } asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #errorClass) equals: 'MethodNotFound'.
	self assert: (error at: #selector) equals: self missingSelectorString.
	self assert: (MCPToolRemoveMethodsTestTarget includesSelector:
			 self firstInstanceBatchSelector)
]

{ #category : 'tests' }
MCPToolRemoveMethodsTest >> testToolRequiresSelectorsInSchema [

	self
		assert: MCPToolRemoveMethods new inputSchema required asSet
		equals: #( 'className' 'classSide' 'selectors' ) asSet
]
