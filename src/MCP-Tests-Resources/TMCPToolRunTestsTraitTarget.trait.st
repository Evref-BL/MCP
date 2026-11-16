"
Fixture trait used by test_run tests: its tests run in the test classes that use it.
"
Trait {
	#name : 'TMCPToolRunTestsTraitTarget',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'helpers' }
TMCPToolRunTestsTraitTarget >> helperFromTheTrait [
	"This is a fixture helper, not a test: none of the test classes that use its trait runs it, and MCP test-running tool tests name it."

	^ 1 + 1
]

{ #category : 'tests' }
TMCPToolRunTestsTraitTarget >> testFromTheTrait [
	"This is a fixture test method; it runs in the test classes that use its trait, and is exercised by MCP test-running tool tests."

	self assert: 1 + 1 equals: 2
]
