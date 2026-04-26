"
Replaces the shared pools of an existing class using the Shift class installer and returns a DTO describing the old and new shared pool name lists plus the resulting class state.
"
Class {
	#name : 'MCPReplaceClassSharedPoolsCommand',
	#superclass : 'Object',
	#instVars : [
		'className',
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

{ #category : 'accessing' }
MCPReplaceClassSharedPoolsCommand >> className [

	^ className
]

{ #category : 'accessing' }
MCPReplaceClassSharedPoolsCommand >> className: aString [

	className := aString
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

	^ ShiftClassInstaller
		  update: aClass
		  to: [ :builder | builder sharedPools: self resolvedSharedPools ]
]

{ #category : 'private' }
MCPReplaceClassSharedPoolsCommand >> resolvedSharedPoolNamed: aSharedPoolName [

	| behavior sharedPoolName |
	sharedPoolName := aSharedPoolName.
	behavior := Smalltalk globals
		            at: sharedPoolName asSymbol
		            ifAbsent: [
			            MCPCommandError
				            signalErrorCode: #SharedPoolNotFound
				            message:
				            'Shared pool ' , sharedPoolName , ' does not exist.'
				            details: {
						            (#className -> self className).
						            (#sharedPoolName -> sharedPoolName) } asDictionary ].
	((behavior isBehavior and: [ behavior inheritsFrom: SharedPool ])
		 or: [ behavior = SharedPool ]) ifFalse: [
		MCPCommandError
			signalErrorCode: #InvalidSharedPool
			message: sharedPoolName , ' is not a shared pool.'
			details: {
					(#className -> self className).
					(#sharedPoolName -> sharedPoolName) } asDictionary ].
	^ behavior
]

{ #category : 'private' }
MCPReplaceClassSharedPoolsCommand >> resolvedSharedPools [

	^ self sharedPools
		  collect: [ :each | self resolvedSharedPoolNamed: each ]
		  as: Array
]

{ #category : 'accessing' }
MCPReplaceClassSharedPoolsCommand >> sharedPoolNames [

	^ sharedPoolNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPReplaceClassSharedPoolsCommand >> sharedPoolNames: someNames [

	sharedPoolNames := someNames
		                   ifNil: [ #(  ) ]
		                   ifNotNil: [ someNames asArray ]
]

{ #category : 'private' }
MCPReplaceClassSharedPoolsCommand >> sharedPoolNamesFromClass: aClass [

	^ aClass sharedPools
		  collect: [ :each | each name asString ]
		  as: Array
]

{ #category : 'accessing' }
MCPReplaceClassSharedPoolsCommand >> sharedPools [

	^ self sharedPoolNames
]

{ #category : 'private' }
MCPReplaceClassSharedPoolsCommand >> targetClass [

	^ Smalltalk globals
		  at: self className asSymbol
		  ifAbsent: [
		  MCPCommandError signalMissingClassNamed: self className ]
]
