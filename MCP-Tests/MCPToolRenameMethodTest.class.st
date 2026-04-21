Class {
	#name : 'MCPToolRenameMethodTest',
	#superclass : 'TestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'private' }
MCPToolRenameMethodTest >> callToolWith: someArguments [

	^ MCP new
		  rpcToolCall: 'pharo-rename-method'
		  withParams: someArguments
]

{ #category : 'private' }
MCPToolRenameMethodTest >> classRenameArguments [

	^ {
		  (#className -> 'MCPToolRenameMethodTestTarget').
		  (#classSide -> true).
		  (#selector -> self classSelector asString).
		  (#newSelector -> self renamedClassSelector asString) }
		  asDictionary
]

{ #category : 'private' }
MCPToolRenameMethodTest >> classSelector [

	^ ('build' , 'Value:') asSymbol
]

{ #category : 'private' }
MCPToolRenameMethodTest >> dataFrom: aResult [

	^ (self structuredContentFrom: aResult) at: #data
]

{ #category : 'private' }
MCPToolRenameMethodTest >> ensureMethodSource: aMethodSource protocol: aProtocol on: aBehavior [

	aBehavior compile: aMethodSource classified: aProtocol
]

{ #category : 'private' }
MCPToolRenameMethodTest >> errorFrom: aResult [

	^ (self structuredContentFrom: aResult) at: #error
]

{ #category : 'private' }
MCPToolRenameMethodTest >> instanceRenameArguments [

	^ {
		  (#className -> 'MCPToolRenameMethodTestTarget').
		  (#classSide -> false).
		  (#selector -> self instanceSelector asString).
		  (#newSelector -> self renamedInstanceSelector asString).
		  (#permutation -> #( 2 1 )) } asDictionary
]

{ #category : 'private' }
MCPToolRenameMethodTest >> instanceSelector [

	^ ('combine:' , 'with:') asSymbol
]

{ #category : 'private' }
MCPToolRenameMethodTest >> removeSelector: aSelector from: aBehavior [

	(aBehavior includesSelector: aSelector) ifTrue: [
		aBehavior removeSelector: aSelector ]
]

{ #category : 'private' }
MCPToolRenameMethodTest >> renamedClassSelector [

	^ ('make' , 'Value:') asSymbol
]

{ #category : 'private' }
MCPToolRenameMethodTest >> renamedInstanceSelector [

	^ ('with:' , 'combine:') asSymbol
]

{ #category : 'private' }
MCPToolRenameMethodTest >> restoreFixtureMethods [

	self
		removeSelector: self instanceSelector
		from: MCPToolRenameMethodTestTarget.
	self
		removeSelector: self renamedInstanceSelector
		from: MCPToolRenameMethodTestTarget.
	self
		removeSelector: self classSelector
		from: MCPToolRenameMethodTestTarget classSide.
	self
		removeSelector: self renamedClassSelector
		from: MCPToolRenameMethodTestTarget classSide.
	self
		ensureMethodSource:
		'combine: first with: second ^ first , ''-'' , second'
		protocol: 'tests'
		on: MCPToolRenameMethodTestTarget.
	self
		ensureMethodSource: 'buildValue: aString ^ ''Class-'' , aString'
		protocol: 'tests'
		on: MCPToolRenameMethodTestTarget classSide.
	self
		ensureMethodSource:
		'callInstanceTarget ^ MCPToolRenameMethodTestTarget new combine: ''first'' with: ''second'''
		protocol: 'tests'
		on: MCPToolRenameMethodTestSender.
	self
		ensureMethodSource:
		'callClassTarget ^ MCPToolRenameMethodTestTarget buildValue: ''value'''
		protocol: 'tests'
		on: MCPToolRenameMethodTestSender
]

{ #category : 'running' }
MCPToolRenameMethodTest >> setUp [

	super setUp.
	self restoreFixtureMethods
]

{ #category : 'private' }
MCPToolRenameMethodTest >> structuredContentFrom: aResult [

	^ aResult at: #structuredContent
]

{ #category : 'running' }
MCPToolRenameMethodTest >> tearDown [

	self restoreFixtureMethods.
	super tearDown
]

{ #category : 'tests' }
MCPToolRenameMethodTest >> testRenameUpdatesSendersAndPermutesArguments [

	| senderSource |
	self callToolWith: self instanceRenameArguments.
	self
		assert: MCPToolRenameMethodTestSender new callInstanceTarget
		equals: 'first-second'.
	senderSource := (MCPToolRenameMethodTestSender >> #callInstanceTarget)
		                sourceCode.
	self assert:
		(senderSource includesSubstring:
			 'with: ''second'' combine: ''first''')
]

{ #category : 'tests' }
MCPToolRenameMethodTest >> testRenamesClassSideMethodWithDefaultPermutation [

	| data result |
	result := self callToolWith: self classRenameArguments.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self deny:
		(MCPToolRenameMethodTestTarget classSide includesSelector:
			 self classSelector).
	self assert:
		(MCPToolRenameMethodTestTarget classSide includesSelector:
			 self renamedClassSelector).
	self
		assert: MCPToolRenameMethodTestSender new callClassTarget
		equals: 'Class-value'.
	self assert: (data at: #classSide).
	self assert: (data at: #permutation) equals: #( 1 ).
	self
		assert: (data at: #methodReference)
		equals: 'MCPToolRenameMethodTestTarget class>>makeValue:'
]

{ #category : 'tests' }
MCPToolRenameMethodTest >> testRenamesInstanceMethodAndReturnsStructuredData [

	| data result |
	result := self callToolWith: self instanceRenameArguments.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self deny:
		(MCPToolRenameMethodTestTarget includesSelector:
			 self instanceSelector).
	self assert: (MCPToolRenameMethodTestTarget includesSelector:
			 self renamedInstanceSelector).
	self
		assert: (data at: #className)
		equals: 'MCPToolRenameMethodTestTarget'.
	self assert: (data at: #classSide) equals: false.
	self
		assert: (data at: #oldSelector)
		equals: self instanceSelector asString.
	self
		assert: (data at: #newSelector)
		equals: self renamedInstanceSelector asString.
	self assert: (data at: #permutation) equals: #( 2 1 ).
	self assert: (data at: #protocol) equals: 'tests'.
	self assert: (data at: #packageName) equals: 'MCP-Tests'.
	self deny: (data at: #isExtension).
	self
		assert: (data at: #oldMethodReference)
		equals: 'MCPToolRenameMethodTestTarget>>combine:with:'.
	self
		assert: (data at: #methodReference)
		equals: 'MCPToolRenameMethodTestTarget>>with:combine:'.
	self assert:
		((data at: #source) includesSubstring: 'with: second combine: first')
]

{ #category : 'tests' }
MCPToolRenameMethodTest >> testReturnsStructuredErrorWhenMethodIsMissing [

	| error result structured |
	self
		removeSelector: self instanceSelector
		from: MCPToolRenameMethodTestTarget.
	result := self callToolWith: self instanceRenameArguments.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #errorClass) equals: 'MethodNotFound'.
	self
		assert: (error at: #methodReference)
		equals: 'MCPToolRenameMethodTestTarget>>combine:with:'
]

{ #category : 'tests' }
MCPToolRenameMethodTest >> testToolRequiresSelectorAndNewSelectorInSchema [

	self
		assert: MCPToolRenameMethod new inputSchema required asSet
		equals: #( 'className' 'classSide' 'selector' 'newSelector' ) asSet
]
