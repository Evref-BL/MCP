"
Runs test classes or selected test methods and returns structured results. It is the testing bridge for the MCP server.
"
Class {
	#name : 'MCPToolRunTests',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'private' }
MCPToolRunTests >> aggregateDataForResults: resultEntries tests: testRequests [

	^ Dictionary new
		  at: #results put: resultEntries asArray;
		  yourself
]

{ #category : 'private' }
MCPToolRunTests >> compactTestNamesFrom: testRequests [

	^ (testRequests collect: [ :each |
		   each at: #testMethodName ifAbsent: [ each at: #className ] ])
		  asArray
]

{ #category : 'defaults' }
MCPToolRunTests >> defaultDescription [

	^ 'Run test classes or individual test methods as a batch and return aggregated results.'
]

{ #category : 'defaults' }
MCPToolRunTests >> defaultIcons [

	^ { (self pngIconNamed: #testRunner) }
]

{ #category : 'defaults' }
MCPToolRunTests >> defaultInputSchema [

	^ MCPStructureInputSchema new
		               type: 'object';
		               properties: { ((MCPStructureProperties new
				                 name: 'tests';
				                 type: 'array';
				                 description:
					                 'The test execution requests to run as a batch.')
				                items: self testRequestObjectSchema;
				                yourself) };
		               required: #( 'tests' );
		               yourself
]

{ #category : 'defaults' }
MCPToolRunTests >> defaultName [

	^ 'run-tests'
]

{ #category : 'defaults' }
MCPToolRunTests >> defaultOutputSchema [

	^ self
		  standardOutputSchemaForDataProperties: { ((self
				    schemaPropertyNamed: 'results'
				    type: 'array'
				    description:
					    'Structured results for each test execution request in the batch.')
				   items: self testResultObjectSchema;
				   yourself) }
		  required: #( 'results' )
]

{ #category : 'defaults' }
MCPToolRunTests >> defaultTitle [

	^ 'Run Pharo Tests'
]

{ #category : 'private' }
MCPToolRunTests >> errorResultForError: anError tests: testRequests [

	(anError isKindOf: MCPCommandError) ifTrue: [
		^ self
			  errorResultText: anError messageText
			  details: anError structuredDetails ].
	^ self
		  errorResultText:
		  (self failureMessageForTests: testRequests error: anError)
		  details: {
				  (#errorClass -> anError class name).
				  (#message -> anError messageText).
				  (#tests -> (self compactTestNamesFrom: testRequests)) }
				  asDictionary
]

{ #category : 'executing' }
MCPToolRunTests >> executeWithArguments: arguments [

	| data resultEntries testRequests validatedRequests |
	testRequests := #(  ).
	^ [
	  testRequests := self testRequestsFromArguments: arguments.
	  validatedRequests := self validatedRequestsFrom: testRequests.
	  resultEntries := validatedRequests collect: [ :each |
		                   self resultForValidatedRequest: each ].
	  data := self
		          aggregateDataForResults: resultEntries
		          tests: testRequests.
	  self
		  successResultText: (self successSummaryForData: data)
		  data: data ]
		  on: Exception
		  do: [ :error |
		  self errorResultForError: error tests: testRequests ]
]

{ #category : 'private' }
MCPToolRunTests >> failureMessageForTests: testRequests error: anError [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Unable to run tests: ';
			  nextPutAll: (', ' join: (testRequests collect: [ :each |
								    | className testMethodName |
								    className := each at: #className.
								    testMethodName := each
									                      at: #testMethodName
									                      ifAbsent: [ nil ].
								    testMethodName
									    ifNil: [ className ]
									    ifNotNil: [ className , '>>' , testMethodName ] ]));
			  nextPutAll: ' (';
			  nextPutAll: anError class name;
			  nextPutAll: '): ';
			  nextPutAll: anError messageText ]
]

{ #category : 'private' }
MCPToolRunTests >> resultForValidatedRequest: aDictionary [

	| request result suite testClass testMethodName |
	request := aDictionary at: #request.
	testClass := aDictionary at: #class.
	testMethodName := request at: #testMethodName ifAbsent: [ nil ].
	suite := self suiteForClass: testClass testMethodName: testMethodName.
	result := MCPStructuredTestResult new.
	suite run: result.
	^ self
		  structuredDataForTestResult: result
		  className: testClass name asString
		  testMethodName: testMethodName
]

{ #category : 'private' }
MCPToolRunTests >> successSummaryForData: data [

	| failureLikeCount results runCount selectionCount selectionWord |
	results := data at: #results.
	selectionCount := results size.
	selectionWord := selectionCount = 1
		                 ifTrue: [ 'test selection' ]
		                 ifFalse: [ 'test selections' ].
	runCount := results
		            inject: 0
		            into: [ :sum :each | sum + (each at: #runCount) ].
	failureLikeCount := results inject: 0 into: [ :sum :each |
		                    sum + ((each at: #issues) count: [ :issue |
			                     #( 'failure' 'error' ) includes:
				                     (issue at: #kind) ]) asInteger ].
	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Executed ';
			  nextPutAll: selectionCount asString;
			  nextPutAll: ' ';
			  nextPutAll: selectionWord;
			  nextPutAll: ' covering ';
			  nextPutAll: runCount asString;
			  nextPutAll: ' tests.'.
		  failureLikeCount > 0 ifTrue: [
			  stream
				  space;
				  nextPutAll: failureLikeCount asString;
				  nextPutAll: ' failures/errors were reported.' ] ]
]

{ #category : 'private' }
MCPToolRunTests >> suiteForClass: testClass testMethodName: testMethodName [

	testMethodName ifNil: [ ^ testClass suite ].
	^ (TestSuite named: testClass name asString)
		  addTest: (testClass selector: testMethodName asSymbol);
		  yourself
]

{ #category : 'private' }
MCPToolRunTests >> testRequestObjectSchema [

	^ MCPStructureProperties new
		  type: 'object';
		  description: 'A single test execution request in the batch.';
		  properties: {
				  (self
					   schemaPropertyNamed: 'className'
					   type: 'string'
					   description: 'The test class to run.').
				  (self
					   schemaPropertyNamed: 'testMethodName'
					   type: 'string'
					   description:
						   'The single test method to run. Omit this to run the full class suite.') };
		  required: #( 'className' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private' }
MCPToolRunTests >> testRequestsFromArguments: arguments [

	| normalized requests |
	requests := arguments at: #tests ifAbsent: [ #(  ) ].
	requests ifNil: [ requests := #(  ) ].
	normalized := OrderedCollection new.
	requests do: [ :each |
		| className request testMethodName |
		(each respondsTo: #at:ifAbsent:) ifFalse: [
			Error signal:
				'tests must contain only objects with className and optional testMethodName.' ].
		className := (each at: #className ifAbsent: [
			              each at: 'className' ifAbsent: [
				              Error signal:
					              'tests must contain only objects with className and optional testMethodName.' ] ])
			             asString trimBoth.
		className isEmpty ifTrue: [
			Error signal: 'tests must contain only non-empty class names.' ].
		testMethodName := each
			                  at: #testMethodName
			                  ifAbsent: [
			                  each at: 'testMethodName' ifAbsent: [ nil ] ].
		testMethodName ifNotNil: [
			testMethodName := testMethodName asString trimBoth.
			testMethodName isEmpty ifTrue: [ testMethodName := nil ] ].
		request := Dictionary new.
		request at: #className put: className.
		testMethodName ifNotNil: [
			request at: #testMethodName put: testMethodName ].
		normalized add: request ].
	normalized ifEmpty: [
		Error signal: 'tests must contain at least one test request.' ].
	^ normalized asArray
]

{ #category : 'private' }
MCPToolRunTests >> testResultObjectSchema [

	| properties |
	properties := OrderedCollection withAll:
		              (self standardTestDataPropertiesIncludingMethodName:
			               false).
	properties add: (self
			 schemaPropertyNamed: 'testMethodName'
			 type: 'string'
			 description:
			 'The single test method that was executed when the batch entry targeted one method.').
	^ MCPStructureProperties new
		  type: 'object';
		  description:
			  'Structured results for one test execution request in the batch.';
		  properties: properties asArray;
		  required:
			  (self standardTestRequiredFieldsIncludingMethodName: false);
		  additionalProperties: false;
		  yourself
]

{ #category : 'private' }
MCPToolRunTests >> validatedRequestsFrom: testRequests [

	^ testRequests collect: [ :each |
		  | className testClass testMethodName validated |
		  className := each at: #className.
		  testMethodName := each at: #testMethodName ifAbsent: [ nil ].
		  testClass := Smalltalk globals
			               at: className asSymbol
			               ifAbsent: [
			               MCPCommandError signalMissingClassNamed: className ].
		  testMethodName ifNotNil: [
			  testClass compiledMethodAt: testMethodName asSymbol ifAbsent: [
				  MCPCommandError
					  signalMissingMethodInClassName: className
					  classSide: false
					  selector: testMethodName ] ].
		  validated := Dictionary new.
		  validated at: #request put: each.
		  validated at: #class put: testClass.
		  validated yourself ]
]
