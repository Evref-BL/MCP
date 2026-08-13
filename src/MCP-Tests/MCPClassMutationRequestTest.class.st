"
Tests parsed class creation and update request objects used by class mutation tools.
"
Class {
	#name : 'MCPClassMutationRequestTest',
	#superclass : 'MCPTestCase',
	#category : 'MCP-Tests-Requests',
	#package : 'MCP-Tests',
	#tag : 'Requests'
}

{ #category : 'tests' }
MCPClassMutationRequestTest >> testCreateRequestParsesDefinitionArguments [

	| context request |
	request := MCPClassCreateRequest
		           fromRequest: (MCPToolRequest new
				            tool: MCPToolCreateClass new;
				            arguments: {
						            (#className -> 'MCPGeneratedClass').
						            (#superclassName -> 'Object').
						            (#packageName -> 'MCP-Generated').
						            (#tag -> 'Models').
						            (#comment -> 'Generated comment.').
						            (#force -> true).
						            (#slots -> #( 'firstName' 'lastName' )).
						            (#classSlots -> #( 'defaultName' )).
						            (#traits -> #( 'TComparable' )).
						            (#classTraits -> #( 'TComparable classTrait' )).
						            (#sharedVariables -> #( 'Current' )).
						            (#sharedPools -> #( 'ChronologyConstants' )).
						            (#layout -> 'WeakLayout') } asDictionary;
				            yourself)
		           tool: MCPToolCreateClass new.
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
	self assert: request classTraits equals: #( 'TComparable classTrait' ).
	self assert: request sharedVariables equals: #( 'Current' ).
	self assert: request sharedPools equals: #( 'ChronologyConstants' ).
	self assert: request layout equals: 'WeakLayout'.
	context := request requestedContext.
	self assert: (context at: #className) equals: 'MCPGeneratedClass'.
	self assert: (context at: #slots) equals: #( 'firstName' 'lastName' ).
	self assert: (context at: #comment) equals: 'Generated comment.'
]

{ #category : 'tests' }
MCPClassMutationRequestTest >> testUpdateCommandResolvesOmittedMovePackageName [

	| command context mutationRequest request tool |
	tool := MCPToolUpdateClassPackage new.
	request := MCPToolRequest new
		           tool: tool;
		           arguments: {
				           (#className -> self class name asString).
				           (#tag -> 'Requests') } asDictionary;
		           yourself.
	mutationRequest := tool parsedRequestFromToolRequest: request.
	command := tool commandForRequest: mutationRequest.
	context := command moveRequestedContext.
	self assert: command classRequest className equals: self class name asString.
	self assert: command movePackageName equals: self class packageName asString.
	self assert: command classRequest tag equals: 'Requests'.
	self assert: (context at: #packageName) equals: self class packageName asString
]

{ #category : 'tests' }
MCPClassMutationRequestTest >> testUpdateRequestParsesSlotArguments [

	| context request tool |
	tool := MCPToolUpdateClassSlotName new.
	request := MCPClassUpdateRequest
		           fromRequest: (self toolRequestWithArguments: {
					            (#className -> 'ExistingClass').
					            (#slotAction -> 'rename').
					            (#slotName -> 'oldName').
					            (#newSlotName -> 'newName').
					            (#classSide -> true).
					            (#force -> true) } asDictionary)
		           tool: tool.
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
MCPClassMutationRequestTest >> testUpdateRequestTracksSuppliedProperties [

	| context request tool |
	tool := MCPToolUpdateClassSlots new.
	request := MCPClassUpdateRequest
		           fromRequest: (self toolRequestWithArguments: {
					            (#className -> 'ExistingClass').
					            (#tag -> 'Models').
					            (#comment -> '').
					            (#force -> true).
					            (#slots -> #(  )) } asDictionary)
		           tool: tool.
	self assert: request className equals: 'ExistingClass'.
	self assert: request tag equals: 'Models'.
	self assert: request classComment equals: ''.
	self assert: request force.
	self assert: request hasUpdates.
	self assert: (request hasSuppliedPropertyNamed: 'tag').
	self assert: (request hasSuppliedPropertyNamed: 'comment').
	self assert: (request hasSuppliedPropertyNamed: 'slots').
	self deny: (request hasSuppliedPropertyNamed: 'classSlots').
	self assert: request slotNames isEmpty.
	context := request requestedContext.
	self assert: (context at: #className) equals: 'ExistingClass'.
	self assert: (context at: #tag) equals: 'Models'.
	self assert: (context at: #comment) equals: ''.
	self assert: (context at: #slots) equals: #(  ).
	self deny: (context includesKey: #classSlots)
]

{ #category : 'tests' }
MCPClassMutationRequestTest >> testUpdateRequestWithNoPatchArgumentsHasNoUpdates [

	| context request tool |
	tool := MCPToolUpdateClassSlots new.
	request := MCPClassUpdateRequest
		           fromRequest: (self toolRequestWithArguments: { (#className -> 'ExistingClass') } asDictionary)
		           tool: tool.
	self assert: request className equals: 'ExistingClass'.
	self deny: request hasUpdates.
	self assert: request suppliedProperties isEmpty.
	context := request requestedContext.
	self assert: context size equals: 1.
	self assert: (context at: #className) equals: 'ExistingClass'
]

{ #category : 'private' }
MCPClassMutationRequestTest >> toolRequestWithArguments: aDictionary [

	^ MCPToolRequest new
		  tool: MCPToolUpdateClassSlots new;
		  arguments: aDictionary;
		  yourself
]
