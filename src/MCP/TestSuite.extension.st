Extension { #name : 'TestSuite' }

{ #category : '*MCP' }
TestSuite >> mcpAddTestCasesTo: testCases using: aCommand [

	self tests do: [ :each |
		aCommand addTestCasesFrom: each to: testCases ]
]
