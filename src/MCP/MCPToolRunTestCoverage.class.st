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

{ #category : 'defaults' }
MCPToolRunTestCoverage class >> toolName [

	^ 'test_coverage_run'
]

{ #category : 'defaults' }
MCPToolRunTestCoverage >> defaultDescription [

	^ 'Run test classes or individual test methods under coverage and return aggregated test and method coverage results.'
]

{ #category : 'defaults' }
MCPToolRunTestCoverage >> defaultInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  ((MCPStructureProperties new
					    name: 'tests';
					    type: 'array';
					    description: 'Test requests.')
					   items: self testRequestObjectSchema;
					   yourself).
				  self coverageOptionsObjectSchema.
				  (self
					   integerSchemaPropertyNamed: 'timeoutSeconds'
					   description: 'Timeout in seconds; 0 returns immediately.'
					   default: self defaultTimeoutSeconds).
				  (self
					   integerSchemaPropertyNamed: 'timeoutMilliseconds'
					   description: 'Timeout in milliseconds.') };
		  required: #( 'tests' 'coverage' );
		  yourself
]

{ #category : 'defaults' }
MCPToolRunTestCoverage >> defaultOutputSchema [

	| coverageProperty resultsProperty unrunTestsProperty |
	resultsProperty := self
		                   schemaPropertyNamed: 'results'
		                   type: 'array'
		                   description:
		                   'Structured results for each test execution request in the batch that completed before timeout.'.
	resultsProperty items: self testResultObjectSchema.
	unrunTestsProperty := self
		                      schemaPropertyNamed: 'unrunTests'
		                      type: 'array'
		                      description:
		                      'Test execution requests that did not run because the batch timed out. Pass this array to test_coverage_run to continue from the timeout point.'.
	unrunTestsProperty items: self testRequestObjectSchema.
	coverageProperty := self coverageResultObjectSchema.
	^ self
		  standardOutputSchemaForDataProperties: {
				  resultsProperty.
				  coverageProperty.
				  (self
					   booleanSchemaPropertyNamed: 'timedOut'
					   description:
					   'Whether the batch stopped early because timeoutSeconds elapsed.').
				  unrunTestsProperty }
		  required: #( 'results' 'coverage' )
]

{ #category : 'defaults' }
MCPToolRunTestCoverage >> defaultTitle [

	^ 'Run Test Coverage'
]

{ #category : 'private - request' }
MCPToolRunTestCoverage >> parsedRequestFromToolRequest: request [

	^ MCPRunTestsRequest
		  fromRequest: request
		  tool: self
		  operation: 'coverage'
]
