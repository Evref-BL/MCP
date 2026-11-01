"
Renraku rule that warns when a lookup answers nil only for the caller to test it.

detect:ifFound: and detect:ifFound:ifNone: hand the element to the block that uses it, so absence is a branch rather than a nil to check. detect:ifFound: answers the collection, not what the block answers, so it replaces the lookup only where nothing reads the answer; detect:ifFound:ifNone: answers the block's value and replaces it anywhere.
"
Class {
	#name : 'MCPDetectIfFoundRule',
	#superclass : 'MCPMethodStyleRule',
	#category : 'MCP-IDE-Critiques',
	#package : 'MCP-IDE',
	#tag : 'Critiques'
}

{ #category : 'accessing' }
MCPDetectIfFoundRule class >> rationale [

	^ 'Hand the found element to a block with detect:ifFound: instead of answering nil from detect:ifNone: and testing it.'
]

{ #category : 'accessing' }
MCPDetectIfFoundRule class >> ruleName [

	^ 'Use detect:ifFound:'
]

{ #category : 'initialization' }
MCPDetectIfFoundRule >> initialize [

	super initialize.
	self
		replace:
			'(`@collection `{ :node | MCPMethodStyleRule canSend: #detect:ifFound: to: node } detect: `@block ifNone: [ nil ]) ifNotNil: `@found `{ :node | MCPMethodStyleRule isValueUnused: node parent }'
		with: '`@collection detect: `@block ifFound: `@found';
		replace:
			'(`@collection `{ :node | MCPMethodStyleRule canSend: #detect:ifFound:ifNone: to: node } detect: `@block ifNone: [ nil ]) ifNil: `@none ifNotNil: `@found'
		with: '`@collection detect: `@block ifFound: `@found ifNone: `@none';
		replace:
			'(`@collection `{ :node | MCPMethodStyleRule canSend: #detect:ifFound:ifNone: to: node } detect: `@block ifNone: [ nil ]) ifNotNil: `@found ifNil: `@none'
		with: '`@collection detect: `@block ifFound: `@found ifNone: `@none'
]
