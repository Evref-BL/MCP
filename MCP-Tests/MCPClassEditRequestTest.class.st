"
Tests for parsed edit-class request objects.
"
Class {
	#name : 'MCPClassEditRequestTest',
	#superclass : 'MCPTestCase',
	#category : 'MCP-Tests-Requests',
	#package : 'MCP-Tests',
	#tag : 'Requests'
}

{ #category : 'tests' }
MCPClassEditRequestTest >> testCreateRequestParsesDefinitionArguments [

	| context request |
	request := MCPClassCreateRequest
		           fromRequest: (self toolRequestWithArguments: {
					            (#className -> 'MCPGeneratedClass').
					            (#superclassName -> 'Object').
					            (#packageName -> 'MCP-Generated').
					            (#tag -> 'Models').
					            (#classComment -> 'Generated comment.').
					            (#force -> true).
					            (#slots -> #( 'firstName' 'lastName' )).
					            (#classSlots -> #( 'defaultName' )).
					            (#traits -> #( 'TComparable' )).
					            (#classTraits -> #( 'TComparable classTrait' )).
					            (#sharedVariables -> #( 'Current' )).
					            (#sharedPools -> #( 'ChronologyConstants' )).
					            (#layout -> 'WeakLayout') } asDictionary)
		           tool: MCPToolEditClass new.
	self assert: request className equals: 'MCPGeneratedClass'.
	self assert: request superclassName equals: 'Object'.
	self assert: request packageName equals: 'MCP-Generated'.
	self assert: request tag equals: 'Models'.
	self assert: request classComment equals: 'Generated comment.'.
	self assert: request force.
	self assert: request slotNames equals: #( 'firstName' 'lastName' ).
	self assert: request slots equals: #( #firstName #lastName ).
	self assert: request classSlotNames equals: #( 'defaultName' ).
	self assert: request classSlots equals: #( #defaultName ).
	self assert: request traits equals: #( 'TComparable' ).
	self
		assert: request classTraits
		equals: #( 'TComparable classTrait' ).
	self assert: request sharedVariables equals: #( 'Current' ).
	self assert: request sharedPools equals: #( 'ChronologyConstants' ).
	self assert: request layout equals: 'WeakLayout'.
	context := request requestedContext.
	self assert: (context at: #className) equals: 'MCPGeneratedClass'.
	self assert: (context at: #slots) equals: #( 'firstName' 'lastName' ).
	self assert: (context at: #classComment) equals: 'Generated comment.'
]

{ #category : 'tests' }
MCPClassEditRequestTest >> testUpdateCommandResolvesOmittedMovePackageName [

	| command context editRequest request tool |
	tool := MCPToolEditClass new.
	request := self toolRequestWithArguments: {
			           (#operation -> 'update').
			           (#className -> self class name asString).
			           (#tag -> 'Requests') } asDictionary.
	editRequest := tool parsedRequestFromToolRequest: request.
	command := tool commandForRequest: editRequest.
	context := command moveRequestedContext.
	self
		assert: command classRequest className
		equals: self class name asString.
	self
		assert: command movePackageName
		equals: self class packageName asString.
	self assert: command classRequest tag equals: 'Requests'.
	self
		assert: (context at: #packageName)
		equals: self class packageName asString
]

{ #category : 'tests' }
MCPClassEditRequestTest >> testUpdateRequestParsesSlotArguments [

	| context request |
	request := MCPClassUpdateRequest
		           fromRequest: (self toolRequestWithArguments: {
					            (#className -> 'ExistingClass').
					            (#slotAction -> 'rename').
					            (#slotName -> 'oldName').
					            (#newSlotName -> 'newName').
					            (#classSide -> true).
					            (#force -> true) } asDictionary)
		           tool: MCPToolEditClass new.
	self assert: request className equals: 'ExistingClass'.
	self assert: request slotAction equals: 'rename'.
	self assert: request slotName equals: 'oldName'.
	self assert: request newSlotName equals: 'newName'.
	self assert: request classSide.
	self assert: request force.
	context := request renameSlotRequestedContext.
	self assert: (context at: #className) equals: 'ExistingClass'.
	self assert: (context at: #slotAction) equals: 'rename'.
	self assert: (context at: #slotName) equals: 'oldName'.
	self assert: (context at: #newSlotName) equals: 'newName'.
	self assert: (context at: #classSide)
]

{ #category : 'tests' }
MCPClassEditRequestTest >> testUpdateRequestTracksSuppliedProperties [

	| context request |
	request := MCPClassUpdateRequest
		           fromRequest: (self toolRequestWithArguments: {
					            (#className -> 'ExistingClass').
					            (#tag -> 'Models').
					            (#classComment -> '').
					            (#force -> true).
					            (#slots -> #(  )) } asDictionary)
		           tool: MCPToolEditClass new.
	self assert: request className equals: 'ExistingClass'.
	self assert: request tag equals: 'Models'.
	self assert: request classComment equals: ''.
	self assert: request force.
	self assert: request hasUpdates.
	self assert: (request hasSuppliedPropertyNamed: 'tag').
	self assert: (request hasSuppliedPropertyNamed: 'classComment').
	self assert: (request hasSuppliedPropertyNamed: 'slots').
	self deny: (request hasSuppliedPropertyNamed: 'classSlots').
	self assert: request slotNames isEmpty.
	context := request requestedContext.
	self assert: (context at: #className) equals: 'ExistingClass'.
	self assert: (context at: #tag) equals: 'Models'.
	self assert: (context at: #classComment) equals: ''.
	self assert: (context at: #slots) equals: #(  ).
	self deny: (context includesKey: #classSlots)
]

{ #category : 'tests' }
MCPClassEditRequestTest >> testUpdateRequestWithNoPatchArgumentsHasNoUpdates [

	| context request |
	request := MCPClassUpdateRequest
		           fromRequest: (self toolRequestWithArguments:
				            { (#className -> 'ExistingClass') } asDictionary)
		           tool: MCPToolEditClass new.
	self assert: request className equals: 'ExistingClass'.
	self deny: request hasUpdates.
	self assert: request suppliedProperties isEmpty.
	context := request requestedContext.
	self assert: context size equals: 1.
	self assert: (context at: #className) equals: 'ExistingClass'
]

{ #category : 'private' }
MCPClassEditRequestTest >> toolRequestWithArguments: aDictionary [

	^ MCPToolRequest new
		  tool: MCPToolEditClass new;
		  arguments: aDictionary;
		  yourself
]
