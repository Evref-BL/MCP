"
Renraku rule: lookup-to-nil followed by ifNotNil:. Prefer at:ifPresent: when absence does nothing; present value stays local.
"
Class {
	#name : 'MCPDictionaryAtIfPresentRule',
	#superclass : 'MCPMethodStyleRule',
	#category : 'MCP-Critiques',
	#package : 'MCP',
	#tag : 'Critiques'
}

{ #category : 'accessing' }
MCPDictionaryAtIfPresentRule class >> rationale [

	^ 'Prefer at:ifPresent: over lookup-to-nil followed by ifNotNil: when absence does nothing.'
]

{ #category : 'accessing' }
MCPDictionaryAtIfPresentRule class >> ruleName [

	^ 'Use at:ifPresent: for lookup presence'
]

{ #category : 'initialization' }
MCPDictionaryAtIfPresentRule >> initialize [

	super initialize.
	self
		replace:
		'(`@dictionary at: `@key ifAbsent: [ nil ]) ifNotNil: `@presentBlock'
		with: '`@dictionary at: `@key ifPresent: `@presentBlock'
]
