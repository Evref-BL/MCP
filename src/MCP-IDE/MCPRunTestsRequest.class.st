"
Parsed request shared by test_run and test_coverage_run.

It stores compact test selections, timeout converted to milliseconds, and the internal operation selected by the concrete tool. Coverage requests are supplied by MCPToolRunTestCoverage.
"
Class {
	#name : 'MCPRunTestsRequest',
	#superclass : 'Object',
	#instVars : [
		'testRequests',
		'timeoutMilliseconds',
		'operation',
		'coverageRequest'
	],
	#category : 'MCP-IDE-Requests',
	#package : 'MCP-IDE',
	#tag : 'Requests'
}

{ #category : 'private - parsing' }
MCPRunTestsRequest class >> addClassNames: classNames to: requests [

	classNames do: [ :className | requests add: (MCPTestRunRequest className: className) ]
]

{ #category : 'private - parsing' }
MCPRunTestsRequest class >> addMethodReferences: methodReferences to: requests forTool: aTool [
	"A method is read in every form method_get reads one, and its side is dropped: test_run reads Foo class as Foo. Every entry that names no method is refused, all in one refusal."

	| violations |
	violations := OrderedCollection new.
	methodReferences do: [ :each |
			(MCPMethodReference fromString: each)
				ifNil: [ violations add: (self violationForMethodReference: each) ]
				ifNotNil: [ :reference | requests add: (MCPTestRunRequest className: reference className testMethodName: reference selector) ] ].
	violations ifNotEmpty: [ MCPInvalidToolInput signalForTool: aTool violations: violations ]
]

{ #category : 'private - parsing' }
MCPRunTestsRequest class >> addPackageNames: packageNames to: requests [

	packageNames do: [ :packageName | requests add: (MCPTestRunRequest packageName: packageName) ]
]

{ #category : 'instance creation' }
MCPRunTestsRequest class >> fromRequest: aRequest tool: aTool operation: operation [

	| coverageRequest |
	(#( 'run' 'coverage' ) includes: operation) ifFalse: [ Error signal: 'operation must be run or coverage.' ].
	coverageRequest := operation = 'coverage' ifTrue: [
			                   MCPTestCoverageRequest
				                   fromValue: (aRequest argumentNamed: 'coverage' ifAbsent: [ nil ])
				                   usingToolRequest: aRequest
				                   defaultMethodLimit: aTool defaultCoverageMethodLimit ].
	^ self new
		  initializeTestRequests: (self testRequestsFromToolRequest: aRequest)
		  timeoutMilliseconds: (self timeoutMillisecondsFromToolRequest: aRequest defaultSeconds: aTool defaultTimeoutSeconds)
		  operation: operation
		  coverageRequest: coverageRequest
]

{ #category : 'private - parsing' }
MCPRunTestsRequest class >> refuseEmptySelectionIn: request [
	"An argument that names nothing once blank values are dropped is named, the first of packages, classes and methods. With none given at all, the call names nothing to run."

	#( 'packages' 'classes' 'methods' ) do: [ :argumentName |
			(request argumentNamed: argumentName ifAbsent: [ nil ]) ifNotNil: [
				MCPInvalidToolInput signalEmptyArgumentNamed: argumentName forTool: request tool ] ].
	MCPInvalidToolInput signalForTool: request tool violations: { (MCPJSONSchemaViolation
			 path: #(  )
			 keyword: #selectionRequired
			 message: 'Name at least one package, class or method to run.'
			 expected: nil
			 actual: nil) }
]

{ #category : 'private - parsing' }
MCPRunTestsRequest class >> testRequestsFromToolRequest: request [
	"Every selection, in the order packages, classes, methods. The refusals answer like the schema's, in the request's tool's name."

	| classNames methodReferences packageNames requests |
	packageNames := request uniqueStringCollectionArgumentNamed: 'packages' default: #(  ).
	classNames := request uniqueStringCollectionArgumentNamed: 'classes' default: #(  ).
	methodReferences := request uniqueStringCollectionArgumentNamed: 'methods' default: #(  ).
	(packageNames isEmpty and: [ classNames isEmpty and: [ methodReferences isEmpty ] ]) ifTrue: [
		self refuseEmptySelectionIn: request ].
	requests := OrderedCollection new.
	self addPackageNames: packageNames to: requests.
	self addClassNames: classNames to: requests.
	self addMethodReferences: methodReferences to: requests forTool: request tool.
	^ requests asArray
]

{ #category : 'private - parsing' }
MCPRunTestsRequest class >> timeoutMillisecondsFromToolRequest: request defaultSeconds: defaultSeconds [

	^ (request nonNegativeIntegerArgumentNamed: 'timeoutSeconds' default: defaultSeconds) * 1000
]

{ #category : 'private - parsing' }
MCPRunTestsRequest class >> violationForMethodReference: aString [

	^ MCPJSONSchemaViolation
		  path: #( 'methods' )
		  keyword: #methodReference
		  message: aString , ' is not a method reference; write it as Class>>#selector.'
		  expected: nil
		  actual: aString
]

{ #category : 'accessing' }
MCPRunTestsRequest >> coverageRequest [

	^ coverageRequest
]

{ #category : 'initialization' }
MCPRunTestsRequest >> initializeTestRequests: aCollection timeoutMilliseconds: anInteger [

	^ self
		  initializeTestRequests: aCollection
		  timeoutMilliseconds: anInteger
		  operation: 'run'
		  coverageRequest: nil
]

{ #category : 'initialization' }
MCPRunTestsRequest >> initializeTestRequests: aCollection timeoutMilliseconds: anInteger operation: operationString coverageRequest: aCoverageRequest [

	testRequests := aCollection.
	timeoutMilliseconds := anInteger.
	operation := operationString ifNil: [ 'run' ].
	coverageRequest := aCoverageRequest.
	^ self
]

{ #category : 'testing' }
MCPRunTestsRequest >> isCoverageOperation [

	^ self operation = 'coverage'
]

{ #category : 'accessing' }
MCPRunTestsRequest >> operation [

	^ operation ifNil: [ 'run' ]
]

{ #category : 'accessing' }
MCPRunTestsRequest >> testRequests [

	^ testRequests
]

{ #category : 'accessing' }
MCPRunTestsRequest >> timeoutMilliseconds [

	^ timeoutMilliseconds
]
