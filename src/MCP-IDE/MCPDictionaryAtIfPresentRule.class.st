"
Renraku rule: lookup-to-nil followed by ifNotNil:. Prefer at:ifPresent: when absence does nothing; present value stays local.

A sequenceable collection has no at:ifPresent:, so a number key, or a receiver the source shows does not understand it, is left alone.
"
Class {
	#name : 'MCPDictionaryAtIfPresentRule',
	#superclass : 'MCPMethodStyleRule',
	#category : 'MCP-IDE-Critiques',
	#package : 'MCP-IDE',
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
	"A number key is an index, and a sequenceable collection has no at:ifPresent:."

	super initialize.
	self
		replace:
		'(`@dictionary `{ :node | MCPMethodStyleRule canSend: #at:ifPresent: to: node } at: `@key `{ :node | (node isLiteralNode and: [ node value isNumber ]) not } ifAbsent: [ nil ]) ifNotNil: `@presentBlock'
		with: '`@dictionary at: `@key ifPresent: `@presentBlock'
]
