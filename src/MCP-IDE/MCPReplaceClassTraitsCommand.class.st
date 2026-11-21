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
	"A trait left out takes its slots with it, and the methods of the class using them are named in a warning first."

	| class |
	class := self currentClass.
	self warnOfMethodsUsing: (self variablesRemovedFrom: class) below: class.
	self installing: [ class setTraitComposition: (self resolvedTraitsNamed: self traitNames) ].
	^ self currentClass
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
MCPReplaceClassTraitsCommand >> variablesRemovedFrom: aClass [
	"The slots, on either side, that aClass has from a trait the replacement leaves out, a trait being kept when one of the traits named supplies it."

	| kept |
	kept := (self resolvedTraitsNamed: self traitNames) flatCollect: [ :each | each allTraits copyWith: each ].
	^ {
		  aClass.
		  aClass classSide } flatCollect: [ :behavior |
			  behavior slots select: [ :each |
					  each definingClass isTrait and: [
						  (kept anySatisfy: [ :trait | trait == each definingClass or: [ trait classSide == each definingClass ] ]) not ] ] ]
]
