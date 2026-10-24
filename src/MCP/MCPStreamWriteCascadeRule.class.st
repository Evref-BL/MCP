"
Renraku rule that warns when consecutive stream writes are cascaded.

`<<` answers the stream it wrote to, so writes chain directly. A cascade says the same thing with more punctuation, and reads as though each write needed the receiver named again.
"
Class {
	#name : 'MCPStreamWriteCascadeRule',
	#superclass : 'MCPMethodStyleRule',
	#category : 'MCP-Critiques',
	#package : 'MCP',
	#tag : 'Critiques'
}

{ #category : 'accessing' }
MCPStreamWriteCascadeRule class >> rationale [

	^ 'Chain stream writes instead of cascading them. << answers the stream, so one write flows into the next.'
]

{ #category : 'accessing' }
MCPStreamWriteCascadeRule class >> ruleName [

	^ 'Chain stream writes'
]

{ #category : 'initialization' }
MCPStreamWriteCascadeRule >> initialize [

	super initialize.
	self replace: '`@stream << `@first; << `@second' with: '`@stream << `@first << `@second'
]
