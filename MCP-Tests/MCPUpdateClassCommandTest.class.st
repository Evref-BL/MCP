"
Tests for the edit-class update command orchestrator.
"
Class {
	#name : 'MCPUpdateClassCommandTest',
	#superclass : 'MCPCommandTestCase',
	#category : 'MCP-Tests-Commands',
	#package : 'MCP-Tests',
	#tag : 'Commands'
}

{ #category : 'private' }
MCPUpdateClassCommandTest >> commandForArguments: arguments [

	| editRequest tool toolRequest |
	tool := MCPToolEditClass new.
	toolRequest := tool requestFromToolCallArguments: arguments.
	editRequest := tool parsedRequestFromToolRequest: toolRequest.
	^ tool commandForRequest: editRequest
]

{ #category : 'tests' }
MCPUpdateClassCommandTest >> testAppliedChangeResultWrapsPlanAndResult [

	| appliedChange changeResult data plan |
	plan := MCPClassUpdatePlanInfo
		        updateAction: 'setComment'
		        requestedContext: { (#className -> 'Object') } asDictionary.
	changeResult := MCPChangeClassCommentResult
		                classInfo: (MCPClassInfo fromClass: Object)
		                oldClassComment: 'old'
		                newClassComment: 'new'.
	appliedChange := MCPClassAppliedChangeResult
		                 updatePlan: plan
		                 changeResult: changeResult.
	data := appliedChange asDictionary.
	self assert: (data at: #operation) equals: 'update'.
	self assert: (data at: #updateAction) equals: 'setComment'.
	self
		assert: ((data at: #updatePlan) at: #updateAction)
		equals: 'setComment'.
	self deny: ((data at: #updatePlan) includesKey: #commandClassName).
	self
		assert: ((data at: #appliedChange) at: #resultClassName)
		equals: 'MCPChangeClassCommentResult'.
	self assert: (data at: #oldClassComment) equals: 'old'.
	self assert: (data at: #newClassComment) equals: 'new'
]

{ #category : 'tests' }
MCPUpdateClassCommandTest >> testBuildsClassTraitReplacementUpdatePlan [

	| command context plan |
	command := self commandForArguments: (self updateArgumentsWith:
			            { (#classTraits -> #( 'TAbleToRotate classTrait' )) }).
	plan := command updatePlan.
	context := plan requestedContext.
	self assert: plan updateAction equals: 'replaceClassTraits'.
	self assert: (context at: #className) equals: 'Object'.
	self
		assert: (context at: #classTraits)
		equals: #( 'TAbleToRotate classTrait' )
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
	self assert: (context at: #className) equals: 'Object'.
	self assert: (context at: #slots) equals: #( 'first' 'second' ).
	self assert: (context at: #classSlots) equals: #( 'Current' )
]

{ #category : 'tests' }
MCPUpdateClassCommandTest >> testBuildsLayoutReplacementUpdatePlan [

	| command context plan |
	command := self commandForArguments:
		           (self updateArgumentsWith: { (#layout -> 'WeakLayout') }).
	plan := command updatePlan.
	context := plan requestedContext.
	self assert: plan updateAction equals: 'replaceLayout'.
	self assert: (context at: #className) equals: 'Object'.
	self assert: (context at: #layout) equals: 'WeakLayout'
]

{ #category : 'tests' }
MCPUpdateClassCommandTest >> testBuildsSharedPoolReplacementUpdatePlan [

	| command context plan |
	command := self commandForArguments: (self updateArgumentsWith:
			            { (#sharedPools -> #( 'ChronologyConstants' )) }).
	plan := command updatePlan.
	context := plan requestedContext.
	self assert: plan updateAction equals: 'replaceSharedPools'.
	self assert: (context at: #className) equals: 'Object'.
	self
		assert: (context at: #sharedPools)
		equals: #( 'ChronologyConstants' )
]

{ #category : 'tests' }
MCPUpdateClassCommandTest >> testBuildsSharedVariableReplacementUpdatePlan [

	| command context plan |
	command := self commandForArguments:
		           (self updateArgumentsWith:
			            { (#sharedVariables -> #( 'Current' )) }).
	plan := command updatePlan.
	context := plan requestedContext.
	self assert: plan updateAction equals: 'replaceSharedVariables'.
	self assert: (context at: #className) equals: 'Object'.
	self assert: (context at: #sharedVariables) equals: #( 'Current' )
]

{ #category : 'tests' }
MCPUpdateClassCommandTest >> testBuildsTraitReplacementUpdatePlan [

	| command context plan |
	command := self commandForArguments:
		           (self updateArgumentsWith:
			            { (#traits -> #( 'TAbleToRotate' )) }).
	plan := command updatePlan.
	context := plan requestedContext.
	self assert: plan updateAction equals: 'replaceTraits'.
	self assert: (context at: #className) equals: 'Object'.
	self assert: (context at: #traits) equals: #( 'TAbleToRotate' )
]

{ #category : 'tests' }
MCPUpdateClassCommandTest >> testBuildsUpdatePlan [

	| command context plan |
	command := self commandForArguments:
		           (self updateArgumentsWith: { (#packageName -> 'MCP') }).
	plan := command updatePlan.
	context := plan requestedContext.
	self assert: plan updateAction equals: 'move'.
	self assert: (context at: #className) equals: 'Object'.
	self assert: (context at: #packageName) equals: 'MCP'
]

{ #category : 'tests' }
MCPUpdateClassCommandTest >> testMapsClassPatchFieldsToUpdateActions [

	self
		assert: (self commandForArguments:
				 (self updateArgumentsWith: { (#newClassName -> 'ObjectRenamed') }))
				updateAction
		equals: 'rename'.
	self
		assert: (self commandForArguments:
				 (self updateArgumentsWith: { (#superclassName -> 'ProtoObject') }))
				updateAction
		equals: 'reparent'.
	self
		assert: (self commandForArguments:
				 (self updateArgumentsWith: { (#packageName -> 'MCP') }))
				updateAction
		equals: 'move'.
	self
		assert: (self commandForArguments:
				 (self updateArgumentsWith: { (#tag -> 'Commands') }))
				updateAction
		equals: 'move'.
	self
		assert: (self commandForArguments:
				 (self updateArgumentsWith: { (#classComment -> '') }))
				updateAction
		equals: 'setComment'.
	self
		assert: (self commandForArguments:
				 (self updateArgumentsWith: { (#slots -> #( 'slot' )) }))
				updateAction
		equals: 'replaceDefinition'.
	self
		assert: (self commandForArguments:
				 (self updateArgumentsWith: { (#classSlots -> #( 'Current' )) }))
				updateAction
		equals: 'replaceDefinition'.
	self
		assert: (self commandForArguments:
				 (self updateArgumentsWith: { (#traits -> #( 'TAbleToRotate' )) }))
				updateAction
		equals: 'replaceTraits'.
	self
		assert: (self commandForArguments: (self updateArgumentsWith:
					  { (#classTraits -> #( 'TAbleToRotate classTrait' )) }))
				updateAction
		equals: 'replaceClassTraits'.
	self
		assert: (self commandForArguments:
				 (self updateArgumentsWith:
					  { (#sharedVariables -> #( 'Current' )) })) updateAction
		equals: 'replaceSharedVariables'.
	self
		assert: (self commandForArguments: (self updateArgumentsWith:
					  { (#sharedPools -> #( 'ChronologyConstants' )) })) updateAction
		equals: 'replaceSharedPools'.
	self
		assert: (self commandForArguments:
				 (self updateArgumentsWith: { (#layout -> 'WeakLayout') }))
				updateAction
		equals: 'replaceLayout'
]

{ #category : 'tests' }
MCPUpdateClassCommandTest >> testMapsSlotActionsToUpdateActions [

	self
		assert: (self commandForArguments: (self updateArgumentsWith: {
						  (#slotAction -> 'add').
						  (#slotName -> 'addedSlot') })) updateAction
		equals: 'addSlot'.
	self
		assert: (self commandForArguments: (self updateArgumentsWith: {
						  (#slotAction -> 'remove').
						  (#slotName -> 'removedSlot') })) updateAction
		equals: 'removeSlot'.
	self
		assert: (self commandForArguments: (self updateArgumentsWith: {
						  (#slotAction -> 'rename').
						  (#slotName -> 'oldSlot').
						  (#newSlotName -> 'newSlot') })) updateAction
		equals: 'renameSlot'.
	self
		assert: (self commandForArguments: (self updateArgumentsWith: {
						  (#slotAction -> 'pullUp').
						  (#slotName -> 'sharedSlot') })) updateAction
		equals: 'pullUpSlot'.
	self
		assert: (self commandForArguments: (self updateArgumentsWith: {
						  (#slotAction -> 'pushDown').
						  (#slotName -> 'sharedSlot') })) updateAction
		equals: 'pushDownSlot'
]

{ #category : 'tests' }
MCPUpdateClassCommandTest >> testRejectsAmbiguousUpdateActions [

	| error |
	error := self captureCommandError: [
		         (self commandForArguments: (self updateArgumentsWith: {
					           (#newClassName -> 'ObjectRenamed').
					           (#classComment -> 'updated') })) updateAction ].
	self assert: error errorCode equals: #AmbiguousClassUpdateRequest.
	self assert: ((error details at: #updateActions) includes: 'rename').
	self assert:
		((error details at: #updateActions) includes: 'setComment')
]

{ #category : 'tests' }
MCPUpdateClassCommandTest >> testRejectsMissingUpdateAction [

	| error |
	error := self captureCommandError: [
		         (self commandForArguments:
			          (self updateArgumentsWith: #(  ))) updateAction ].
	self assert: error errorCode equals: #NoClassUpdateRequested.
	self assert: (error details at: #className) equals: 'Object'
]

{ #category : 'tests' }
MCPUpdateClassCommandTest >> testRequiresExplicitSlotAction [

	| error |
	error := self captureCommandError: [
		         (self commandForArguments: (self updateArgumentsWith: {
					           (#slotName -> 'oldSlot').
					           (#newSlotName -> 'newSlot') })) updateAction ].
	self assert: error errorCode equals: #SlotActionRequired.
	self assert: (error details at: #slotName) equals: 'oldSlot'
]

{ #category : 'tests' }
MCPUpdateClassCommandTest >> testToolBuildsUpdateClassCommand [

	| command editRequest tool toolRequest |
	tool := MCPToolEditClass new.
	toolRequest := tool requestFromToolCallArguments:
		               (self updateArgumentsWith:
			                { (#classComment -> 'updated') }).
	editRequest := tool parsedRequestFromToolRequest: toolRequest.
	command := tool commandForRequest: editRequest.
	self assert: editRequest class equals: MCPClassUpdateRequest.
	self assert: command class equals: MCPUpdateClassCommand.
	self assert: command tool identicalTo: tool.
	self assert: command classRequest identicalTo: editRequest.
	self assert: command classRequest className equals: 'Object'.
	self assert: command classRequest classComment equals: 'updated'
]

{ #category : 'private' }
MCPUpdateClassCommandTest >> updateArgumentsWith: associations [

	| arguments |
	arguments := {
		             (#operation -> 'update').
		             (#className -> 'Object') } asDictionary.
	associations do: [ :each | arguments at: each key put: each value ].
	^ arguments
]
