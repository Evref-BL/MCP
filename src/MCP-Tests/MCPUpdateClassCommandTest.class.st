"
Tests the class update command orchestrator used behind class mutation tools.
"
Class {
	#name : 'MCPUpdateClassCommandTest',
	#superclass : 'MCPCommandTestCase',
	#category : 'MCP-Tests-Commands',
	#package : 'MCP-Tests',
	#tag : 'Commands'
}

{ #category : 'private' }
MCPUpdateClassCommandTest >> classToolClassForArguments: arguments slotAction: slotAction [

	((arguments includesKey: #superclass) and: [ arguments includesKey: #package ]) ifTrue: [ ^ MCPToolCreateClass ].
	slotAction = 'add' ifTrue: [ ^ MCPToolAddClassSlot ].
	slotAction = 'remove' ifTrue: [ ^ MCPToolRemoveClassSlot ].
	slotAction = 'rename' ifTrue: [ ^ MCPToolUpdateClassSlotName ].
	slotAction = 'pullUp' ifTrue: [ ^ MCPToolPullUpClassSlot ].
	slotAction = 'pushDown' ifTrue: [ ^ MCPToolPushDownClassSlot ].
	(arguments includesKey: #newName) ifTrue: [ ^ MCPToolUpdateClassName ].
	(arguments includesKey: #comment) ifTrue: [ ^ MCPToolUpdateClassComment ].
	(arguments includesKey: #traits) ifTrue: [ ^ MCPToolUpdateClassTraits ].
	(arguments includesKey: #classTraits) ifTrue: [ ^ MCPToolUpdateClassSideTraits ].
	(arguments includesKey: #sharedVariables) ifTrue: [ ^ MCPToolUpdateClassSharedVariables ].
	(arguments includesKey: #sharedPools) ifTrue: [ ^ MCPToolUpdateClassSharedPools ].
	(arguments includesKey: #layout) ifTrue: [ ^ MCPToolUpdateClassLayout ].
	((arguments includesKey: #slots) or: [ arguments includesKey: #classSlots ]) ifTrue: [ ^ MCPToolUpdateClassSlots ].
	(arguments includesKey: #superclass) ifTrue: [ ^ MCPToolUpdateClassSuperclass ].
	((arguments includesKey: #package) or: [ arguments includesKey: #tag ]) ifTrue: [ ^ MCPToolUpdateClassPackage ].
	^ MCPToolUpdateClassComment
]

{ #category : 'private' }
MCPUpdateClassCommandTest >> commandForArguments: arguments [

	| action mutationRequest rawArguments slotAction tool toolClass toolRequest |
	rawArguments := arguments copy.
	action := rawArguments removeKey: #action ifAbsent: [ nil ].
	slotAction := rawArguments removeKey: #slotAction ifAbsent: [ nil ].
	toolClass := action = 'create'
		             ifTrue: [ MCPToolCreateClass ]
		             ifFalse: [ self classToolClassForArguments: rawArguments slotAction: slotAction ].
	tool := toolClass new.
	toolRequest := tool requestFromToolCallArguments: rawArguments.
	mutationRequest := tool parsedRequestFromToolRequest: toolRequest.
	^ tool commandForRequest: mutationRequest
]

{ #category : 'tests' }
MCPUpdateClassCommandTest >> testAppliedChangeResultWrapsPlanAndResult [

	| appliedChange changeResult data plan |
	plan := MCPClassUpdatePlanInfo updateAction: 'setComment' requestedContext: { (#name -> 'Object') } asDictionary.
	changeResult := MCPChangeClassCommentResult
		                classInfo: (MCPClassInfo fromClass: Object)
		                oldClassComment: 'old'
		                newClassComment: 'new'.
	appliedChange := MCPClassAppliedChangeResult updatePlan: plan changeResult: changeResult.
	data := appliedChange asDictionary.
	self assert: data isEmpty
]

{ #category : 'tests' }
MCPUpdateClassCommandTest >> testBuildsClassTraitReplacementUpdatePlan [

	| command context plan |
	command := self commandForArguments: (self updateArgumentsWith: { (#classTraits -> #( 'TAbleToRotate classTrait' )) }).
	plan := command updatePlan.
	context := plan requestedContext.
	self assert: plan updateAction equals: 'replaceClassTraits'.
	self assert: (context at: #name) equals: 'Object'.
	self assert: (context at: #classTraits) equals: #( 'TAbleToRotate classTrait' )
]

{ #category : 'tests' }
MCPUpdateClassCommandTest >> testBuildsDefinitionReplacementUpdatePlan [

	| command context plan |
	command := self commandForArguments: (self updateArgumentsWith: {
				            (#slots -> #( 'first' 'second' )).
				            (#classSlots -> #( 'Current' )) }).
	plan := command updatePlan.
	context := plan requestedContext.
	self assert: plan updateAction equals: 'replaceDefinition'.
	self assert: (context at: #name) equals: 'Object'.
	self assert: (context at: #slots) equals: #( 'first' 'second' ).
	self assert: (context at: #classSlots) equals: #( 'Current' )
]

{ #category : 'tests' }
MCPUpdateClassCommandTest >> testBuildsLayoutReplacementUpdatePlan [

	| command context plan |
	command := self commandForArguments: (self updateArgumentsWith: { (#layout -> 'WeakLayout') }).
	plan := command updatePlan.
	context := plan requestedContext.
	self assert: plan updateAction equals: 'replaceLayout'.
	self assert: (context at: #name) equals: 'Object'.
	self assert: (context at: #layout) equals: 'WeakLayout'
]

{ #category : 'tests' }
MCPUpdateClassCommandTest >> testBuildsSharedPoolReplacementUpdatePlan [

	| command context plan |
	command := self commandForArguments: (self updateArgumentsWith: { (#sharedPools -> #( 'ChronologyConstants' )) }).
	plan := command updatePlan.
	context := plan requestedContext.
	self assert: plan updateAction equals: 'replaceSharedPools'.
	self assert: (context at: #name) equals: 'Object'.
	self assert: (context at: #sharedPools) equals: #( 'ChronologyConstants' )
]

{ #category : 'tests' }
MCPUpdateClassCommandTest >> testBuildsSharedVariableReplacementUpdatePlan [

	| command context plan |
	command := self commandForArguments: (self updateArgumentsWith: { (#sharedVariables -> #( 'Current' )) }).
	plan := command updatePlan.
	context := plan requestedContext.
	self assert: plan updateAction equals: 'replaceSharedVariables'.
	self assert: (context at: #name) equals: 'Object'.
	self assert: (context at: #sharedVariables) equals: #( 'Current' )
]

{ #category : 'tests' }
MCPUpdateClassCommandTest >> testBuildsTraitReplacementUpdatePlan [

	| command context plan |
	command := self commandForArguments: (self updateArgumentsWith: { (#traits -> #( 'TAbleToRotate' )) }).
	plan := command updatePlan.
	context := plan requestedContext.
	self assert: plan updateAction equals: 'replaceTraits'.
	self assert: (context at: #name) equals: 'Object'.
	self assert: (context at: #traits) equals: #( 'TAbleToRotate' )
]

{ #category : 'tests' }
MCPUpdateClassCommandTest >> testBuildsUpdatePlan [

	| command context plan |
	command := self commandForArguments: (self updateArgumentsWith: { (#package -> 'MCP') }).
	plan := command updatePlan.
	context := plan requestedContext.
	self assert: plan updateAction equals: 'move'.
	self assert: (context at: #class) equals: 'Object'.
	self assert: (context at: #package) equals: 'MCP'
]

{ #category : 'tests' }
MCPUpdateClassCommandTest >> testMapsClassPatchFieldsToUpdateActions [

	self
		assert: (self commandForArguments: {
					 (#action -> 'update').
					 (#name -> 'Object').
					 (#newName -> 'ObjectRenamed') } asDictionary) updateAction
		equals: 'rename'.
	self
		assert: (self commandForArguments: (self updateArgumentsWith: { (#superclass -> 'ProtoObject') })) updateAction
		equals: 'reparent'.
	self assert: (self commandForArguments: (self updateArgumentsWith: { (#package -> 'MCP') })) updateAction equals: 'move'.
	self assert: (self commandForArguments: (self updateArgumentsWith: { (#tag -> 'Commands') })) updateAction equals: 'move'.
	self assert: (self commandForArguments: (self updateArgumentsWith: { (#comment -> '') })) updateAction equals: 'setComment'.
	self
		assert: (self commandForArguments: (self updateArgumentsWith: { (#slots -> #( 'slot' )) })) updateAction
		equals: 'replaceDefinition'.
	self
		assert: (self commandForArguments: (self updateArgumentsWith: { (#classSlots -> #( 'Current' )) })) updateAction
		equals: 'replaceDefinition'.
	self
		assert: (self commandForArguments: (self updateArgumentsWith: { (#traits -> #( 'TAbleToRotate' )) })) updateAction
		equals: 'replaceTraits'.
	self
		assert:
		(self commandForArguments: (self updateArgumentsWith: { (#classTraits -> #( 'TAbleToRotate classTrait' )) })) updateAction
		equals: 'replaceClassTraits'.
	self
		assert: (self commandForArguments: (self updateArgumentsWith: { (#sharedVariables -> #( 'Current' )) })) updateAction
		equals: 'replaceSharedVariables'.
	self
		assert: (self commandForArguments: (self updateArgumentsWith: { (#sharedPools -> #( 'ChronologyConstants' )) })) updateAction
		equals: 'replaceSharedPools'.
	self
		assert: (self commandForArguments: (self updateArgumentsWith: { (#layout -> 'WeakLayout') })) updateAction
		equals: 'replaceLayout'
]

{ #category : 'tests' }
MCPUpdateClassCommandTest >> testMapsSlotActionsToUpdateActions [

	self
		assert: (self commandForArguments: (self updateArgumentsWith: {
						  (#slotAction -> 'add').
						  (#slot -> 'addedSlot') })) updateAction
		equals: 'addSlot'.
	self
		assert: (self commandForArguments: (self updateArgumentsWith: {
						  (#slotAction -> 'remove').
						  (#slot -> 'removedSlot') })) updateAction
		equals: 'removeSlot'.
	self
		assert: (self commandForArguments: (self updateArgumentsWith: {
						  (#slotAction -> 'rename').
						  (#slot -> 'oldSlot').
						  (#newSlot -> 'newSlot') })) updateAction
		equals: 'renameSlot'.
	self
		assert: (self commandForArguments: (self updateArgumentsWith: {
						  (#slotAction -> 'pullUp').
						  (#slot -> 'sharedSlot') })) updateAction
		equals: 'pullUpSlot'.
	self
		assert: (self commandForArguments: (self updateArgumentsWith: {
						  (#slotAction -> 'pushDown').
						  (#slot -> 'sharedSlot') })) updateAction
		equals: 'pushDownSlot'
]

{ #category : 'tests' }
MCPUpdateClassCommandTest >> testToolBuildsUpdateClassCommand [

	| command mutationRequest tool toolRequest |
	tool := MCPToolUpdateClassComment new.
	toolRequest := tool requestFromToolCallArguments: {
			               (#name -> 'Object').
			               (#comment -> 'updated') } asDictionary.
	mutationRequest := tool parsedRequestFromToolRequest: toolRequest.
	command := tool commandForRequest: mutationRequest.
	self assert: mutationRequest class equals: MCPClassUpdateRequest.
	self assert: command class equals: MCPUpdateClassCommand.
	self assert: command tool identicalTo: tool.
	self assert: command classRequest identicalTo: mutationRequest.
	self assert: command classRequest className equals: 'Object'.
	self assert: command classRequest classComment equals: 'updated'
]

{ #category : 'private' }
MCPUpdateClassCommandTest >> updateArgumentsWith: associations [

	| arguments |
	arguments := {
		             (#action -> 'update').
		             (#name -> 'Object') } asDictionary.
	associations do: [ :each | arguments at: each key put: each value ].
	^ arguments
]
