Class {
	#name : 'MCPMessageSendHandler',
	#superclass : 'JRPCMessageSendHandler',
	#category : 'MCP-Server',
	#package : 'MCP',
	#tag : 'Server'
}

{ #category : 'parameters-checking' }
MCPMessageSendHandler >> checkParametersForRequest: aJRPCRequestObject [

	aJRPCRequestObject params ifNil: [
		self parametersCount = 0 ifFalse: [ JRPCInvalidParameters signal ] ].


	(aJRPCRequestObject params isDictionary or: [
		 aJRPCRequestObject params isNil ]) ifFalse: [
		JRPCInvalidParameters signal ]
]

{ #category : 'evaluation' }
MCPMessageSendHandler >> executeWithArguments: anArrayOrDictionary [

	| arguments |
	arguments := anArrayOrDictionary.

	anArrayOrDictionary ifNil: [ arguments := #(  ) ].

	anArrayOrDictionary isDictionary ifTrue: [
		arguments := OrderedCollection new.
		arguments addAll: (self parametersNames collect: [ :name |
				 anArrayOrDictionary at: name ifAbsent: [ nil ] ]).
		arguments := arguments asArray ].

	^ self send: self messageSelector to: self receiver with: arguments
]

{ #category : 'accessing' }
MCPMessageSendHandler >> parametersNames [

	^ (self receiver class lookupSelector: self messageSelector)
		  argumentNames
]
