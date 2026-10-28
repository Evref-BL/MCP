"
Renraku rule that warns when a string is built by chaining three or more concatenations, where each comma copies everything to its left into a new string.

A stream writes the parts once. The patterns only match a chain holding a string literal, so concatenation of other sequenceable collections is left alone.
"
Class {
	#name : 'MCPStringConcatenationRule',
	#superclass : 'MCPMethodStyleRule',
	#category : 'MCP-IDE-Critiques',
	#package : 'MCP-IDE',
	#tag : 'Critiques'
}

{ #category : 'accessing' }
MCPStringConcatenationRule class >> rationale [

	^ 'Build a string with String streamContents: instead of chaining concatenations, each of which copies everything to its left.'
]

{ #category : 'accessing' }
MCPStringConcatenationRule class >> ruleName [

	^ 'Build strings with a stream'
]

{ #category : 'initialization' }
MCPStringConcatenationRule >> initialize [

	super initialize.
	self
		replace: '`#first , `@second , `@third' with: 'String streamContents: [ :stream | stream << `#first; << `@second; << `@third ]';
		replace: '`@first , `#second , `@third' with: 'String streamContents: [ :stream | stream << `@first; << `#second; << `@third ]'
]
