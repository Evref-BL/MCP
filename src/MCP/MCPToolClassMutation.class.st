"
Shared implementation for class mutation tools.

It defines per-tool input schemas, translates each concrete class tool request into class creation or update requests, and returns structured class mutation results.
"
Class {
	#name : 'MCPToolClassMutation',
	#superclass : 'MCPToolMutation',
	#traits : 'TMCPClassTool',
	#classTraits : 'TMCPClassTool classTrait',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'testing' }
MCPToolClassMutation class >> isAbstract [

	^ self = MCPToolClassMutation
]

{ #category : 'private - schema' }
MCPToolClassMutation >> atLeastOneInputProperties [

	^ self classToolSpec
		  at: #atLeastOneProperties
		  ifAbsent: [ #(  ) ]
]

{ #category : 'metadata' }
MCPToolClassMutation >> buildOutputSchema [

	^ self standardOutputSchemaForDataProperties: #(  ) required: #(  )
]

{ #category : 'private - schema' }
MCPToolClassMutation >> classCommentSchemaProperty [

	^ self
		  schemaPropertyNamed: 'classComment'
		  type: 'string'
		  description: 'Class comment; empty clears.'
]

{ #category : 'private - schema' }
MCPToolClassMutation >> classNameSchemaProperty [

	^ self
		  schemaPropertyNamed: 'className'
		  type: 'string'
		  description: 'Class name.'
]

{ #category : 'private - schema' }
MCPToolClassMutation >> classSideSlotSchemaProperty [

	^ self
		  booleanSchemaPropertyNamed: 'classSide'
		  description: 'Whether the slot update targets class-side slots.'
		  default: false
]

{ #category : 'private - schema' }
MCPToolClassMutation >> classSlotsSchemaProperty [

	^ self
		  stringArraySchemaNamed: 'classSlots'
		  description:
		  'Class-side slots; empty array clears; can combine slots.'
		  itemDescription: 'Slot name.'
]

{ #category : 'private - specs' }
MCPToolClassMutation >> classToolSpec [

	self subclassResponsibility
]

{ #category : 'private - schema' }
MCPToolClassMutation >> classTraitsSchemaProperty [

	^ self
		  stringArraySchemaNamed: 'classTraits'
		  description: 'Class-side traits; empty array clears.'
		  itemDescription: 'Trait name.'
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

	^ 'Failed to add ' , (self slotDescriptionForClassSide: classSide)
	  , ' ' , slotName , ' to class ' , className , ': '
	  , (self normalizedCauseMessageForMutationError: anError)
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
			  nextPutAll:
				  (self normalizedCauseMessageForMutationError: anError) ]
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
			  nextPutAll:
				  (self normalizedCauseMessageForMutationError: anError) ]
]

{ #category : 'private' }
MCPToolClassMutation >> failureMessageForMoveSlotNamed: slotName onClassNamed: className classSide: classSide operation: operation error: anError [

	operation = 'pullUpSlot' ifTrue: [
		^ 'Failed to pull up '
		  , (self slotDescriptionForClassSide: classSide) , ' ' , slotName
		  , ' to class ' , className , ': '
		  , (self normalizedCauseMessageForMutationError: anError) ].
	^ 'Failed to push down '
	  , (self slotDescriptionForClassSide: classSide) , ' ' , slotName
	  , ' from class ' , className , ': '
	  , (self normalizedCauseMessageForMutationError: anError)
]

{ #category : 'private' }
MCPToolClassMutation >> failureMessageForRemoveSlotNamed: slotName onClassNamed: className classSide: classSide error: anError [

	^ 'Failed to remove ' , (self slotDescriptionForClassSide: classSide)
	  , ' ' , slotName , ' from class ' , className , ': '
	  , (self normalizedCauseMessageForMutationError: anError)
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
			  nextPutAll:
				  (self normalizedCauseMessageForMutationError: anError) ]
]

{ #category : 'private' }
MCPToolClassMutation >> failureMessageForRenameSlotNamed: slotName to: newSlotName onClassNamed: className classSide: classSide error: anError [

	^ 'Failed to rename ' , (self slotDescriptionForClassSide: classSide)
	  , ' ' , slotName , ' to ' , newSlotName , ' in class ' , className
	  , ': ' , (self normalizedCauseMessageForMutationError: anError)
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
			  nextPutAll:
				  (self normalizedCauseMessageForMutationError: anError) ]
]

{ #category : 'private' }
MCPToolClassMutation >> failureMessageForReplaceClassTraitsOnClassNamed: className error: anError [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Unable to replace class-side traits for class ';
			  nextPutAll: className;
			  nextPutAll: ': ';
			  nextPutAll:
				  (self normalizedCauseMessageForMutationError: anError) ]
]

{ #category : 'private' }
MCPToolClassMutation >> failureMessageForReplaceDefinitionOnClassNamed: className error: anError [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Unable to replace slot definition for class ';
			  nextPutAll: className;
			  nextPutAll: ': ';
			  nextPutAll:
				  (self normalizedCauseMessageForMutationError: anError) ]
]

{ #category : 'private' }
MCPToolClassMutation >> failureMessageForReplaceLayoutOnClassNamed: className error: anError [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Unable to replace layout for class ';
			  nextPutAll: className;
			  nextPutAll: ': ';
			  nextPutAll:
				  (self normalizedCauseMessageForMutationError: anError) ]
]

{ #category : 'private' }
MCPToolClassMutation >> failureMessageForReplaceSharedPoolsOnClassNamed: className error: anError [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Unable to replace shared pools for class ';
			  nextPutAll: className;
			  nextPutAll: ': ';
			  nextPutAll:
				  (self normalizedCauseMessageForMutationError: anError) ]
]

{ #category : 'private' }
MCPToolClassMutation >> failureMessageForReplaceSharedVariablesOnClassNamed: className error: anError [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Unable to replace shared variables for class ';
			  nextPutAll: className;
			  nextPutAll: ': ';
			  nextPutAll:
				  (self normalizedCauseMessageForMutationError: anError) ]
]

{ #category : 'private' }
MCPToolClassMutation >> failureMessageForReplaceTraitsOnClassNamed: className error: anError [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Unable to replace traits for class ';
			  nextPutAll: className;
			  nextPutAll: ': ';
			  nextPutAll:
				  (self normalizedCauseMessageForMutationError: anError) ]
]

{ #category : 'private' }
MCPToolClassMutation >> failureMessageForSetCommentOnClassNamed: className error: anError [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Unable to set comment for class ';
			  nextPutAll: className;
			  nextPutAll: ': ';
			  nextPutAll:
				  (self normalizedCauseMessageForMutationError: anError) ]
]

{ #category : 'private - specs' }
MCPToolClassMutation >> fixedArguments [

	^ self classToolSpec
		  at: #fixedArguments
		  ifAbsent: [ Dictionary new ]
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
		  description: 'layout class; AbstractLayout subclass.'
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
MCPToolClassMutation >> newClassNameSchemaProperty [

	^ self
		  schemaPropertyNamed: 'newClassName'
		  type: 'string'
		  description: 'The new class name.'
]

{ #category : 'private - schema' }
MCPToolClassMutation >> newSlotNameSchemaProperty [

	^ self
		  schemaPropertyNamed: 'newSlotName'
		  type: 'string'
		  description: 'The replacement slot name.'
]

{ #category : 'private - request' }
MCPToolClassMutation >> packageNameForMoveClassNamed: className requestedPackageName: requestedPackageName [

	requestedPackageName ifNotNil: [ ^ requestedPackageName ].
	^ (Smalltalk globals at: className asSymbol ifAbsent: [ ^ '' ])
		  packageName asString
]

{ #category : 'private - schema' }
MCPToolClassMutation >> packageNameSchemaProperty [

	^ self
		  schemaPropertyNamed: 'packageName'
		  type: 'string'
		  description:
		  'Package name; omit packageName with tag to recategorize current package.'
]

{ #category : 'private - request' }
MCPToolClassMutation >> parsedRequestFromToolRequest: request [

	| arguments mutationToolRequest requestClass |
	arguments := request arguments copy.
	self fixedArguments keysAndValuesDo: [ :key :value |
		arguments at: key put: value ].
	mutationToolRequest := MCPToolRequest new
		                  tool: self;
		                  arguments: arguments;
		                  yourself.
	requestClass := self mutationAction = 'create'
		                ifTrue: [ MCPClassCreateRequest ]
		                ifFalse: [ MCPClassUpdateRequest ].
	^ requestClass fromRequest: mutationToolRequest tool: self
]

{ #category : 'private - schema' }
MCPToolClassMutation >> requiredInputProperties [

	^ self classToolSpec
		  at: #requiredProperties
		  ifAbsent: [ #( 'className' ) ]
]

{ #category : 'private - schema' }
MCPToolClassMutation >> sharedPoolsSchemaProperty [

	^ self
		  stringArraySchemaNamed: 'sharedPools'
		  description: 'shared pool names; empty array clears.'
		  itemDescription: 'Pool name.'
]

{ #category : 'private - schema' }
MCPToolClassMutation >> sharedVariablesSchemaProperty [

	^ self
		  stringArraySchemaNamed: 'sharedVariables'
		  description: 'Class variables; empty array clears.'
		  itemDescription: 'Variable name.'
]

{ #category : 'private' }
MCPToolClassMutation >> slotDescriptionForClassSide: aBoolean [

	^ aBoolean
		  ifTrue: [ 'class-side slot' ]
		  ifFalse: [ 'slot' ]
]

{ #category : 'private - schema' }
MCPToolClassMutation >> slotNameSchemaProperty [

	^ self
		  schemaPropertyNamed: 'slotName'
		  type: 'string'
		  description: 'The slot name.'
]

{ #category : 'private - schema' }
MCPToolClassMutation >> slotsSchemaProperty [

	^ self
		  stringArraySchemaNamed: 'slots'
		  description:
		  'Instance slots; empty array clears; can combine classSlots.'
		  itemDescription: 'Slot name.'
]

{ #category : 'private - schema' }
MCPToolClassMutation >> superclassNameSchemaProperty [

	^ self
		  schemaPropertyNamed: 'superclassName'
		  type: 'string'
		  description: 'Superclass name.'
]

{ #category : 'private - schema' }
MCPToolClassMutation >> tagSchemaProperty [

	^ self
		  schemaPropertyNamed: 'tag'
		  type: 'string'
		  description: 'Package tag; recategorizes current package.'
]

{ #category : 'metadata' }
MCPToolClassMutation >> title [

	^ self classToolSpec at: #title
]

{ #category : 'private - schema' }
MCPToolClassMutation >> traitsSchemaProperty [

	^ self
		  stringArraySchemaNamed: 'traits'
		  description: 'Instance traits; empty array clears.'
		  itemDescription: 'Trait name.'
]

{ #category : 'validating' }
MCPToolClassMutation >> validateAtLeastOneInputPropertyIn: request [

	| propertyNames requiredName |
	propertyNames := self atLeastOneInputProperties.
	propertyNames ifEmpty: [ ^ self ].
	(propertyNames anySatisfy: [ :each | request hasArgumentNamed: each ])
		ifTrue: [ ^ self ].
	requiredName := String streamContents: [ :stream |
			                propertyNames
				                do: [ :each | stream nextPutAll: each ]
				                separatedBy: [ stream nextPutAll: ' or ' ] ].
	MCPInvalidToolInput
		signalMissingRequiredArgumentNamed: requiredName
		forTool: self
]

{ #category : 'validating' }
MCPToolClassMutation >> validateRequest: request [

	super validateRequest: request.
	self validateAtLeastOneInputPropertyIn: request
]
