Extension { #name : 'MCPLostChangeQuery' }

{ #category : '*MCP-IDE-Compatibility-Before12' }
MCPLostChangeQuery >> visitBehaviorCategoryChange: aChange [
	"Before Pharo 12, a class moved to another category."

	self recordRepackaging: aChange
]
