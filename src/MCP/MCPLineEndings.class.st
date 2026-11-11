"
I convert line endings where text crosses the protocol boundary. Pharo ends a line with a carriage return; a client, like JSON text everywhere, with a line feed. The message processor hands me every message it receives, just parsed, and every answer it sends, just before writing it, and I convert each string they hold, at any depth, so that each side meets the line endings it expects whichever tool or argument carries the text.
"
Class {
	#name : 'MCPLineEndings',
	#superclass : 'Object',
	#category : 'MCP-Transport',
	#package : 'MCP',
	#tag : 'Transport'
}

{ #category : 'private' }
MCPLineEndings class >> convert: aJSONValue with: aBlock [
	"Each string converted, at any depth. A dictionary's keys name properties rather than carry lines, and collect: leaves them as they are."

	aJSONValue isString ifTrue: [ ^ aBlock value: aJSONValue ].
	aJSONValue isCollection ifFalse: [ ^ aJSONValue ].
	^ aJSONValue collect: [ :each | self convert: each with: aBlock ]
]

{ #category : 'converting' }
MCPLineEndings class >> entering: aJSONValue [
	"aJSONValue with each of its strings as the image keeps text: every line ended by a carriage return, whether the client ended it with a line feed or with both."

	^ self convert: aJSONValue with: [ :string |
			  (string includes: Character lf)
				  ifTrue: [ string withInternalLineEndings ]
				  ifFalse: [ string ] ]
]

{ #category : 'converting' }
MCPLineEndings class >> leaving: aJSONValue [
	"aJSONValue with each of its strings as a client reads text: every line ended by a line feed."

	^ self convert: aJSONValue with: [ :string |
			  (string includes: Character cr)
				  ifTrue: [ string withUnixLineEndings ]
				  ifFalse: [ string ] ]
]
