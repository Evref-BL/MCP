"
A lost change to the definition of one class or trait. Its states are Epicea's class definitions, compared with the image's definitions on both sides, and installed the way Epicea installs a recorded one, so a definition reads back in the syntax this Pharo recorded it in.
"
Class {
	#name : 'MCPLostClassChange',
	#superclass : 'MCPLostChange',
	#category : 'MCP-IDE-Queries',
	#package : 'MCP-IDE',
	#tag : 'Queries'
}

{ #category : 'restoring' }
MCPLostClassChange >> addDefinitionTo: classChangesByName [

	targetState ifNotNil: [ classChangesByName at: affectedClassName put: self ]
]

{ #category : 'converting' }
MCPLostClassChange >> addTargetTo: aDictionary [
	"The class side shows only where it is what differs from the image, as a class-side slot: elsewhere it says nothing the instance side does not."

	targetState ifNil: [ ^ self ].
	aDictionary at: #definition put: targetState definition.
	self
		imageClassIfPresent: [ :class |
				class classSide definitionString = targetState classSide definition ifFalse: [
					aDictionary at: #classSideDefinition put: targetState classSide definition ] ]
		ifAbsent: [ ]
]

{ #category : 'restoring' }
MCPLostClassChange >> addition [

	^ targetState isTrait
		  ifTrue: [ EpTraitAddition trait: targetState ]
		  ifFalse: [ EpClassAddition class: targetState ]
]

{ #category : 'accessing' }
MCPLostClassChange >> changeDescription [

	^ String streamContents: [ :stream |
			  stream
				  << self kindName;
				  space;
				  << (targetState ifNil: [ 'removed' ] ifNotNil: [
								   (knowsSavedState and: [ savedState isNil ])
									   ifTrue: [ 'added' ]
									   ifFalse: [ 'modified' ] ]) ]
]

{ #category : 'testing' }
MCPLostClassChange >> imageHolds: aClassDefinition [
	"Both sides count: a class-side slot is part of the definition restoring installs."

	^ self
		  imageClassIfPresent: [ :class |
				  aClassDefinition isNotNil and: [
						  class definitionString = aClassDefinition definition and: [
							  class classSide definitionString = aClassDefinition classSide definition ] ] ]
		  ifAbsent: [ aClassDefinition isNil ]
]

{ #category : 'converting' }
MCPLostClassChange >> imageVersionIfPresent: presentBlock ifAbsent: absentBlock [

	^ self imageClassIfPresent: [ :class | presentBlock value: class definitionString ] ifAbsent: absentBlock
]

{ #category : 'accessing' }
MCPLostClassChange >> kindName [
	"What the element is, from a definition the changes recorded."

	^ ({
		   targetState.
		   savedState } detect: [ :each | each isNotNil ] ifFound: [ :definition | definition isTrait ] ifNone: [ false ])
		  ifTrue: [ 'trait' ]
		  ifFalse: [ 'class' ]
]

{ #category : 'restoring' }
MCPLostClassChange >> modificationOf: aClass [

	^ targetState isTrait
		  ifTrue: [ EpTraitModification oldTrait: aClass newTrait: targetState ]
		  ifFalse: [ EpClassModification oldClass: aClass newClass: targetState ]
]

{ #category : 'restoring' }
MCPLostClassChange >> restoreDepthAmong: classChangesByName [
	"A superclass defined among the changes installs before its subclasses. A removal goes the other way: the deepest class first, as the image has it."

	targetState ifNil: [ ^ self imageClassIfPresent: [ :class | class allSuperclasses size negated ] ifAbsent: [ 0 ] ].
	^ classChangesByName
		  at: targetState superclassName asString
		  ifPresent: [ :superclassChange | (superclassChange restoreDepthAmong: classChangesByName) + 1 ]
		  ifAbsent: [ 0 ]
]

{ #category : 'restoring' }
MCPLostClassChange >> restoreIfImpossible: aBlock [
	"A definition installs through the Epicea change that would have recorded it: an addition, which brings the class comment along, for a class the image lacks, a modification for one it has."

	targetState ifNil: [ ^ self imageClassIfPresent: [ :class | class removeFromSystem ] ifAbsent: [ ] ].
	self imageClassIfPresent: [ :class | (self modificationOf: class) applyCodeChange ] ifAbsent: [
			(self superclassIsInImage or: [ targetState isTrait ]) ifFalse: [
					^ aBlock value:
						  (String streamContents: [ :stream | stream << 'Its superclass ' << targetState superclassName << ' is not in the image.' ]) ].
			self addition applyCodeChange ]
]

{ #category : 'restoring' }
MCPLostClassChange >> restorePhase [

	targetState ifNil: [ ^ 6 ].
	^ targetState isTrait
		  ifTrue: [ 1 ]
		  ifFalse: [ 2 ]
]

{ #category : 'testing' }
MCPLostClassChange >> superclassIsInImage [

	^ self class environment includesKey: targetState superclassName asSymbol
]
