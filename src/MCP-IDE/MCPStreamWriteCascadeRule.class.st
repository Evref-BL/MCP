"
Renraku rule that warns when consecutive stream writes are cascaded.

`<<` answers the stream it wrote to, so writes chain directly. A cascade says the same thing with more punctuation, and reads as though each write needed the receiver named again.

A cascade's messages are matched as a list of exactly the length the pattern writes, so no pattern can stand for a cascade of any length. The match is a pattern block asking whether a node is a cascade of stream writes, and the chain that takes its place is built rather than written out.
"
Class {
	#name : 'MCPStreamWriteCascadeRule',
	#superclass : 'MCPMethodStyleRule',
	#category : 'MCP-IDE-Critiques',
	#package : 'MCP-IDE',
	#tag : 'Critiques'
}

{ #category : 'rewriting' }
MCPStreamWriteCascadeRule class >> chainedFrom: aCascadeNode [
	"The one chain that says what the cascade says, built from copies: the node answered here replaces the cascade, while the cascade itself belongs to the method being read."

	| chain |
	chain := aCascadeNode messages first copy.
	aCascadeNode messages allButFirst do: [ :each |
			| write |
			write := each copy.
			write receiver: chain.
			chain := write ].
	^ chain
]

{ #category : 'testing' }
MCPStreamWriteCascadeRule class >> isCascadeOfStreamWrites: aNode [
	"The pattern block asks this of every node, because no pattern can say 'a cascade of any length': a cascade pattern matches a cascade of exactly as many messages as it writes."

	^ aNode isCascade and: [ aNode messages allSatisfy: [ :each | each selector = #'<<' ] ]
]

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
	self
		replace: '`@cascade `{ :node | MCPStreamWriteCascadeRule isCascadeOfStreamWrites: node }'
		byEvaluating: [ :node | self class chainedFrom: node ]
]
