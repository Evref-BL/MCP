"
Run SUnit tests while collecting coverage for an explicit method scope.
"
Class {
	#name : 'MCPToolRunTestCoverage',
	#superclass : 'MCPToolRunTests',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolRunTestCoverage class >> toolName [

	^ 'test_coverage_run'
]

{ #category : 'metadata' }
MCPToolRunTestCoverage >> buildInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: self testSelectionInputProperties , {
					  self coverageOptionsObjectSchema.
					  self timeoutSecondsProperty };
		  required: #( 'coverage' );
		  yourself
]

{ #category : 'private - arguments' }
MCPToolRunTestCoverage >> checkArguments: request [
	"The coverage scope is checked first, so a call wrong in both ways is refused for its scope."

	self coverageScopeFrom: request.
	super checkArguments: request
]

{ #category : 'private - arguments' }
MCPToolRunTestCoverage >> coverageScopeFrom: request [
	"The methods whose coverage the run measures. Coverage is reported for an explicit scope, never for whatever the tests happen to reach."

	| scope scopeQuery |
	scope := request valueNamed: 'scope' in: (request argumentNamed: 'coverage' ifAbsent: [ nil ]) ifAbsent: [ Dictionary new ].
	scopeQuery := MCPCompiledMethodScopeQuery new
		              packageNames: (request stringCollectionArgumentNamed: 'packages' in: scope);
		              classNames: (request stringCollectionArgumentNamed: 'classes' in: scope);
		              subclassClassNames: (request stringCollectionArgumentNamed: 'subclassesOf' in: scope);
		              parentClassNames: (request stringCollectionArgumentNamed: 'superclassesOf' in: scope);
		              yourself.
	scopeQuery usesImplicitImageScope ifTrue: [
			MCPCommandError
				signalErrorCode: #CoverageScopeRequired
				message:
				'coverage requires at least one explicit method scope: scope.packages, scope.classes, scope.subclassesOf, or scope.superclassesOf.'
				details: { (#tool -> self name) } asDictionary ].
	^ scopeQuery
]

{ #category : 'private - results' }
MCPToolRunTestCoverage >> dataTextOn: stream for: data [
	"A truncation flag is worth a line only when it is set, and the summary already states the percentage."

	| coverage rest |
	rest := data copy.
	rest at: #coverage ifPresent: [ :measured |
			coverage := measured copy.
			coverage removeKey: #percentage ifAbsent: [ nil ].
			coverage keys do: [ :key |
				((key asString endsWith: 'Truncated') and: [ (coverage at: key) = false ]) ifTrue: [ coverage removeKey: key ] ].
			rest at: #coverage put: coverage ].
	super dataTextOn: stream for: rest
]

{ #category : 'metadata' }
MCPToolRunTestCoverage >> defaultExposure [

	^ 'discoverable'
]

{ #category : 'metadata' }
MCPToolRunTestCoverage >> description [

	^ 'Run tests while recording which of the methods under coverage.scope they execute, and report the test summary, the share of those methods'' code that ran, and the methods left unexecuted or partly executed.'
]

{ #category : 'private - execution' }
MCPToolRunTestCoverage >> operationFor: request [
	"The run the checked arguments ask for, measuring the coverage of their scope."

	| coverage scope |
	scope := self coverageScopeFrom: request.
	coverage := request argumentNamed: 'coverage' ifAbsent: [ nil ].
	^ MCPRunTestsCommand
		  selections: (self testSelectionsFrom: request)
		  timeoutMilliseconds: (self timeoutMillisecondsFrom: request)
		  coverageScope: scope
		  includeCoveredMethods: (request booleanArgumentNamed: 'includeCoveredMethods' in: coverage default: false)
		  methodLimit: (request valueNamed: 'methodLimit' in: coverage ifAbsent: [ self defaultCoverageMethodLimit ])
]

{ #category : 'metadata' }
MCPToolRunTestCoverage >> title [

	^ 'Run Test Coverage'
]

{ #category : 'private - results' }
MCPToolRunTestCoverage >> warningsFor: anOperation [
	"The coverage scope answers partial results, as a search scope does: an entry that names nothing is skipped, and the answer says so."

	^ anOperation coverageScope warnings
]
