"
Shared implementation for focused class editing tools. It parses create/update class requests, dispatches class create/update commands, and returns structured class edit results.
"
Class {
	#name : 'MCPToolEditClass',
	#superclass : 'MCPToolEdit',
	#traits : 'TMCPClassTool',
	#classTraits : 'TMCPClassTool classTrait',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'testing' }
MCPToolEditClass class >> isAbstract [

	^ self = MCPToolEditClass
]

{ #category : 'private - schema' }
MCPToolEditClass >> appliedChangeOutputSchemaProperty [

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

{ #category : 'private' }
MCPToolEditClass >> dataForAppliedUpdateResult: anAppliedUpdateResult [

	^ self dataWithClassCommentFrom: anAppliedUpdateResult asDictionary
]

{ #category : 'private' }
MCPToolEditClass >> dataForResult: aResult action: actionName [

	| data |
	data := aResult asDictionary copy.
	data at: #action put: actionName.
	^ self dataWithClassCommentFrom: data

]

{ #category : 'private' }
MCPToolEditClass >> dataWithClassCommentFrom: aDictionary [

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
MCPToolEditClass >> defaultOutputSchema [

	^ self
		  standardOutputSchemaForDataProperties: {
				  (self
					   schemaPropertyNamed: 'action'
					   type: 'string'
					   description:
					   'The class edit action that was performed: create or update.').
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
					   'Whether the slot edit targeted class-side slots instead of instance-side slots.'
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

{ #category : 'private' }
MCPToolEditClass >> failureMessageForAddSlotNamed: slotName onClassNamed: className classSide: classSide error: anError [

	^ 'Failed to add ' , (self slotDescriptionForClassSide: classSide)
	  , ' ' , slotName , ' to class ' , className , ': '
	  , (self normalizedCauseMessageForOperationError: anError)
]

{ #category : 'private' }
MCPToolEditClass >> failureMessageForCreateClassNamed: className superclassName: superclassName packageName: packageName error: anError [

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
				  (self normalizedCauseMessageForOperationError: anError) ]
]

{ #category : 'private' }
MCPToolEditClass >> failureMessageForMoveClassNamed: className packageName: packageName tag: tag error: anError [

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
				  (self normalizedCauseMessageForOperationError: anError) ]
]

{ #category : 'private' }
MCPToolEditClass >> failureMessageForMoveSlotNamed: slotName onClassNamed: className classSide: classSide operation: operation error: anError [

	operation = 'pullUpSlot' ifTrue: [
		^ 'Failed to pull up '
		  , (self slotDescriptionForClassSide: classSide) , ' ' , slotName
		  , ' to class ' , className , ': '
		  , (self normalizedCauseMessageForOperationError: anError) ].
	^ 'Failed to push down '
	  , (self slotDescriptionForClassSide: classSide) , ' ' , slotName
	  , ' from class ' , className , ': '
	  , (self normalizedCauseMessageForOperationError: anError)
]

{ #category : 'private' }
MCPToolEditClass >> failureMessageForRemoveSlotNamed: slotName onClassNamed: className classSide: classSide error: anError [

	^ 'Failed to remove ' , (self slotDescriptionForClassSide: classSide)
	  , ' ' , slotName , ' from class ' , className , ': '
	  , (self normalizedCauseMessageForOperationError: anError)
]

{ #category : 'private' }
MCPToolEditClass >> failureMessageForRenameClassNamed: className to: newClassName error: anError [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Unable to rename class ';
			  nextPutAll: className;
			  nextPutAll: ' to ';
			  nextPutAll: newClassName;
			  nextPutAll: ': ';
			  nextPutAll:
				  (self normalizedCauseMessageForOperationError: anError) ]
]

{ #category : 'private' }
MCPToolEditClass >> failureMessageForRenameSlotNamed: slotName to: newSlotName onClassNamed: className classSide: classSide error: anError [

	^ 'Failed to rename ' , (self slotDescriptionForClassSide: classSide)
	  , ' ' , slotName , ' to ' , newSlotName , ' in class ' , className
	  , ': ' , (self normalizedCauseMessageForOperationError: anError)
]

{ #category : 'private' }
MCPToolEditClass >> failureMessageForReparentClassNamed: className superclassName: superclassName error: anError [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Unable to reparent class ';
			  nextPutAll: className;
			  nextPutAll: ' to superclass ';
			  nextPutAll: superclassName;
			  nextPutAll: ': ';
			  nextPutAll:
				  (self normalizedCauseMessageForOperationError: anError) ]
]

{ #category : 'private' }
MCPToolEditClass >> failureMessageForReplaceClassTraitsOnClassNamed: className error: anError [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Unable to replace class-side traits for class ';
			  nextPutAll: className;
			  nextPutAll: ': ';
			  nextPutAll:
				  (self normalizedCauseMessageForOperationError: anError) ]
]

{ #category : 'private' }
MCPToolEditClass >> failureMessageForReplaceDefinitionOnClassNamed: className error: anError [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Unable to replace slot definition for class ';
			  nextPutAll: className;
			  nextPutAll: ': ';
			  nextPutAll:
				  (self normalizedCauseMessageForOperationError: anError) ]
]

{ #category : 'private' }
MCPToolEditClass >> failureMessageForReplaceLayoutOnClassNamed: className error: anError [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Unable to replace layout for class ';
			  nextPutAll: className;
			  nextPutAll: ': ';
			  nextPutAll:
				  (self normalizedCauseMessageForOperationError: anError) ]
]

{ #category : 'private' }
MCPToolEditClass >> failureMessageForReplaceSharedPoolsOnClassNamed: className error: anError [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Unable to replace shared pools for class ';
			  nextPutAll: className;
			  nextPutAll: ': ';
			  nextPutAll:
				  (self normalizedCauseMessageForOperationError: anError) ]
]

{ #category : 'private' }
MCPToolEditClass >> failureMessageForReplaceSharedVariablesOnClassNamed: className error: anError [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Unable to replace shared variables for class ';
			  nextPutAll: className;
			  nextPutAll: ': ';
			  nextPutAll:
				  (self normalizedCauseMessageForOperationError: anError) ]
]

{ #category : 'private' }
MCPToolEditClass >> failureMessageForReplaceTraitsOnClassNamed: className error: anError [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Unable to replace traits for class ';
			  nextPutAll: className;
			  nextPutAll: ': ';
			  nextPutAll:
				  (self normalizedCauseMessageForOperationError: anError) ]
]

{ #category : 'private' }
MCPToolEditClass >> failureMessageForSetCommentOnClassNamed: className error: anError [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Unable to set comment for class ';
			  nextPutAll: className;
			  nextPutAll: ': ';
			  nextPutAll:
				  (self normalizedCauseMessageForOperationError: anError) ]
]

{ #category : 'private - operations' }
MCPToolEditClass >> operationSpecifications [

	^ {
		  {
			  (#name -> 'create').
			  (#requiredProperties -> #( 'superclassName' 'packageName' )) }
			  asDictionary.
		  {
			  (#name -> 'update').
			  (#requiredProperties -> #(  )) } asDictionary }
]

{ #category : 'private - request' }
MCPToolEditClass >> packageNameForMoveClassNamed: className requestedPackageName: requestedPackageName [

	requestedPackageName ifNotNil: [ ^ requestedPackageName ].
	^ (Smalltalk globals at: className asSymbol ifAbsent: [ ^ '' ])
		  packageName asString
]

{ #category : 'private - request' }
MCPToolEditClass >> parsedRequestFromToolRequest: request [

	| operation |
	operation := self operationFromRequest: request.
	self
		validateRequiredPropertiesForOperation: operation
		inRequest: request.
	operation = 'create' ifTrue: [
		^ MCPClassCreateRequest fromRequest: request tool: self ].
	operation = 'update' ifTrue: [
		^ MCPClassUpdateRequest fromRequest: request tool: self ].
	Error signal: self operationValidationErrorMessage
]

{ #category : 'private' }
MCPToolEditClass >> slotDescriptionForClassSide: aBoolean [

	^ aBoolean
		  ifTrue: [ 'class-side slot' ]
		  ifFalse: [ 'slot' ]
]

{ #category : 'private - schema' }
MCPToolEditClass >> updatePlanOutputSchemaProperty [

	| property requestedContextProperty updateActionProperty |
	updateActionProperty := self
		                        schemaPropertyNamed: 'updateAction'
		                        type: 'string'
		                        description:
		                        'The update action selected from operation=update.'.
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
