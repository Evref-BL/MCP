Class {
	#name : 'MCPToolStructuredOutputTest',
	#superclass : 'MCPToolAPITestCase',
	#category : 'MCP-Tests-Internal',
	#package : 'MCP-Tests',
	#tag : 'Internal'
}

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testAllToolsAdvertiseOutputSchema [

	| tools |
	tools := MCP new rpcToolsList at: #tools.
	self assert:
		(tools allSatisfy: [ :each | each includesKey: #outputSchema ])
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
	self assert: (data at: #totalCount) equals: classNames size.
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
	self assert: (data at: #totalCount) equals: selectors size.
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
			          (#filter -> 'MCP').
			          (#filterTargets -> #( 'project' )).
			          (#filterMode -> 'exact') } asDictionary.
	data := self dataFrom: result.
	packageNames := (data at: #packages) collect: [ :each |
		                each at: #packageName ].
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (data at: #totalCount) > 0.
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
	self assert: (data at: #totalCount) equals: packageNames size.
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
MCPToolStructuredOutputTest >> testInspectClassReturnsStructuredError [

	| error result structured |
	result := self
		          callToolNamed: 'inspect-class'
		          withArguments:
			          { (#className -> 'MCPToolInspectClassDefinitelyMissing') }
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
		equals: 'MCPToolInspectClassDefinitelyMissing'
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testInspectClassReturnsStructuredSuccess [

	| data result structured |
	result := self
		          callToolNamed: 'inspect-class'
		          withArguments:
		          { (#className -> 'MCPToolInspectMethodTestTarget') }
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
		equals: 'MCPToolInspectMethodTestTarget'.
	self assert: (data at: #instanceMethodCount) equals: 1.
	self assert: (data at: #classMethodCount) equals: 1.
	self deny: (data includesKey: #classComment).
	self assert: (data at: #superclasses) isEmpty.
	self assert: (data at: #subclasses) isEmpty
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testInspectMethodReturnsStructuredError [

	| error result structured |
	result := self
		          callToolNamed: 'inspect-method'
		          withArguments: {
				          (#className -> 'MCPToolInspectMethodTestTarget').
				          (#selector -> 'doesNotExist') } asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'. self assert: (error at: #errorCode) equals: 'MethodNotFound'.
	self
		assert: (error at: #className)
		equals: 'MCPToolInspectMethodTestTarget'.
	self assert: (error at: #selector) equals: 'doesNotExist'.
	self assert: (error at: #side) equals: 'instance'.
	self deny: (error at: #classSide)
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testInspectMethodReturnsStructuredSuccess [

	| data result |
	result := self callToolNamed: 'inspect-method' withArguments: {
			          (#className -> 'MCPToolInspectMethodTestTarget').
			          (#selector -> 'readInstanceWith:') } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (data at: #protocol) equals: 'reading'.
	self deny: (data includesKey: #variableReferences).
	self deny: (data includesKey: #className).
	self deny: (data includesKey: #selector).
	self deny: (data includesKey: #side).
	self deny: (data includesKey: #argumentNames).
	self deny: (data includesKey: #temporaryNames).
	self deny: (data includesKey: #variableDetailsIncluded).
	self deny: (data includesKey: #externalVariableCount).
	self deny: (data includesKey: #variableReferenceCount).
	self deny: (data includesKey: #externalVariableReferences).
	self assert:
		((data at: #source) includesSubstring: String cr asString)
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

	| data firstIssue issueMethodNames result singleResult |
	result := self callToolNamed: 'run-tests' withArguments: { (#tests
		           ->
		           { { (#className -> 'MCPToolStructuredOutputTestTarget') }
			           asDictionary }) } asDictionary.
	data := self dataFrom: result.
	singleResult := (data at: #results) first.
	issueMethodNames := (singleResult at: #issues) collect: [ :each |
		                    each at: #testMethodName ].
	firstIssue := (singleResult at: #issues) first.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: data keys asSet equals: #( #results ) asSet.
	self assert: (data at: #results) size equals: 1.
	self
		assert: (singleResult at: #className)
		equals: 'MCPToolStructuredOutputTestTarget'.
	self assert: (singleResult at: #runCount) equals: 3.
	self assert: (singleResult at: #issues) size equals: 2.
	self assert: (issueMethodNames includes: 'testFails').
	self assert: (issueMethodNames includes: 'testErrors').
	self assert: (firstIssue includesKey: #message).
	self
		assert: (firstIssue at: #className)
		equals: 'MCPToolStructuredOutputTestTarget'.
	self deny: (firstIssue includesKey: #testName).
	self deny: (data includesKey: #tests).
	self deny: (data includesKey: #selectionCount).
	self deny: (data includesKey: #runCount).
	self deny: (data includesKey: #passedCount).
	self deny: (data includesKey: #skippedCount).
	self deny: (data includesKey: #failureCount).
	self deny: (data includesKey: #errorCount).
	self deny: (data includesKey: #failingTestNames).
	self deny: (data includesKey: #issues).
	self deny: (singleResult includesKey: #passedCount).
	self deny: (singleResult includesKey: #skippedCount).
	self deny: (singleResult includesKey: #failureCount).
	self deny: (singleResult includesKey: #errorCount).
	self deny: (singleResult includesKey: #failingTestNames)
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testRunTestMethodReturnsStructuredIssues [

	| data firstIssue methodResult result |
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
	firstIssue := (methodResult at: #issues) first.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: data keys asSet equals: #( #results ) asSet.
	self assert: (data at: #results) size equals: 2.
	self assert: (methodResult at: #runCount) equals: 1.
	self assert: (methodResult at: #testMethodName) equals: 'testFails'.
	self assert: (methodResult at: #issues) size equals: 1.
	self assert: (firstIssue at: #testMethodName) equals: 'testFails'.
	self
		assert: (firstIssue at: #className)
		equals: 'MCPToolStructuredOutputTestTarget'.
	self deny: (firstIssue includesKey: #testName).
	self deny: (data includesKey: #tests).
	self deny: (data includesKey: #selectionCount).
	self deny: (data includesKey: #runCount).
	self deny: (data includesKey: #passedCount).
	self deny: (data includesKey: #skippedCount).
	self deny: (data includesKey: #failureCount).
	self deny: (data includesKey: #errorCount).
	self deny: (data includesKey: #failingTestNames).
	self deny: (data includesKey: #issues).
	self deny: (methodResult includesKey: #passedCount).
	self deny: (methodResult includesKey: #skippedCount).
	self deny: (methodResult includesKey: #failureCount).
	self deny: (methodResult includesKey: #errorCount).
	self deny: (methodResult includesKey: #failingTestNames)
]
