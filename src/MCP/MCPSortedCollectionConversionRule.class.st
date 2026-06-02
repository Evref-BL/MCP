"
Renraku rule that warns when code converts to a SortedCollection and immediately converts back to an Array.

Use sorted for a sorted copy or sort/sort: when mutating an array in place. The intent is clearer and avoids the unnecessary SortedCollection conversion.
"
Class {
	#name : 'MCPSortedCollectionConversionRule',
	#superclass : 'MCPMethodStyleRule',
	#category : 'MCP-Critiques',
	#package : 'MCP',
	#tag : 'Critiques'
}

{ #category : 'accessing' }
MCPSortedCollectionConversionRule class >> rationale [

	^ 'Use sorted for a sorted copy, or sort/sort: when mutating an array, instead of converting through SortedCollection and back to Array.'
]

{ #category : 'accessing' }
MCPSortedCollectionConversionRule class >> ruleName [

	^ 'Avoid sorted collection conversion chains'
]

{ #category : 'initialization' }
MCPSortedCollectionConversionRule >> initialize [

	super initialize.
	self
		replace: '`@collection asSortedCollection asArray'
		with: '`@collection sorted';
		replace: '(`@collection asSortedCollection: `@block) asArray'
		with: '`@collection sorted: `@block'
]
