"
Tests structured output produced by MCP tools.
"
Class {
	#name : 'MCPToolStructuredOutputTest',
	#superclass : 'MCPToolAPITestCase',
	#category : 'MCP-Tests-Internal',
	#package : 'MCP-Tests',
	#tag : 'Internal'
}

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
MCPToolStructuredOutputTest >> testGetClassParseErrorReturnsStructuredToolError [

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
MCPToolStructuredOutputTest >> testGetClassReturnsStructuredError [

	| error result structured |
	result := self callToolNamed: 'class_get' withArguments: { (#className -> 'MCPToolGetClassDefinitelyMissing') } asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self deny: (structured includesKey: #warnings).
	self assert: ((result at: #content) first at: #text) equals: (structured at: #summary).
	self assert: (self warningsFrom: result) equals: #(  ).
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'ClassNotFound'.
	self assert: (error at: #className) equals: 'MCPToolGetClassDefinitelyMissing'
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testGetClassReturnsStructuredSuccess [

	| data expectedSharedVariableNames result structured |
	result := self callToolNamed: 'class_get' withArguments: { (#className -> 'MCPToolGetMethodTestTarget') } asDictionary.
	structured := self structuredContentFrom: result.
	data := self dataFrom: result.
	expectedSharedVariableNames := (MCPToolGetMethodTestTarget classVarNames collect: [ :each | each asString ]) asArray.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (structured at: #status) equals: 'ok'.
	self deny: (structured includesKey: #warnings).
	self assert: ((result at: #content) first at: #text) equals: (structured at: #summary).
	self assert: (self warningsFrom: result) equals: #(  ).
	self assert: (data at: #className) equals: 'MCPToolGetMethodTestTarget'.
	self assert: (data at: #instanceMethodCount) equals: 1.
	self assert: (data at: #classMethodCount) equals: 1.
	self assert: (data at: #sharedVariableNames) equals: expectedSharedVariableNames.
	self assert: (data includesKey: #layoutClassName).
	self deny: (data includesKey: #traitComposition).
	self deny: (data includesKey: #classTraitComposition).
	self deny: (data includesKey: #classComment).
	self deny: (data includesKey: #superclasses).
	self deny: (data includesKey: #subclasses)
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testGetMethodReturnsStructuredError [

	| error result structured |
	result := self callToolNamed: 'method_get' withArguments: {
			          (#className -> 'MCPToolGetMethodTestTarget').
			          (#selector -> 'doesNotExist') } asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'MethodNotFound'.
	self
		assert: (error at: #className)
		equals: 'MCPToolGetMethodTestTarget'.
	self assert: (error at: #selector) equals: 'doesNotExist'.
	self assert: (error includesKey: #classSide).
	self deny: (error at: #classSide).
	self deny: (error includesKey: #side)
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testGetMethodReturnsStructuredSuccess [

	| data result |
	result := self callToolNamed: 'method_get' withArguments: {
			          (#className -> 'MCPToolGetMethodTestTarget').
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
MCPToolStructuredOutputTest >> testMethodMetadataSearchReturnsStructuredArrayData [

	| data methods result selectors |
	result := self
		          callToolNamed: 'method_metadata_search'
		          withArguments: { (self searchScope:
				           { (#classes -> #( 'MCPToolMethodSearchTestTarget' )) }) }
				          asDictionary.
	data := self dataFrom: result.
	methods := data at: #methods.
	selectors := methods collect: [ :each | each at: #selector ].
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: methods notEmpty.
	self assert: (methods allSatisfy: [ :each |
				 (each includesKey: #selector) and: [
					 (each includesKey: #className) and: [
						 each includesKey: #packageName ] ] ]).
	self assert: (selectors includes: 'alphaNeedleSelector')
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testMethodMetadataSearchReturnsStructuredWarnings [

	| data result structured warnings |
	result := self
		          callToolNamed: 'method_metadata_search'
		          withArguments:
			          { (self searchScope:
				           { (#packages -> #( 'MCP-Definitely-Missing' )) }) }
				          asDictionary.
	structured := self structuredContentFrom: result.
	data := self dataFrom: result.
	warnings := self warningsFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (structured at: #status) equals: 'ok'.
	self assert: (structured includesKey: #error) not.
	self assert: (data at: #methods) isEmpty.
	self assert: warnings size equals: 1.
	self assert:
		(warnings first includesSubstring: 'MCP-Definitely-Missing').
	self assert: (warnings first includesSubstring: 'packageNames scope').
	self assert: (warnings first includesSubstring: 'Did you mean:')
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

	| data error failure result skipped |
	result := self
		          callToolNamed: 'test_run'
		          withArguments:
			          { (#classes -> #( 'MCPToolStructuredOutputTestTarget' )) }
				          asDictionary.
	data := self dataFrom: result.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (data at: #runCount) equals: 3.
	self assert: (data at: #passedCount) equals: 1.
	skipped := data at: #skipped.
	failure := (data at: #failures) first.
	error := (data at: #errors) first.
	self
		assert: skipped
		equals: #( 'MCPToolStructuredOutputTestTarget>>#testSkips' ).
	self
		assert: (failure at: #test)
		equals: 'MCPToolStructuredOutputTestTarget>>#testFails'.
	self assert:
		((failure at: #message) includesSubstring: 'boom failure').
	self
		assert: (error at: #test)
		equals: 'MCPToolStructuredOutputTestTarget>>#testErrors'.
	self assert: (error at: #errorClass) equals: 'Error'.
	self assert: ((error at: #message) includesSubstring: 'boom error').
	self deny: (data includesKey: #results).
	self deny: (data includesKey: #issues)
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testRunTestMethodReturnsStructuredIssues [

	| data failure result |
	result := self
		          callToolNamed: 'test_run'
		          withArguments:
			          { (#methods
			           -> #( 'MCPToolStructuredOutputTestTarget>>#testFails' )) }
				          asDictionary.
	data := self dataFrom: result.
	failure := (data at: #failures) first.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (data at: #runCount) equals: 1.
	self assert: (data at: #passedCount) equals: 0.
	self assert: (data at: #failures) size equals: 1.
	self
		assert: (failure at: #test)
		equals: 'MCPToolStructuredOutputTestTarget>>#testFails'.
	self assert:
		((failure at: #message) includesSubstring: 'boom failure').
	self deny: (data includesKey: #results).
	self deny: (data includesKey: #skipped).
	self deny: (data includesKey: #errors)
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testRunTestsCoverageCanIncludeCoveredMethodsAndCapLists [

	| coverage coveredSelectors data result |
	result := self callToolNamed: 'test_coverage_run' withArguments: {
			          (#classes -> #( 'MCPToolCoverageTargetTest' )).
			          (#coverage -> {
				           (#scope
				            ->
				            { (#classes -> #( 'MCPToolCoverageTarget' )) }
					            asDictionary).
				           (#includeCoveredMethods -> true).
				           (#methodLimit -> 1) } asDictionary) } asDictionary.
	data := self dataFrom: result.
	coverage := data at: #coverage.
	coveredSelectors := (coverage at: #coveredMethods) collect: [ :each |
		                    each at: #selector ].
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (data at: #runCount) equals: 2.
	self assert: (data at: #passedCount) equals: 2.
	self assert: (coverage at: #coveredMethodCount) equals: 2.
	self assert: (coverage at: #coveredMethods) size equals: 1.
	self assert: (coverage at: #coveredMethodsTruncated).
	self assert: coveredSelectors size equals: 1
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testRunTestsCoverageRequiresExplicitScope [

	| error result |
	result := self callToolNamed: 'test_coverage_run' withArguments: {
			          (#classes -> #( 'MCPToolCoverageTargetTest' )).
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

	| coverage data partialSelectors result uncoveredSelectors |
	result := self callToolNamed: 'test_coverage_run' withArguments: {
			          (#classes -> #( 'MCPToolCoverageTargetTest' )).
			          (#coverage -> {
				           (#scope
				            ->
				            { (#classes -> #( 'MCPToolCoverageTarget' )) }
					            asDictionary).
				           (#methodLimit -> 10) } asDictionary) } asDictionary.
	data := self dataFrom: result.
	coverage := data at: #coverage.
	uncoveredSelectors := (coverage at: #uncoveredMethods) collect: [
		                      :each | each at: #selector ].
	partialSelectors := (coverage at: #partiallyCoveredMethods) collect: [
		                    :each | each at: #selector ].
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert:
		((self summaryFrom: result) includesSubstring: 'Coverage:').
	self assert: (data at: #runCount) equals: 2.
	self assert: (data at: #passedCount) equals: 2.
	self deny: (data includesKey: #results).
	self assert: (coverage at: #methodCount) equals: 3.
	self assert: (coverage at: #coveredMethodCount) equals: 2.
	self assert: (coverage at: #fullyCoveredMethodCount) equals: 1.
	self assert: (coverage at: #uncoveredMethodCount) equals: 1.
	self assert: (coverage at: #partiallyCoveredMethodCount) equals: 1.
	self assert: (coverage at: #coveredNodeCount) equals: 3.
	self assert: (coverage at: #nodeCount) equals: 5.
	self assert: ((coverage at: #percentage) between: 59 and: 61).
	self assert: (uncoveredSelectors includes: 'uncoveredMethod').
	self assert: (partialSelectors includes: 'partiallyCoveredMethod:')
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testRunTestsDeduplicatesConcreteCasesAcrossSelections [

	| data result |
	result := self callToolNamed: 'test_run' withArguments: {
			          (#classes -> #( 'MCPToolStructuredOutputTestTarget' )).
			          (#methods
			           -> #( 'MCPToolStructuredOutputTestTarget>>#testFails' )) }
			          asDictionary.
	data := self dataFrom: result.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (data at: #runCount) equals: 3.
	self assert: (data at: #passedCount) equals: 1.
	self assert: (data at: #skipped) size equals: 1.
	self assert: (data at: #failures) size equals: 1.
	self assert: (data at: #errors) size equals: 1
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testRunTestsDeduplicatesUnrunCasesAcrossSelections [

	| data result |
	result := self callToolNamed: 'test_run' withArguments: {
			          (#classes -> #( 'MCPToolStructuredOutputTestTarget' )).
			          (#methods
			           -> #( 'MCPToolStructuredOutputTestTarget>>#testFails' )).
			          (#timeoutSeconds -> 0) } asDictionary.
	data := self dataFrom: result.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (data at: #timedOut) equals: true.
	self assert: (data at: #runCount) equals: 0.
	self assert: (data at: #passedCount) equals: 0.
	self
		assert: (data at: #unrunClasses)
		equals: #( 'MCPToolStructuredOutputTestTarget' ).
	self deny: (data includesKey: #unrunMethods).
	self deny: (data includesKey: #results)
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testRunTestsParameterizedMethodFailureIncludesCaseDetails [

	| data issue result |
	result := self callToolNamed: 'test_run' withArguments: { (#methods
		           ->
		           #( 'MCPToolRunTestsParameterizedTarget>>#testFailsOnlyForUTF16' )) }
			          asDictionary.
	data := self dataFrom: result.
	issue := (data at: #failures) first.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (data at: #runCount) equals: 3.
	self assert: (data at: #passedCount) equals: 2.
	self assert: (data at: #failures) size equals: 1.
	self
		assert: (issue at: #test)
		equals: 'MCPToolRunTestsParameterizedTarget>>#testFailsOnlyForUTF16'.
	self
		assert: (issue at: #parameters)
		equals: #( '#encoding->''UTF-16''' ).
	self assert: ((issue at: #message) includesSubstring: 'UTF-16').
	self deny: (issue includesKey: #testName).
	self deny: (issue includesKey: #testCaseName)
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testRunTestsParseErrorReturnsStructuredToolError [

	| error result structured |
	result := self
		          callToolNamed: 'test_run'
		          withArguments:
		          { (#methods -> #( 'NotAMethodReference' )) } asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #errorClass) equals: #Error.
	self deny: (error includesKey: #tests).
	self assert:
		((error at: #message) includesSubstring: 'Class>>#selector')
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testRunTestsSkippedMethodReportsCompactList [

	| data result |
	result := self
		          callToolNamed: 'test_run'
		          withArguments:
			          { (#methods
			           -> #( 'MCPToolStructuredOutputTestTarget>>#testSkips' )) }
				          asDictionary.
	data := self dataFrom: result.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (data at: #runCount) equals: 0.
	self assert: (data at: #passedCount) equals: 0.
	self
		assert: (data at: #skipped)
		equals: #( 'MCPToolStructuredOutputTestTarget>>#testSkips' ).
	self deny: (data includesKey: #failures).
	self deny: (data includesKey: #errors)
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testRunTestsSuccessfulResultHasExpectedShape [

	| data result |
	result := self
		          callToolNamed: 'test_run'
		          withArguments: { (#methods -> #( 'MCPToolStructuredOutputTestTarget>>#testPasses' )) } asDictionary.
	data := self dataFrom: result.
	self assert: ((self structuredContentFrom: result) at: #status) equals: 'ok'.
	self assert: data equals: {
			(#runCount -> 1).
			(#passedCount -> 1) } asDictionary
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testRunTestsTimeoutReturnsPartialResultsAndUnrunSelectionsCanResume [

	| data request resumedData resumedResult result runTestsRequest tool |
	tool := MCPToolRunTests new.
	runTestsRequest := MCPRunTestsRequest new
		                   initializeTestRequests: {
				                   (MCPTestRunRequest className:
					                    'MCPToolRunTestsTimeoutTarget').
				                   (MCPTestRunRequest className:
					                    'MCPToolCoverageTargetTest').
				                   (MCPTestRunRequest packageName:
					                    'MCP-Spec-Tests') }
		                   timeoutMilliseconds: 100
		                   operation: 'run'
		                   coverageRequest: nil.
	result := (tool commandForRequest: runTestsRequest) execute.
	data := result asDictionary.
	self assert: (data at: #timedOut).
	self assert: (data at: #runCount) equals: 1.
	self assert: (data at: #passedCount) equals: 1.
	self
		assert: (data at: #unrunMethods)
		equals: #( 'MCPToolRunTestsTimeoutTarget>>#testSlowPass' ).
	self
		assert: (data at: #unrunClasses)
		equals: #( 'MCPToolCoverageTargetTest' ).
	self assert: (data at: #unrunPackages) equals: #( 'MCP-Spec-Tests' ).
	request := Dictionary new
		           at: #methods put: (data at: #unrunMethods);
		           at: #classes put: (data at: #unrunClasses);
		           at: #packages put: (data at: #unrunPackages);
		           at: #timeoutSeconds put: 30;
		           yourself.
	resumedResult := self
		                 callToolNamed: 'test_run'
		                 withArguments: request.
	resumedData := self dataFrom: resumedResult.
	self
		assert: ((self structuredContentFrom: resumedResult) at: #status)
		equals: 'ok'.
	self deny: (resumedData includesKey: #timedOut).
	self
		assert: (resumedData at: #passedCount)
		equals: (resumedData at: #runCount).
	self assert: (resumedData at: #runCount) > 3
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testSearchClassesReturnsStructuredArrayData [

	| classNames classes data result |
	result := self
		          callToolNamed: 'class_search'
		          withArguments:
			          { (self searchScope:
				           { (#classes -> #( 'MCPToolContractsTest' )) }) }
				          asDictionary.
	data := self dataFrom: result.
	classes := data at: #classes.
	classNames := classes collect: [ :each | each at: #className ].
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: classes size equals: 1.
	self assert: (classes allSatisfy: [ :each |
			 (each includesKey: #className) and: [
				 each includesKey: #packageName ] ]).
	self assert: (classNames includes: 'MCPToolContractsTest')
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testSearchClassesReturnsStructuredWarnings [

	| data result structured warnings |
	result := self
		          callToolNamed: 'class_search'
		          withArguments:
			          { (self searchScope:
				           { (#packages -> #( 'MCP-Definitely-Missing' )) }) }
				          asDictionary.
	structured := self structuredContentFrom: result.
	data := self dataFrom: result.
	warnings := self warningsFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (structured at: #status) equals: 'ok'.
	self assert: (structured includesKey: #error) not.
	self assert: (data at: #classes) isEmpty.
	self assert: warnings size equals: 1.
	self assert:
		(warnings first includesSubstring: 'MCP-Definitely-Missing').
	self assert: (warnings first includesSubstring: 'packageNames scope').
	self assert: (warnings first includesSubstring: 'Did you mean:')
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testSearchPackagesDefaultsToImageScopeWhenScopePropertiesAreOmitted [

	| data packageNames packages result |
	result := self callToolNamed: 'package_search' withArguments: {
			          (#projectName -> 'MCP').
			          (#filterMode -> 'exact') } asDictionary.
	data := self dataFrom: result.
	packages := data at: #packages.
	packageNames := packages collect: [ :each | each at: #packageName ].
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: packages notEmpty.
	self assert: (packageNames includes: 'MCP')
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testSearchPackagesReturnsStructuredArrayData [

	| data packageNames packages result |
	result := self
		          callToolNamed: 'package_search'
		          withArguments:
		          { (#projectNames -> #( 'MCP' )) } asDictionary.
	data := self dataFrom: result.
	packages := data at: #packages.
	packageNames := packages collect: [ :each | each at: #packageName ].
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: packages notEmpty.
	self assert: (packages allSatisfy: [ :each |
				 (each includesKey: #packageName) and: [
					 each includesKey: #projectNames ] ]).
	self assert: (packageNames includes: 'MCP')
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testSearchPackagesReturnsStructuredError [

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
MCPToolStructuredOutputTest >> testToolsListAdvertisesPublicToolContracts [

	| tools |
	tools := MCP new rpcToolsList at: #tools.
	self assert: tools notEmpty.
	tools do: [ :tool | self assert: tool keys asSet equals: #( name title description inputSchema ) asSet ]
]
