"
Renraku rule that warns when a collect: result is converted to another species right after, where collect:as: builds that species directly and without the intermediate collection.

The rewrite is not an equivalence for every receiver. A Set or a Bag answers its own species from collect:, so it deduplicates before the conversion, which collect:as: Array does not: read the receiver before accepting the change.
"
Class {
	#name : 'MCPCollectConversionRule',
	#superclass : 'MCPMethodStyleRule',
	#category : 'MCP-IDE-Critiques',
	#package : 'MCP-IDE',
	#tag : 'Critiques'
}

{ #category : 'accessing' }
MCPCollectConversionRule class >> rationale [

	^ 'Use collect:as: or flatCollect:as: instead of collecting into one species and converting the result.'
]

{ #category : 'accessing' }
MCPCollectConversionRule class >> ruleName [

	^ 'Use collect:as: for the result species'
]

{ #category : 'initialization' }
MCPCollectConversionRule >> initialize [

	super initialize.
	self
		replace: '(`@collection collect: `@block) asArray' with: '`@collection collect: `@block as: Array';
		replace: '(`@collection collect: `@block) asOrderedCollection' with: '`@collection collect: `@block as: OrderedCollection';
		replace: '(`@collection collect: `@block) asSet' with: '`@collection collect: `@block as: Set';
		replace: '(`@collection collect: `@block) asBag' with: '`@collection collect: `@block as: Bag';
		replace: '(`@collection flatCollect: `@block) asArray' with: '`@collection flatCollect: `@block as: Array';
		replace: '(`@collection flatCollect: `@block) asOrderedCollection'
		with: '`@collection flatCollect: `@block as: OrderedCollection'
]
