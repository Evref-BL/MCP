Class {
	#name : 'MCPToolExecuteClassTest',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'executing' }
MCPToolExecuteClassTest >> executeWithArguments: arguments [

	| result suite testClass testMethodName data |
	testClass := self class environment at:
		             (arguments at: #className) asSymbol.
	testMethodName := arguments at: #testMethodName.
	suite := TestSuite named: testClass name asString.
	suite addTest: (testClass selector: testMethodName asSymbol).
	result := MCPStructuredTestResult new.
	suite run: result.
	data := self
		        structuredDataForTestResult: result
		        className: testClass name asString
		        testMethodName: testMethodName.
	^ self
		  successResultText:
		  result runCount asString , ' test run completed.'
		  data: data
]

{ #category : 'initialization' }
MCPToolExecuteClassTest >> initialize [

	super initialize.
	name := 'pharo-run-test-method'.
	title := 'Run Pharo Test Method'.
	description := 'Run a single test method on a Pharo test class.'.
	inputSchema := MCPStructureInputSchema new
		               type: 'object';
		               properties: {
				               (MCPStructureProperties new
					                name: 'className';
					                type: 'string';
					                description:
						                'The name of the test class that defines the method to run.';
					                yourself).
				               (MCPStructureProperties new
					                name: 'testMethodName';
					                type: 'string';
					                description:
						                'The name of the test method to run.';
					                yourself) };
		               required: #( 'className' 'testMethodName' );
		               yourself.
	outputSchema := self
		                standardOutputSchemaForDataProperties:
		                (self
			                 standardTestDataPropertiesIncludingMethodName:
			                 true)
		                required:
		                (self
			                 standardTestRequiredFieldsIncludingMethodName:
			                 true).
	icons := {  }
]
