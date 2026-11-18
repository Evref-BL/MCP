"
A method as a Tonel file writes it, read back as the source method_compile compiles: `{ #category : 'accessing' }`, then `Foo >> bar [`, the body, and `]`. The category line may be left out. Tonel v1 writes the category as a symbol, v2 and v3 as a string; the class side reads `Foo class >> bar [`.

A source that begins with the category line alone, followed by a selector line or a method's reference, is read too: the line gives the protocol and the rest is the source.

No method Pharo compiles can begin with `{`, or with a class name followed by `>>`, so no source that compiles as written is read as Tonel. Pharo's own TonelParser reads it, so brackets in strings and comments are left alone.
"
Class {
	#name : 'MCPTonelMethodSource',
	#superclass : 'Object',
	#instVars : [
		'category',
		'className',
		'classSide',
		'header',
		'source'
	],
	#category : 'MCP-IDE-Utilities',
	#package : 'MCP-IDE',
	#tag : 'Utilities'
}

{ #category : 'private' }
MCPTonelMethodSource class >> categoryIn: aMetadata [
	"The category a Tonel method's metadata gives, as a string: Tonel v1 writes it as a symbol, v2 and v3 as a string. nil when it gives none."

	^ (aMetadata isDictionary ifTrue: [ aMetadata at: #category ifAbsent: [ nil ] ]) ifNotNil: [ :category | category asString ]
]

{ #category : 'instance creation' }
MCPTonelMethodSource class >> fromString: aString [
	"The Tonel method aString writes, or nil when it writes none: it begins neither with a category line nor with a method header, or something other than blanks follows the method's closing bracket. A category line followed by no header leaves the rest of aString as the source. The source ends at its last character that is not a blank, as every other source method_compile is given does: Tonel's reader leaves in the body the empty lines above the closing bracket."

	| category hasMetadata header parser stream |
	aString isString ifFalse: [ ^ nil ].
	stream := aString readStream.
	parser := TonelParser on: stream.
	^ [
		  parser separator.
		  hasMetadata := stream peek = ${.
		  hasMetadata ifTrue: [
				  category := self categoryIn: parser metadata.
				  parser separator ].
		  header := self headerLineAt: stream.
		  header
			  ifNil: [
					  hasMetadata ifTrue: [
							  self new
								  setCategory: category source: stream upToEnd trimRight;
								  yourself ] ]
			  ifNotNil: [
					  | body signature |
					  signature := parser method.
					  body := parser methodBody.
					  parser separator.
					  stream atEnd ifTrue: [
							  self new
								  setCategory: category source: (signature second , body) trimRight;
								  setHeader: header className: signature first first classSide: signature first second isNotNil;
								  yourself ] ] ]
		  on: Error
		  do: [ nil ]
]

{ #category : 'private' }
MCPTonelMethodSource class >> headerLineAt: aStream [
	"The method header aStream is at, as Foo >> bar: x [ or Foo class >> bar [, up to its bracket and without the spaces around it; nil when the line it is at is not one. aStream is left where it was."

	| line position |
	position := aStream position.
	line := [ aStream nextLine ifNil: [ '' ] ] ensure: [ aStream position: position ].
	(line matchesRegex: '[A-Za-z_][A-Za-z0-9_]*(\s+class)?\s*>>.*\[.*') ifFalse: [ ^ nil ].
	^ (line copyUpTo: $[) trimBoth
]

{ #category : 'instance creation' }
MCPTonelMethodSource class >> methodTextsIn: aString [
	"The text of each method aString writes as a Tonel file does, its category line included, when it writes more than one, as a page class_get answers does; empty when it writes one or none, or anything else."

	| parser stream texts |
	aString isString ifFalse: [ ^ #(  ) ].
	stream := aString readStream.
	parser := TonelParser on: stream.
	texts := OrderedCollection new.
	^ [
		  parser separator.
		  [ stream atEnd ] whileFalse: [
				  | start |
				  start := stream position.
				  stream peek = ${ ifTrue: [
						  parser metadata.
						  parser separator ].
				  (self headerLineAt: stream) ifNil: [ ^ #(  ) ].
				  parser method.
				  parser methodBody.
				  texts add: (aString copyFrom: start + 1 to: stream position).
				  parser separator ].
		  texts size > 1
			  ifTrue: [ texts asArray ]
			  ifFalse: [ #(  ) ] ]
		  on: Error
		  do: [ #(  ) ]
]

{ #category : 'accessing' }
MCPTonelMethodSource >> category [
	"The protocol the category line gives, or nil when there is none."

	^ category
]

{ #category : 'accessing' }
MCPTonelMethodSource >> className [
	"The class the method's header names, without its side; nil when the source has no header."

	^ className
]

{ #category : 'accessing' }
MCPTonelMethodSource >> classSide [
	"Whether the method's header names the class side."

	^ classSide = true
]

{ #category : 'accessing' }
MCPTonelMethodSource >> hasHeader [
	"Whether the source began with a method header, Foo >> bar [, which names the class and side."

	^ className isNotNil
]

{ #category : 'accessing' }
MCPTonelMethodSource >> header [
	"The method's header as written, Foo class >> bar: x, without its bracket; nil when the source has none."

	^ header
]

{ #category : 'initialization' }
MCPTonelMethodSource >> setCategory: aCategory source: aSource [

	category := aCategory.
	source := aSource
]

{ #category : 'initialization' }
MCPTonelMethodSource >> setHeader: aHeader className: aClassName classSide: aBoolean [

	header := aHeader.
	className := aClassName.
	classSide := aBoolean
]

{ #category : 'accessing' }
MCPTonelMethodSource >> source [
	"The method's source from its selector line on, without the header's class and brackets: what method_compile compiles."

	^ source
]
