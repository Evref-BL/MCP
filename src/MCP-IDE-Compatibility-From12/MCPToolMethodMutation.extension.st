Extension { #name : 'MCPToolMethodMutation' }

{ #category : '*MCP-IDE-Compatibility-From12' }
MCPToolMethodMutation >> isNotNilAndConditionalRuleClass [

	^ ReIsNotNilAndConditionalRule
]

{ #category : '*MCP-IDE-Compatibility-From12' }
MCPToolMethodMutation >> notOptimizedIfRuleClasses [

	^ {
		  ReNotOptimizedIfRule.
		  ReNotOptimizedIfNilRule }
]
