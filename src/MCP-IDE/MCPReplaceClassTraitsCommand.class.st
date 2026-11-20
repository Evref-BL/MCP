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

	^ self currentClass
		  setTraitComposition: (self resolvedTraitsNamed: self traitNames);
		  yourself
]

{ #category : 'accessing' }
MCPReplaceClassTraitsCommand >> traitNames [

	^ traitNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPReplaceClassTraitsCommand >> traitNames: someNames [

	traitNames := someNames ifNil: [ #(  ) ] ifNotNil: [ someNames asArray ]
]
