"
A lost change to one method. Its states are Epicea's method definitions, compared with the image by source and protocol, since restoring installs both. behaviorName is Epicea's name for the class, with ' class' or ' classTrait' for a class side.
"
Class {
	#name : 'MCPLostMethodChange',
	#superclass : 'MCPLostChange',
	#instVars : [
		'behaviorName',
		'selector',
		'sourceMatches'
	],
	#category : 'MCP-IDE-Queries',
	#package : 'MCP-IDE',
	#tag : 'Queries'
}

{ #category : 'instance creation' }
MCPLostMethodChange class >> behaviorName: aBehaviorName selector: aSelector saved: aMethodDefinition [
	"The change to aBehaviorName>>aSelector, which was aMethodDefinition at the save, nil when it did not exist."

	^ self new
		  setBehaviorName: aBehaviorName selector: aSelector;
		  savedState: aMethodDefinition;
		  yourself
]

{ #category : 'accessing' }
MCPLostMethodChange class >> elementForBehaviorNamed: aBehaviorName selector: aSelector [
	"Foo>>bar or Foo class>>bar, the behavior named as Epicea names it: the key under which a method's changes are found again."

	^ String streamContents: [ :stream | stream << aBehaviorName << '>>' << aSelector ]
]

{ #category : 'converting' }
MCPLostMethodChange >> addTargetTo: aDictionary [

	targetState ifNotNil: [
			aDictionary at: #protocol put: targetState protocol asString.
			aDictionary at: #source put: targetState sourceCode ]
]

{ #category : 'accessing' }
MCPLostMethodChange >> changeDescription [

	savedState ifNil: [ ^ 'method added' ].
	^ targetState ifNil: [ 'method removed' ] ifNotNil: [ 'method modified' ]
]

{ #category : 'accessing' }
MCPLostMethodChange >> element [

	^ self class elementForBehaviorNamed: behaviorName selector: selector
]

{ #category : 'private - image' }
MCPLostMethodChange >> imageBehaviorIfPresent: presentBlock ifAbsent: absentBlock [

	^ self
		  imageClassIfPresent: [ :class |
				  presentBlock value: (self isClassSide
						   ifTrue: [ class classSide ]
						   ifFalse: [ class ]) ]
		  ifAbsent: absentBlock
]

{ #category : 'testing' }
MCPLostMethodChange >> imageHolds: aMethodDefinition [
	"Its protocol counts as well as its source, since restoring installs both."

	^ self
		  imageMethodIfPresent: [ :method |
				  aMethodDefinition isNotNil and: [
					  method protocolName asString = aMethodDefinition protocol asString and: [ self source: method matches: aMethodDefinition ] ] ]
		  ifAbsent: [ aMethodDefinition isNil ]
]

{ #category : 'private - image' }
MCPLostMethodChange >> imageMethodIfPresent: presentBlock ifAbsent: absentBlock [
	"The method the image has for the element, its own: one a trait gives the class is the trait's, and restoring does not touch it."

	^ self
		  imageBehaviorIfPresent: [ :behavior |
				  behavior
					  compiledMethodAt: selector
					  ifPresent: [ :method |
							  method isFromTrait
								  ifTrue: [ absentBlock value ]
								  ifFalse: [ presentBlock value: method ] ]
					  ifAbsent: absentBlock ]
		  ifAbsent: absentBlock
]

{ #category : 'converting' }
MCPLostMethodChange >> imageVersionIfPresent: presentBlock ifAbsent: absentBlock [

	^ self imageMethodIfPresent: [ :method | presentBlock value: method sourceCode ] ifAbsent: absentBlock
]

{ #category : 'testing' }
MCPLostMethodChange >> isClassSide [

	^ MCPImageLookup namesClassSide: behaviorName
]

{ #category : 'testing' }
MCPLostMethodChange >> isOfClassNamed: aClassName [

	^ self affectedClassName = aClassName asString
]

{ #category : 'restoring' }
MCPLostMethodChange >> restoreIfImpossible: aBlock [

	self
		imageBehaviorIfPresent: [ :behavior |
				targetState
					ifNil: [ behavior removeSelector: selector ]
					ifNotNil: [ behavior mcpCompile: targetState sourceCode classified: targetState protocol ] ]
		ifAbsent: [
			aBlock value:
				(String streamContents: [ :stream | stream << 'Its class ' << self affectedClassName << ' is not in the image.' ]) ]
]

{ #category : 'restoring' }
MCPLostMethodChange >> restorePhase [

	^ targetState ifNil: [ 5 ] ifNotNil: [ 4 ]
]

{ #category : 'initialization' }
MCPLostMethodChange >> setBehaviorName: aBehaviorName selector: aSelector [

	behaviorName := aBehaviorName asString.
	affectedClassName := MCPImageLookup baseNameOf: behaviorName.
	selector := aSelector asSymbol.
	sourceMatches := IdentityDictionary new
]

{ #category : 'private - image' }
MCPLostMethodChange >> source: aCompiledMethod matches: aMethodDefinition [
	"Whether the method's source is the one aMethodDefinition records. An installed method keeps its source, so the answer holds for as long as the image has that method, and only one compiled since reads its source again."

	| known |
	known := sourceMatches at: aMethodDefinition ifAbsent: [ nil ].
	(known isNotNil and: [ known key == aCompiledMethod ]) ifTrue: [ ^ known value ].
	^ (sourceMatches at: aMethodDefinition put: aCompiledMethod -> (aCompiledMethod sourceCode = aMethodDefinition sourceCode)) value
]
