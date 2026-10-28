"
Shared implementation for class mutation tools.

It defines per-tool input schemas, translates each concrete class tool request into class creation or update requests, and returns structured class mutation results.
"
Class {
	#name : 'MCPToolClassMutation',
	#superclass : 'MCPToolMutation',
	#traits : 'TMCPClassTool',
	#classTraits : 'TMCPClassTool classTrait',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolClassMutation class >> groupName [

	^ self classesGroupName
]

{ #category : 'testing' }
MCPToolClassMutation class >> isAbstract [

	^ self = MCPToolClassMutation
]

{ #category : 'metadata' }
MCPToolClassMutation >> additionalKeywords [

	^ #( 'class' 'refactor' 'refactoring' )
]

{ #category : 'private - schema' }
MCPToolClassMutation >> atLeastOneInputProperties [

	^ self classToolSpec at: #atLeastOneProperties ifAbsent: [ #(  ) ]
]

{ #category : 'private - schema' }
MCPToolClassMutation >> classNameSchemaProperty [

	^ self schemaPropertyNamed: 'name' type: 'string' description: 'Name of the class to change.'
]

{ #category : 'private - specs' }
MCPToolClassMutation >> classToolSpec [

	self subclassResponsibility
]

{ #category : 'private - schema' }
MCPToolClassMutation >> classTraitsSchemaProperty [

	^ self stringArraySchemaNamed: 'classTraits' description: 'Class-side traits; empty array clears.' itemDescription: 'Trait name.'
]

{ #category : 'private - schema' }
MCPToolClassMutation >> commentSchemaProperty [

	^ self schemaPropertyNamed: 'comment' type: 'string' description: 'Class comment; empty clears.'
]

{ #category : 'private' }
MCPToolClassMutation >> dataForAppliedUpdateResult: anAppliedUpdateResult [

	^ anAppliedUpdateResult asDictionary
]

{ #category : 'private' }
MCPToolClassMutation >> dataForResult: aResult action: actionName [

	^ Dictionary new
]

{ #category : 'metadata' }
MCPToolClassMutation >> description [

	^ self classToolSpec at: #description
]

{ #category : 'private' }
MCPToolClassMutation >> failureMessageForAddSlotNamed: slotName onClassNamed: className classSide: classSide error: anError [

	^ String streamContents: [ :stream |
			  stream << 'Failed to add ' << (self slotDescriptionForClassSide: classSide) << ' ' << slotName << ' to class ' << className
			  << ': ' << (self normalizedCauseMessageForMutationError: anError) ]
]

{ #category : 'private' }
MCPToolClassMutation >> failureMessageForCreateClassNamed: className superclassName: superclassName packageName: packageName error: anError [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Unable to create class ';
				  nextPutAll: className;
				  nextPutAll: ' < ';
				  nextPutAll: superclassName;
				  nextPutAll: ' in package ';
				  nextPutAll: packageName;
				  nextPutAll: ': ';
				  nextPutAll: (self normalizedCauseMessageForMutationError: anError) ]
]

{ #category : 'private' }
MCPToolClassMutation >> failureMessageForMoveClassNamed: className packageName: packageName tag: tag error: anError [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Unable to move class ';
				  nextPutAll: className;
				  nextPutAll: ' to package ';
				  nextPutAll: packageName.
			  tag ifNotNil: [
					  stream
						  nextPutAll: ' tag ';
						  nextPutAll: tag ].
			  stream
				  nextPutAll: ': ';
				  nextPutAll: (self normalizedCauseMessageForMutationError: anError) ]
]

{ #category : 'private' }
MCPToolClassMutation >> failureMessageForMoveSlotNamed: slotName onClassNamed: className classSide: classSide operation: operation error: anError [

	operation = 'pullUpSlot' ifTrue: [
			^ String streamContents: [ :stream |
					  stream << 'Failed to pull up ' << (self slotDescriptionForClassSide: classSide) << ' ' << slotName << ' to class '
					  << className << ': ' << (self normalizedCauseMessageForMutationError: anError) ] ].
	^ String streamContents: [ :stream |
			  stream << 'Failed to push down ' << (self slotDescriptionForClassSide: classSide) << ' ' << slotName << ' from class '
			  << className << ': ' << (self normalizedCauseMessageForMutationError: anError) ]
]

{ #category : 'private' }
MCPToolClassMutation >> failureMessageForRemoveSlotNamed: slotName onClassNamed: className classSide: classSide error: anError [

	^ String streamContents: [ :stream |
			  stream << 'Failed to remove ' << (self slotDescriptionForClassSide: classSide) << ' ' << slotName << ' from class '
			  << className << ': ' << (self normalizedCauseMessageForMutationError: anError) ]
]

{ #category : 'private' }
MCPToolClassMutation >> failureMessageForRenameClassNamed: className to: newClassName error: anError [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Unable to rename class ';
				  nextPutAll: className;
				  nextPutAll: ' to ';
				  nextPutAll: newClassName;
				  nextPutAll: ': ';
				  nextPutAll: (self normalizedCauseMessageForMutationError: anError) ]
]

{ #category : 'private' }
MCPToolClassMutation >> failureMessageForRenameSlotNamed: slotName to: newSlotName onClassNamed: className classSide: classSide error: anError [

	^ String streamContents: [ :stream |
			  stream << 'Failed to rename ' << (self slotDescriptionForClassSide: classSide) << ' ' << slotName << ' to ' << newSlotName
			  << ' in class ' << className << ': ' << (self normalizedCauseMessageForMutationError: anError) ]
]

{ #category : 'private' }
MCPToolClassMutation >> failureMessageForReparentClassNamed: className superclassName: superclassName error: anError [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Unable to reparent class ';
				  nextPutAll: className;
				  nextPutAll: ' to superclass ';
				  nextPutAll: superclassName;
				  nextPutAll: ': ';
				  nextPutAll: (self normalizedCauseMessageForMutationError: anError) ]
]

{ #category : 'private' }
MCPToolClassMutation >> failureMessageForReplaceClassTraitsOnClassNamed: className error: anError [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Unable to replace class-side traits for class ';
				  nextPutAll: className;
				  nextPutAll: ': ';
				  nextPutAll: (self normalizedCauseMessageForMutationError: anError) ]
]

{ #category : 'private' }
MCPToolClassMutation >> failureMessageForReplaceDefinitionOnClassNamed: className error: anError [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Unable to replace slot definition for class ';
				  nextPutAll: className;
				  nextPutAll: ': ';
				  nextPutAll: (self normalizedCauseMessageForMutationError: anError) ]
]

{ #category : 'private' }
MCPToolClassMutation >> failureMessageForReplaceLayoutOnClassNamed: className error: anError [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Unable to replace layout for class ';
				  nextPutAll: className;
				  nextPutAll: ': ';
				  nextPutAll: (self normalizedCauseMessageForMutationError: anError) ]
]

{ #category : 'private' }
MCPToolClassMutation >> failureMessageForReplaceSharedPoolsOnClassNamed: className error: anError [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Unable to replace shared pools for class ';
				  nextPutAll: className;
				  nextPutAll: ': ';
				  nextPutAll: (self normalizedCauseMessageForMutationError: anError) ]
]

{ #category : 'private' }
MCPToolClassMutation >> failureMessageForReplaceSharedVariablesOnClassNamed: className error: anError [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Unable to replace shared variables for class ';
				  nextPutAll: className;
				  nextPutAll: ': ';
				  nextPutAll: (self normalizedCauseMessageForMutationError: anError) ]
]

{ #category : 'private' }
MCPToolClassMutation >> failureMessageForReplaceTraitsOnClassNamed: className error: anError [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Unable to replace traits for class ';
				  nextPutAll: className;
				  nextPutAll: ': ';
				  nextPutAll: (self normalizedCauseMessageForMutationError: anError) ]
]

{ #category : 'private' }
MCPToolClassMutation >> failureMessageForSetCommentOnClassNamed: className error: anError [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Unable to set comment for class ';
				  nextPutAll: className;
				  nextPutAll: ': ';
				  nextPutAll: (self normalizedCauseMessageForMutationError: anError) ]
]

{ #category : 'private - specs' }
MCPToolClassMutation >> fixedArguments [

	^ self classToolSpec at: #fixedArguments ifAbsent: [ Dictionary new ]
]

{ #category : 'private - schema' }
MCPToolClassMutation >> inputProperties [

	^ self classToolSpec at: #inputProperties
]

{ #category : 'private - schema' }
MCPToolClassMutation >> layoutSchemaProperty [

	^ self
		  schemaPropertyNamed: 'layout'
		  type: 'string'
		  description: 'Name of the layout class, a subclass of AbstractLayout, such as FixedLayout or VariableLayout.'
]

{ #category : 'private - actions' }
MCPToolClassMutation >> mutationAction [

	^ self classToolSpec at: #action ifAbsent: [ 'update' ]
]

{ #category : 'private - errors' }
MCPToolClassMutation >> mutationActionForErrorFromParsedRequest: mutationRequest rawRequest: rawRequest [

	^ self mutationAction
]

{ #category : 'private - schema' }
MCPToolClassMutation >> newSlotNameSchemaProperty [

	^ self schemaPropertyNamed: 'newSlot' type: 'string' description: 'The replacement slot name.'
]

{ #category : 'private - request' }
MCPToolClassMutation >> packageNameForMoveClassNamed: className requestedPackageName: requestedPackageName [

	requestedPackageName ifNotNil: [ ^ requestedPackageName ].
	^ (Smalltalk globals at: className asSymbol ifAbsent: [ ^ '' ]) packageName asString
]

{ #category : 'private - schema' }
MCPToolClassMutation >> packageNameSchemaProperty [

	^ self
		  schemaPropertyNamed: 'package'
		  type: 'string'
		  description: 'Move the class to this package. Give tag alone to retag it inside the package it is already in.'
]

{ #category : 'private - request' }
MCPToolClassMutation >> parsedRequestFromToolRequest: request [

	| arguments mutationToolRequest requestClass |
	arguments := request arguments copy.
	self fixedArguments keysAndValuesDo: [ :key :value | arguments at: key put: value ].
	mutationToolRequest := MCPToolRequest new
		                       tool: self;
		                       arguments: arguments;
		                       yourself.
	requestClass := self mutationAction = 'create'
		                ifTrue: [ MCPClassCreateRequest ]
		                ifFalse: [ MCPClassUpdateRequest ].
	^ requestClass fromRequest: mutationToolRequest tool: self
]

{ #category : 'private - specs' }
MCPToolClassMutation >> renameNewClassNameSchemaProperty [

	^ self
		  schemaPropertyNamed: 'newName'
		  type: 'string'
		  description: 'Rename the class to this name, updating every reference to it.'
]

{ #category : 'private - schema' }
MCPToolClassMutation >> requiredInputProperties [

	^ self classToolSpec at: #requiredProperties ifAbsent: [ #( 'class' ) ]
]

{ #category : 'private - schema' }
MCPToolClassMutation >> sharedPoolsSchemaProperty [

	^ self
		  stringArraySchemaNamed: 'sharedPools'
		  description: 'Shared pools the class reads variables from; empty array clears.'
		  itemDescription: 'Pool name.'
]

{ #category : 'private - schema' }
MCPToolClassMutation >> sharedVariablesSchemaProperty [

	^ self
		  stringArraySchemaNamed: 'sharedVariables'
		  description: 'Class variables; empty array clears.'
		  itemDescription: 'Variable name.'
]

{ #category : 'private - schema' }
MCPToolClassMutation >> slotDeltaSchemaPropertyNamed: aName describedAs: aDescription [
	"Slots are patched, not replaced: naming one slot to add needs nothing else, where a replacement list has to be complete and a stale one silently drops a slot the caller did not know about."

	^ (MCPStructureProperties new
		   name: aName;
		   type: 'object';
		   description: aDescription;
		   yourself)
		  properties: {
				  (self stringArraySchemaNamed: 'add' description: 'Slots to add.' itemDescription: 'Slot name.').
				  (self stringArraySchemaNamed: 'remove' description: 'Slots to remove.' itemDescription: 'Slot name.').
				  (MCPStructureProperties new
					   name: 'rename';
					   type: 'object';
					   description: 'Slots to rename, as current name to new name. Values are migrated and references updated.';
					   yourself).
				  (self stringArraySchemaNamed: 'pullUp' description: 'Slots to move up to the superclass.' itemDescription: 'Slot name.').
				  (self
					   stringArraySchemaNamed: 'pushDown'
					   description: 'Slots to move down to every direct subclass.'
					   itemDescription: 'Slot name.').
				  (self
					   stringArraySchemaNamed: 'replace'
					   description: 'The complete slot list, replacing what the class has. Prefer add and remove.'
					   itemDescription: 'Slot name.') };
		  yourself
]

{ #category : 'private' }
MCPToolClassMutation >> slotDescriptionForClassSide: aBoolean [

	^ aBoolean
		  ifTrue: [ 'class-side slot' ]
		  ifFalse: [ 'slot' ]
]

{ #category : 'private - schema' }
MCPToolClassMutation >> slotNameSchemaProperty [

	^ self schemaPropertyNamed: 'slot' type: 'string' description: 'The slot name.'
]

{ #category : 'private - schema' }
MCPToolClassMutation >> slotSideSchemaProperty [

	^ self targetSideSchemaPropertyDescribedAs: 'Which side the slot is on.'
]

{ #category : 'private - schema' }
MCPToolClassMutation >> superclassNameSchemaProperty [

	^ self schemaPropertyNamed: 'superclass' type: 'string' description: 'Reparent the class under this superclass.'
]

{ #category : 'private - schema' }
MCPToolClassMutation >> tagSchemaProperty [

	^ self schemaPropertyNamed: 'tag' type: 'string' description: 'Move the class to this tag inside its package.'
]

{ #category : 'metadata' }
MCPToolClassMutation >> title [

	^ self classToolSpec at: #title
]

{ #category : 'private - schema' }
MCPToolClassMutation >> traitsSchemaProperty [

	^ self stringArraySchemaNamed: 'traits' description: 'Instance traits; empty array clears.' itemDescription: 'Trait name.'
]
