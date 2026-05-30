"
Parsed coverage options for the test_run tool.

Coverage is deliberately scoped by method scope properties such as packageNames or classNames. The request also controls whether covered method details are included and how many method entries each coverage list may return.
"
Class {
	#name : 'MCPTestCoverageRequest',
	#superclass : 'Object',
	#instVars : [
		'scopeQuery',
		'includeCoveredMethods',
		'methodLimit'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPTestCoverageRequest class >> fromValue: rawValue usingToolRequest: toolRequest defaultMethodLimit: defaultMethodLimit [

	| includeCovered methodLimit scopeQuery |
	rawValue ifNil: [ self signalMissingCoverageOptions ].
	(rawValue respondsTo: #at:ifAbsent:) ifFalse: [
		Error signal: 'coverage must be an object.' ].
	scopeQuery := self
		              scopeQueryFromValue: rawValue
		              usingToolRequest: toolRequest.
	scopeQuery usesImplicitImageScope ifTrue: [
		self signalMissingCoverageScope ].
	includeCovered := toolRequest
		                  booleanArgumentNamed: 'includeCoveredMethods'
		                  in: rawValue
		                  default: false.
	methodLimit := self
		               nonNegativeIntegerNamed: 'methodLimit'
		               in: rawValue
		               usingToolRequest: toolRequest
		               default: defaultMethodLimit.
	^ self new
		  initializeScopeQuery: scopeQuery
		  includeCoveredMethods: includeCovered
		  methodLimit: methodLimit
]

{ #category : 'private - parsing' }
MCPTestCoverageRequest class >> nonNegativeIntegerNamed: argumentName in: rawValue usingToolRequest: toolRequest default: defaultValue [

	| value |
	value := toolRequest
		         valueNamed: argumentName
		         in: rawValue
		         ifAbsent: [ ^ defaultValue ].
	value ifNil: [ ^ defaultValue ].
	(value isInteger and: [ value >= 0 ]) ifTrue: [ ^ value ].
	Error signal: 'coverage.' , argumentName asString
		, ' must be a non-negative integer.'
]

{ #category : 'private - parsing' }
MCPTestCoverageRequest class >> scopeQueryFromValue: rawValue usingToolRequest: toolRequest [

	^ MCPCompiledMethodScopeQuery new
		  packageNames: (toolRequest stringCollectionFrom: (toolRequest
						    valueNamed: 'packageNames'
						    in: rawValue
						    ifAbsent: [ #(  ) ]));
		  classNames: (toolRequest stringCollectionFrom:
					   (toolRequest
						    valueNamed: 'classNames'
						    in: rawValue
						    ifAbsent: [ #(  ) ]));
		  hierarchyClassNames:
			  (toolRequest stringCollectionFrom: (toolRequest
						    valueNamed: 'hierarchyClassNames'
						    in: rawValue
						    ifAbsent: [ #(  ) ]));
		  subclassClassNames:
			  (toolRequest stringCollectionFrom: (toolRequest
						    valueNamed: 'subclassClassNames'
						    in: rawValue
						    ifAbsent: [ #(  ) ]));
		  parentClassNames: (toolRequest stringCollectionFrom: (toolRequest
						    valueNamed: 'parentClassNames'
						    in: rawValue
						    ifAbsent: [ #(  ) ]));
		  side:
			  (toolRequest
				   stringArgumentNamed: 'side'
				   in: rawValue
				   default: 'both');
		  yourself
]

{ #category : 'private - signaling' }
MCPTestCoverageRequest class >> signalMissingCoverageOptions [

	^ MCPCommandError
		  signalErrorCode: #CoverageOptionsRequired
		  message:
		  'test_coverage_run requires a coverage object with an explicit method scope.'
		  details: { (#tool -> 'test_coverage_run') } asDictionary
]

{ #category : 'private - signaling' }
MCPTestCoverageRequest class >> signalMissingCoverageScope [

	^ MCPCommandError
		  signalErrorCode: #CoverageScopeRequired
		  message:
		  'coverage requires at least one explicit method scope: packageNames, classNames, hierarchyClassNames, subclassClassNames, or parentClassNames.'
		  details: { (#tool -> 'test_coverage_run') } asDictionary
]

{ #category : 'accessing' }
MCPTestCoverageRequest >> includeCoveredMethods [

	^ includeCoveredMethods = true
]

{ #category : 'initialization' }
MCPTestCoverageRequest >> initializeScopeQuery: aScopeQuery includeCoveredMethods: aBoolean methodLimit: anInteger [

	scopeQuery := aScopeQuery.
	includeCoveredMethods := aBoolean = true.
	methodLimit := anInteger.
	^ self
]

{ #category : 'accessing' }
MCPTestCoverageRequest >> methodLimit [

	^ methodLimit ifNil: [ 200 ]
]

{ #category : 'accessing' }
MCPTestCoverageRequest >> scopeQuery [

	^ scopeQuery
]
