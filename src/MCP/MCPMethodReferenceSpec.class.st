"
Parsed method reference used by specialized method lookup tools. It identifies one compiled method by class name, selector, and whether the class side should be used.
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

{ #category : 'instance creation' }
MCPMethodReferenceSpec class >> className: aClassName selector: aSelector classSide: aBoolean [

	^ self new initializeClassName: aClassName selector: aSelector classSide: aBoolean
]

{ #category : 'resolving' }
MCPMethodReferenceSpec >> behavior [

	| baseClass |
	baseClass := MCPImageLookup classNamed: self className.
	^ self classSide
		  ifTrue: [ baseClass classSide ]
		  ifFalse: [ baseClass ]
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
		MCPCommandError signalMissingMethodInClassName: self className classSide: self classSide selector: self selector ].
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
