"
Replaces the shared pools of an existing class using the Shift class installer and answers the updated class.
"
Class {
	#name : 'MCPReplaceClassSharedPoolsCommand',
	#superclass : 'MCPClassCommand',
	#instVars : [
		'sharedPoolNames'
	],
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPReplaceClassSharedPoolsCommand class >> className: aClassName sharedPoolNames: someNames [

	^ self new
		  className: aClassName;
		  sharedPoolNames: someNames;
		  yourself
]

{ #category : 'executing' }
MCPReplaceClassSharedPoolsCommand >> execute [
	"A pool left out goes, and the methods reading its variables are named in a warning first."

	| class |
	class := self currentClass.
	self warnOfMethodsUsing: (self variablesRemovedFrom: class) below: class.
	^ self installing: [ self replaceSharedPoolsOn: class ]
]

{ #category : 'accessing' }
MCPReplaceClassSharedPoolsCommand >> sharedPoolNames [

	^ sharedPoolNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPReplaceClassSharedPoolsCommand >> sharedPoolNames: someNames [

	sharedPoolNames := someNames ifNil: [ #(  ) ] ifNotNil: [ someNames asArray ]
]

{ #category : 'private' }
MCPReplaceClassSharedPoolsCommand >> variablesRemovedFrom: aClass [
	"The variables of the pools aClass names itself that the replacement leaves out, unless its superclass still reads that pool."

	| inherited |
	inherited := aClass superclass ifNil: [ #(  ) ] ifNotNil: [ :superclass | superclass allSharedPools ].
	^ (aClass sharedPools reject: [ :each | (self sharedPoolNames includes: each name asString) or: [ inherited includes: each ] ])
		  flatCollect: [ :each | each classVarNames collect: [ :name | each classVariableNamed: name ] ]
]
