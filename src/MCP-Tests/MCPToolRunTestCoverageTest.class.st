"
Coverage through the public tool, on every supported runtime, with cleanup and test-runner contracts preserved.
"
Class {
	#name : 'MCPToolRunTestCoverageTest',
	#superclass : 'MCPToolAPITestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'private' }
MCPToolRunTestCoverageTest >> arguments [

	^ {
		  (#classes -> #( 'MCPToolCoverageTargetTest' )).
		  (#coverage -> { (#scope -> { (#classes -> #( 'MCPToolCoverageTarget' )) } asDictionary) } asDictionary) } asDictionary
]

{ #category : 'private' }
MCPToolRunTestCoverageTest >> assertNoCoverageLinks [

	{
		(self classNamed: 'MCPToolCoverageTarget').
		(self classNamed: 'MCPToolCoverageTarget') classSide } do: [ :behavior |
		behavior methods do: [ :method | method ast nodesDo: [ :node | self assert: node links isEmptyOrNil ] ] ]
]

{ #category : 'private' }
MCPToolRunTestCoverageTest >> runCoverage: arguments [

	^ self callToolNamed: 'test_coverage_run' withArguments: arguments
]

{ #category : 'tests' }
MCPToolRunTestCoverageTest >> testAnotherCollectorsLinksAndAnnotationsSurvive [

	| ast link arguments |
	ast := ((self classNamed: 'MCPToolCoverageTarget') >> #coveredMethod) ast.
	link := MetaLink new
		        metaObject: #node;
		        selector: #tagExecuted;
		        yourself.
	[
		ast link: link.
		(self classNamed: 'MCPToolCoverageTarget') new coveredMethod.
		self assert: ast hasBeenExecuted.
		arguments := self arguments.
		self dataFrom: (self runCoverage: arguments).
		self assert: (ast links includes: link).
		self assert: ast hasBeenExecuted ] ensure: [
			link uninstall.
			ast removeProperty: #tagExecuted ifAbsent: [ ] ]
]

{ #category : 'tests' }
MCPToolRunTestCoverageTest >> testCleanupCannotChangeTheCoverageSnapshot [

	| method result recorder |
	method := (self classNamed: 'MCPToolCoverageTarget') >> #coveredMethod.
	result := MCPTestCoverageResult new
		          methods: { method };
		          includeCoveredMethods: false;
		          methodLimit: 0;
		          yourself.
	recorder := result executedNodes.
	result finishWithTestResult: (MCPRunTestsResult outcomes: #(  ) timedOut: false unrunTests: #(  )).
	recorder
		add: method ast;
		add: method ast body.
	self assert: (result coverageDictionary at: #coveredMethodCount) equals: 0.
	self assert: (result coverageDictionary at: #coveredNodeCount) equals: 0
]

{ #category : 'tests' }
MCPToolRunTestCoverageTest >> testEmptyAndSideOnlyScopesAreRefused [

	{
		Dictionary new.
		{ (#side -> 'class') } asDictionary.
		{ (#classes -> #(  )) } asDictionary } do: [ :scope |
			| arguments result |
			arguments := self arguments.
			(arguments at: #coverage) at: #scope put: scope.
			result := self runCoverage: arguments.
			self assert: (self resultIndicatesError: result).
			self assert: ((self errorFrom: result) at: #errorCode) equals: 'CoverageScopeRequired' ].
	self assertNoCoverageLinks
]

{ #category : 'tests' }
MCPToolRunTestCoverageTest >> testExactCoverageAndRepeatedRuns [

	| arguments first second data coverage |
	arguments := self arguments.
	(arguments at: #coverage) at: #includeCoveredMethods put: true.
	first := self runCoverage: arguments.
	data := self dataFrom: first.
	self assert: (data at: #runCount) equals: 2.
	self assert: (data at: #passedCount) equals: 2.
	coverage := data at: #coverage.
	self assert: (coverage at: #methodCount) equals: 4.
	self assert: (coverage at: #coveredMethodCount) equals: 3.
	self assert: (coverage at: #fullyCoveredMethodCount) equals: 2.
	self assert: (coverage at: #partiallyCoveredMethodCount) equals: 1.
	self assert: (coverage at: #uncoveredMethodCount) equals: 1.
	self assert: (coverage at: #nodeCount) equals: 6.
	self assert: (coverage at: #coveredNodeCount) equals: 4.
	self assert: ((coverage at: #percentage) - (100.0 * 4 / 6)) abs < 0.001.
	self entryForReference: 'MCPToolCoverageTarget>>uncoveredMethod' in: (coverage at: #uncoveredMethods).
	self entryForReference: 'MCPToolCoverageTarget>>partiallyCoveredMethod:' in: (coverage at: #partiallyCoveredMethods).
	self entryForReference: 'MCPToolCoverageTarget class>>classCoveredMethod' in: (coverage at: #coveredMethods).
	second := self runCoverage: arguments.
	self assert: ((self dataFrom: second) at: #coverage) equals: coverage.
	self assertNoCoverageLinks
]

{ #category : 'tests' }
MCPToolRunTestCoverageTest >> testHierarchyScopeUsesTheSharedResolver [

	| tool arguments query |
	tool := MCPToolRunTestCoverage new.
	arguments := self arguments.
	(arguments at: #coverage) at: #scope put: {
			(#hierarchyOf -> #( 'MCPToolCoverageTarget' )).
			(#side -> 'instance') } asDictionary.
	query := tool coverageScopeFrom: (tool requestFromToolCallArguments: arguments).
	self assert: query hierarchyClassNames equals: #( 'MCPToolCoverageTarget' ).
	self assert: query side equals: 'instance'
]

{ #category : 'tests' }
MCPToolRunTestCoverageTest >> testInterruptedTestRetainsItsCoverageAndRemovesInstrumentation [

	| arguments result data |
	arguments := self arguments.
	arguments at: #classes put: #( 'MCPToolCoverageSlowTargetTest' ).
	arguments at: #timeoutSeconds put: 1.
	result := self runCoverage: arguments.
	data := self dataFrom: result.
	self assert: (data at: #timedOut).
	self assert: (data at: #runCount) equals: 0.
	self assert: (data at: #notRunCount) equals: 1.
	self assert: ((data at: #coverage) at: #coveredMethodCount) equals: 1.
	self assert: ((data at: #coverage) at: #coveredNodeCount) equals: 1.
	self assert: ((self summaryFrom: result) includesSubstring: 'Sequence coverage so far:').
	self assertNoCoverageLinks
]

{ #category : 'tests' }
MCPToolRunTestCoverageTest >> testMethodSelectionAndListLimits [

	| arguments coverage |
	arguments := self arguments.
	arguments removeKey: #classes.
	arguments at: #methods put: #( 'MCPToolCoverageTargetTest>>testCoveredMethod' ).
	(arguments at: #coverage) at: #methodLimit put: 0.
	coverage := (self dataFrom: (self runCoverage: arguments)) at: #coverage.
	self assert: (coverage at: #coveredMethodCount) equals: 2.
	self assert: (coverage at: #uncoveredMethodCount) equals: 2.
	self assert: (coverage at: #uncoveredMethods) isEmpty.
	self assert: (coverage at: #uncoveredMethodsTruncated).
	self deny: (coverage includesKey: #coveredMethods)
]

{ #category : 'tests' }
MCPToolRunTestCoverageTest >> testMissingScopeWarnsAndHasNoPercentage [

	| arguments result data |
	arguments := self arguments.
	((arguments at: #coverage) at: #scope) at: #classes put: #( 'MCPMissingCoverageClass' ).
	result := self runCoverage: arguments.
	data := self dataFrom: result.
	self assert: ((data at: #coverage) at: #methodCount) equals: 0.
	self assert: ((data at: #coverage) at: #percentage) isNil.
	self assert: (self warningsFrom: result) isNotEmpty
]

{ #category : 'tests' }
MCPToolRunTestCoverageTest >> testNotificationsKeepTheNormalTestRunnerBehaviour [

	| arguments data |
	arguments := self arguments.
	arguments at: #classes put: #( 'MCPToolNotificationTargetTest' ).
	data := self dataFrom: (self runCoverage: arguments).
	self assert: (data at: #passedCount) equals: 1.
	self assertNoCoverageLinks
]

{ #category : 'tests' }
MCPToolRunTestCoverageTest >> testPharosOwnMethodsAreLeftOutWithAWarning [
	"Measured, the methods a coverage link runs through would stop the image, so they are left out and the answer says so. Another package's extension to IdentitySet, as Fuel has on Pharo 10, is that package's to measure."

	| command extensions arguments result coverage |
	command := MCPRunTestCoverageCommand new.
	extensions := IdentitySet methods , IdentitySet class methods reject: [ :each |
		              (command isInstrumentationMethod: each) or: [ command shouldIgnoreMethod: each ] ].
	arguments := self arguments.
	(arguments at: #coverage) at: #scope put: { (#classes -> #( 'IdentitySet' 'MCPToolCoverageTarget' )) } asDictionary.
	result := self runCoverage: arguments.
	coverage := (self dataFrom: result) at: #coverage.
	self assert: (coverage at: #methodCount) equals: 4 + extensions size.
	self assert: ((self warningsFrom: result) anySatisfy: [ :each | each includesSubstring: 'Did not measure' ]).
	self assertNoCoverageLinks
]

{ #category : 'tests' }
MCPToolRunTestCoverageTest >> testRunnerErrorRemovesInstrumentation [

	| operation |
	operation := MCPRunTestCoverageCommandFailing
		             selections: { (MCPTestSelectionSpec className: 'MCPToolCoverageTargetTest') }
		             timeoutMilliseconds: 1000.
	operation
		coverageScope: (MCPCompiledMethodScopeQuery new
				 classNames: #( 'MCPToolCoverageTarget' );
				 yourself);
		includeCoveredMethods: false;
		methodLimit: 0.
	self should: [ operation execute ] raise: Error.
	self assertNoCoverageLinks
]

{ #category : 'tests' }
MCPToolRunTestCoverageTest >> testSchemaRejectsMissingScopeAndInvalidLimits [

	| arguments |
	arguments := self arguments.
	(arguments at: #coverage) removeKey: #scope.
	self assert: (self resultIndicatesError: (self runCoverage: arguments)).
	#( -1 'wrong' ) do: [ :limit |
			arguments := self arguments.
			(arguments at: #coverage) at: #methodLimit put: limit.
			self assert: (self resultIndicatesError: (self runCoverage: arguments)) ].
	self assertNoCoverageLinks
]

{ #category : 'tests' }
MCPToolRunTestCoverageTest >> testScopeHonoursSide [

	| arguments scope coverage |
	arguments := self arguments.
	scope := {
		         (#classes -> #( 'MCPToolCoverageTarget' )).
		         (#side -> 'class') } asDictionary.
	(arguments at: #coverage) at: #scope put: scope.
	coverage := (self dataFrom: (self runCoverage: arguments)) at: #coverage.
	self assert: (coverage at: #methodCount) equals: 1.
	self assert: (coverage at: #percentage) equals: 100.0
]

{ #category : 'tests' }
MCPToolRunTestCoverageTest >> testTimeoutReturnsPartialCoverageAndCleansUp [

	| arguments result data |
	arguments := self arguments.
	arguments at: #timeoutSeconds put: 0.
	result := self runCoverage: arguments.
	data := self dataFrom: result.
	self assert: (data at: #timedOut).
	self assert: (data at: #runCount) equals: 0.
	self assert: (data at: #notRunCount) equals: 2.
	self assert: ((data at: #coverage) at: #coveredNodeCount) equals: 0.
	self assert: ((self summaryFrom: result) includesSubstring: 'Sequence coverage so far: 0.00%').
	self assertNoCoverageLinks
]
