Class {
	#name : 'MCPToolStructuredOutputTest',
	#superclass : 'TestCase',
	#category : 'MCP-Tests-Internal',
	#package : 'MCP-Tests',
	#tag : 'Internal'
}

{ #category : 'private' }
MCPToolStructuredOutputTest >> callToolNamed: aToolName withArguments: someArguments [

	^ MCP new rpcToolCall: aToolName withParams: someArguments
]

{ #category : 'private' }
MCPToolStructuredOutputTest >> dataFrom: aResult [

	^ (self structuredContentFrom: aResult) at: #data
]

{ #category : 'private' }
MCPToolStructuredOutputTest >> errorFrom: aResult [

	^ (self structuredContentFrom: aResult) at: #error
]

{ #category : 'private' }
MCPToolStructuredOutputTest >> structuredContentFrom: aResult [

	^ aResult at: #structuredContent
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testAllToolsAdvertiseOutputSchema [

	| tools |
	tools := MCP new rpcToolsList at: #tools.
	self assert:
		(tools allSatisfy: [ :each | each includesKey: #outputSchema ])
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testDescribeClassReturnsStructuredError [

	| error result structured |
	result := self
		          callToolNamed: 'pharo-describe-class'
		          withArguments:
			          { (#className -> 'MCPToolDescribeClassDefinitelyMissing') }
				          asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #errorClass) equals: 'ClassNotFound'.
	self
		assert: (error at: #className)
		equals: 'MCPToolDescribeClassDefinitelyMissing'
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testDescribeClassReturnsStructuredSuccess [

	| data result |
	result := self
		          callToolNamed: 'pharo-describe-class'
		          withArguments:
		          { (#className -> 'MCPToolReadMethodTestTarget') }
			          asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self
		assert: (data at: #className)
		equals: 'MCPToolReadMethodTestTarget'.
	self assert: (data at: #instanceMethodCount) equals: 1.
	self assert: (data at: #classMethodCount) equals: 1.
	self assert: (data at: #superclasses) isEmpty.
	self assert: (data at: #subclasses) isEmpty
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testEvalReturnsStructuredError [

	| result structured error |
	result := self
		          callToolNamed: 'pharo-eval'
		          withArguments: { (#code -> '1 +') } asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #errorClass) equals: 'RBSyntaxErrorNotice'.
	self assert: ((error at: #message) includesSubstring: 'expected')
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testEvalReturnsStructuredSuccess [

	| result data structured |
	result := self
		          callToolNamed: 'pharo-eval'
		          withArguments: { (#code -> '1 + 2') } asDictionary.
	structured := self structuredContentFrom: result.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (structured at: #status) equals: 'ok'.
	self assert: (data at: #resultPrintString) equals: '3'
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testListPackageClassesReturnsStructuredArrayData [

	| result data |
	result := self
		          callToolNamed: 'pharo-list-package-classes'
		          withArguments:
		          { (#packageName -> 'MCP-Tests') } asDictionary.
	data := self dataFrom: result.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (data at: #packageName) equals: 'MCP-Tests'.
	self assert: (data at: #count) equals: (data at: #classNames) size.
	self assert:
		((data at: #classNames) includes: 'MCPToolContractsTest')
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testListPackageClassesReturnsStructuredError [

	| result structured error |
	result := self
		          callToolNamed: 'pharo-list-package-classes'
		          withArguments:
		          { (#packageName -> 'MCP-Definitely-Missing') }
			          asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self
		assert: (error at: #packageName)
		equals: 'MCP-Definitely-Missing'.
	self assert:
		((error at: #message) includesSubstring: 'There is no package named')
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testListPackagesReturnsStructuredArrayData [

	| result data |
	result := self
		          callToolNamed: 'pharo-list-packages'
		          withArguments: Dictionary new.
	data := self dataFrom: result.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (data at: #count) equals: (data at: #packageNames) size.
	self assert: ((data at: #packageNames) includes: 'MCP')
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testRemoveClassReturnsStructuredError [

	| result structured error |
	result := self
		          callToolNamed: 'pharo-remove-classes'
		          withArguments:
			          { (#classNames
			           -> { 'MCPToolRemoveClassDefinitelyMissing' }) }
				          asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #errorClass) equals: 'ClassNotFound'.
	self
		assert: (error at: #className)
		equals: 'MCPToolRemoveClassDefinitelyMissing'
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testRunTestClassReturnsStructuredIssues [

	| data firstIssue result singleResult |
	result := self
		          callToolNamed: 'pharo-run-tests'
		          withArguments: { (#tests
			           ->
			           { { (#className -> 'MCPToolStructuredOutputTestTarget') }
				           asDictionary }) } asDictionary.
	data := self dataFrom: result.
	singleResult := (data at: #results) first.
	firstIssue := (data at: #issues) first.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (data at: #selectionCount) equals: 1.
	self assert: (data at: #runCount) equals: 3.
	self assert: (singleResult at: #runCount) equals: 3.
	self assert: (singleResult at: #failureCount) equals: 1.
	self assert: (singleResult at: #errorCount) equals: 1.
	self assert: ((singleResult at: #failingTestNames) includes:
			 'MCPToolStructuredOutputTestTarget>>#testFails').
	self assert: ((singleResult at: #failingTestNames) includes:
			 'MCPToolStructuredOutputTestTarget>>#testErrors').
	self assert: (firstIssue includesKey: #message)
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testRunTestMethodReturnsStructuredIssues [

	| data methodResult result |
	result := self
		          callToolNamed: 'pharo-run-tests'
		          withArguments: { (#tests -> {
				           { (#className -> 'MCPToolStructuredOutputTestTarget') }
					           asDictionary.
				           {
					           (#className -> 'MCPToolStructuredOutputTestTarget').
					           (#testMethodName -> 'testFails') } asDictionary }) }
				          asDictionary.
	data := self dataFrom: result.
	methodResult := (data at: #results) detect: [ :each |
		                (each at: #testMethodName ifAbsent: [ nil ])
		                = 'testFails' ].
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (data at: #selectionCount) equals: 2.
	self assert: (data at: #runCount) equals: 4.
	self assert: (data at: #failureCount) equals: 2.
	self assert: (data at: #errorCount) equals: 1.
	self assert: (data at: #issues) size equals: 3.
	self assert: (methodResult at: #runCount) equals: 1.
	self assert: (methodResult at: #testMethodName) equals: 'testFails'.
	self assert: (methodResult at: #failureCount) equals: 1.
	self assert: (methodResult at: #errorCount) equals: 0.
	self
		assert: ((methodResult at: #issues) first at: #testName)
		equals: 'MCPToolStructuredOutputTestTarget>>#testFails'
]
