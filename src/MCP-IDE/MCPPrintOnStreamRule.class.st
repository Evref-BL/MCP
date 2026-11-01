"
Renraku rule that warns when code writes an object's printString to a stream instead of printing the object on it.

printString builds a string only for the stream to copy it: print: has the object print itself on the stream directly. A transcript's print: writes asString rather than printString, which drops the quotes around a string.
"
Class {
	#name : 'MCPPrintOnStreamRule',
	#superclass : 'MCPMethodStyleRule',
	#category : 'MCP-IDE-Critiques',
	#package : 'MCP-IDE',
	#tag : 'Critiques'
}

{ #category : 'accessing' }
MCPPrintOnStreamRule class >> rationale [

	^ 'Print an object on the stream with print: instead of writing its printString, which builds a string only for the stream to copy.'
]

{ #category : 'accessing' }
MCPPrintOnStreamRule class >> ruleName [

	^ 'Use print: on a stream'
]

{ #category : 'initialization' }
MCPPrintOnStreamRule >> initialize [
	"Only a write nothing reads: nextPutAll: answers what it wrote and print: the stream, and a
	 print: inside a chain of << sends would need parentheses the chain was written to avoid."

	super initialize.
	self
		replace:
			'`@stream `{ :node | MCPMethodStyleRule canSend: #print: to: node } nextPutAll: `@object `{ :node | MCPMethodStyleRule isValueUnused: node parent parent } printString'
		with: '`@stream print: `@object';
		replace:
			'`@stream `{ :node | (MCPMethodStyleRule canSend: #print: to: node) and: [ (node isMessage and: [ node selector = #<< ]) not ] } << `@object `{ :node | MCPMethodStyleRule isValueUnused: node parent parent } printString'
		with: '`@stream print: `@object'
]
