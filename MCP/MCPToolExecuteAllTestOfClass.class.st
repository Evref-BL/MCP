Class {
	#name : 'MCPToolExecuteAllTestOfClass',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'executing' }
MCPToolExecuteAllTestOfClass >> executeWithArguments: arguments [

	| result suite testClass data |
	testClass := self class environment at:
		             (arguments at: #className) asSymbol.
	suite := testClass suite.
	result := MCPStructuredTestResult new.
	suite run: result.
	data := self
		        structuredDataForTestResult: result
		        className: testClass name asString
		        testMethodName: nil.
	^ self
		  successResultText:
		  result runCount asString , ' tests run completed.'
		  data: data
]

{ #category : 'initialization' }
MCPToolExecuteAllTestOfClass >> initialize [

	super initialize.
	name := 'pharo-run-test-class'.
	title := 'Run Pharo Test Class'.
	description := 'Run the full test suite defined by a Pharo test class.'.
	inputSchema := MCPStructureInputSchema new
		               type: 'object';
		               properties: { (MCPStructureProperties new
				                name: 'className';
				                type: 'string';
				                description:
					                'The name of the test class whose suite should be run.';
				                yourself) };
		               required: #( 'className' );
		               yourself.
	outputSchema := self
		                standardOutputSchemaForDataProperties:
		                (self
			                 standardTestDataPropertiesIncludingMethodName:
			                 false)
		                required:
		                (self
			                 standardTestRequiredFieldsIncludingMethodName:
			                 false).
	icons := {  }
]
