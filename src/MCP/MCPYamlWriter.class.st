"
Writes a payload as YAML, for a result that has to be read without guessing.

Plain lines are compact but cannot say whether a value is a number or the text of one, whether a list holds one item or is a single string containing a comma, or where a value ends when it contains spaces. YAML answers all three, and every scalar it writes here is a JSON scalar, which YAML accepts, so the output parses as both.
"
Class {
	#name : 'MCPYamlWriter',
	#superclass : 'Object',
	#category : 'MCP-Utilities',
	#package : 'MCP',
	#tag : 'Utilities'
}

{ #category : 'writing' }
MCPYamlWriter class >> yamlFor: anObject indent: anIndentString [

	^ String streamContents: [ :stream | self new writeValue: anObject on: stream indent: anIndentString ]
]

{ #category : 'private - writing' }
MCPYamlWriter >> isScalar: value [

	^ value isDictionary not and: [ value isString or: [ value isCollection not ] ]
]

{ #category : 'private - writing' }
MCPYamlWriter >> needsQuoting: aString [
	"Quote whenever a bare scalar could be read as something else: as a number, as a boolean, as the start of a list or comment, or as a key."

	aString isEmpty ifTrue: [ ^ true ].
	(#( 'true' 'false' 'null' 'yes' 'no' 'on' 'off' '~' ) includes: aString asLowercase) ifTrue: [ ^ true ].
	aString first isLetter ifFalse: [ ^ true ].
	aString last isSeparator ifTrue: [ ^ true ].
	(aString includesSubstring: ': ') ifTrue: [ ^ true ].
	(aString includesSubstring: ' #') ifTrue: [ ^ true ].
	^ aString anySatisfy: [ :each | each = $" or: [ each = $' or: [ each isSeparator and: [ each ~= Character space ] ] ] ]
]

{ #category : 'private - writing' }
MCPYamlWriter >> scalarFor: value [
	"Answer the value as a JSON scalar, which YAML reads the same way."

	value ifNil: [ ^ 'null' ].
	value == true ifTrue: [ ^ 'true' ].
	value == false ifTrue: [ ^ 'false' ].
	value isNumber ifTrue: [ ^ value printString ].
	^ (self needsQuoting: value asString)
		  ifTrue: [
				  String streamContents: [ :stream |
						  stream nextPut: $".
						  value asString do: [ :each |
								  each = $" ifTrue: [ stream nextPutAll: '\"' ].
								  each = $\ ifTrue: [ stream nextPutAll: '\\' ].
								  each = Character lf ifTrue: [ stream nextPutAll: '\n' ].
								  each = Character cr ifTrue: [ stream nextPutAll: '\n' ].
								  each = Character tab ifTrue: [ stream nextPutAll: '\t' ].
								  ((#( $" $\ ) includes: each) or: [ each isSeparator and: [ each ~= Character space ] ]) ifFalse: [ stream nextPut: each ] ].
						  stream nextPut: $" ] ]
		  ifFalse: [ value asString ]
]

{ #category : 'private - writing' }
MCPYamlWriter >> writeSequence: aCollection on: stream indent: indent [
	"A list of scalars reads in flow style, which is compact and still bracketed; a list of structures takes a block entry each, whose first key sits on the dash."

	aCollection ifEmpty: [ ^ stream nextPutAll: ' []' ].
	(aCollection allSatisfy: [ :each | self isScalar: each ]) ifTrue: [
			stream nextPutAll: ' ['.
			aCollection do: [ :each | stream nextPutAll: (self scalarFor: each) ] separatedBy: [ stream nextPutAll: ', ' ].
			^ stream nextPut: $] ].
	aCollection do: [ :each |
			stream
				nextPut: Character lf;
				nextPutAll: indent;
				nextPutAll: '- '.
			(self isScalar: each)
				ifTrue: [ stream nextPutAll: (self scalarFor: each) ]
				ifFalse: [
						| nested |
						nested := String streamContents: [ :each2 | self writeValue: each on: each2 indent: indent , '  ' ].
						stream nextPutAll: (nested allButFirst: indent size + 2) ] ]
]

{ #category : 'writing' }
MCPYamlWriter >> writeValue: value on: stream indent: indent [
	"Write value without a trailing line feed, so a caller decides what follows it."

	| keys |
	(self isScalar: value) ifTrue: [ ^ stream nextPutAll: (self scalarFor: value) ].
	value isDictionary ifFalse: [ ^ self writeSequence: value on: stream indent: indent ].
	value ifEmpty: [ ^ stream nextPutAll: '{}' ].
	keys := value keys asSortedCollection: [ :left :right | left asString <= right asString ].
	keys
		do: [ :key |
				| each |
				each := value at: key.
				stream
					nextPutAll: indent;
					nextPutAll: (self scalarFor: key asString);
					nextPut: $:.
				(self isScalar: each)
					ifTrue: [
							stream
								space;
								nextPutAll: (self scalarFor: each) ]
					ifFalse: [
							(each isDictionary and: [ each notEmpty ])
								ifTrue: [
										stream nextPut: Character lf.
										self writeValue: each on: stream indent: indent , '  ' ]
								ifFalse: [
										each isDictionary
											ifTrue: [ stream nextPutAll: ' {}' ]
											ifFalse: [ self writeSequence: each on: stream indent: indent ] ] ] ]
		separatedBy: [ stream nextPut: Character lf ]
]
