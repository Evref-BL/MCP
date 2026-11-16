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

	^ self replaceSharedPoolsOn: self targetClass
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

{ #category : 'accessing' }
MCPReplaceClassSharedPoolsCommand >> sharedPools [

	^ self sharedPoolNames
]

{ #category : 'private' }
MCPReplaceClassSharedPoolsCommand >> targetClass [

	^ MCPImageLookup classNamed: self className
]
