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
MCPToolClassMutation >> appliedChangeOutputSchemaProperty [

	| property resultClassProperty resultProperty updateActionProperty |
	updateActionProperty := self
		                        schemaPropertyNamed: 'updateAction'
		                        type: 'string'
		                        description:
		                        'The update action that produced the applied change.'.
	resultClassProperty := self
		                       schemaPropertyNamed: 'resultClassName'
		                       type: 'string'
		                       description:
		                       'The result DTO class returned by the update action.'.
	resultProperty := self
		                  schemaPropertyNamed: 'result'
		                  type: 'object'
		                  description:
		                  'The update result DTO serialized as a dictionary.'.
	resultProperty additionalProperties: true.
	property := self
		            schemaPropertyNamed: 'appliedChange'
		            type: 'object'
		            description:
		            'The applied update change and its result DTO.'.
	property
		properties: {
				updateActionProperty.
				resultClassProperty.
				resultProperty };
		required: #( 'updateAction' 'resultClassName' 'result' );
		additionalProperties: false.
	^ property
]

{ #category : 'private - schema' }
MCPToolClassMutation >> atLeastOneInputProperties [

	^ self classToolSpec
		  at: #atLeastOneProperties
		  ifAbsent: [ #(  ) ]
]

{ #category : 'private - schema' }
MCPToolClassMutation >> classCommentSchemaProperty [

	^ self
		  schemaPropertyNamed: 'classComment'
		  type: 'string'
		  description: 'The class comment. Use an empty string to clear it.'
]

{ #category : 'private - schema' }
MCPToolClassMutation >> classNameSchemaProperty [

	^ self
		  schemaPropertyNamed: 'className'
		  type: 'string'
		  description: 'Class name targeted by this class tool.'
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
		  'Class-side slot names. Use an empty array to define no class-side slots or remove all class-side slots during replacement. May be combined with slots.'
		  itemDescription: 'A class-side slot name.'
]

{ #category : 'private - specs' }
MCPToolClassMutation >> classToolSpec [

	self subclassResponsibility
]

{ #category : 'private - schema' }
MCPToolClassMutation >> classTraitsSchemaProperty [

	^ self
		  stringArraySchemaNamed: 'classTraits'
		  description:
		  'Class-side trait names. Use names like TraitName classTrait or TraitName. Use an empty array to remove all class-side traits.'
		  itemDescription: 'A class-side trait name.'
]

{ #category : 'private' }
MCPToolClassMutation >> dataForAppliedUpdateResult: anAppliedUpdateResult [

	^ self dataWithClassCommentFrom: anAppliedUpdateResult asDictionary
]

{ #category : 'private' }
MCPToolClassMutation >> dataForResult: aResult action: actionName [

	| data |
	data := aResult asDictionary copy.
	data at: #action put: actionName.
	^ self dataWithClassCommentFrom: data

]

{ #category : 'private' }
MCPToolClassMutation >> dataWithClassCommentFrom: aDictionary [

	| class data |
	data := aDictionary copy.
	class := Smalltalk globals
		         at: (data at: #className) asSymbol
		         ifAbsent: [ nil ].
	data
		at: #classComment
		put: (class ifNil: [ '' ] ifNotNil: [ class comment ]).
	^ data
]

{ #category : 'defaults' }
MCPToolClassMutation >> defaultDescription [

	^ self classToolSpec at: #description
]

{ #category : 'defaults' }
MCPToolClassMutation >> defaultInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: self inputProperties;
		  required: self requiredInputProperties;
		  additionalProperties: false;
		  yourself
]

{ #category : 'defaults' }
MCPToolClassMutation >> defaultOutputSchema [

	^ self
		  standardOutputSchemaForDataProperties: {
				  (self
					   schemaPropertyNamed: 'action'
					   type: 'string'
					   description:
					   'The class mutation action that was performed: create or update.').
				  (self
					   schemaPropertyNamed: 'updateAction'
					   type: 'string'
					   description:
					   'The update action performed when action=update.').
				  self updatePlanOutputSchemaProperty.
				  self appliedChangeOutputSchemaProperty.
				  (self
					   schemaPropertyNamed: 'className'
					   type: 'string'
					   description: 'The class name after the action completes.').
				  (self
					   schemaPropertyNamed: 'superclassName'
					   type: 'string'
					   description:
					   'The superclass of the class after the action.').
				  (self
					   schemaPropertyNamed: 'packageName'
					   type: 'string'
					   description:
					   'The owning package of the class after the action.').
				  (self
					   schemaPropertyNamed: 'tag'
					   type: 'string'
					   description:
					   'The package tag assigned to the class after the action.').
				  (self
					   schemaPropertyNamed: 'classComment'
					   type: 'string'
					   description: 'The class comment after the action.').
				  (self
					   stringArraySchemaNamed: 'instanceSlotNames'
					   description:
					   'The instance-side slots present on the class after the action.'
					   itemDescription: 'An instance-side slot name.').
				  (self
					   stringArraySchemaNamed: 'classSlotNames'
					   description:
					   'The class-side slots present on the class after the action.'
					   itemDescription: 'A class-side slot name.').
				  (self
					   stringArraySchemaNamed: 'oldInstanceSlotNames'
					   description:
					   'The instance-side slots present before updateAction=replaceDefinition.'
					   itemDescription: 'A previous instance-side slot name.').
				  (self
					   stringArraySchemaNamed: 'newInstanceSlotNames'
					   description:
					   'The instance-side slots requested by updateAction=replaceDefinition.'
					   itemDescription: 'A new instance-side slot name.').
				  (self
					   stringArraySchemaNamed: 'oldClassSlotNames'
					   description:
					   'The class-side slots present before updateAction=replaceDefinition.'
					   itemDescription: 'A previous class-side slot name.').
				  (self
					   stringArraySchemaNamed: 'newClassSlotNames'
					   description:
					   'The class-side slots requested by updateAction=replaceDefinition.'
					   itemDescription: 'A new class-side slot name.').
				  (self
					   stringArraySchemaNamed: 'traitNames'
					   description:
					   'The traits used by the class after the action.'
					   itemDescription: 'A trait name.').
				  (self
					   stringArraySchemaNamed: 'oldTraitNames'
					   description:
					   'The instance-side traits used before updateAction=replaceTraits.'
					   itemDescription: 'A previous trait name.').
				  (self
					   stringArraySchemaNamed: 'newTraitNames'
					   description:
					   'The instance-side traits requested by updateAction=replaceTraits.'
					   itemDescription: 'A new trait name.').
				  (self
					   stringArraySchemaNamed: 'classTraitNames'
					   description:
					   'The traits used by the class side after the action.'
					   itemDescription: 'A class-side trait name.').
				  (self
					   stringArraySchemaNamed: 'oldClassTraitNames'
					   description:
					   'The class-side traits used before updateAction=replaceClassTraits.'
					   itemDescription: 'A previous class-side trait name.').
				  (self
					   stringArraySchemaNamed: 'newClassTraitNames'
					   description:
					   'The class-side traits requested by updateAction=replaceClassTraits.'
					   itemDescription: 'A new class-side trait name.').
				  (self
					   stringArraySchemaNamed: 'sharedVariableNames'
					   description:
					   'The class variables defined on the class after the action.'
					   itemDescription: 'A class variable name.').
				  (self
					   stringArraySchemaNamed: 'oldSharedVariableNames'
					   description:
					   'The class variables defined before updateAction=replaceSharedVariables.'
					   itemDescription: 'A previous class variable name.').
				  (self
					   stringArraySchemaNamed: 'newSharedVariableNames'
					   description:
					   'The class variables requested by updateAction=replaceSharedVariables.'
					   itemDescription: 'A new class variable name.').
				  (self
					   stringArraySchemaNamed: 'sharedPoolNames'
					   description:
					   'The shared pools referenced by the class after the action.'
					   itemDescription: 'A shared pool name.').
				  (self
					   stringArraySchemaNamed: 'oldSharedPoolNames'
					   description:
					   'The shared pools referenced before updateAction=replaceSharedPools.'
					   itemDescription: 'A previous shared pool name.').
				  (self
					   stringArraySchemaNamed: 'newSharedPoolNames'
					   description:
					   'The shared pools requested by updateAction=replaceSharedPools.'
					   itemDescription: 'A new shared pool name.').
				  (self
					   schemaPropertyNamed: 'layoutClassName'
					   type: 'string'
					   description:
					   'The layout class used by the class after the action.').
				  (self
					   schemaPropertyNamed: 'oldLayoutClassName'
					   type: 'string'
					   description:
					   'The layout class used before updateAction=replaceLayout.').
				  (self
					   schemaPropertyNamed: 'newLayoutClassName'
					   type: 'string'
					   description:
					   'The layout class requested by updateAction=replaceLayout.').
				  (self
					   schemaPropertyNamed: 'slotName'
					   type: 'string'
					   description:
					   'The slot name that was added, removed, pulled up, or pushed down when updateAction=addSlot, updateAction=removeSlot, updateAction=pullUpSlot, or updateAction=pushDownSlot.').
				  (self
					   schemaPropertyNamed: 'oldSlotName'
					   type: 'string'
					   description:
					   'The previous slot name when updateAction=renameSlot.').
				  (self
					   schemaPropertyNamed: 'newSlotName'
					   type: 'string'
					   description: 'The new slot name when updateAction=renameSlot.').
				  (self
					   booleanSchemaPropertyNamed: 'classSide'
					   description:
					   'Whether the slot update targeted class-side slots instead of instance-side slots.'
					   default: false).
				  ((self
					    schemaPropertyNamed: 'affectedClassNames'
					    type: 'array'
					    description:
						    'The other classes whose slot definitions were changed by updateAction=pullUpSlot or updateAction=pushDownSlot.')
					   items: (MCPStructureProperties new
							    type: 'string';
							    description: 'An affected class name.';
							    yourself);
					   yourself).
				  ((self
					    schemaPropertyNamed: 'subclassNames'
					    type: 'array'
					    description:
						    'The direct subclasses of the class after the action.')
					   items: (MCPStructureProperties new
							    type: 'string';
							    description: 'A direct subclass name.';
							    yourself);
					   yourself).
				  (self
					   schemaPropertyNamed: 'oldPackageName'
					   type: 'string'
					   description: 'The previous package when updateAction=move.').
				  (self
					   schemaPropertyNamed: 'oldTag'
					   type: 'string'
					   description:
					   'The previous package tag when updateAction=move.').
				  (self
					   schemaPropertyNamed: 'oldClassName'
					   type: 'string'
					   description:
					   'The previous class name when updateAction=rename.').
				  (self
					   schemaPropertyNamed: 'newClassName'
					   type: 'string'
					   description: 'The new class name when updateAction=rename.').
				  (self
					   schemaPropertyNamed: 'oldSuperclassName'
					   type: 'string'
					   description:
					   'The previous superclass when updateAction=reparent.').
				  (self
					   schemaPropertyNamed: 'oldClassComment'
					   type: 'string'
					   description:
					   'The previous class comment when updateAction=setComment.').
				  (self
					   schemaPropertyNamed: 'newClassComment'
					   type: 'string'
					   description:
					   'The new class comment when updateAction=setComment.') }
		  required:
			  #( 'action' 'className' 'superclassName' 'packageName'
			     'tag' 'classComment' 'instanceSlotNames' 'classSlotNames'
			     'traitNames' 'classTraitNames' 'sharedVariableNames'
			     'sharedPoolNames' 'layoutClassName' 'subclassNames' )
]

{ #category : 'defaults' }
MCPToolClassMutation >> defaultTitle [

	^ self classToolSpec at: #title
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
		  description:
		  'The layout class name. It must resolve to AbstractLayout or one of its subclasses.'
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
		  'The package name for class creation or movement. When moving a class, omit packageName and provide tag to recategorize inside the current package.'
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
		  description:
		  'Shared pool names. Use an empty array to remove all shared pools.'
		  itemDescription: 'A shared pool name.'
]

{ #category : 'private - schema' }
MCPToolClassMutation >> sharedVariablesSchemaProperty [

	^ self
		  stringArraySchemaNamed: 'sharedVariables'
		  description:
		  'Class variable names. Use an empty array to remove all class variables.'
		  itemDescription: 'A class variable name.'
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
		  'Instance-side slot names. Use an empty array to define no instance-side slots or remove all instance-side slots during replacement. May be combined with classSlots.'
		  itemDescription: 'An instance-side slot name.'
]

{ #category : 'private - schema' }
MCPToolClassMutation >> superclassNameSchemaProperty [

	^ self
		  schemaPropertyNamed: 'superclassName'
		  type: 'string'
		  description: 'The superclass name.'
]

{ #category : 'private - schema' }
MCPToolClassMutation >> tagSchemaProperty [

	^ self
		  schemaPropertyNamed: 'tag'
		  type: 'string'
		  description:
		  'The package tag or class category. When updating package assignment, tag recategorizes a class; omit packageName to use the current package.'
]

{ #category : 'private - schema' }
MCPToolClassMutation >> traitsSchemaProperty [

	^ self
		  stringArraySchemaNamed: 'traits'
		  description:
		  'Instance-side trait names. Use an empty array to remove all instance-side traits.'
		  itemDescription: 'A trait name.'
]

{ #category : 'private - schema' }
MCPToolClassMutation >> updatePlanOutputSchemaProperty [

	| property requestedContextProperty updateActionProperty |
	updateActionProperty := self
		                        schemaPropertyNamed: 'updateAction'
		                        type: 'string'
		                        description:
		                        'The class update action selected by the tool request.'.
	requestedContextProperty := self
		                            schemaPropertyNamed: 'requestedContext'
		                            type: 'object'
		                            description:
		                            'The normalized request context used to execute the update.'.
	requestedContextProperty additionalProperties: true.
	property := self
		            schemaPropertyNamed: 'updatePlan'
		            type: 'object'
		            description:
		            'The planned update action before it is executed.'.
	property
		properties: {
				updateActionProperty.
				requestedContextProperty };
		required: #( 'updateAction' 'requestedContext' );
		additionalProperties: false.
	^ property
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

	self requiredInputProperties do: [ :each |
			(request argumentNamed: each ifAbsent: [ nil ]) ifNil: [
					MCPInvalidToolInput
						signalMissingRequiredArgumentNamed: each
						forTool: self ] ].
	self validateAtLeastOneInputPropertyIn: request
]
