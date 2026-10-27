Extension { #name : 'TestSuite' }

{ #category : '*MCP-IDE' }
TestSuite >> mcpAddTestCasesTo: testCases using: aCommand [

	self tests do: [ :each | aCommand addTestCasesFrom: each to: testCases ]
]
