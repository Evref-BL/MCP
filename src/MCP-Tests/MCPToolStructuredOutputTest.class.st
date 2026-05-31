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
		          callToolNamed: 'image_evaluate'
		          withArguments: { (#code -> '1 +') } asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self
		assert: (error at: #errorClass)
		equals: self expectedSyntaxErrorNoticeClassName.
	self assert: ((error at: #message) includesSubstring: 'expected')
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testEvaluateReturnsStructuredRuntimeErrorWithStackTrace [

	| error result stackTrace |
	result := self
		          callToolNamed: 'image_evaluate'
		          withArguments:
		          { (#code -> 'Error signal: ''boom''') } asDictionary.
	error := self errorFrom: result.
	stackTrace := error at: #stackTrace.
	self assert: (result at: #isError).
	self assert: (error at: #errorClass) equals: 'Error'.
	self assert: ((error at: #message) includesSubstring: 'boom').
	self assert: (error includesKey: #signalerContext).
	self assert: stackTrace class equals: Array.
	self deny: stackTrace isEmpty.
	self assert: stackTrace first equals: (error at: #signalerContext)
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testEvaluateReturnsStructuredSuccess [

	| result data structured |
	result := self
		          callToolNamed: 'image_evaluate'
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
	result := self
		          callToolNamed: 'class_search'
		          withArguments:
		          { (#packageNames -> #( 'MCP-Tests' )) } asDictionary.
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
MCPToolStructuredOutputTest >> testFindClassesReturnsStructuredWarnings [

	| data result structured warnings |
	result := self
		          callToolNamed: 'class_search'
		          withArguments:
		          { (#packageNames -> #( 'MCP-Definitely-Missing' )) }
			          asDictionary.
	structured := self structuredContentFrom: result.
	data := self dataFrom: result.
	warnings := self warningsFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (structured at: #status) equals: 'ok'.
	self assert: (structured includesKey: #error) not.
	self assert: (data at: #totalCount) equals: 0.
	self assert: (data at: #classes) isEmpty.
	self assert: warnings size equals: 1.
	self assert:
		(warnings first includesSubstring: 'MCP-Definitely-Missing').
	self assert: (warnings first includesSubstring: 'packageNames scope').
	self assert: (warnings first includesSubstring: 'Did you mean:')
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testFindMethodsReturnsStructuredArrayData [

	| data result selectors |
	result := self
		          callToolNamed: 'method_metadata_search'
		          withArguments:
		          { (#classNames -> #( 'MCPToolFindMethodsTestTarget' )) }
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
MCPToolStructuredOutputTest >> testFindMethodsReturnsStructuredWarnings [

	| data result structured warnings |
	result := self
		          callToolNamed: 'method_metadata_search'
		          withArguments:
		          { (#packageNames -> #( 'MCP-Definitely-Missing' )) }
			          asDictionary.
	structured := self structuredContentFrom: result.
	data := self dataFrom: result.
	warnings := self warningsFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (structured at: #status) equals: 'ok'.
	self assert: (structured includesKey: #error) not.
	self assert: (data at: #totalCount) equals: 0.
	self assert: (data at: #methods) isEmpty.
	self assert: warnings size equals: 1.
	self assert:
		(warnings first includesSubstring: 'MCP-Definitely-Missing').
	self assert: (warnings first includesSubstring: 'packageNames scope').
	self assert: (warnings first includesSubstring: 'Did you mean:')
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testFindPackagesDefaultsToImageScopeWhenScopePropertiesAreOmitted [

	| data packageNames result |
	result := self callToolNamed: 'package_search' withArguments: {
			          (#projectName -> 'MCP').
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
	result := self
		          callToolNamed: 'package_search'
		          withArguments:
		          { (#projectNames -> #( 'MCP' )) } asDictionary.
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
	result := self
		          callToolNamed: 'package_search'
		          withArguments:
		          { (#projectNames -> #( 'DefinitelyMissingProject' )) }
			          asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self
		assert: (error at: #projectName)
		equals: 'DefinitelyMissingProject'.
	self assert: (error at: #scope) equals: 'projects'.
	self assert: ((error at: #message) includesSubstring:
			 'Project DefinitelyMissingProject does not exist.')
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testInspectClassParseErrorReturnsStructuredToolError [

	| error result structured |
	result := self
		          callToolNamed: 'class_get'
		          withArguments: { (#className -> '') } asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #errorClass) equals: #Error.
	self assert: (error at: #className) equals: ''.
	self assert: ((error at: #message) includesSubstring:
			 'className must be a non-empty string')
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testInspectClassReturnsStructuredError [

	| error result structured |
	result := self
		          callToolNamed: 'class_get'
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
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'ClassNotFound'.
	self
		assert: (error at: #className)
		equals: 'MCPToolInspectClassDefinitelyMissing'
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testInspectClassReturnsStructuredSuccess [

	| data expectedSharedVariableNames result structured |
	result := self
		          callToolNamed: 'class_get'
		          withArguments:
		          { (#className -> 'MCPToolInspectMethodTestTarget') }
			          asDictionary.
	structured := self structuredContentFrom: result.
	data := self dataFrom: result.
	expectedSharedVariableNames := (MCPToolInspectMethodTestTarget
		                                classVarNames collect: [ :each |
		                                each asString ]) asArray.
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
	self
		assert: (data at: #sharedVariableNames)
		equals: expectedSharedVariableNames.
	self assert: (data includesKey: #layoutClassName).
	self assert: (data includesKey: #traitComposition).
	self assert: (data includesKey: #classTraitComposition).
	self deny: (data includesKey: #classComment).
	self assert: (data at: #superclasses) isEmpty.
	self assert: (data at: #subclasses) isEmpty
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testInspectMethodReturnsStructuredError [

	| error result structured |
	result := self callToolNamed: 'method_get' withArguments: {
			          (#className -> 'MCPToolInspectMethodTestTarget').
			          (#selector -> 'doesNotExist') } asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'MethodNotFound'.
	self
		assert: (error at: #className)
		equals: 'MCPToolInspectMethodTestTarget'.
	self assert: (error at: #selector) equals: 'doesNotExist'.
	self assert: (error includesKey: #classSide).
	self deny: (error at: #classSide).
	self deny: (error includesKey: #side)
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testInspectMethodReturnsStructuredSuccess [

	| data result |
	result := self callToolNamed: 'method_get' withArguments: {
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
		          callToolNamed: 'class_remove'
		          withArguments:
			          { (#classNames
			           -> { 'MCPToolRemoveClassDefinitelyMissing' }) }
				          asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'ClassNotFound'.
	self
		assert: (error at: #className)
		equals: 'MCPToolRemoveClassDefinitelyMissing'
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testRunTestClassReturnsStructuredIssues [

	| data firstIssue issueMethodNames result singleResult |
	result := self callToolNamed: 'test_run' withArguments: { (#tests
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
		          callToolNamed: 'test_run'
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

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testRunTestsCoverageCanIncludeCoveredMethodsAndCapLists [

	| coverage coveredSelectors data result |
	result := self callToolNamed: 'test_coverage_run' withArguments: {
			          (#tests
			           ->
			           { { (#className -> 'MCPToolCoverageTargetTest') }
				           asDictionary }).
			          (#coverage -> {
				           (#classNames -> #( 'MCPToolCoverageTarget' )).
				           (#includeCoveredMethods -> true).
				           (#methodLimit -> 1) } asDictionary) } asDictionary.
	data := self dataFrom: result.
	coverage := data at: #coverage.
	coveredSelectors := (coverage at: #coveredMethods) collect: [ :each |
		                    each at: #selector ].
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (coverage at: #coveredMethodCount) equals: 2.
	self assert: (coverage at: #coveredMethods) size equals: 1.
	self assert: (coverage at: #coveredMethodsTruncated).
	self assert: coveredSelectors size equals: 1
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testRunTestsCoverageRequiresExplicitScope [

	| error result |
	result := self callToolNamed: 'test_coverage_run' withArguments: {
			          (#tests
			           ->
			           { { (#className -> 'MCPToolCoverageTargetTest') }
				           asDictionary }).
			          (#coverage -> Dictionary new) } asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'error'.
	self assert: (error at: #errorCode) equals: 'CoverageScopeRequired'.
	self assert:
		((error at: #message) includesSubstring: 'explicit method scope')
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testRunTestsCoverageReturnsStructuredCoverage [

	| coverage data partialSelectors result singleResult uncoveredSelectors |
	result := self callToolNamed: 'test_coverage_run' withArguments: {
			          (#tests
			           ->
			           { { (#className -> 'MCPToolCoverageTargetTest') }
				           asDictionary }).
			          (#coverage -> {
				           (#classNames -> #( 'MCPToolCoverageTarget' )).
				           (#methodLimit -> 10) } asDictionary) } asDictionary.
	data := self dataFrom: result.
	coverage := data at: #coverage.
	singleResult := (data at: #results) first.
	uncoveredSelectors := (coverage at: #uncoveredMethods) collect: [
		                      :each | each at: #selector ].
	partialSelectors := (coverage at: #partiallyCoveredMethods) collect: [
		                    :each | each at: #selector ].
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert:
		((self summaryFrom: result) includesSubstring: 'Coverage:').
	self assert: (singleResult at: #runCount) equals: 2.
	self assert: (coverage at: #methodCount) equals: 3.
	self assert: (coverage at: #coveredMethodCount) equals: 2.
	self assert: (coverage at: #fullyCoveredMethodCount) equals: 1.
	self assert: (coverage at: #uncoveredMethodCount) equals: 1.
	self assert: (coverage at: #partiallyCoveredMethodCount) equals: 1.
	self assert: (coverage at: #coveredNodeCount) equals: 3.
	self assert: (coverage at: #nodeCount) equals: 5.
	self assert: (coverage at: #percentage) equals: 60.0.
	self assert: (uncoveredSelectors includes: 'uncoveredMethod').
	self assert: (partialSelectors includes: 'partiallyCoveredMethod:').
	self deny: (coverage includesKey: #coveredMethods).
	self deny: (coverage at: #uncoveredMethodsTruncated).
	self deny: (coverage at: #partiallyCoveredMethodsTruncated)
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testRunTestsParameterizedMethodFailureIncludesCaseDetails [

	| data issue methodResult result |
	result := self
		          callToolNamed: 'test_run'
		          withArguments: { (#tests -> { {
				           (#className -> 'MCPToolRunTestsParameterizedTarget').
				           (#testMethodName -> 'testFailsOnlyForUTF16') }
				           asDictionary }) } asDictionary.
	data := self dataFrom: result.
	methodResult := (data at: #results) first.
	issue := (methodResult at: #issues) first.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (methodResult at: #runCount) equals: 3.
	self
		assert: (methodResult at: #testMethodName)
		equals: 'testFailsOnlyForUTF16'.
	self assert: (methodResult at: #issues) size equals: 1.
	self
		assert: (issue at: #testMethodName)
		equals: 'testFailsOnlyForUTF16'.
	self
		assert: (issue at: #testCaseName)
		equals: 'testFailsOnlyForUTF16(#encoding->''UTF-16'')'.
	self
		assert: (issue at: #parameters)
		equals: #( '#encoding->''UTF-16''' ).
	self assert: ((issue at: #message) includesSubstring: 'UTF-16').
	self deny: (issue includesKey: #testName)
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testRunTestsParseErrorReturnsStructuredToolError [

	| error result structured |
	result := self
		          callToolNamed: 'test_run'
		          withArguments:
		          { (#tests -> { { (#className -> '') } asDictionary }) }
			          asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #errorClass) equals: #Error.
	self assert: (error at: #tests) equals: #( '' ).
	self assert: ((error at: #message) includesSubstring:
			 'tests must contain only non-empty class names')
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testRunTestsSuccessfulResultOmitsEmptyIssues [

	| data result singleResult |
	result := self
		          callToolNamed: 'test_run'
		          withArguments: { (#tests -> { {
				           (#className -> 'MCPToolStructuredOutputTestTarget').
				           (#testMethodName -> 'testPasses') } asDictionary }) }
				          asDictionary.
	data := self dataFrom: result.
	singleResult := (data at: #results) first.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (singleResult at: #runCount) equals: 1.
	self deny: (singleResult includesKey: #issues)
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testRunTestsTimeoutReturnsPartialResultsAndUnrunTestsCanResume [

	| data partialResult resumedData resumedResult result unrunTests |
	result := self callToolNamed: 'test_run' withArguments: {
			          (#tests -> {
				           { (#className -> 'MCPToolRunTestsTimeoutTarget') }
					           asDictionary.
				           {
					           (#className -> 'MCPToolRequestTest').
					           (#testMethodName
					            -> 'testValidRequestProvidesTypedAccessors') }
					           asDictionary }).
			          (#timeoutMilliseconds -> 100) } asDictionary.
	data := self dataFrom: result.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (data at: #timedOut).
	partialResult := (data at: #results) first.
	self
		assert: (partialResult at: #className)
		equals: 'MCPToolRunTestsTimeoutTarget'.
	self assert: (partialResult at: #runCount) equals: 1.
	unrunTests := data at: #unrunTests.
	self assert: (unrunTests anySatisfy: [ :each |
				 (each at: #className) = 'MCPToolRunTestsTimeoutTarget' and: [
					 (each at: #testMethodName) = 'testSlowPass' ] ]).
	self assert: (unrunTests anySatisfy: [ :each |
				 (each at: #className) = 'MCPToolRequestTest' and: [
					 (each at: #testMethodName)
					 = 'testValidRequestProvidesTypedAccessors' ] ]).
	resumedResult := self callToolNamed: 'test_run' withArguments: {
			                 (#tests -> unrunTests).
			                 (#timeoutMilliseconds -> 1000) } asDictionary.
	resumedData := self dataFrom: resumedResult.
	self
		assert: ((self structuredContentFrom: resumedResult) at: #status)
		equals: 'ok'.
	self deny: (resumedData includesKey: #timedOut).
	self
		assert:
		((resumedData at: #results) sum: [ :each | each at: #runCount ])
		equals: unrunTests size
]
