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
MCPToolStructuredOutputTest >> testCountedNounsReadAsEnglish [

	| tool |
	tool := MCPToolGetClass new.
	self assert: (tool textForCount: 1 noun: 'change history entry') equals: '1 change history entry'.
	self assert: (tool textForCount: 2 noun: 'change history entry') equals: '2 change history entries'.
	self assert: (tool textForCount: 2 noun: 'class') equals: '2 classes'.
	self assert: (tool textForCount: 2 noun: 'match') equals: '2 matches'.
	self assert: (tool textForCount: 2 noun: 'method') equals: '2 methods'
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testCoverageDropsFlagsThatAreNotSet [

	| contentText |
	contentText := MCPToolRunTestCoverage new contentTextForStructuredContent: (Dictionary new
		               at: #summary put: 'Ran 4 tests (4 passed). Coverage: 78.95%.';
		               at: #data put: (Dictionary new
				                at: #coverage put: (Dictionary new
						                 at: #percentage put: 78.94736842105263;
						                 at: #methodCount put: 6;
						                 at: #coveredMethodsTruncated put: false;
						                 at: #uncoveredMethodsTruncated put: true;
						                 yourself);
				                yourself);
		               yourself).
	self assert: (contentText includesSubstring: 'methodCount: 6').
	self assert: (contentText includesSubstring: 'uncoveredMethodsTruncated: true').
	self deny: (contentText includesSubstring: 'percentage').
	self deny: (contentText lines anySatisfy: [ :each | each trimBoth beginsWith: 'coveredMethodsTruncated' ])
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testDebugResultDoesNotRepeatItsWarnings [

	| contentText |
	contentText := MCPToolDebugSearch new contentTextForStructuredContent: (Dictionary new
		               at: #summary put: 'One open debugger.';
		               at: #warnings put: { 'Careful.' };
		               at: #data put: (Dictionary new
				                at: #debuggers put: { (Dictionary new
						                 at: #debugger put: 'A debugger';
						                 at: #exception put: 'ZeroDivide: divide by zero';
						                 yourself) };
				                yourself);
		               yourself).
	self assert: (contentText includesSubstring: 'debugger="A debugger"').
	self assert: (contentText includesSubstring: 'Careful.').
	"The warnings are read out above the payload, so the payload does not name them again."
	self deny: (contentText includesSubstring: 'warnings')
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testEntryFieldQuotingEscapesEmbeddedQuotes [

	| contentText entry |
	entry := Dictionary new
		         at: #label put: 'says "hi" there';
		         at: #name put: 'Plain';
		         yourself.
	contentText := MCPToolGetClass new contentTextForStructuredContent: (Dictionary new
		               at: #summary put: 'Summary.';
		               at: #data put: (Dictionary new
				                at: #entries put: { entry };
				                yourself);
		               yourself).
	self assert: (contentText includesSubstring: 'label="says \"hi\" there"').
	self assert: (contentText includesSubstring: 'name=Plain')
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testEntryFieldsWithSeparatorsAreQuoted [

	| contentText result |
	result := self callToolNamed: 'method_search' withArguments: {
		          (#protocol -> 'meta filtering').
		          (self searchScope: { (#classes -> #( 'MCPToolMethodSearchTestTarget' )) } side: 'class') } asDictionary.
	contentText := (result at: #content) first at: #text.
	self deny: (self resultIndicatesError: result).
	self assert: (contentText includesSubstring: 'protocol="meta filtering"')
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testEvaluateReturnsStructuredError [

	| result structured error |
	result := self callToolNamed: 'image_evaluate' withArguments: { (#code -> '1 +') } asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #errorClass) equals: self expectedSyntaxErrorNoticeClassName.
	self assert: ((error at: #message) includesSubstring: 'expected')
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testEvaluateReturnsStructuredRuntimeErrorWithStackTrace [

	| error result stackTrace |
	result := self callToolNamed: 'image_evaluate' withArguments: { (#code -> 'Error signal: ''boom''') } asDictionary.
	error := self errorFrom: result.
	stackTrace := error at: #stackTrace.
	self assert: (result at: #isError).
	self assert: (error at: #errorClass) equals: 'Error'.
	self assert: ((error at: #message) includesSubstring: 'boom').
	self assert: (error includesKey: #signalerContext).
	self assert: stackTrace class equals: Array.
	self deny: stackTrace isEmpty.
	self assert: (stackTrace first beginsWith: (error at: #signalerContext))
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testEvaluateReturnsStructuredSuccess [

	| result data structured |
	result := self callToolNamed: 'image_evaluate' withArguments: { (#code -> '1 + 2') } asDictionary.
	structured := self structuredContentFrom: result.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #resultClassName) equals: 'SmallInteger'.
	self assert: (data at: #resultPrintString) equals: '3'
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testGetClassParseErrorReturnsStructuredToolError [

	| error result structured |
	result := self callToolNamed: 'class_get' withArguments: { (#name -> '') } asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #errorClass) equals: #Error.
	self assert: (error at: #class) equals: ''.
	self assert: ((error at: #message) includesSubstring: 'name must be a non-empty string')
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testGetClassReturnsStructuredError [

	| contentText error result structured |
	result := self callToolNamed: 'class_get' withArguments: { (#name -> 'MCPToolGetClassDefinitelyMissing') } asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	contentText := (result at: #content) first at: #text.
	self assert: (result at: #isError).
	self deny: (structured includesKey: #warnings).
	self assert: (contentText includesSubstring: (structured at: #summary)).
	self deny: (contentText includesSubstring: '"errorCode"').
	self assert: (self warningsFrom: result) equals: #(  ).
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'ClassNotFound'.
	self assert: (error at: #class) equals: 'MCPToolGetClassDefinitelyMissing'
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testGetClassReturnsStructuredSuccess [

	| contentText data expectedSharedVariableNames result structured |
	result := self callToolNamed: 'class_get' withArguments: { (#name -> 'MCPToolGetMethodTestTarget') } asDictionary.
	structured := self structuredContentFrom: result.
	data := self dataFrom: result.
	contentText := (result at: #content) first at: #text.
	expectedSharedVariableNames := (MCPToolGetMethodTestTarget classVarNames collect: [ :each | each asString ]) asArray.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self deny: (structured includesKey: #warnings).
	self assert: (contentText includesSubstring: (structured at: #summary)).
	self deny: (contentText includesSubstring: 'class: MCPToolGetMethodTestTarget').
	self assert: (self warningsFrom: result) equals: #(  ).
	self assert: (data at: #class) equals: 'MCPToolGetMethodTestTarget'.
	self assert: (data at: #methods) equals: 1.
	self assert: (data at: #classMethods) equals: 1.
	self assert: (data at: #sharedVariables) equals: expectedSharedVariableNames.
	self assert: (data includesKey: #layout).
	self deny: (data includesKey: #traitComposition).
	self deny: (data includesKey: #classTraitComposition).
	self deny: (data includesKey: #comment).
	self deny: (data includesKey: #superclasses).
	self deny: (data includesKey: #subclasses)
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testGetMethodReturnsStructuredError [

	| error result structured |
	result := self callToolNamed: 'method_get' withArguments: {
			          (#class -> 'MCPToolGetMethodTestTarget').
			          (#selector -> 'doesNotExist') } asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'MethodNotFound'.
	self assert: (error at: #class) equals: 'MCPToolGetMethodTestTarget'.
	self assert: (error at: #selector) equals: 'doesNotExist'.
	self assert: (error includesKey: #side).
	self assert: (error at: #side) equals: 'instance'
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testGetMethodReturnsStructuredSuccess [

	| data result |
	result := self callToolNamed: 'method_get' withArguments: {
			          (#class -> 'MCPToolGetMethodTestTarget').
			          (#selector -> 'readInstanceWith:') } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self deny: (self resultIndicatesError: result).
	self assert: (data at: #protocol) equals: 'reading'.
	self deny: (data includesKey: #variableReferences).
	self deny: (data includesKey: #class).
	self deny: (data includesKey: #selector).
	self deny: (data includesKey: #side).
	self deny: (data includesKey: #arguments).
	self deny: (data includesKey: #temporaryNames).
	self deny: (data includesKey: #variableDetailsIncluded).
	self deny: (data includesKey: #externalVariableCount).
	self deny: (data includesKey: #variableReferenceCount).
	self deny: (data includesKey: #externalVariableReferences).
	self assert: ((data at: #source) includesSubstring: String cr asString)
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testMethodMetadataSearchReturnsStructuredArrayData [

	| data methods result selectors |
	result := self
		          callToolNamed: 'method_search'
		          withArguments: { (self searchScope: { (#classes -> #( 'MCPToolMethodSearchTestTarget' )) }) } asDictionary.
	data := self dataFrom: result.
	methods := data at: #methods.
	selectors := methods collect: [ :each | each at: #selector ].
	self deny: (self resultIndicatesError: result).
	self assert: methods notEmpty.
	self assert: (methods allSatisfy: [ :each |
			 (each includesKey: #selector) and: [ (each includesKey: #class) and: [ each includesKey: #package ] ] ]).
	self assert: (selectors includes: 'alphaNeedleSelector')
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testMethodMetadataSearchReturnsStructuredWarnings [

	| data result structured warnings |
	result := self
		          callToolNamed: 'method_search'
		          withArguments: { (self searchScope: { (#packages -> #( 'MCP-Definitely-Missing' )) }) } asDictionary.
	structured := self structuredContentFrom: result.
	data := self dataFrom: result.
	warnings := self warningsFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (structured includesKey: #error) not.
	self assert: (data at: #methods) isEmpty.
	self assert: warnings size equals: 1.
	self assert: (warnings first includesSubstring: 'MCP-Definitely-Missing').
	self assert: (warnings first includesSubstring: 'packages scope').
	self assert: (warnings first includesSubstring: 'Did you mean:')
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testMethodRecordsReadAsMethodReferences [

	| contentText result |
	result := self callToolNamed: 'method_search' withArguments: {
		          (self searchScope: { (#classes -> #( 'MCPToolMethodSearchTestTarget' )) }) } asDictionary.
	contentText := (result at: #content) first at: #text.
	self deny: (self resultIndicatesError: result).
	self assert: (contentText includesSubstring: 'MCPToolMethodSearchTestTarget>>alphaNeedleSelector').
	self assert: (contentText includesSubstring: 'MCPToolMethodSearchTestTarget class>>classNeedleSelector').
	self deny: (contentText includesSubstring: 'className=').
	self deny: (contentText includesSubstring: 'classSide=')
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testRecordListsCarryTheirLabel [

	| contentText lines result |
	result := self callToolNamed: 'class_get' withArguments: {
		          (#name -> 'MCPToolMutation').
		          (#subclassDepth -> 1).
		          (#upToSuperclass -> 'Object') } asDictionary.
	contentText := (result at: #content) first at: #text.
	lines := contentText lines.
	self deny: (self resultIndicatesError: result).
	self assert: (lines includes: 'subclasses:').
	self assert: (lines includes: 'superclasses:').
	self assert: (lines indexOf: 'subclasses:') < (lines indexOf: 'superclasses:').
	self assert: ((lines indexOf: 'className: MCPToolMutation') < (lines indexOf: 'subclasses:'))
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testRemoveClassReturnsStructuredError [

	| result structured error |
	result := self callToolNamed: 'class_remove' withArguments: { (#name -> { 'MCPToolRemoveClassDefinitelyMissing' }) } asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'ClassNotFound'.
	self assert: (error at: #class) equals: 'MCPToolRemoveClassDefinitelyMissing'
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testRunTestClassReturnsStructuredIssues [

	| data error errorReference failure failureReference fixtureClassName result skipped skippedReference |
	fixtureClassName := MCPToolStructuredOutputTestTarget name asString.
	skippedReference := self testReferenceForMethod: MCPToolStructuredOutputTestTarget >> #testSkips.
	failureReference := self testReferenceForMethod: MCPToolStructuredOutputTestTarget >> #testFails.
	errorReference := self testReferenceForMethod: MCPToolStructuredOutputTestTarget >> #testErrors.
	result := self callToolNamed: 'test_run' withArguments: { (#classes -> { fixtureClassName }) } asDictionary.
	data := self dataFrom: result.
	self deny: (self resultIndicatesError: result).
	self assert: (data at: #runCount) equals: 3.
	self assert: (data at: #passedCount) equals: 1.
	skipped := data at: #skipped.
	failure := (data at: #failures) first.
	error := (data at: #errors) first.
	self assert: skipped equals: { skippedReference }.
	self assert: (failure at: #test) equals: failureReference.
	self assert: ((failure at: #message) includesSubstring: 'boom failure').
	self assert: (error at: #test) equals: errorReference.
	self assert: (error at: #errorClass) equals: 'Error'.
	self assert: ((error at: #message) includesSubstring: 'boom error').
	self deny: (data includesKey: #results).
	self deny: (data includesKey: #issues)
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testRunTestCoverageLetsNotificationsUseTheirDefaultAction [

	| data result |
	result := self callToolNamed: 'test_coverage_run' withArguments: {
			  (#classes -> { MCPToolNotificationTargetTest name }).
			  (#coverage -> { (#scope -> { (#classes -> { MCPToolCoverageTarget name }) } asDictionary) } asDictionary) } asDictionary.
	data := self dataFrom: result.
	self assert: (data at: #runCount) equals: 1.
	self assert: (data at: #passedCount) equals: 1
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testRunTestMethodReturnsStructuredIssues [

	| data failure failureReference result |
	failureReference := self testReferenceForMethod: MCPToolStructuredOutputTestTarget >> #testFails.
	result := self callToolNamed: 'test_run' withArguments: { (#methods -> { failureReference }) } asDictionary.
	data := self dataFrom: result.
	failure := (data at: #failures) first.
	self deny: (self resultIndicatesError: result).
	self assert: (data at: #runCount) equals: 1.
	self assert: (data at: #passedCount) equals: 0.
	self assert: (data at: #failures) size equals: 1.
	self assert: (failure at: #test) equals: failureReference.
	self assert: ((failure at: #message) includesSubstring: 'boom failure').
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
				           (#scope -> { (#classes -> #( 'MCPToolCoverageTarget' )) } asDictionary).
				           (#includeCoveredMethods -> true).
				           (#methodLimit -> 1) } asDictionary) } asDictionary.
	data := self dataFrom: result.
	coverage := data at: #coverage.
	coveredSelectors := (coverage at: #coveredMethods) collect: [ :each | each at: #selector ].
	self deny: (self resultIndicatesError: result).
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
	self assert: (self resultIndicatesError: result).
	self assert: (error at: #errorCode) equals: 'CoverageScopeRequired'.
	self assert: ((error at: #message) includesSubstring: 'explicit method scope')
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testRunTestsCoverageReturnsStructuredCoverage [

	| coverage data partialSelectors result uncoveredSelectors |
	result := self callToolNamed: 'test_coverage_run' withArguments: {
			          (#classes -> #( 'MCPToolCoverageTargetTest' )).
			          (#coverage -> {
				           (#scope -> { (#classes -> #( 'MCPToolCoverageTarget' )) } asDictionary).
				           (#methodLimit -> 10) } asDictionary) } asDictionary.
	data := self dataFrom: result.
	coverage := data at: #coverage.
	uncoveredSelectors := (coverage at: #uncoveredMethods) collect: [ :each | each at: #selector ].
	partialSelectors := (coverage at: #partiallyCoveredMethods) collect: [ :each | each at: #selector ].
	self deny: (self resultIndicatesError: result).
	self assert: ((self summaryFrom: result) includesSubstring: 'Coverage:').
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

	| data failureReference fixtureClassName result |
	fixtureClassName := MCPToolStructuredOutputTestTarget name asString.
	failureReference := self testReferenceForMethod: MCPToolStructuredOutputTestTarget >> #testFails.
	result := self callToolNamed: 'test_run' withArguments: {
			          (#classes -> { fixtureClassName }).
			          (#methods -> { failureReference }) } asDictionary.
	data := self dataFrom: result.
	self deny: (self resultIndicatesError: result).
	self assert: (data at: #runCount) equals: 3.
	self assert: (data at: #passedCount) equals: 1.
	self assert: (data at: #skipped) size equals: 1.
	self assert: (data at: #failures) size equals: 1.
	self assert: (data at: #errors) size equals: 1
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testRunTestsDeduplicatesUnrunCasesAcrossSelections [

	| data failureReference fixtureClassName result |
	fixtureClassName := MCPToolStructuredOutputTestTarget name asString.
	failureReference := self testReferenceForMethod: MCPToolStructuredOutputTestTarget >> #testFails.
	result := self callToolNamed: 'test_run' withArguments: {
			          (#classes -> { fixtureClassName }).
			          (#methods -> { failureReference }).
			          (#timeoutSeconds -> 0) } asDictionary.
	data := self dataFrom: result.
	self deny: (self resultIndicatesError: result).
	self assert: (data at: #timedOut) equals: true.
	self assert: (data at: #runCount) equals: 0.
	self assert: (data at: #passedCount) equals: 0.
	self assert: (data at: #unrunClasses) equals: { fixtureClassName }.
	self deny: (data includesKey: #unrunMethods).
	self deny: (data includesKey: #results)
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testRunTestsLetsNotificationsUseTheirDefaultAction [

	| data result |
	result := self callToolNamed: 'test_run' withArguments: { (#classes -> { MCPToolNotificationTargetTest name }) } asDictionary.
	data := self dataFrom: result.
	self assert: (data at: #runCount) equals: 1.
	self assert: (data at: #passedCount) equals: 1
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testRunTestsParameterizedMethodFailureIncludesCaseDetails [

	| data issue result |
	result := self
		          callToolNamed: 'test_run'
		          withArguments: { (#methods -> #( 'MCPToolRunTestsParameterizedTarget>>#testFailsOnlyForUTF16' )) } asDictionary.
	data := self dataFrom: result.
	issue := (data at: #failures) first.
	self deny: (self resultIndicatesError: result).
	self assert: (data at: #runCount) equals: 3.
	self assert: (data at: #passedCount) equals: 2.
	self assert: (data at: #failures) size equals: 1.
	self assert: (issue at: #test) equals: 'MCPToolRunTestsParameterizedTarget>>#testFailsOnlyForUTF16'.
	self assert: (issue at: #parameters) equals: #( '#encoding->''UTF-16''' ).
	self assert: ((issue at: #message) includesSubstring: 'UTF-16').
	self deny: (issue includesKey: #testName).
	self deny: (issue includesKey: #testCaseName)
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testRunTestsParseErrorReturnsStructuredToolError [

	| error result structured |
	result := self callToolNamed: 'test_run' withArguments: { (#methods -> #( 'NotAMethodReference' )) } asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #errorClass) equals: #Error.
	self deny: (error includesKey: #tests).
	self assert: ((error at: #message) includesSubstring: 'Class>>#selector')
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testRunTestsSkippedMethodReportsCompactList [

	| data result skippedReference |
	skippedReference := self testReferenceForMethod: MCPToolStructuredOutputTestTarget >> #testSkips.
	result := self callToolNamed: 'test_run' withArguments: { (#methods -> { skippedReference }) } asDictionary.
	data := self dataFrom: result.
	self deny: (self resultIndicatesError: result).
	self assert: (data at: #runCount) equals: 0.
	self assert: (data at: #passedCount) equals: 0.
	self assert: (data at: #skipped) equals: { skippedReference }.
	self deny: (data includesKey: #failures).
	self deny: (data includesKey: #errors)
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testRunTestsSuccessfulResultHasExpectedShape [

	| data result testMethodReference |
	testMethodReference := self testReferenceForMethod: MCPToolStructuredOutputTestTarget >> #testPasses.
	result := self callToolNamed: 'test_run' withArguments: { (#methods -> { testMethodReference }) } asDictionary.
	data := self dataFrom: result.
	self deny: (self resultIndicatesError: result).
	self assert: data equals: {
			(#runCount -> 1).
			(#passedCount -> 1) } asDictionary
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testRunTestsTimeoutReturnsPartialResultsAndUnrunSelectionsCanResume [

	| data expectedRunCount request resumedData resumedResult result runTestsRequest tool |
	tool := MCPToolRunTests new.
	expectedRunCount := 1 + MCPToolCoverageTargetTest testSelectors size + MCPToolRunTestsPackageTarget testSelectors size.
	runTestsRequest := MCPRunTestsRequest new
		                   initializeTestRequests: {
				                   (MCPTestRunRequest className: MCPToolRunTestsTimeoutTarget name).
				                   (MCPTestRunRequest className: MCPToolCoverageTargetTest name).
				                   (MCPTestRunRequest packageName: 'MCP-Tests-RunResources') }
		                   timeoutMilliseconds: 100
		                   operation: 'run'
		                   coverageRequest: nil.
	result := (tool commandForRequest: runTestsRequest) execute.
	data := result asDictionary.
	self assert: (data at: #timedOut).
	self assert: (data at: #runCount) equals: 1.
	self assert: (data at: #passedCount) equals: 1.
	self assert: (data at: #unrunMethods) equals: { (MCPToolRunTestsTimeoutTarget name , '>>#testSlowPass') }.
	self assert: (data at: #unrunClasses) equals: { MCPToolCoverageTargetTest name }.
	self assert: (data at: #unrunPackages) equals: #( 'MCP-Tests-RunResources' ).
	request := Dictionary new
		           at: #methods put: (data at: #unrunMethods);
		           at: #classes put: (data at: #unrunClasses);
		           at: #packages put: (data at: #unrunPackages);
		           at: #timeoutSeconds put: 30;
		           yourself.
	resumedResult := self callToolNamed: 'test_run' withArguments: request.
	resumedData := self dataFrom: resumedResult.
	self deny: (self resultIndicatesError: resumedResult).
	self deny: (resumedData includesKey: #timedOut).
	self assert: (resumedData at: #passedCount) equals: (resumedData at: #runCount).
	self assert: (resumedData at: #runCount) equals: expectedRunCount
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testSearchClassesReturnsStructuredArrayData [

	| classNames classes data result |
	result := self
		          callToolNamed: 'class_search'
		          withArguments: { (self searchScope: { (#classes -> #( 'MCPToolContractsTest' )) }) } asDictionary.
	data := self dataFrom: result.
	classes := data at: #classes.
	classNames := classes collect: [ :each | each at: #class ].
	self deny: (self resultIndicatesError: result).
	self assert: classes size equals: 1.
	self assert: (classes allSatisfy: [ :each | (each includesKey: #class) and: [ each includesKey: #package ] ]).
	self assert: (classNames includes: 'MCPToolContractsTest')
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testSearchClassesReturnsStructuredWarnings [

	| data result structured warnings |
	result := self
		          callToolNamed: 'class_search'
		          withArguments: { (self searchScope: { (#packages -> #( 'MCP-Definitely-Missing' )) }) } asDictionary.
	structured := self structuredContentFrom: result.
	data := self dataFrom: result.
	warnings := self warningsFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (structured includesKey: #error) not.
	self assert: (data at: #classes) isEmpty.
	self assert: warnings size equals: 1.
	self assert: (warnings first includesSubstring: 'MCP-Definitely-Missing').
	self assert: (warnings first includesSubstring: 'packages scope').
	self assert: (warnings first includesSubstring: 'Did you mean:')
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testSearchPackagesDefaultsToImageScopeWhenScopePropertiesAreOmitted [

	| data packageNames packages result |
	result := self callToolNamed: 'package_search' withArguments: { (#packages -> #( 'MCP-Tests-Resources' )) } asDictionary.
	data := self dataFrom: result.
	packages := data at: #packages.
	packageNames := packages collect: [ :each | each at: #package ].
	self deny: (self resultIndicatesError: result).
	self assert: packages size equals: 1.
	self assert: packageNames equals: #( 'MCP-Tests-Resources' )
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testSearchPackagesReturnsStructuredArrayData [

	| data packageNames packages result |
	result := self
		          callToolNamed: 'package_search'
		          withArguments: { (#packages -> self packageSearchFixturePackageNames) } asDictionary.
	data := self dataFrom: result.
	packages := data at: #packages.
	packageNames := packages collect: [ :each | each at: #package ].
	self deny: (self resultIndicatesError: result).
	self assert: packages size equals: self packageSearchFixturePackageNames size.
	self assert: (packages allSatisfy: [ :each | (each includesKey: #package) and: [ each includesKey: #projects ] ]).
	self assert: packageNames equals: self packageSearchFixturePackageNames
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testSearchPackagesReturnsStructuredError [

	| result structured error |
	result := self callToolNamed: 'package_search' withArguments: { (#projects -> #( 'DefinitelyMissingProject' )) } asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #project) equals: 'DefinitelyMissingProject'.
	self assert: (error at: #scope) equals: 'projects'.
	self assert: ((error at: #message) includesSubstring: 'Project DefinitelyMissingProject does not exist.')
]

{ #category : 'tests' }
MCPToolStructuredOutputTest >> testToolsListAdvertisesToolContracts [

	| tools |
	tools := MCP new rpcToolsList at: #tools.
	self assert: tools notEmpty.
	tools do: [ :tool | self assert: tool keys asSet equals: #( name title description annotations inputSchema ) asSet ]
]
