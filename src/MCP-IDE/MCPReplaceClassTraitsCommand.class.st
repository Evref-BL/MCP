"
Replaces the instance-side trait composition of an existing class and answers the class.
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

	| targetClass |
	targetClass := self targetClass.
	targetClass setTraitComposition: self resolvedTraits.
	^ targetClass
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
