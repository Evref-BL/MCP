"
Command that validates and runs parsed test_run selections.

It resolves MCPTestRunRequest objects to MCPValidatedTestRunRequest objects, executes them, and returns MCPRunTestsResult DTOs.
"
Class {
	#name : 'MCPRunTestsCommand',
	#superclass : 'MCPToolRequestCommand',
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
	#tag : 'Commands'
}

{ #category : 'private' }
MCPRunTestsCommand >> addTestCasesFrom: aTestOrSuite to: testCases [

	aTestOrSuite mcpAddTestCasesTo: testCases using: self
]

{ #category : 'private' }
MCPRunTestsCommand >> aggregateDataForResults: resultEntries timedOut: timedOut unrunTests: unrunTests [

	^ MCPRunTestsResult results: resultEntries timedOut: timedOut unrunTests: unrunTests
]

{ #category : 'private - coverage' }
MCPRunTestsCommand >> coverableMethodsForCoverageRequest: aCoverageRequest [

	^ (aCoverageRequest scopeQuery methods reject: [ :method | self shouldIgnoreMethodForCoverage: method ]) asArray
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

	| deadline validatedRequests |
	validatedRequests := self validatedRequestsFrom: request testRequests.
	deadline := self deadlineForTimeoutMilliseconds: request timeoutMilliseconds.
	^ request isCoverageOperation
		  ifTrue: [ self runCoverageForValidatedRequests: validatedRequests deadline: deadline ]
		  ifFalse: [ self runValidatedRequests: validatedRequests deadline: deadline ]
]

{ #category : 'private - coverage' }
MCPRunTestsCommand >> hasAllSequenceNodesCoveredIn: aCompiledMethod [

	aCompiledMethod ast nodesDo: [ :node | node isSequence ifTrue: [ node hasBeenExecuted ifFalse: [ ^ false ] ] ].
	^ true
]

{ #category : 'private - timeout' }
MCPRunTestsCommand >> hasTimedOutAt: deadline [

	^ (self millisecondsRemainingUntil: deadline) <= 0
]

{ #category : 'private - timeout' }
MCPRunTestsCommand >> millisecondsRemainingUntil: deadline [

	^ 0 max: deadline - Time millisecondClockValue
]

{ #category : 'private - coverage' }
MCPRunTestsCommand >> partiallyCoveredMethodsFromCoverageResult: coverageResult [

	^ (coverageResult methods select: [ :method | (self hasAllSequenceNodesCoveredIn: method) not ]) asArray
]

{ #category : 'private - validation' }
MCPRunTestsCommand >> referringTestClassLimit [
	"Enough referring test classes to pass back, few enough to read."

	^ 5
]

{ #category : 'private - validation' }
MCPRunTestsCommand >> refusalOfSelection: validatedRequest referringByClass: referringByClass [
	"Nil for a selection that holds tests, or a package; else its sentence and its entry. A test class whose suite holds no case of the method is refused, and so is any class that is not a test class."

	| entry referring selection testClass |
	validatedRequest isPackageRequest ifTrue: [ ^ nil ].
	testClass := validatedRequest testClass.
	selection := self selectionTextOf: validatedRequest.
	entry := Dictionary new.
	entry at: #selection put: selection.
	entry at: #class put: testClass name asString.
	testClass isTestCase ifTrue: [
			validatedRequest hasTestMethod ifFalse: [ ^ nil ].
			(self testCasesForValidatedRequest: validatedRequest) ifNotEmpty: [ ^ nil ].
			^ (self textForMethod: selection notATestOf: testClass name) -> entry ].
	referring := referringByClass
		             at: testClass
		             ifAbsentPut: [
		             (MCPClassReferenceQuery forClass: testClass) referringTestClasses collect: [ :each | each key name asString ] ].
	(referring first: (referring size min: self referringTestClassLimit)) ifNotEmpty: [ :said | entry at: #testClasses put: said ].
	entry at: #testClassCount put: referring size.
	^ (String streamContents: [ :stream |
			   validatedRequest hasTestMethod ifTrue: [ stream << selection << ' is not a test: ' ].
			   stream << (self textForClassNamed: testClass name notATestClassReferredBy: referring) ]) -> entry
]

{ #category : 'private - validation' }
MCPRunTestsCommand >> refuseSelectionsThatAreNotTests: validatedRequests [
	"One sentence per selection that is no test, in selection order. A class that is no test class names the test classes that refer to it, found once per class."

	| refusals referringByClass |
	referringByClass := IdentityDictionary new.
	refusals := OrderedCollection new.
	validatedRequests do: [ :each |
		(self refusalOfSelection: each referringByClass: referringByClass) ifNotNil: [ :refusal | refusals add: refusal ] ].
	refusals ifEmpty: [ ^ self ].
	MCPCommandError
		signalErrorCode: ((refusals anySatisfy: [ :each | each value includesKey: #testClassCount ])
				 ifTrue: [ #NotATestClass ]
				 ifFalse: [ #NotATest ])
		message: (' ' join: (refusals collect: [ :each | each key ]))
		details: { (#notTests -> (refusals collect: [ :each | each value ] as: Array)) } asDictionary
]

{ #category : 'private - validation' }
MCPRunTestsCommand >> resolvedRequestFor: aTestRequest [
	"A method is looked up as its class answers it, so a test the class inherits is found."

	| testClass |
	aTestRequest isPackageRequest ifTrue: [
			MCPImageLookup packageNamed: aTestRequest packageName.
			^ MCPValidatedTestRunRequest request: aTestRequest testClass: nil ].
	testClass := MCPImageLookup classNamed: aTestRequest className.
	aTestRequest testMethodName ifNotNil: [ :selector |
		(testClass lookupSelector: selector asSymbol) ifNil: [ MCPCommandError signalMissingMethod: selector in: testClass ] ].
	^ MCPValidatedTestRunRequest request: aTestRequest testClass: testClass
]

{ #category : 'private' }
MCPRunTestsCommand >> resultForValidatedRequest: validatedRequest deadline: deadline seenTestCaseNames: seenTestCaseNames [

	| includeResult result resultInfo selectedTestCount testCases timedOutIndex unrunTestRequests |
	testCases := self uniqueTestCasesForValidatedRequest: validatedRequest seenTestCaseNames: seenTestCaseNames.
	selectedTestCount := testCases size.
	result := MCPStructuredTestResult new.
	timedOutIndex := nil.
	testCases doWithIndex: [ :testCase :index |
		timedOutIndex ifNil: [ (self runTestCase: testCase into: result deadline: deadline) ifTrue: [ timedOutIndex := index ] ] ].
	includeResult := self shouldIncludeTestResult: result selectedTestCount: selectedTestCount timedOutIndex: timedOutIndex.
	resultInfo := includeResult ifTrue: [
		              self testRunInfoForTestResult: result validatedRequest: validatedRequest selectedTestCount: selectedTestCount ].
	unrunTestRequests := timedOutIndex
		                     ifNil: [ #(  ) ]
		                     ifNotNil: [
		                     self unrunRequestsForValidatedRequest: validatedRequest testCases: testCases startingAt: timedOutIndex ].
	^ MCPTestRunResult resultInfo: resultInfo timedOut: timedOutIndex isNotNil unrunTestRequests: unrunTestRequests
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
				runResult := self runValidatedRequests: validatedRequests deadline: deadline.
				"Collect before resetting annotations so partial node coverage remains observable."
				collector remapMethods.
				coverageResult := collector basicCollectResult.
				partialMethods := self partiallyCoveredMethodsFromCoverageResult: coverageResult ] ] ensure: [ collector reset ].
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
					unrunTests := self unrunTestsFrom: validatedRequests startingAt: index seenTestCaseNames: seenTestCaseNames.
					^ self aggregateDataForResults: resultEntries timedOut: true unrunTests: unrunTests ].
			outcome := self
				           resultForValidatedRequest: (validatedRequests at: index)
				           deadline: deadline
				           seenTestCaseNames: seenTestCaseNames.
			outcome hasResult ifTrue: [ resultEntries add: outcome resultInfo ].
			outcome timedOut ifTrue: [
					unrunTests := OrderedCollection new.
					unrunTests addAll: outcome unrunTestRequests.
					unrunTests addAll: (self unrunTestsFrom: validatedRequests startingAt: index + 1 seenTestCaseNames: seenTestCaseNames).
					^ self aggregateDataForResults: resultEntries timedOut: true unrunTests: unrunTests ] ].
	^ self aggregateDataForResults: resultEntries timedOut: false unrunTests: #(  )
]

{ #category : 'private - validation' }
MCPRunTestsCommand >> selectionTextOf: validatedRequest [
	"A class or method selection as the refusal writes it, by the name of the class it resolved to."

	^ String streamContents: [ :stream |
			  stream << validatedRequest testClass name.
			  validatedRequest testMethodName ifNotNil: [ :selector | stream << '>>#' << selector ] ]
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
	^ aResult issueDetails isNotEmpty
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
MCPRunTestsCommand >> testCasesForPackageRequest: validatedRequest [

	^ Array streamContents: [ :stream |
			  (self testClassesInPackageNamed: validatedRequest packageName) do: [ :testClass |
				  (self testCasesFromSuite: testClass suite) do: [ :testCase | stream nextPut: testCase ] ] ]
]

{ #category : 'private' }
MCPRunTestsCommand >> testCasesForValidatedRequest: validatedRequest [

	| suite testCases testMethodSelector |
	validatedRequest isPackageRequest ifTrue: [ ^ self testCasesForPackageRequest: validatedRequest ].
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
MCPRunTestsCommand >> testClassesInPackageNamed: packageName [

	| package |
	package := MCPImageLookup packageNamed: packageName.
	^ (package definedClasses select: [ :each | each isTestCase and: [ each isAbstract not ] ]) asArray sort: [ :left :right |
		  left name <= right name ]
]

{ #category : 'private' }
MCPRunTestsCommand >> testRequestForTestCase: aTestCase [

	^ MCPTestRunRequest className: aTestCase class name asString testMethodName: aTestCase selector asString
]

{ #category : 'private' }
MCPRunTestsCommand >> testRequestsByClassForTestCases: testCases startingAt: startIndex [

	| firstClass requests seenClassNames |
	requests := OrderedCollection new.
	seenClassNames := Set new.
	firstClass := (testCases at: startIndex) class.
	startIndex to: testCases size do: [ :index |
			| className testCase |
			testCase := testCases at: index.
			className := testCase class name asString.
			testCase class = firstClass
				ifTrue: [ requests add: (self testRequestForTestCase: testCase) ]
				ifFalse: [
						(seenClassNames includes: className) ifFalse: [
								seenClassNames add: className.
								requests add: (MCPTestRunRequest className: className) ] ] ].
	^ requests asArray
]

{ #category : 'private' }
MCPRunTestsCommand >> testRequestsForTestCases: testCases startingAt: startIndex [

	| requests |
	requests := OrderedCollection new.
	startIndex to: testCases size do: [ :index | requests add: (self testRequestForTestCase: (testCases at: index)) ].
	^ requests asArray
]

{ #category : 'private - tests' }
MCPRunTestsCommand >> testRunInfoForTestResult: aResult validatedRequest: validatedRequest selectedTestCount: selectedTestCount [

	| issues |
	issues := (aResult issueDetails asArray sort: [ :left :right | (left at: #test) <= (right at: #test) ]) collect: [ :each |
			          | issue |
			          issue := each copy.
			          issue removeKey: #test ifAbsent: [ ].
			          issue ].
	^ MCPTestRunInfo
		  validatedRequest: validatedRequest
		  selectedTestCount: selectedTestCount
		  result: aResult
		  issues: issues
]

{ #category : 'private - validation' }
MCPRunTestsCommand >> textForClassNamed: aClassName notATestClassReferredBy: testClassNames [
	"testClassNames are all the test classes that refer to the class, most referring first. The first few are named, and the rest counted."

	| limit |
	limit := self referringTestClassLimit.
	^ String streamContents: [ :stream |
			  stream << aClassName << ' is not a test class'.
			  testClassNames ifEmpty: [ stream << ', and no test class refers to it' ] ifNotEmpty: [
					  stream << '. Test classes that refer to it: ' << (', ' join: (testClassNames first: (testClassNames size min: limit))).
					  testClassNames size > limit ifTrue: [ stream << ', and ' << (testClassNames size - limit) printString << ' more' ] ].
			  stream nextPut: $. ]
]

{ #category : 'private - validation' }
MCPRunTestsCommand >> textForMethod: aSelectionText notATestOf: aClassName [
	"The class's tests are the answer, so SUnit's rule for a test selector is not spelt out."

	^ String streamContents: [ :stream |
			  stream << aSelectionText << ' is not one of ' << aClassName
			  << '''s tests. Name one of its test methods, or the class to run them all.' ]
]

{ #category : 'private' }
MCPRunTestsCommand >> uniqueTestCasesForValidatedRequest: validatedRequest seenTestCaseNames: seenTestCaseNames [

	^ self uniqueTestCasesFrom: (self testCasesForValidatedRequest: validatedRequest) seenTestCaseNames: seenTestCaseNames
]

{ #category : 'private' }
MCPRunTestsCommand >> uniqueTestCasesFrom: testCases seenTestCaseNames: seenTestCaseNames [

	| uniqueTestCases |
	uniqueTestCases := OrderedCollection new.
	testCases do: [ :testCase |
			| testCaseName |
			testCaseName := self testCaseDeduplicationKeyFor: testCase.
			(seenTestCaseNames includes: testCaseName) ifFalse: [
					seenTestCaseNames add: testCaseName.
					uniqueTestCases add: testCase ] ].
	^ uniqueTestCases asArray
]

{ #category : 'private' }
MCPRunTestsCommand >> unrunRequestsForValidatedRequest: validatedRequest seenTestCaseNames: seenTestCaseNames [

	| testCases uniqueTestCases |
	testCases := self testCasesForValidatedRequest: validatedRequest.
	uniqueTestCases := self uniqueTestCasesFrom: testCases seenTestCaseNames: seenTestCaseNames.
	uniqueTestCases ifEmpty: [ ^ #(  ) ].
	(validatedRequest hasTestMethod not and: [ uniqueTestCases size = testCases size ]) ifTrue: [
		^ { validatedRequest testRunRequest } ].
	^ self testRequestsForTestCases: uniqueTestCases startingAt: 1
]

{ #category : 'private' }
MCPRunTestsCommand >> unrunRequestsForValidatedRequest: validatedRequest testCases: testCases startingAt: startIndex [

	validatedRequest isPackageRequest ifTrue: [ ^ self testRequestsByClassForTestCases: testCases startingAt: startIndex ].
	^ self testRequestsForTestCases: testCases startingAt: startIndex
]

{ #category : 'private' }
MCPRunTestsCommand >> unrunTestsFrom: validatedRequests startingAt: startIndex seenTestCaseNames: seenTestCaseNames [

	| unrun |
	unrun := OrderedCollection new.
	startIndex to: validatedRequests size do: [ :index |
		unrun addAll: (self unrunRequestsForValidatedRequest: (validatedRequests at: index) seenTestCaseNames: seenTestCaseNames) ].
	^ unrun asArray
]

{ #category : 'private - validation' }
MCPRunTestsCommand >> validatedRequestsFrom: testRequests [
	"Every name is resolved first, in the order the selections come, packages, classes, methods: the first that names nothing refuses the call alone, in the lookup's words. Then every selection that is no test is refused, all in one refusal. Either way nothing has run."

	| validatedRequests |
	validatedRequests := testRequests collect: [ :each | self resolvedRequestFor: each ].
	self refuseSelectionsThatAreNotTests: validatedRequests.
	^ validatedRequests
]
