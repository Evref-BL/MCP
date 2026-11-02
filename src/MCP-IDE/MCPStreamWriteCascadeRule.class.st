"
Renraku rule that warns when consecutive stream writes are cascaded.

`<<` answers the stream it wrote to, so writes chain directly. A cascade says the same thing with more punctuation, and reads as though each write needed the receiver named again.

A cascade's messages are matched as a list of exactly the length the pattern writes, so one pattern cannot stand for every length the way a concatenation pattern does. There is a pattern per length instead, up to longestCascadeMatched.
"
Class {
	#name : 'MCPStreamWriteCascadeRule',
	#superclass : 'MCPMethodStyleRule',
	#category : 'MCP-IDE-Critiques',
	#package : 'MCP-IDE',
	#tag : 'Critiques'
}

{ #category : 'accessing' }
MCPStreamWriteCascadeRule class >> longestCascadeMatched [
	"How many cascaded writes the patterns reach. A cascade pattern matches a cascade of exactly its own length, so one pattern per length is the only way to say it, and the rule has to stop somewhere. Twelve is past the longest all-<< cascade a Pharo image holds."

	^ 12
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
	2 to: self class longestCascadeMatched do: [ :writeCount | self replaceCascadeOf: writeCount ]
]

{ #category : 'initialization' }
MCPStreamWriteCascadeRule >> replaceCascadeOf: writeCount [
	"One pattern pair for a cascade of exactly writeCount writes, and the single chain that says the same thing."

	| writes |
	writes := (1 to: writeCount) collect: [ :index | '`@write' , index asString ].
	self
		replace: (String streamContents: [ :stream |
					 stream << '`@stream << ' << writes first.
					 writes allButFirst do: [ :each | stream << '; << ' << each ] ])
		with: (String streamContents: [ :stream |
					 stream << '`@stream'.
					 writes do: [ :each | stream << ' << ' << each ] ])
]
