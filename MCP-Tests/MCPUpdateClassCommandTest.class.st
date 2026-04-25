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

	| tool toolRequest |
	tool := MCPToolEditClass new.
	toolRequest := tool requestFromToolCallArguments: arguments.
	^ tool updateCommandForToolRequest: toolRequest
]

{ #category : 'tests' }
MCPUpdateClassCommandTest >> testAppliedChangeResultWrapsPlanAndResult [

	| appliedChange changeResult data plan |
	plan := MCPClassUpdatePlanInfo
		        operation: 'setComment'
		        commandClassName: 'MCPChangeClassCommentCommand'
		        requestedContext: { (#className -> 'Object') } asDictionary.
	changeResult := MCPChangeClassCommentResult
		                classInfo: (MCPClassInfo fromClass: Object)
		                oldClassComment: 'old'
		                newClassComment: 'new'.
	appliedChange := MCPClassAppliedChangeResult
		                 updatePlan: plan
		                 changeResult: changeResult.
	data := appliedChange asDictionary.
	self assert: (data at: #operation) equals: 'setComment'.
	self
		assert: ((data at: #updatePlan) at: #operation)
		equals: 'setComment'.
	self
		assert: ((data at: #appliedChange) at: #resultClassName)
		equals: 'MCPChangeClassCommentResult'.
	self assert: (data at: #oldClassComment) equals: 'old'.
	self assert: (data at: #newClassComment) equals: 'new'
]

{ #category : 'tests' }
MCPUpdateClassCommandTest >> testBuildsUpdatePlan [

	| command context plan |
	command := self commandForArguments:
		           (self updateArgumentsWith: { (#packageName -> 'MCP') }).
	plan := command updatePlan.
	context := plan requestedContext.
	self assert: plan operation equals: 'move'.
	self assert: plan commandClassName equals: 'MCPMoveClassCommand'.
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
		equals: 'setComment'
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
MCPUpdateClassCommandTest >> testRejectsDefinitionReplacementUntilImplemented [

	| error |
	error := self captureCommandError: [
		         (self commandForArguments:
			          (self updateArgumentsWith: { (#slots -> #( 'alpha' )) }))
			         updateAction ].
	self
		assert: error errorCode
		equals: #ClassDefinitionUpdateNotImplemented.
	self assert:
		((error details at: #definitionProperties) includes: 'slots')
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
	self assert: command class equals: MCPUpdateClassCommand.
	self assert: command tool identicalTo: tool.
	self assert: command classRequest className equals: 'Object'.
	self assert: command classRequest classComment equals: 'updated'.
	self assert: command slotRequest className equals: 'Object'
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
