Extension { #name : 'TestCase' }

{ #category : '*MCP-IDE' }
TestCase >> mcpAddTestCasesTo: testCases using: aCommand [

	testCases add: self
]

{ #category : '*MCP-IDE' }
TestCase >> mcpParameterPrintStrings [

	^ #(  )
]
