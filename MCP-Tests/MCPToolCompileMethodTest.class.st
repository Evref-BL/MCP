Class {
	#name : 'MCPToolCompileMethodTest',
	#superclass : 'TestCase',
	#instVars : [
		'tool'
	],
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'private' }
MCPToolCompileMethodTest >> argumentsForClassName: aClassName classSide: aBoolean methodSource: aMethodSource protocol: aProtocol [

	^ {
		  (#className -> aClassName).
		  (#classSide -> aBoolean).
		  (#methodSource -> aMethodSource).
		  (#protocol -> aProtocol) } asDictionary
]

{ #category : 'private' }
MCPToolCompileMethodTest >> removeSelector: aSelector from: aBehavior [

	(aBehavior includesSelector: aSelector) ifTrue: [
		aBehavior removeSelector: aSelector ]
]

{ #category : 'running' }
MCPToolCompileMethodTest >> setUp [

	super setUp.
	tool := MCPToolCompileMethod new.
	self
		removeSelector: #instanceAnswer
		from: MCPToolCompileMethodTestTarget.
	self
		removeSelector: #classAnswer
		from: MCPToolCompileMethodTestTarget classSide.
	self
		removeSelector: #multilineAnswer
		from: MCPToolCompileMethodTestTarget.
	self removeSelector: #uglyAnswer from: MCPToolCompileMethodTestTarget
]

{ #category : 'running' }
MCPToolCompileMethodTest >> tearDown [

	self
		removeSelector: #instanceAnswer
		from: MCPToolCompileMethodTestTarget.
	self
		removeSelector: #classAnswer
		from: MCPToolCompileMethodTestTarget classSide.
	self
		removeSelector: #multilineAnswer
		from: MCPToolCompileMethodTestTarget.
	self removeSelector: #uglyAnswer from: MCPToolCompileMethodTestTarget.
	super tearDown
]

{ #category : 'tests' }
MCPToolCompileMethodTest >> testCompilesClassSideMethod [

	| result |
	result := tool executeWithArguments: (self
			           argumentsForClassName: 'MCPToolCompileMethodTestTarget'
			           classSide: true
			           methodSource: 'classAnswer ^ 7'
			           protocol: 'tests').
	self assert: MCPToolCompileMethodTestTarget classAnswer equals: 7.
	self
		assert:
			(MCPToolCompileMethodTestTarget classSide >> #classAnswer) protocol
				name
		equals: #tests.
	self assert: (result first text includesSubstring:
			 'MCPToolCompileMethodTestTarget class>>classAnswer')
]

{ #category : 'tests' }
MCPToolCompileMethodTest >> testCompilesInstanceSideMethod [

	| result |
	result := tool executeWithArguments: (self
			           argumentsForClassName: 'MCPToolCompileMethodTestTarget'
			           classSide: false
			           methodSource: 'instanceAnswer ^ 42'
			           protocol: 'tests').
	self
		assert: MCPToolCompileMethodTestTarget new instanceAnswer
		equals: 42.
	self
		assert:
		(MCPToolCompileMethodTestTarget >> #instanceAnswer) protocol name
		equals: #tests.
	self assert: (result first text includesSubstring:
			 'MCPToolCompileMethodTestTarget>>instanceAnswer')
]

{ #category : 'tests' }
MCPToolCompileMethodTest >> testNormalizesLineEndingsBeforeCompilation [

	| source normalizedSource |
	source := 'multilineAnswer' , String lf , '| value |' , String lf
	          , 'value := 41.' , String lf , '^ value + 1'.
	tool executeWithArguments: (self
			 argumentsForClassName: 'MCPToolCompileMethodTestTarget'
			 classSide: false
			 methodSource: source
			 protocol: 'tests').
	normalizedSource := (MCPToolCompileMethodTestTarget
	                     >> #multilineAnswer) sourceCode.
	self deny: (normalizedSource includes: Character lf).
	self assert: (normalizedSource includes: Character cr).
	self
		assert: MCPToolCompileMethodTestTarget new multilineAnswer
		equals: 42
]

{ #category : 'tests' }
MCPToolCompileMethodTest >> testReformatsCompiledMethod [

	| source reformattedSource |
	source := 'uglyAnswer   ^   1+2'.
	tool executeWithArguments: (self
			 argumentsForClassName: 'MCPToolCompileMethodTestTarget'
			 classSide: false
			 methodSource: source
			 protocol: 'tests').
	reformattedSource := (MCPToolCompileMethodTestTarget >> #uglyAnswer)
		                     sourceCode.
	self assert: (reformattedSource includesSubstring: '1 + 2').
	self assert: MCPToolCompileMethodTestTarget new uglyAnswer equals: 3
]
