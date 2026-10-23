"
DTO for compiled method metadata.

It records selector, declaring class, class-side flag, protocol, package, extension status, the trait the method was installed from when there is one, and optionally formatted source text.
"
Class {
	#name : 'MCPCompiledMethodInfo',
	#superclass : 'MCPDataTransferObject',
	#instVars : [
		'className',
		'selector',
		'protocol',
		'packageName',
		'isExtension',
		'source',
		'classSide',
		'traitName'
	],
	#category : 'MCP-DTOs',
	#package : 'MCP',
	#tag : 'DTOs'
}

{ #category : 'instance creation' }
MCPCompiledMethodInfo class >> fromMethod: aCompiledMethod [

	^ self new initializeFromMethod: aCompiledMethod
]

{ #category : 'converting' }
MCPCompiledMethodInfo >> asDictionary [

	| data |
	data := {
		        (#selector -> self selector).
		        (#class -> self className).
		        (#package -> self packageName).
		        (#protocol -> self protocol) } asDictionary.
	self classSide ifTrue: [ data at: #side put: 'class' ].
	self traitName ifNotNil: [ :aTraitName | data at: #trait put: aTraitName ].
	self isExtension ifTrue: [ data at: #isExtension put: true ].
	^ data
]

{ #category : 'accessing' }
MCPCompiledMethodInfo >> className [

	^ className
]

{ #category : 'accessing' }
MCPCompiledMethodInfo >> classSide [

	^ classSide
]

{ #category : 'accessing' }
MCPCompiledMethodInfo >> classSide: anObject [

	classSide := anObject
]

{ #category : 'initialization' }
MCPCompiledMethodInfo >> initializeFromMethod: aCompiledMethod [

	| classPackageName methodPackageName |
	className := aCompiledMethod methodClass instanceSide name asString.
	classSide := aCompiledMethod methodClass isMeta.
	selector := aCompiledMethod selector asString.
	aCompiledMethod isFromTrait ifTrue: [ traitName := aCompiledMethod origin instanceSide name asString ].
	protocol := aCompiledMethod protocol ifNil: [ '' ] ifNotNil: [ :aProtocol | aProtocol name asString ].
	methodPackageName := aCompiledMethod package
		                     ifNil: [ aCompiledMethod methodClass instanceSide package name asString ]
		                     ifNotNil: [ :aPackage | aPackage name asString ].
	packageName := methodPackageName.
	classPackageName := aCompiledMethod methodClass instanceSide package name asString.
	isExtension := packageName ~= classPackageName.
	source := aCompiledMethod sourceCode ifNil: [ '' ].
	^ self
]

{ #category : 'accessing' }
MCPCompiledMethodInfo >> isExtension [

	^ isExtension = true
]

{ #category : 'accessing' }
MCPCompiledMethodInfo >> packageName [

	^ packageName
]

{ #category : 'accessing' }
MCPCompiledMethodInfo >> protocol [

	^ protocol
]

{ #category : 'accessing' }
MCPCompiledMethodInfo >> selector [

	^ selector
]

{ #category : 'accessing' }
MCPCompiledMethodInfo >> source [

	^ source ifNil: [ '' ]
]

{ #category : 'accessing' }
MCPCompiledMethodInfo >> traitName [
	"The trait that defines this method, when the class only carries a copy installed from one."

	^ traitName
]
