Class {
	#name : 'MCPToolChangeMethodProtocolTest',
	#superclass : 'TestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'private' }
MCPToolChangeMethodProtocolTest >> callToolWith: someArguments [

	^ MCP new
		  rpcToolCall: 'pharo-change-method-protocol'
		  withParams: someArguments
]

{ #category : 'private' }
MCPToolChangeMethodProtocolTest >> classChangeArguments [

	^ {
		  (#className -> 'MCPToolChangeMethodProtocolTestTarget').
		  (#classSide -> true).
		  (#selector -> self classSelector asString).
		  (#protocol -> 'instance creation') } asDictionary
]

{ #category : 'private' }
MCPToolChangeMethodProtocolTest >> classSelector [

	^ #classProtocolTarget
]

{ #category : 'private' }
MCPToolChangeMethodProtocolTest >> dataFrom: aResult [

	^ (self structuredContentFrom: aResult) at: #data
]

{ #category : 'private' }
MCPToolChangeMethodProtocolTest >> ensureMethodSource: aMethodSource protocol: aProtocol on: aBehavior [

	aBehavior compile: aMethodSource classified: aProtocol
]

{ #category : 'private' }
MCPToolChangeMethodProtocolTest >> errorFrom: aResult [

	^ (self structuredContentFrom: aResult) at: #error
]

{ #category : 'private' }
MCPToolChangeMethodProtocolTest >> extensionChangeArguments [

	^ {
		  (#className -> 'MCPToolChangeMethodProtocolTestTarget').
		  (#classSide -> false).
		  (#selector -> self extensionSelector asString).
		  (#protocol -> 'tests') } asDictionary
]

{ #category : 'private' }
MCPToolChangeMethodProtocolTest >> extensionSelector [

	^ #extensionProtocolTarget
]

{ #category : 'private' }
MCPToolChangeMethodProtocolTest >> instanceChangeArguments [

	^ {
		  (#className -> 'MCPToolChangeMethodProtocolTestTarget').
		  (#classSide -> false).
		  (#selector -> self instanceSelector asString).
		  (#protocol -> 'accessing') } asDictionary
]

{ #category : 'private' }
MCPToolChangeMethodProtocolTest >> instanceSelector [

	^ #instanceProtocolTarget
]

{ #category : 'private' }
MCPToolChangeMethodProtocolTest >> removeSelector: aSelector from: aBehavior [

	(aBehavior includesSelector: aSelector) ifTrue: [
		aBehavior removeSelector: aSelector ]
]

{ #category : 'private' }
MCPToolChangeMethodProtocolTest >> restoreFixtureMethods [

	self
		removeSelector: self instanceSelector
		from: MCPToolChangeMethodProtocolTestTarget.
	self
		removeSelector: self classSelector
		from: MCPToolChangeMethodProtocolTestTarget classSide.
	self
		removeSelector: self extensionSelector
		from: MCPToolChangeMethodProtocolTestTarget.
	self
		ensureMethodSource: 'instanceProtocolTarget ^ 41'
		protocol: 'tests'
		on: MCPToolChangeMethodProtocolTestTarget.
	self
		ensureMethodSource: 'classProtocolTarget ^ 7'
		protocol: 'tests'
		on: MCPToolChangeMethodProtocolTestTarget classSide.
	self
		ensureMethodSource: 'extensionProtocolTarget ^ 99'
		protocol: '*MCP-Tests-Extensions'
		on: MCPToolChangeMethodProtocolTestTarget
]

{ #category : 'running' }
MCPToolChangeMethodProtocolTest >> setUp [

	super setUp.
	self restoreFixtureMethods
]

{ #category : 'private' }
MCPToolChangeMethodProtocolTest >> structuredContentFrom: aResult [

	^ aResult at: #structuredContent
]

{ #category : 'running' }
MCPToolChangeMethodProtocolTest >> tearDown [

	self restoreFixtureMethods.
	super tearDown
]

{ #category : 'tests' }
MCPToolChangeMethodProtocolTest >> testChangesClassSideMethodProtocol [

	| data result |
	result := self callToolWith: self classChangeArguments.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self
		assert:
			(MCPToolChangeMethodProtocolTestTarget classSide
			 >> self classSelector) protocol name asString
		equals: 'instance creation'.
	self assert: (data at: #classSide).
	self assert: (data at: #oldProtocol) equals: 'tests'.
	self assert: (data at: #protocol) equals: 'instance creation'.
	self
		assert: (data at: #methodReference)
		equals:
		'MCPToolChangeMethodProtocolTestTarget class>>classProtocolTarget'
]

{ #category : 'tests' }
MCPToolChangeMethodProtocolTest >> testChangesInstanceSideMethodProtocol [

	| data result |
	result := self callToolWith: self instanceChangeArguments.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self
		assert:
			(MCPToolChangeMethodProtocolTestTarget >> self instanceSelector)
				protocol name asString
		equals: 'accessing'.
	self
		assert: (data at: #className)
		equals: 'MCPToolChangeMethodProtocolTestTarget'.
	self assert: (data at: #classSide) equals: false.
	self
		assert: (data at: #selector)
		equals: self instanceSelector asString.
	self assert: (data at: #oldProtocol) equals: 'tests'.
	self assert: (data at: #protocol) equals: 'accessing'.
	self assert: (data at: #packageName) equals: 'MCP-Tests'.
	self deny: (data at: #isExtension).
	self
		assert: (data at: #methodReference)
		equals:
		'MCPToolChangeMethodProtocolTestTarget>>instanceProtocolTarget'.
	self assert:
		((data at: #source) includesSubstring: 'instanceProtocolTarget')
]

{ #category : 'tests' }
MCPToolChangeMethodProtocolTest >> testChangingExtensionMethodProtocolUpdatesPackageMetadata [

	| data result |
	result := self callToolWith: self extensionChangeArguments.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self
		assert:
			(MCPToolChangeMethodProtocolTestTarget >> self extensionSelector)
				protocol name asString
		equals: 'tests'.
	self assert: (data at: #oldProtocol) equals: '*MCP-Tests-Extensions'.
	self assert: (data at: #protocol) equals: 'tests'.
	self assert: (data at: #packageName) equals: 'MCP-Tests'.
	self deny: (data at: #isExtension)
]

{ #category : 'tests' }
MCPToolChangeMethodProtocolTest >> testReturnsStructuredErrorWhenMethodIsMissing [

	| error result structured |
	self
		removeSelector: self instanceSelector
		from: MCPToolChangeMethodProtocolTestTarget.
	result := self callToolWith: self instanceChangeArguments.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #errorClass) equals: 'MethodNotFound'.
	self
		assert: (error at: #methodReference)
		equals:
		'MCPToolChangeMethodProtocolTestTarget>>instanceProtocolTarget'
]

{ #category : 'tests' }
MCPToolChangeMethodProtocolTest >> testToolRequiresProtocolInSchema [

	self
		assert: MCPToolChangeMethodProtocol new inputSchema required asSet
		equals: #( 'className' 'classSide' 'selector' 'protocol' ) asSet
]
