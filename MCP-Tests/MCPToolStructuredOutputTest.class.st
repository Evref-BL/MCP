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

{ #category : 'private' }
MCPToolStructuredOutputTest >> summaryFrom: aResult [

	^ (self structuredContentFrom: aResult) at: #summary
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
		          callToolNamed: 'describe-class'
		          withArguments:
			          { (#className -> 'MCPToolDescribeClassDefinitelyMissing') }
				          asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self
		assert: (self summaryFrom: result)
		equals: ((result at: #content) first at: #text).
	self assert: (self warningsFrom: result) equals: #(  ).
	self assert: (error at: #errorClass) equals: 'MCPCommandError'. self assert: (error at: #errorCode) equals: 'ClassNotFound'.
	self
		assert: (error at: #className)
		equals: 'MCPToolDescribeClassDefinitelyMissing'
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testDescribeClassReturnsStructuredSuccess [

	| data result structured |
	result := self
		          callToolNamed: 'describe-class'
		          withArguments:
		          { (#className -> 'MCPToolDescribeMethodTestTarget') }
			          asDictionary.
	structured := self structuredContentFrom: result.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (structured at: #status) equals: 'ok'.
	self
		assert: (self summaryFrom: result)
		equals: ((result at: #content) first at: #text).
	self assert: (self warningsFrom: result) equals: #(  ).
	self
		assert: (data at: #className)
		equals: 'MCPToolDescribeMethodTestTarget'.
	self assert: (data at: #instanceMethodCount) equals: 1.
	self assert: (data at: #classMethodCount) equals: 1.
	self deny: (data includesKey: #classComment).
	self assert: (data at: #superclasses) isEmpty.
	self assert: (data at: #subclasses) isEmpty
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testDescribeMethodReturnsStructuredError [

	| error result structured |
	result := self
		          callToolNamed: 'describe-method'
		          withArguments: {
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
	self deny: (error at: #classSide)
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testDescribeMethodReturnsStructuredSuccess [

	| data result |
	result := self callToolNamed: 'describe-method' withArguments: {
			          (#className -> 'MCPToolDescribeMethodTestTarget').
			          (#selector -> 'readInstanceWith:') } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self
		assert: (data at: #className)
		equals: 'MCPToolDescribeMethodTestTarget'.
	self assert: (data at: #selector) equals: 'readInstanceWith:'.
	self assert: (data at: #externalVariableCount) equals: 4.
	self deny:
		((data at: #externalVariableReferences) anySatisfy: [ :each |
			 (each at: #name) = 'self' ]).
	self assert: ((data at: #variableReferences) allSatisfy: [ :each |
			 #( #sourceIntervals #external #declaredInMethod ) noneSatisfy: [
				 :key | each includesKey: key ] ]).
	self assert:
		((data at: #source) includesSubstring: String cr asString)
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testEvaluateReturnsStructuredError [

	| result structured error |
	result := self
		          callToolNamed: 'evaluate'
		          withArguments: { (#code -> '1 +') } asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #errorClass) equals: 'RBSyntaxErrorNotice'.
	self assert: ((error at: #message) includesSubstring: 'expected')
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testEvaluateReturnsStructuredSuccess [

	| result data structured |
	result := self
		          callToolNamed: 'evaluate'
		          withArguments: { (#code -> '1 + 2') } asDictionary.
	structured := self structuredContentFrom: result.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (structured at: #status) equals: 'ok'.
	self assert: (data at: #resultClassName) equals: 'SmallInteger'.
	self assert: (data at: #resultPrintString) equals: '3'
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testFindClassesReturnsStructuredArrayData [

	| classNames data result |
	result := self callToolNamed: 'find-classes' withArguments: {
			          (#scope -> 'packages').
			          (#packageNames -> #( 'MCP-Tests' )) } asDictionary.
	data := self dataFrom: result.
	classNames := (data at: #classes) collect: [ :each |
		              each at: #className ].
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (data at: #scope) equals: 'packages'.
	self assert: (data at: #packageNames) equals: #( 'MCP-Tests' ).
	self assert: (data at: #returnedCount) equals: classNames size.
	self assert: ((data at: #classes) allSatisfy: [ :each |
			 (each includesKey: #className) and: [
				 each includesKey: #packageName ] ]).
	self assert: (classNames includes: 'MCPToolContractsTest')
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testFindClassesReturnsStructuredError [

	| result structured error |
	result := self callToolNamed: 'find-classes' withArguments: {
			          (#scope -> 'packages').
			          (#packageNames -> #( 'MCP-Definitely-Missing' )) }
			          asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self
		assert: (error at: #packageName)
		equals: 'MCP-Definitely-Missing'.
	self assert: (error at: #scope) equals: 'packages'.
	self assert: ((error at: #message) includesSubstring:
			 'Package MCP-Definitely-Missing does not exist.')
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testFindMethodsReturnsStructuredArrayData [

	| data result selectors |
	result := self callToolNamed: 'find-methods' withArguments: {
			          (#scope -> 'classes').
			          (#classNames -> #( 'MCPToolFindMethodsTestTarget' )) }
			          asDictionary.
	data := self dataFrom: result.
	selectors := (data at: #methods) collect: [ :each |
		             each at: #selector ].
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (data at: #scope) equals: 'classes'.
	self
		assert: (data at: #classNames)
		equals: #( 'MCPToolFindMethodsTestTarget' ).
	self assert: (data at: #filterTargets) equals: #( 'selector' ).
	self assert: (data at: #returnedCount) equals: selectors size.
	self assert: ((data at: #methods) allSatisfy: [ :each |
			 (each includesKey: #selector) and: [
				 (each includesKey: #className) and: [
					 each includesKey: #packageName ] ] ]).
	self assert: (selectors includes: 'alphaNeedleSelector')
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testFindMethodsReturnsStructuredError [

	| result structured error |
	result := self callToolNamed: 'find-methods' withArguments: {
			          (#scope -> 'packages').
			          (#packageNames -> #( 'MCP-Definitely-Missing' )) }
			          asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self
		assert: (error at: #packageName)
		equals: 'MCP-Definitely-Missing'.
	self assert: (error at: #scope) equals: 'packages'.
	self assert: ((error at: #message) includesSubstring:
			 'Package MCP-Definitely-Missing does not exist.')
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testFindPackagesDefaultsToImageScopeWhenScopeIsOmitted [

	| data packageNames result |
	result := self callToolNamed: 'find-packages' withArguments: {
			          (#filter -> '^MCP\s').
			          (#filterMode -> 'regex') } asDictionary.
	data := self dataFrom: result.
	packageNames := (data at: #packages) collect: [ :each |
		                each at: #packageName ].
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (data at: #scope) equals: 'image'.
	self assert: (data at: #projectNames) equals: #(  ).
	self assert: (data at: #returnedCount) equals: 1.
	self assert: (packageNames includes: 'MCP')
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testFindPackagesReturnsStructuredArrayData [

	| result data packageNames |
	result := self callToolNamed: 'find-packages' withArguments: {
			          (#scope -> 'project').
			          (#projectNames -> #( 'MCP' )) } asDictionary.
	data := self dataFrom: result.
	packageNames := (data at: #packages) collect: [ :each |
		                each at: #packageName ].
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (data at: #scope) equals: 'project'.
	self assert: (data at: #projectNames) equals: #( 'MCP' ).
	self assert: (data at: #returnedCount) equals: packageNames size.
	self assert: ((data at: #packages) allSatisfy: [ :each |
			 (each includesKey: #packageName) and: [
				 each includesKey: #projectNames ] ]).
	self assert: (packageNames includes: 'MCP')
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testFindPackagesReturnsStructuredError [

	| result structured error |
	result := self callToolNamed: 'find-packages' withArguments: {
			          (#scope -> 'project').
			          (#projectNames -> #( 'DefinitelyMissingProject' )) }
			          asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self
		assert: (error at: #projectName)
		equals: 'DefinitelyMissingProject'.
	self assert: (error at: #scope) equals: 'project'.
	self assert: ((error at: #message) includesSubstring:
			 'Project DefinitelyMissingProject does not exist.')
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testRemoveClassReturnsStructuredError [

	| result structured error |
	result := self
		          callToolNamed: 'remove-classes'
		          withArguments:
			          { (#classNames
			           -> { 'MCPToolRemoveClassDefinitelyMissing' }) }
				          asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'. self assert: (error at: #errorCode) equals: 'ClassNotFound'.
	self
		assert: (error at: #className)
		equals: 'MCPToolRemoveClassDefinitelyMissing'
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testRunTestClassReturnsStructuredIssues [

	| data firstIssue result singleResult |
	result := self
		          callToolNamed: 'run-tests'
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
		          callToolNamed: 'run-tests'
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

{ #category : 'private' }
MCPToolStructuredOutputTest >> warningsFrom: aResult [

	^ (self structuredContentFrom: aResult) at: #warnings
]
