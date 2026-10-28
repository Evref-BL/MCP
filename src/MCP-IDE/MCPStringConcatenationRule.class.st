"
Renraku rule that warns when a string is built by chaining three or more concatenations, where each comma copies everything to its left into a new string.

A stream writes the parts once. The patterns only match a chain holding a string literal, so concatenation of other sequenceable collections is left alone.

The patterns take three parts at a time, and the last of them absorbs a concatenation left inside a stream write, which is the intermediate the stream was reached for. A longer chain therefore flattens over several passes: apply the rule again while it still reports a hit.
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
	"The last pair absorbs what a longer chain leaves behind: a concatenation written to a
	 stream is exactly the intermediate the stream was reached for."

	super initialize.
	self
		replace: '`#first , `@second , `@third' with: 'String streamContents: [ :stream | stream << `#first << `@second << `@third ]';
		replace: '`@first , `#second , `@third' with: 'String streamContents: [ :stream | stream << `@first << `#second << `@third ]';
		replace: '`@first , `@second , `#third' with: 'String streamContents: [ :stream | stream << `@first << `@second << `#third ]';
		replace: '`@stream << (`@first , `@second)' with: '`@stream << `@first << `@second'
]
