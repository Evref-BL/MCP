"
Replaces the instance-side trait composition of an existing class and returns a DTO describing the old and new trait lists plus the resulting class state.
"
Class {
	#name : 'MCPReplaceClassTraitsCommand',
	#superclass : 'MCPClassCommand',
	#instVars : [
		'traitNames'
	],
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPReplaceClassTraitsCommand class >> className: aClassName traitNames: someTraitNames [

	^ self new
		  className: aClassName;
		  traitNames: someTraitNames;
		  yourself
]

{ #category : 'executing' }
MCPReplaceClassTraitsCommand >> execute [

	| oldTraitNames targetClass |
	targetClass := self targetClass.
	oldTraitNames := self traitNamesFromClass: targetClass.
	targetClass setTraitComposition: self resolvedTraits.
	^ MCPReplaceClassTraitsResult
		  classInfo: (MCPClassInfo fromClass: targetClass)
		  oldTraitNames: oldTraitNames
		  newTraitNames: self traitNames
]

{ #category : 'private' }
MCPReplaceClassTraitsCommand >> resolvedTraits [

	^ self traitNames
		  collect: [ :each |
				  MCPImageLookup traitNamed: each details: {
						  (#class -> self className).
						  (#traits -> self traitNames) } ]
		  as: Array
]

{ #category : 'private' }
MCPReplaceClassTraitsCommand >> targetClass [

	^ MCPImageLookup classNamed: self className
]

{ #category : 'accessing' }
MCPReplaceClassTraitsCommand >> traitNames [

	^ traitNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPReplaceClassTraitsCommand >> traitNames: someNames [

	traitNames := someNames ifNil: [ #(  ) ] ifNotNil: [ someNames asArray ]
]

{ #category : 'private' }
MCPReplaceClassTraitsCommand >> traitNamesFromClass: aClass [

	^ aClass traits collect: [ :each | each name asString ] as: Array
]
