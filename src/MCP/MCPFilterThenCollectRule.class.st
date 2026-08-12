"
Renraku rule that warns when code filters a collection and immediately collects from the filtered result.

Use select:thenCollect: or reject:thenCollect: when the filtering and mapping steps are a single local transformation.
"
Class {
	#name : 'MCPFilterThenCollectRule',
	#superclass : 'MCPMethodStyleRule',
	#category : 'MCP-Critiques',
	#package : 'MCP',
	#tag : 'Critiques'
}

{ #category : 'accessing' }
MCPFilterThenCollectRule class >> rationale [

	^ 'Use select:thenCollect: or reject:thenCollect: when a filter is immediately followed by a collect:.'
]

{ #category : 'accessing' }
MCPFilterThenCollectRule class >> ruleName [

	^ 'Use fused filter and collect'
]

{ #category : 'initialization' }
MCPFilterThenCollectRule >> initialize [

	super initialize.
	self
		replace: '(`@collection select: `@filterBlock) collect: `@collectBlock'
		with: '`@collection select: `@filterBlock thenCollect: `@collectBlock';
		replace: '(`@collection reject: `@filterBlock) collect: `@collectBlock'
		with: '`@collection reject: `@filterBlock thenCollect: `@collectBlock'
]
