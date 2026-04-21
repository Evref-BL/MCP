Class {
	#name : 'MCPToolEditMethodTest',
	#superclass : 'TestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'private' }
MCPToolEditMethodTest >> callToolWith: someArguments [

	^ MCP new rpcToolCall: 'pharo-edit-method' withParams: someArguments
]

{ #category : 'private' }
MCPToolEditMethodTest >> classChangeArguments [

	^ {
		  (#operation -> 'changeProtocol').
		  (#className -> 'MCPToolEditMethodTestTarget').
		  (#classSide -> true).
		  (#selector -> self classProtocolSelector asString).
		  (#protocol -> 'instance creation') } asDictionary
]

{ #category : 'private' }
MCPToolEditMethodTest >> classProtocolSelector [

	^ #classProtocolTarget
]

{ #category : 'private' }
MCPToolEditMethodTest >> classRenameArguments [

	^ {
		  (#operation -> 'rename').
		  (#className -> 'MCPToolEditMethodTestTarget').
		  (#classSide -> true).
		  (#selector -> self classSelector asString).
		  (#newSelector -> self renamedClassSelector asString) }
		  asDictionary
]

{ #category : 'private' }
MCPToolEditMethodTest >> classSelector [

	^ ('build' , 'Value:') asSymbol
]

{ #category : 'private' }
MCPToolEditMethodTest >> compileArgumentsForClassName: aClassName classSide: aBoolean methodSource: aMethodSource protocol: aProtocol [

	^ {
		  (#operation -> 'compile').
		  (#className -> aClassName).
		  (#classSide -> aBoolean).
		  (#methodSource -> aMethodSource).
		  (#protocol -> aProtocol) } asDictionary
]

{ #category : 'private' }
MCPToolEditMethodTest >> dataFrom: aResult [

	^ (self structuredContentFrom: aResult) at: #data
]

{ #category : 'private' }
MCPToolEditMethodTest >> ensureMethodSource: aMethodSource protocol: aProtocol on: aBehavior [

	aBehavior compile: aMethodSource classified: aProtocol
]

{ #category : 'private' }
MCPToolEditMethodTest >> errorFrom: aResult [

	^ (self structuredContentFrom: aResult) at: #error
]

{ #category : 'private' }
MCPToolEditMethodTest >> extensionChangeArguments [

	^ {
		  (#operation -> 'changeProtocol').
		  (#className -> 'MCPToolEditMethodTestTarget').
		  (#classSide -> false).
		  (#selector -> self extensionProtocolSelector asString).
		  (#protocol -> 'tests') } asDictionary
]

{ #category : 'private' }
MCPToolEditMethodTest >> extensionProtocolSelector [

	^ #extensionProtocolTarget
]

{ #category : 'private' }
MCPToolEditMethodTest >> instanceChangeArguments [

	^ {
		  (#operation -> 'changeProtocol').
		  (#className -> 'MCPToolEditMethodTestTarget').
		  (#classSide -> false).
		  (#selector -> self instanceProtocolSelector asString).
		  (#protocol -> 'accessing') } asDictionary
]

{ #category : 'private' }
MCPToolEditMethodTest >> instanceProtocolSelector [

	^ #instanceProtocolTarget
]

{ #category : 'private' }
MCPToolEditMethodTest >> instanceRenameArguments [

	^ {
		  (#operation -> 'rename').
		  (#className -> 'MCPToolEditMethodTestTarget').
		  (#classSide -> false).
		  (#selector -> self instanceSelector asString).
		  (#newSelector -> self renamedInstanceSelector asString).
		  (#permutation -> #( 2 1 )) } asDictionary
]

{ #category : 'private' }
MCPToolEditMethodTest >> instanceSelector [

	^ ('combine:' , 'with:') asSymbol
]

{ #category : 'private' }
MCPToolEditMethodTest >> removeSelector: aSelector from: aBehavior [

	(aBehavior includesSelector: aSelector) ifTrue: [
		aBehavior removeSelector: aSelector ]
]

{ #category : 'private' }
MCPToolEditMethodTest >> renamedClassSelector [

	^ ('make' , 'Value:') asSymbol
]

{ #category : 'private' }
MCPToolEditMethodTest >> renamedInstanceSelector [

	^ ('with:' , 'combine:') asSymbol
]

{ #category : 'private' }
MCPToolEditMethodTest >> restoreFixtureMethods [

	self
		removeSelector: #instanceAnswer
		from: MCPToolEditMethodTestTarget.
	self
		removeSelector: #classAnswer
		from: MCPToolEditMethodTestTarget classSide.
	self
		removeSelector: #multilineAnswer
		from: MCPToolEditMethodTestTarget.
	self removeSelector: #uglyAnswer from: MCPToolEditMethodTestTarget.
	self
		removeSelector: self instanceSelector
		from: MCPToolEditMethodTestTarget.
	self
		removeSelector: self renamedInstanceSelector
		from: MCPToolEditMethodTestTarget.
	self
		removeSelector: self classSelector
		from: MCPToolEditMethodTestTarget classSide.
	self
		removeSelector: self renamedClassSelector
		from: MCPToolEditMethodTestTarget classSide.
	self
		removeSelector: self instanceProtocolSelector
		from: MCPToolEditMethodTestTarget.
	self
		removeSelector: self classProtocolSelector
		from: MCPToolEditMethodTestTarget classSide.
	self
		removeSelector: self extensionProtocolSelector
		from: MCPToolEditMethodTestTarget.
	self
		removeSelector: #callInstanceTarget
		from: MCPToolEditMethodTestSender.
	self
		removeSelector: #callClassTarget
		from: MCPToolEditMethodTestSender.
	self
		ensureMethodSource:
		'combine: first with: second ^ first , ''-'' , second'
		protocol: 'tests'
		on: MCPToolEditMethodTestTarget.
	self
		ensureMethodSource: 'buildValue: aString ^ ''Class-'' , aString'
		protocol: 'tests'
		on: MCPToolEditMethodTestTarget classSide.
	self
		ensureMethodSource: 'instanceProtocolTarget ^ 41'
		protocol: 'tests'
		on: MCPToolEditMethodTestTarget.
	self
		ensureMethodSource: 'classProtocolTarget ^ 7'
		protocol: 'tests'
		on: MCPToolEditMethodTestTarget classSide.
	self
		ensureMethodSource: 'extensionProtocolTarget ^ 99'
		protocol: '*MCP-Tests-Extensions'
		on: MCPToolEditMethodTestTarget.
	self
		ensureMethodSource:
		'callInstanceTarget ^ MCPToolEditMethodTestTarget new combine: ''first'' with: ''second'''
		protocol: 'tests'
		on: MCPToolEditMethodTestSender.
	self
		ensureMethodSource:
		'callClassTarget ^ MCPToolEditMethodTestTarget buildValue: ''value'''
		protocol: 'tests'
		on: MCPToolEditMethodTestSender
]

{ #category : 'running' }
MCPToolEditMethodTest >> setUp [

	super setUp.
	self restoreFixtureMethods
]

{ #category : 'private' }
MCPToolEditMethodTest >> structuredContentFrom: aResult [

	^ aResult at: #structuredContent
]

{ #category : 'running' }
MCPToolEditMethodTest >> tearDown [

	self restoreFixtureMethods.
	super tearDown
]

{ #category : 'tests' }
MCPToolEditMethodTest >> testChangeProtocolReturnsStructuredErrorWhenMethodIsMissing [

	| error result structured |
	self
		removeSelector: self instanceProtocolSelector
		from: MCPToolEditMethodTestTarget.
	result := self callToolWith: self instanceChangeArguments.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #operation) equals: 'changeProtocol'.
	self assert: (error at: #errorClass) equals: 'MethodNotFound'.
	self
		assert: (error at: #methodReference)
		equals: 'MCPToolEditMethodTestTarget>>instanceProtocolTarget'
]

{ #category : 'tests' }
MCPToolEditMethodTest >> testChangesClassSideMethodProtocol [

	| data result |
	result := self callToolWith: self classChangeArguments.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self
		assert:
			(MCPToolEditMethodTestTarget classSide
			 >> self classProtocolSelector) protocol name asString
		equals: 'instance creation'.
	self assert: (data at: #operation) equals: 'changeProtocol'.
	self assert: (data at: #classSide).
	self assert: (data at: #oldProtocol) equals: 'tests'.
	self assert: (data at: #protocol) equals: 'instance creation'.
	self
		assert: (data at: #methodReference)
		equals: 'MCPToolEditMethodTestTarget class>>classProtocolTarget'
]

{ #category : 'tests' }
MCPToolEditMethodTest >> testChangesInstanceSideMethodProtocol [

	| data result |
	result := self callToolWith: self instanceChangeArguments.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self
		assert:
			(MCPToolEditMethodTestTarget >> self instanceProtocolSelector)
				protocol name asString
		equals: 'accessing'.
	self assert: (data at: #operation) equals: 'changeProtocol'.
	self
		assert: (data at: #className)
		equals: 'MCPToolEditMethodTestTarget'.
	self assert: (data at: #classSide) equals: false.
	self
		assert: (data at: #selector)
		equals: self instanceProtocolSelector asString.
	self assert: (data at: #oldProtocol) equals: 'tests'.
	self assert: (data at: #protocol) equals: 'accessing'.
	self assert: (data at: #packageName) equals: 'MCP-Tests'.
	self deny: (data at: #isExtension).
	self
		assert: (data at: #methodReference)
		equals: 'MCPToolEditMethodTestTarget>>instanceProtocolTarget'.
	self assert:
		((data at: #source) includesSubstring: 'instanceProtocolTarget')
]

{ #category : 'tests' }
MCPToolEditMethodTest >> testChangingExtensionMethodProtocolUpdatesPackageMetadata [

	| data result |
	result := self callToolWith: self extensionChangeArguments.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self
		assert:
			(MCPToolEditMethodTestTarget >> self extensionProtocolSelector)
				protocol name asString
		equals: 'tests'.
	self assert: (data at: #operation) equals: 'changeProtocol'.
	self assert: (data at: #oldProtocol) equals: '*MCP-Tests-Extensions'.
	self assert: (data at: #protocol) equals: 'tests'.
	self assert: (data at: #packageName) equals: 'MCP-Tests'.
	self deny: (data at: #isExtension)
]

{ #category : 'tests' }
MCPToolEditMethodTest >> testCompilesClassSideMethod [

	| data result |
	result := self callToolWith: (self
			           compileArgumentsForClassName:
			           'MCPToolEditMethodTestTarget'
			           classSide: true
			           methodSource: 'classAnswer ^ 7'
			           protocol: 'tests').
	data := self dataFrom: result.
	self assert: MCPToolEditMethodTestTarget classAnswer equals: 7.
	self
		assert:
		(MCPToolEditMethodTestTarget classSide >> #classAnswer) protocol
			name
		equals: #tests.
	self assert: (data at: #operation) equals: 'compile'.
	self assert: (data at: #classSide).
	self assert: (data at: #selector) equals: 'classAnswer'.
	self
		assert: (data at: #methodReference)
		equals: 'MCPToolEditMethodTestTarget class>>classAnswer'
]

{ #category : 'tests' }
MCPToolEditMethodTest >> testCompilesInstanceSideMethod [

	| data result |
	result := self callToolWith: (self
			           compileArgumentsForClassName:
			           'MCPToolEditMethodTestTarget'
			           classSide: false
			           methodSource: 'instanceAnswer ^ 42'
			           protocol: 'tests').
	data := self dataFrom: result.
	self
		assert: MCPToolEditMethodTestTarget new instanceAnswer
		equals: 42.
	self
		assert:
		(MCPToolEditMethodTestTarget >> #instanceAnswer) protocol name
		equals: #tests.
	self assert: (data at: #operation) equals: 'compile'.
	self
		assert: (data at: #className)
		equals: 'MCPToolEditMethodTestTarget'.
	self assert: (data at: #classSide) equals: false.
	self assert: (data at: #selector) equals: 'instanceAnswer'.
	self assert: (data at: #protocol) equals: 'tests'.
	self assert: (data at: #packageName) equals: 'MCP-Tests'.
	self deny: (data at: #isExtension).
	self
		assert: (data at: #methodReference)
		equals: 'MCPToolEditMethodTestTarget>>instanceAnswer'
]

{ #category : 'tests' }
MCPToolEditMethodTest >> testNormalizesLineEndingsBeforeCompilation [

	| normalizedSource source |
	source := 'multilineAnswer' , String lf , '| value |' , String lf
	          , 'value := 41.' , String lf , '^ value + 1'.
	self callToolWith: (self
			 compileArgumentsForClassName: 'MCPToolEditMethodTestTarget'
			 classSide: false
			 methodSource: source
			 protocol: 'tests').
	normalizedSource := (MCPToolEditMethodTestTarget >> #multilineAnswer)
		                    sourceCode.
	self deny: (normalizedSource includes: Character lf).
	self assert: (normalizedSource includes: Character cr).
	self
		assert: MCPToolEditMethodTestTarget new multilineAnswer
		equals: 42
]

{ #category : 'tests' }
MCPToolEditMethodTest >> testReformatsCompiledMethod [

	| reformattedSource source |
	source := 'uglyAnswer   ^   1+2'.
	self callToolWith: (self
			 compileArgumentsForClassName: 'MCPToolEditMethodTestTarget'
			 classSide: false
			 methodSource: source
			 protocol: 'tests').
	reformattedSource := (MCPToolEditMethodTestTarget >> #uglyAnswer)
		                     sourceCode.
	self assert: (reformattedSource includesSubstring: '1 + 2').
	self assert: MCPToolEditMethodTestTarget new uglyAnswer equals: 3
]

{ #category : 'tests' }
MCPToolEditMethodTest >> testRenameReturnsStructuredErrorWhenMethodIsMissing [

	| error result structured |
	self
		removeSelector: self instanceSelector
		from: MCPToolEditMethodTestTarget.
	result := self callToolWith: self instanceRenameArguments.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #operation) equals: 'rename'.
	self assert: (error at: #errorClass) equals: 'MethodNotFound'.
	self
		assert: (error at: #methodReference)
		equals: 'MCPToolEditMethodTestTarget>>combine:with:'
]

{ #category : 'tests' }
MCPToolEditMethodTest >> testRenameUpdatesSendersAndPermutesArguments [

	| senderSource |
	self callToolWith: self instanceRenameArguments.
	self
		assert: MCPToolEditMethodTestSender new callInstanceTarget
		equals: 'first-second'.
	senderSource := (MCPToolEditMethodTestSender >> #callInstanceTarget)
		                sourceCode.
	self assert:
		(senderSource includesSubstring:
			 'with: ''second'' combine: ''first''')
]

{ #category : 'tests' }
MCPToolEditMethodTest >> testRenamesClassSideMethodWithDefaultPermutation [

	| data result |
	result := self callToolWith: self classRenameArguments.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self deny: (MCPToolEditMethodTestTarget classSide includesSelector:
			 self classSelector).
	self assert:
		(MCPToolEditMethodTestTarget classSide includesSelector:
			 self renamedClassSelector).
	self
		assert: MCPToolEditMethodTestSender new callClassTarget
		equals: 'Class-value'.
	self assert: (data at: #operation) equals: 'rename'.
	self assert: (data at: #classSide).
	self assert: (data at: #permutation) equals: #( 1 ).
	self
		assert: (data at: #methodReference)
		equals: 'MCPToolEditMethodTestTarget class>>makeValue:'
]

{ #category : 'tests' }
MCPToolEditMethodTest >> testRenamesInstanceMethodAndReturnsStructuredData [

	| data result |
	result := self callToolWith: self instanceRenameArguments.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self deny:
		(MCPToolEditMethodTestTarget includesSelector: self instanceSelector).
	self assert: (MCPToolEditMethodTestTarget includesSelector:
			 self renamedInstanceSelector).
	self assert: (data at: #operation) equals: 'rename'.
	self
		assert: (data at: #className)
		equals: 'MCPToolEditMethodTestTarget'.
	self assert: (data at: #classSide) equals: false.
	self
		assert: (data at: #selector)
		equals: self renamedInstanceSelector asString.
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
		equals: 'MCPToolEditMethodTestTarget>>combine:with:'.
	self
		assert: (data at: #methodReference)
		equals: 'MCPToolEditMethodTestTarget>>with:combine:'.
	self assert:
		((data at: #source) includesSubstring: 'with: second combine: first')
]

{ #category : 'tests' }
MCPToolEditMethodTest >> testToolRequiresOperationClassNameAndClassSideInSchema [

	self
		assert: MCPToolEditMethod new inputSchema required asSet
		equals: #( 'operation' 'className' 'classSide' ) asSet
]
