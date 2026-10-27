"
Names one method as a piece of text, the way a search result prints it.

The forms accepted are deliberately wide, because the exact Smalltalk spelling is not what a caller should have to get right: `MCPTool>>batchSummaryNoun`, `MCPTool>>#batchSummaryNoun`, `MCPTool#batchSummaryNoun` and `MCPTool class>>toolName` all name a method, with any spacing around the separator.
"
Class {
	#name : 'MCPMethodReference',
	#superclass : 'Object',
	#instVars : [
		'className',
		'classSide',
		'selector'
	],
	#category : 'MCP-IDE-Utilities',
	#package : 'MCP-IDE',
	#tag : 'Utilities'
}

{ #category : 'instance creation' }
MCPMethodReference class >> fromString: aString [
	"Answer the method aString names, or nil when it names no class and is therefore a bare selector."

	| text separatorIndex head tail side name |
	aString ifNil: [ ^ nil ].
	text := aString asString trimBoth.
	separatorIndex := self separatorIndexIn: text.
	separatorIndex isZero ifTrue: [ ^ nil ].
	head := (text first: separatorIndex - 1) trimBoth.
	tail := (text allButFirst: separatorIndex - 1) trimBoth.
	[ tail notEmpty and: [ '>#' includes: tail first ] ] whileTrue: [ tail := tail allButFirst trimBoth ].
	side := head asLowercase endsWith: ' class'.
	name := side
		        ifTrue: [ (head first: head size - 6) trimBoth ]
		        ifFalse: [ head ].
	(self namesAClass: name) ifFalse: [ ^ nil ].
	tail ifEmpty: [ ^ nil ].
	^ self new
		  initializeClassName: name
		  classSide: side
		  selector: tail
]

{ #category : 'accessing' }
MCPMethodReference class >> helpText [
	"What to tell a caller whose text was meant to name a method and did not."

	^ 'Write a method as Class>>selector, or Class class>>selector for the class side. A bare selector works too when className is given.'
]

{ #category : 'testing' }
MCPMethodReference class >> looksLikeAReference: aString [
	"Whether the caller was trying to name a class, however they spelled the rest."

	aString ifNil: [ ^ false ].
	^ (self separatorIndexIn: aString asString trimBoth) isZero not
]

{ #category : 'testing' }
MCPMethodReference class >> namesAClass: aString [

	^ aString notEmpty and: [
		  aString first isUppercase and: [ aString allSatisfy: [ :character | character isAlphaNumeric or: [ character = $_ ] ] ] ]
]

{ #category : 'private' }
MCPMethodReference class >> separatorIndexIn: aString [
	"Answer where the class stops, whichever separator the caller reached for."

	| index |
	index := aString indexOfSubCollection: '>>'.
	index isZero ifFalse: [ ^ index ].
	^ aString indexOf: $#
]

{ #category : 'accessing' }
MCPMethodReference >> className [

	^ className
]

{ #category : 'accessing' }
MCPMethodReference >> classSide [

	^ classSide
]

{ #category : 'initialization' }
MCPMethodReference >> initializeClassName: aClassName classSide: aBoolean selector: aSelector [

	className := aClassName.
	classSide := aBoolean.
	selector := aSelector.
	^ self
]

{ #category : 'printing' }
MCPMethodReference >> printOn: aStream [

	aStream
		nextPutAll: className;
		nextPutAll: (classSide
				 ifTrue: [ ' class>>' ]
				 ifFalse: [ '>>' ]);
		nextPutAll: selector
]

{ #category : 'accessing' }
MCPMethodReference >> selector [

	^ selector
]
