"
Run SUnit tests with method and sequence coverage for an explicit scope.
"
Class {
	#name : 'MCPToolRunTestCoverage',
	#superclass : 'MCPToolRunTests',
	#traits : 'TMCPMethodTool',
	#classTraits : 'TMCPMethodTool classTrait',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolRunTestCoverage class >> toolName [

	^ 'test_coverage_run'
]

{ #category : 'metadata' }
MCPToolRunTestCoverage >> additionalKeywords [

	^ super additionalKeywords , #( 'coverage' 'uncovered' 'partial' )
]

{ #category : 'metadata' }
MCPToolRunTestCoverage >> buildInputSchema [

	^ MCPStructureInputSchema
		  properties: self testSelectionInputProperties , {
				  self coverageOptionsObjectSchema.
				  self timeoutSecondsProperty }
		  required: #( 'coverage' )
]

{ #category : 'private - arguments' }
MCPToolRunTestCoverage >> checkArguments: request [

	self coverageScopeFrom: request.
	super checkArguments: request
]

{ #category : 'private - schema' }
MCPToolRunTestCoverage >> coverageOptionsObjectSchema [

	| limit scope |
	limit := self
		         integerSchemaPropertyNamed: 'methodLimit'
		         description: 'Maximum entries per method list; 0 returns counts only.'
		         default: 50.
	limit minimum: 0.
	scope := self methodSearchScopeSchemaProperty.
	scope description:
		'Methods to measure, with an explicit package, class or hierarchy. Test classes, abstract methods and methods with the coverage exclusion pragma are excluded.'.
	^ (self
		   schemaPropertyNamed: 'coverage'
		   type: 'object'
		   description:
			   'Measure method entry and sequence entry in this explicit scope; the percentage is sequence coverage, not line or branch coverage.')
		  properties: {
				  scope.
				  (self booleanSchemaPropertyNamed: 'includeCoveredMethods' description: 'Also list executed methods.' default: false).
				  limit };
		  required: #( 'scope' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - arguments' }
MCPToolRunTestCoverage >> coverageScopeFrom: request [

	| nested query |
	nested := MCPToolRequest new
		          arguments: (request argumentNamed: 'coverage' ifAbsent: [ Dictionary new ]);
		          yourself.
	query := self methodScopeQueryFromRequest: nested.
	query usesImplicitImageScope ifTrue: [
			MCPCommandError
				signalErrorCode: #CoverageScopeRequired
				message: 'coverage.scope must name at least one package, class or hierarchy.'
				details: { (#tool -> self name) } asDictionary ].
	^ query
]

{ #category : 'private - results' }
MCPToolRunTestCoverage >> dataTextOn: stream for: data [

	| coverage rest |
	rest := data copy.
	coverage := (rest at: #coverage) copy.
	coverage removeKey: #percentage.
	coverage keys do: [ :key |
		((key asString endsWith: 'Truncated') and: [ (coverage at: key) = false ]) ifTrue: [ coverage removeKey: key ] ].
	rest at: #coverage put: coverage.
	super dataTextOn: stream for: rest
]

{ #category : 'metadata' }
MCPToolRunTestCoverage >> defaultExposure [

	^ 'discoverable'
]

{ #category : 'metadata' }
MCPToolRunTestCoverage >> description [

	^ 'Run SUnit tests and measure method and sequence coverage within coverage.scope. Report test issues, uncovered and partially executed methods, and partial coverage when the run times out.'
]

{ #category : 'private - execution' }
MCPToolRunTestCoverage >> operationFor: request [

	| coverage |
	coverage := request argumentNamed: 'coverage' ifAbsent: [ nil ].
	^ (MCPRunTestCoverageCommand
		   selections: (self testSelectionsFrom: request)
		   timeoutMilliseconds: (self timeoutMillisecondsFrom: request))
		  coverageScope: (self coverageScopeFrom: request);
		  includeCoveredMethods: (request booleanArgumentOrDefaultNamed: 'includeCoveredMethods' in: coverage);
		  methodLimit: (request argumentOrDefaultNamed: 'methodLimit' in: coverage);
		  yourself
]

{ #category : 'private - results' }
MCPToolRunTestCoverage >> successSummaryForData: data [

	| percentage |
	percentage := (data at: #coverage) at: #percentage.
	^ (super successSummaryForData: data) , ((data at: #timedOut ifAbsent: [ false ])
		   ifTrue: [ ' Sequence coverage so far: ' ]
		   ifFalse: [ ' Sequence coverage: ' ])
	  , (percentage ifNil: [ 'n/a (no coverable sequences).' ] ifNotNil: [ (percentage printShowingDecimalPlaces: 2) , '%.' ])
]

{ #category : 'metadata' }
MCPToolRunTestCoverage >> title [

	^ 'Run Test Coverage'
]

{ #category : 'private - results' }
MCPToolRunTestCoverage >> warningsFor: anOperation [

	^ anOperation coverageScope warnings
]
