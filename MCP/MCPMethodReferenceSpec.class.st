"
Parsed method reference used inside query predicates. It identifies one compiled method by class name, selector, and whether the class side should be used.
"
Class {
	#name : 'MCPMethodReferenceSpec',
	#superclass : 'Object',
	#instVars : [
		'className',
		'selector',
		'classSide'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'private - parsing' }
MCPMethodReferenceSpec class >> booleanValueNamed: aName in: aDictionary default: defaultValue [

	^ self valueNamed: aName in: aDictionary ifAbsent: [ defaultValue ]
]

{ #category : 'instance creation' }
MCPMethodReferenceSpec class >> className: aClassName selector: aSelector classSide: aBoolean [

	^ self new
		  initializeClassName: aClassName
		  selector: aSelector
		  classSide: aBoolean
]

{ #category : 'instance creation' }
MCPMethodReferenceSpec class >> fromValue: rawValue [

	(self isDictionaryLike: rawValue) ifFalse: [
		Error signal: 'equivalentTo must be an object.' ].
	^ self
		  className: (self
				   requiredStringValueNamed: 'className'
				   in: rawValue
				   for: 'equivalentTo')
		  selector: (self
				   requiredStringValueNamed: 'selector'
				   in: rawValue
				   for: 'equivalentTo')
		  classSide:
		  (self booleanValueNamed: 'classSide' in: rawValue default: false)
]

{ #category : 'private - parsing' }
MCPMethodReferenceSpec class >> isDictionaryLike: aValue [

	aValue ifNil: [ ^ false ].
	^ aValue isDictionary
]

{ #category : 'private - parsing' }
MCPMethodReferenceSpec class >> requiredStringValueNamed: aName in: aDictionary for: predicateName [

	| valueString |
	valueString := self
		               stringValueNamed: aName
		               in: aDictionary
		               default: nil.
	valueString ifNil: [
		Error signal:
			predicateName , ' method reference requires ' , aName , '.' ].
	^ valueString
]

{ #category : 'private - parsing' }
MCPMethodReferenceSpec class >> stringValueFrom: aValue [

	| normalized |
	aValue ifNil: [ ^ nil ].
	normalized := aValue asString trimBoth.
	^ normalized isEmpty
		  ifTrue: [ nil ]
		  ifFalse: [ normalized ]
]

{ #category : 'private - parsing' }
MCPMethodReferenceSpec class >> stringValueNamed: aName in: aDictionary default: defaultValue [

	| rawValue |
	rawValue := self
		            valueNamed: aName
		            in: aDictionary
		            ifAbsent: [ ^ defaultValue ].
	^ (self stringValueFrom: rawValue)
		  ifNil: [ defaultValue ]
		  ifNotNil: [ :valueString | valueString ]
]

{ #category : 'private - parsing' }
MCPMethodReferenceSpec class >> valueNamed: aName in: aDictionary ifAbsent: absentBlock [

	^ aDictionary
		  at: aName asSymbol
		  ifAbsent: [ aDictionary at: aName asString ifAbsent: absentBlock ]
]

{ #category : 'converting' }
MCPMethodReferenceSpec >> asDictionary [

	^ {
		  (#className -> self className).
		  (#selector -> self selector).
		  (#classSide -> self classSide) } asDictionary
]

{ #category : 'resolving' }
MCPMethodReferenceSpec >> behavior [

	| baseClass |
	baseClass := Smalltalk globals
		             at: self className asSymbol
		             ifAbsent: [
		             MCPCommandError signalMissingClassNamed: self className ].
	^ self classSide
		  ifTrue: [ baseClass classSide ]
		  ifFalse: [ baseClass ]
]

{ #category : 'accessing' }
MCPMethodReferenceSpec >> cacheKey [

	^ {
		  self className.
		  self selector.
		  self classSide }
]

{ #category : 'accessing' }
MCPMethodReferenceSpec >> className [

	^ className
]

{ #category : 'accessing' }
MCPMethodReferenceSpec >> classSide [

	^ classSide ifNil: [ false ]
]

{ #category : 'resolving' }
MCPMethodReferenceSpec >> compiledMethod [

	| behavior selectorSymbol |
	behavior := self behavior.
	selectorSymbol := self selector asSymbol.
	(behavior includesSelector: selectorSymbol) ifFalse: [
		MCPCommandError
			signalMissingMethodInClassName: self className
			classSide: self classSide
			selector: self selector ].
	^ behavior compiledMethodAt: selectorSymbol
]

{ #category : 'initialization' }
MCPMethodReferenceSpec >> initializeClassName: aClassName selector: aSelector classSide: aBoolean [

	className := aClassName.
	selector := aSelector.
	classSide := aBoolean ifNil: [ false ].
	^ self
]

{ #category : 'printing' }
MCPMethodReferenceSpec >> printOn: aStream [

	aStream nextPutAll: self className.
	self classSide ifTrue: [ aStream nextPutAll: ' class' ].
	aStream
		nextPutAll: '>>';
		nextPutAll: self selector
]

{ #category : 'accessing' }
MCPMethodReferenceSpec >> selector [

	^ selector
]
