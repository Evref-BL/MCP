Extension { #name : 'TestCase' }

{ #category : '*MCP' }
TestCase >> mcpAddTestCasesTo: testCases using: aCommand [

	testCases add: self
]

{ #category : '*MCP' }
TestCase >> mcpParameterPrintStrings [

	^ #(  )
]
