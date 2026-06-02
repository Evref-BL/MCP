"
Renraku rule that warns when code builds a selected collection only to ask for its size.

Use count: when the intent is to count matching elements. It states the question directly and avoids materializing an intermediate collection.
"
Class {
	#name : 'MCPSelectSizeCountRule',
	#superclass : 'MCPMethodStyleRule',
	#category : 'MCP-Critiques',
	#package : 'MCP',
	#tag : 'Critiques'
}

{ #category : 'accessing' }
MCPSelectSizeCountRule class >> rationale [

	^ 'Use count: instead of selecting elements and then asking the intermediate collection for its size.'
]

{ #category : 'accessing' }
MCPSelectSizeCountRule class >> ruleName [

	^ 'Use count: instead of select: size'
]

{ #category : 'initialization' }
MCPSelectSizeCountRule >> initialize [

	super initialize.
	self
		replace: '(`@collection select: `@block) size'
		with: '`@collection count: `@block'
]
