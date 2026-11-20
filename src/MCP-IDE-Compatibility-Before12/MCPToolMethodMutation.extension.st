Extension { #name : 'MCPToolMethodMutation' }

{ #category : '*MCP-IDE-Compatibility-Before12' }
MCPToolMethodMutation >> isNotNilAndConditionalRuleClass [
	"Pharo 10 has no such rule, so it is looked up by name: nil where it is absent."

	^ self class environment at: #ReIsNotNilAndConditionalRule ifAbsent: [ nil ]
]

{ #category : '*MCP-IDE-Compatibility-Before12' }
MCPToolMethodMutation >> notOptimizedIfRuleClasses [
	"Pharo 10 has neither rule, so they are looked up by name: nil where they are absent."

	^ #( #ReNotOptimizedIfRule #ReNotOptimizedIfNilRule ) collect: [ :each | self class environment at: each ifAbsent: [ nil ] ]
]
