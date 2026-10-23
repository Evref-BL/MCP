"
Fixture trait whose methods are installed into several classes, so method-search tests can check that the copies are answered once.
"
Trait {
	#name : 'TMCPToolMethodSearchFixture',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'accessing' }
TMCPToolMethodSearchFixture classSide >> mcpTraitFixtureValue [

	^ 'from the class side of the trait'
]

{ #category : 'accessing' }
TMCPToolMethodSearchFixture >> mcpTraitFixtureValue [

	^ 'from the trait'
]
