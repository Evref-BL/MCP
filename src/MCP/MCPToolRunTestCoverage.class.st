"
Run SUnit tests while collecting coverage for an explicit method scope.
"
Class {
	#name : 'MCPToolRunTestCoverage',
	#superclass : 'MCPToolRunTests',
	#category : 'MCP-Tools',
	#package : 'MCP',
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
		                   description:
		                   'Timeout seconds; 0 returns immediately.'
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

{ #category : 'metadata' }
MCPToolRunTestCoverage >> buildOutputSchema [

	^ self
		  standardOutputSchemaForDataProperties:
		  self testRunDataProperties , { self coverageResultObjectSchema }
		  required: #( 'runCount' 'passedCount' 'coverage' )
]

{ #category : 'metadata' }
MCPToolRunTestCoverage >> description [

	^ 'Run tests under coverage return compact aggregate test coverage results.'
]

{ #category : 'private - request' }
MCPToolRunTestCoverage >> parsedRequestFromToolRequest: request [

	^ MCPRunTestsRequest
		  fromRequest: request
		  tool: self
		  operation: 'coverage'
]

{ #category : 'metadata' }
MCPToolRunTestCoverage >> title [

	^ 'Run Test Coverage'
]
