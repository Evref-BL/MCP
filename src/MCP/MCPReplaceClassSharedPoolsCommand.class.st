"
Replaces the shared pools of an existing class using the Shift class installer and returns a DTO describing the old and new shared pool name lists plus the resulting class state.
"
Class {
	#name : 'MCPReplaceClassSharedPoolsCommand',
	#superclass : 'MCPClassCommand',
	#instVars : [
		'sharedPoolNames'
	],
	#category : 'MCP-Commands',
	#package : 'MCP',
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

	| oldSharedPoolNames targetClass updatedClass |
	targetClass := self targetClass.
	oldSharedPoolNames := self sharedPoolNamesFromClass: targetClass.
	updatedClass := self replaceSharedPoolsOn: targetClass.
	^ MCPReplaceClassSharedPoolsResult
		  classInfo: (MCPClassInfo fromClass: updatedClass)
		  oldSharedPoolNames: oldSharedPoolNames
		  newSharedPoolNames: self sharedPoolNames
]

{ #category : 'private' }
MCPReplaceClassSharedPoolsCommand >> replaceSharedPoolsOn: aClass [

	^ ShiftClassInstaller update: aClass to: [ :builder | builder sharedPools: self resolvedSharedPools ]
]

{ #category : 'private' }
MCPReplaceClassSharedPoolsCommand >> resolvedSharedPools [

	^ self sharedPools collect: [ :each | self resolvedSharedPoolNamed: each ] as: Array
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
MCPReplaceClassSharedPoolsCommand >> sharedPoolNamesFromClass: aClass [

	^ aClass sharedPools collect: [ :each | each name asString ] as: Array
]

{ #category : 'accessing' }
MCPReplaceClassSharedPoolsCommand >> sharedPools [

	^ self sharedPoolNames
]

{ #category : 'private' }
MCPReplaceClassSharedPoolsCommand >> targetClass [

	^ MCPImageLookup classNamed: self className
]
