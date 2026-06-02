"
Command that validates and runs parsed test_run selections.

It resolves MCPTestRunRequest objects to MCPValidatedTestRunRequest objects, executes them, and returns MCPRunTestsResult DTOs.
"
Class {
	#name : 'MCPRunTestsCommand',
	#superclass : 'Object',
	#instVars : [
		'tool',
		'request'
	],
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPRunTestsCommand class >> tool: aTool request: aRequest [

	^ self new initializeTool: aTool request: aRequest
]

{ #category : 'private' }
MCPRunTestsCommand >> addTestCasesFrom: aTestOrSuite to: testCases [

	aTestOrSuite mcpAddTestCasesTo: testCases using: self
]

{ #category : 'private' }
MCPRunTestsCommand >> aggregateDataForResults: resultEntries timedOut: timedOut unrunTests: unrunTests [

	^ MCPRunTestsResult
		  results: resultEntries
		  timedOut: timedOut
		  unrunTests: unrunTests
]

{ #category : 'private - coverage' }
MCPRunTestsCommand >> coverableMethodsForCoverageRequest: aCoverageRequest [

	^ (aCoverageRequest scopeQuery methods reject: [ :method |
		   self shouldIgnoreMethodForCoverage: method ]) asArray
]

{ #category : 'private - coverage' }
MCPRunTestsCommand >> coverageCollectorClass [

	^ Smalltalk globals at: #CoverageCollector ifAbsent: [
		  MCPCommandError
			  signalErrorCode: #CoverageUnavailable
			  message: 'CoverageCollector is not available in this image.'
			  details: Dictionary new ]
]

{ #category : 'private - coverage' }
MCPRunTestsCommand >> coverageCollectorForMethods: methods [

	| collector |
	collector := self coverageCollectorClass new.
	collector methods: methods.
	^ collector
]

{ #category : 'private - timeout' }
MCPRunTestsCommand >> deadlineForTimeoutMilliseconds: timeoutMilliseconds [

	^ Time millisecondClockValue + timeoutMilliseconds
]

{ #category : 'executing' }
MCPRunTestsCommand >> execute [

	| deadline tracker validatedRequests |
	validatedRequests := self validatedRequestsFrom: request testRequests.
	deadline := self deadlineForTimeoutMilliseconds:
		            request timeoutMilliseconds.
	tracker := MCPImageCodeChangeTracker new.
	^ [
		  tracker trackDuring: [
				  request isCoverageOperation
					  ifTrue: [
							  self
								  runCoverageForValidatedRequests: validatedRequests
								  deadline: deadline ]
					  ifFalse: [
					  self runValidatedRequests: validatedRequests deadline: deadline ] ] ]
		  ensure: [
				  tracker hasChanges ifTrue: [
					  self refreshRegisteredRepositoryDirtyPackages ] ]
]

{ #category : 'private - coverage' }
MCPRunTestsCommand >> hasAllSequenceNodesCoveredIn: aCompiledMethod [

	aCompiledMethod ast nodesDo: [ :node |
		node isSequence ifTrue: [ node hasBeenExecuted ifFalse: [ ^ false ] ] ].
	^ true
]

{ #category : 'private - timeout' }
MCPRunTestsCommand >> hasTimedOutAt: deadline [

	^ (self millisecondsRemainingUntil: deadline) <= 0
]

{ #category : 'initialization' }
MCPRunTestsCommand >> initializeTool: aTool request: aRequest [

	tool := aTool.
	request := aRequest.
	^ self
]

{ #category : 'private - timeout' }
MCPRunTestsCommand >> millisecondsRemainingUntil: deadline [

	^ 0 max: deadline - Time millisecondClockValue
]

{ #category : 'private - coverage' }
MCPRunTestsCommand >> partiallyCoveredMethodsFromCoverageResult: coverageResult [

	^ (coverageResult methods select: [ :method |
		   (self hasAllSequenceNodesCoveredIn: method) not ]) asArray
]

{ #category : 'private' }
MCPRunTestsCommand >> refreshRegisteredRepositoryDirtyPackages [

	IceRepository registry do: [ :repository |
			repository isMissing ifFalse: [
				repository workingCopy refreshDirtyPackages ] ]
]

{ #category : 'accessing' }
MCPRunTestsCommand >> request [

	^ request
]

{ #category : 'private' }
MCPRunTestsCommand >> resultForValidatedRequest: validatedRequest deadline: deadline seenTestCaseNames: seenTestCaseNames [

	| includeResult result resultInfo selectedTestCount testCases timedOutIndex unrunTestRequests |
	testCases := self
		             uniqueTestCasesForValidatedRequest: validatedRequest
		             seenTestCaseNames: seenTestCaseNames.
	selectedTestCount := testCases size.
	result := MCPStructuredTestResult new.
	timedOutIndex := nil.
	testCases doWithIndex: [ :testCase :index |
			timedOutIndex ifNil: [
					(self runTestCase: testCase into: result deadline: deadline)
						ifTrue: [ timedOutIndex := index ] ] ].
	includeResult := self
		                 shouldIncludeTestResult: result
		                 selectedTestCount: selectedTestCount
		                 timedOutIndex: timedOutIndex.
	resultInfo := includeResult ifTrue: [
			              self
				              testRunInfoForTestResult: result
				              validatedRequest: validatedRequest
				              selectedTestCount: selectedTestCount ].
	unrunTestRequests := timedOutIndex
		                     ifNil: [ #(  ) ]
		                     ifNotNil: [
		                     self
			                     testRequestsForTestCases: testCases
			                     startingAt: timedOutIndex ].
	^ MCPTestRunResult
		  resultInfo: resultInfo
		  timedOut: timedOutIndex notNil
		  unrunTestRequests: unrunTestRequests
]

{ #category : 'private - coverage' }
MCPRunTestsCommand >> runCoverageForValidatedRequests: validatedRequests deadline: deadline [

	| collector coverageRequest coverageResult methods partialMethods runResult |
	coverageRequest := request coverageRequest.
	methods := self coverableMethodsForCoverageRequest: coverageRequest.
	collector := self coverageCollectorForMethods: methods.
	[
	collector installOn: [
		collector reset.
		runResult := self
			             runValidatedRequests: validatedRequests
			             deadline: deadline.
		"Collect before resetting annotations so partial node coverage remains observable."
		collector remapMethods.
		coverageResult := collector basicCollectResult.
		partialMethods := self partiallyCoveredMethodsFromCoverageResult:
			                  coverageResult ] ] ensure: [ collector reset ].
	runResult coverage: (MCPTestCoverageResult
			 coverageResult: coverageResult
			 includeCoveredMethods: coverageRequest includeCoveredMethods
			 methodLimit: coverageRequest methodLimit
			 partiallyCoveredMethods: partialMethods).
	^ runResult
]

{ #category : 'private - timeout' }
MCPRunTestsCommand >> runTestCase: aTestCase into: aResult deadline: deadline [

	| remaining |
	remaining := self millisecondsRemainingUntil: deadline.
	remaining <= 0 ifTrue: [ ^ true ].
	^ [
	  aTestCase run: aResult.
	  false ] valueWithinMilliseconds: remaining onTimeout: [ true ]
]

{ #category : 'private' }
MCPRunTestsCommand >> runValidatedRequests: validatedRequests deadline: deadline [

	| outcome resultEntries seenTestCaseNames unrunTests |
	resultEntries := OrderedCollection new.
	seenTestCaseNames := Set new.
	1 to: validatedRequests size do: [ :index |
			(self hasTimedOutAt: deadline) ifTrue: [
					unrunTests := self
						              unrunTestsFrom: validatedRequests
						              startingAt: index
						              seenTestCaseNames: seenTestCaseNames.
					^ self
						  aggregateDataForResults: resultEntries
						  timedOut: true
						  unrunTests: unrunTests ].
			outcome := self
				           resultForValidatedRequest:
				           (validatedRequests at: index)
				           deadline: deadline
				           seenTestCaseNames: seenTestCaseNames.
			outcome hasResult ifTrue: [ resultEntries add: outcome resultInfo ].
			outcome timedOut ifTrue: [
					unrunTests := OrderedCollection new.
					unrunTests addAll: outcome unrunTestRequests.
					unrunTests addAll: (self
							 unrunTestsFrom: validatedRequests
							 startingAt: index + 1
							 seenTestCaseNames: seenTestCaseNames).
					^ self
						  aggregateDataForResults: resultEntries
						  timedOut: true
						  unrunTests: unrunTests ] ].
	^ self
		  aggregateDataForResults: resultEntries
		  timedOut: false
		  unrunTests: #(  )
]

{ #category : 'private - coverage' }
MCPRunTestsCommand >> shouldIgnoreMethodForCoverage: aCompiledMethod [

	aCompiledMethod isTestMethod ifTrue: [ ^ true ].
	aCompiledMethod methodClass instanceSide isTestCase ifTrue: [ ^ true ].
	aCompiledMethod isAbstract ifTrue: [ ^ true ].
	^ aCompiledMethod hasPragmaNamed: #ignoreForCoverage
]

{ #category : 'private' }
MCPRunTestsCommand >> shouldIncludeTestResult: aResult selectedTestCount: selectedTestCount timedOutIndex: timedOutIndex [

	selectedTestCount isZero ifTrue: [ ^ false ].
	timedOutIndex ifNil: [ ^ true ].
	aResult runCount > 0 ifTrue: [ ^ true ].
	aResult skippedCount > 0 ifTrue: [ ^ true ].
	^ aResult issueDetails notEmpty
]

{ #category : 'private' }
MCPRunTestsCommand >> testCaseDeduplicationKeyFor: aTestCase [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: aTestCase class name;
				  nextPut: $/;
				  nextPutAll: aTestCase selector asString;
				  nextPut: $/;
				  nextPutAll: aTestCase nameForReport ]
]

{ #category : 'private' }
MCPRunTestsCommand >> testCasesForValidatedRequest: validatedRequest [

	| suite testCases testMethodSelector |
	suite := validatedRequest testClass suite.
	testCases := self testCasesFromSuite: suite.
	validatedRequest testMethodName ifNotNil: [ :testMethodName |
		testMethodSelector := testMethodName asSymbol.
		^ testCases select: [ :each | each selector = testMethodSelector ] ].
	^ testCases
]

{ #category : 'private' }
MCPRunTestsCommand >> testCasesFromSuite: aSuite [

	| testCases |
	testCases := OrderedCollection new.
	self addTestCasesFrom: aSuite to: testCases.
	^ testCases asArray
]

{ #category : 'private' }
MCPRunTestsCommand >> testRequestForTestCase: aTestCase [

	^ MCPTestRunRequest
		  className: aTestCase class name asString
		  testMethodName: aTestCase selector asString
]

{ #category : 'private' }
MCPRunTestsCommand >> testRequestsForTestCases: testCases startingAt: startIndex [

	| requests |
	requests := OrderedCollection new.
	startIndex to: testCases size do: [ :index |
		requests add: (self testRequestForTestCase: (testCases at: index)) ].
	^ requests asArray
]

{ #category : 'private - tests' }
MCPRunTestsCommand >> testRunInfoForTestResult: aResult validatedRequest: validatedRequest selectedTestCount: selectedTestCount [

	| issues |
	issues := (aResult issueDetails asSortedCollection: [ :left :right |
		           (left at: #testName) <= (right at: #testName) ])
		          collect: [ :each |
				          | issue |
				          issue := each copy.
				          issue removeKey: #testName ifAbsent: [ ].
				          issue ].
	^ MCPTestRunInfo
		  validatedRequest: validatedRequest
		  selectedTestCount: selectedTestCount
		  result: aResult
		  issues: issues asArray
]

{ #category : 'accessing' }
MCPRunTestsCommand >> tool [

	^ tool
]

{ #category : 'private' }
MCPRunTestsCommand >> uniqueTestCasesForValidatedRequest: validatedRequest seenTestCaseNames: seenTestCaseNames [

	| uniqueTestCases |
	uniqueTestCases := OrderedCollection new.
	(self testCasesForValidatedRequest: validatedRequest) do: [ :testCase |
			| testCaseName |
			testCaseName := self testCaseDeduplicationKeyFor: testCase.
			(seenTestCaseNames includes: testCaseName) ifFalse: [
					seenTestCaseNames add: testCaseName.
					uniqueTestCases add: testCase ] ].
	^ uniqueTestCases asArray
]

{ #category : 'private' }
MCPRunTestsCommand >> unrunTestsFrom: validatedRequests startingAt: startIndex seenTestCaseNames: seenTestCaseNames [

	| unrun |
	unrun := OrderedCollection new.
	startIndex to: validatedRequests size do: [ :index |
			unrun addAll: (self
					 testRequestsForTestCases: (self
							  uniqueTestCasesForValidatedRequest:
							  (validatedRequests at: index)
							  seenTestCaseNames: seenTestCaseNames)
					 startingAt: 1) ].
	^ unrun asArray
]

{ #category : 'private' }
MCPRunTestsCommand >> validatedRequestsFrom: testRequests [

	^ testRequests collect: [ :each |
		  | testClass |
		  testClass := MCPImageLookup classNamed: each className.
		  each testMethodName ifNotNil: [ :testMethodName |
			  testClass compiledMethodAt: testMethodName asSymbol ifAbsent: [
				  MCPCommandError
					  signalMissingMethodInClassName: each className
					  classSide: false
					  selector: testMethodName ] ].
		  MCPValidatedTestRunRequest request: each testClass: testClass ]
]
