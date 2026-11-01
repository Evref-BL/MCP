"
Renraku rule that warns when code collects a dictionary's keys to ask whether one of them is there.

keys answers a new collection and includes: searches it element by element; includesKey: asks the dictionary, which finds a key by hashing it.
"
Class {
	#name : 'MCPIncludesKeyRule',
	#superclass : 'MCPMethodStyleRule',
	#category : 'MCP-IDE-Critiques',
	#package : 'MCP-IDE',
	#tag : 'Critiques'
}

{ #category : 'accessing' }
MCPIncludesKeyRule class >> rationale [

	^ 'Ask includesKey: instead of collecting the keys to search them.'
]

{ #category : 'accessing' }
MCPIncludesKeyRule class >> ruleName [

	^ 'Use includesKey:'
]

{ #category : 'initialization' }
MCPIncludesKeyRule >> initialize [

	super initialize.
	self
		replace: '`@dictionary `{ :node | MCPMethodStyleRule canSend: #includesKey: to: node } keys includes: `@key'
		with: '`@dictionary includesKey: `@key'
]
