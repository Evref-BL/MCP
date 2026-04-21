Class {
	#name : 'MCPToolStructuredOutputTest',
	#superclass : 'TestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
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
		          callToolNamed: 'pharo-remove-class'
		          withArguments:
		          { (#className -> 'MCPToolRemoveClassDefinitelyMissing') }
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

	| data firstIssue result |
	result := self
		          callToolNamed: 'pharo-run-test-class'
		          withArguments:
		          { (#className -> 'MCPToolStructuredOutputTestTarget') }
			          asDictionary.
	data := self dataFrom: result.
	firstIssue := (data at: #issues) first.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (data at: #runCount) equals: 3.
	self assert: (data at: #failureCount) equals: 1.
	self assert: (data at: #errorCount) equals: 1.
	self assert: ((data at: #failingTestNames) includes:
			 'MCPToolStructuredOutputTestTarget>>#testFails').
	self assert: ((data at: #failingTestNames) includes:
			 'MCPToolStructuredOutputTestTarget>>#testErrors').
	self assert: (firstIssue includesKey: #message)
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testRunTestMethodReturnsStructuredIssues [

	| data issue result |
	result := self
		          callToolNamed: 'pharo-run-test-method'
		          withArguments: {
				          (#className -> 'MCPToolStructuredOutputTestTarget').
				          (#testMethodName -> 'testFails') } asDictionary.
	data := self dataFrom: result.
	issue := (data at: #issues) first.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (data at: #runCount) equals: 1.
	self assert: (data at: #testMethodName) equals: 'testFails'.
	self assert: (data at: #failureCount) equals: 1.
	self assert: (data at: #errorCount) equals: 0.
	self
		assert: (issue at: #testName)
		equals: 'MCPToolStructuredOutputTestTarget>>#testFails'
]
