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

	| timeoutProperty |
	timeoutProperty := self
		                   integerSchemaPropertyNamed: 'timeoutSeconds'
		                   description: 'Timeout seconds; 0 returns immediately.'
		                   default: self defaultTimeoutSeconds.
	timeoutProperty minimum: 0.
	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: self testSelectionInputProperties , {
					  self coverageOptionsObjectSchema.
					  timeoutProperty };
		  required: #( 'coverage' );
		  yourself
]

{ #category : 'private - results' }
MCPToolRunTestCoverage >> dataTextOn: stream for: data [
	"A truncation flag is worth a line only when it is set, and the summary already states the percentage."

	| coverage rest |
	rest := data copy.
	(rest at: #coverage ifAbsent: [ nil ]) ifNotNil: [ :measured |
			coverage := measured copy.
			coverage removeKey: #percentage ifAbsent: [ nil ].
			coverage keys do: [ :key |
				((key asString endsWith: 'Truncated') and: [ (coverage at: key) = false ]) ifTrue: [
					coverage removeKey: key ] ].
			rest at: #coverage put: coverage ].
	super dataTextOn: stream for: rest
]

{ #category : 'metadata' }
MCPToolRunTestCoverage >> defaultExposure [

	^ 'discoverable'
]

{ #category : 'metadata' }
MCPToolRunTestCoverage >> description [

	^ 'Run tests while recording which methods they execute, and return the test summary with per-package and per-class coverage. Name the methods to measure under coverage.scope; without it nothing is measured.'
]

{ #category : 'private - request' }
MCPToolRunTestCoverage >> parsedRequestFromToolRequest: request [

	^ MCPRunTestsRequest fromRequest: request tool: self operation: 'coverage'
]

{ #category : 'metadata' }
MCPToolRunTestCoverage >> title [

	^ 'Run Test Coverage'
]
