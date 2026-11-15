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

{ #category : 'private - request' }
MCPToolRunTestCoverage >> parsedRequestFromToolRequest: request [

	^ MCPRunTestsRequest fromRequest: request tool: self operation: 'coverage'
]

{ #category : 'metadata' }
MCPToolRunTestCoverage >> title [

	^ 'Run Test Coverage'
]
