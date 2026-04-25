"
Edits class structure and metadata in the running image. Use it for class-level changes such as creation, moves, renames, reparenting, slot additions, removals, renames, pull-ups, push-downs, trait and layout replacement, shared variable and shared pool replacement, and comment updates.
"
Class {
	#name : 'MCPToolEditClass',
	#superclass : 'MCPToolEdit',
	#traits : '{} + TMCPClassTool',
	#classTraits : '{} + TMCPClassTool classTrait',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

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

{ #category : 'private - execution' }
MCPToolEditClass >> commandForRequest: editRequest [

	(editRequest isKindOf: MCPClassCreateRequest) ifTrue: [
		^ MCPCreateClassToolCommand tool: self request: editRequest ].
	(editRequest isKindOf: MCPClassUpdateRequest) ifTrue: [
		^ MCPUpdateClassCommand tool: self request: editRequest ].
	^ super commandForRequest: editRequest
]

{ #category : 'private' }
MCPToolEditClass >> dataForAppliedUpdateResult: anAppliedUpdateResult [

	^ self dataWithClassCommentFrom: anAppliedUpdateResult asDictionary
]

{ #category : 'private' }
MCPToolEditClass >> dataForResult: aResult operation: operation [

	| data |
	data := aResult asDictionary copy.
	data at: #operation put: operation.
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
MCPToolEditClass >> defaultDescription [

	^ 'Create or update classes in the running image. Use operation=create for new class definitions. Use operation=update with fields such as newClassName, superclassName, packageName, tag, classComment, slots, classSlots, traits, classTraits, sharedVariables, sharedPools, layout, or slotAction to perform one class edit. Omit packageName with tag to recategorize inside the current package. force=false stops on refactoring warnings and returns impactMessages plus howToProceed; force=true continues and returns warnings in the output.'
]

{ #category : 'defaults' }
MCPToolEditClass >> defaultIcons [

	^ { (self pngCompositeBaseIconNamed: #class badgeIconNamed: #edit) }
]

{ #category : 'defaults' }
MCPToolEditClass >> defaultInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  (self
					   operationSchemaPropertyWithDescription:
						   'The high-level class edit operation. operation=create defines a new class. operation=update is patch style: provide exactly one update action field, such as newClassName, superclassName, packageName or tag, classComment, slots and/or classSlots, traits, classTraits, sharedVariables, sharedPools, layout, or slotAction.'
					   supportedValuesLeadIn: 'Supported values are').
				  (MCPStructureProperties new
					   name: 'className';
					   type: 'string';
					   description:
						   'The existing class to patch during operation=update, or the new class name for operation=create.';
					   yourself).
				  (MCPStructureProperties new
					   name: 'superclassName';
					   type: 'string';
					   description:
						   'The superclass for operation=create. During operation=update this is a reparent patch action; do not combine it with another update action.';
					   yourself).
				  (MCPStructureProperties new
					   name: 'packageName';
					   type: 'string';
					   description:
						   'The package to create into, or the destination package for an operation=update move patch. Combine with tag to move or recategorize to a package tag. Omit packageName and provide tag to recategorize the class inside its current package. Missing destination packages are created automatically.';
					   yourself).
				  (MCPStructureProperties new
					   name: 'tag';
					   type: 'string';
					   description:
						   'Optional package tag for creation. During operation=update this is a move or recategorization patch: tag with packageName moves to that package tag, while tag without packageName recategorizes inside the current package.';
					   yourself).
				  (self
					   stringArraySchemaNamed: 'slots'
					   description:
					   'Optional instance-side slot names for operation=create. During operation=update this replaces the full instance-side slot list; use an empty array to remove all instance-side slots. May be combined with classSlots because together they are one definition replacement action. Do not combine with another update action.'
					   itemDescription: 'An instance-side slot name.').
				  (self
					   stringArraySchemaNamed: 'classSlots'
					   description:
					   'Optional class-side slot names for operation=create. During operation=update this replaces the full class-side slot list; use an empty array to remove all class-side slots. May be combined with slots because together they are one definition replacement action. Do not combine with another update action.'
					   itemDescription: 'A class-side slot name.').
				  (self
					   stringArraySchemaNamed: 'traits'
					   description:
					   'Optional instance-side trait names for operation=create. During operation=update this replaces the full instance-side trait list; use an empty array to remove all instance-side traits. Do not combine with another update action.'
					   itemDescription: 'A trait name.').
				  (self
					   stringArraySchemaNamed: 'classTraits'
					   description:
					   'Optional class-side trait names for operation=create. Use names like TraitName classTrait or TraitName. During operation=update this replaces the full class-side trait list; use an empty array to remove all class-side traits. Do not combine with another update action.'
					   itemDescription: 'A class-side trait name.').
				  (self
					   stringArraySchemaNamed: 'sharedVariables'
					   description:
					   'Optional class variable names for operation=create. During operation=update this replaces the full class variable list; use an empty array to remove all class variables. Do not combine with another update action.'
					   itemDescription: 'A class variable name.').
				  (self
					   stringArraySchemaNamed: 'sharedPools'
					   description:
					   'Optional shared pool names for operation=create. During operation=update this replaces the full shared pool list; use an empty array to remove all shared pools. Each name must resolve to SharedPool or one of its subclasses. Do not combine with another update action.'
					   itemDescription: 'A shared pool name.').
				  (MCPStructureProperties new
					   name: 'layout';
					   type: 'string';
					   description:
						   'Optional layout class name for operation=create. During operation=update this replaces the layout class; the name must resolve to AbstractLayout or one of its subclasses. Do not combine with another update action.';
					   yourself).
				  (MCPStructureProperties new
					   name: 'newClassName';
					   type: 'string';
					   description:
						   'The new class name for an operation=update rename patch; do not combine it with another update action.';
					   yourself).
				  self refactoringScopePackageNamesSchemaProperty.
				  self refactoringScopeClassNamesSchemaProperty.
				  self refactoringScopeHierarchyClassNamesSchemaProperty.
				  (self
					   stringEnumSchemaPropertyNamed: 'slotAction'
					   description:
					   'The slot patch action for operation=update. Requires slotName. Use add, remove, rename, pullUp, or pushDown, and do not combine with another update action.'
					   values: #( 'add' 'remove' 'rename' 'pullUp' 'pushDown' )).
				  (MCPStructureProperties new
					   name: 'slotName';
					   type: 'string';
					   description:
						   'The slot name targeted by slotAction during an operation=update slot patch.';
					   yourself).
				  (MCPStructureProperties new
					   name: 'newSlotName';
					   type: 'string';
					   description:
						   'The replacement slot name when slotAction=rename. Supports instance-side and class-side slot renames; class-side renames preserve existing class object values.';
					   yourself).
				  (self
					   booleanSchemaPropertyNamed: 'classSide'
					   description:
					   'Whether slotAction targets class-side slots instead of instance-side slots.'
					   default: false).
				  self forceSchemaProperty.
				  (MCPStructureProperties new
					   name: 'classComment';
					   type: 'string';
					   description:
						   'The class comment to assign during operation=create. During operation=update this is a set-comment patch action; use an empty string to clear the comment and do not combine it with another update action.';
					   yourself) };
		  required: #( 'operation' 'className' );
		  oneOf: self operationBranchSchemas;
		  additionalProperties: false;
		  yourself
]

{ #category : 'defaults' }
MCPToolEditClass >> defaultName [

	^ 'edit-class'
]

{ #category : 'defaults' }
MCPToolEditClass >> defaultOutputSchema [

	^ self
		  standardOutputSchemaForDataProperties: {
				  (self
					   schemaPropertyNamed: 'operation'
					   type: 'string'
					   description:
					   'The public class edit operation that was performed: create or update.').
				  (self
					   schemaPropertyNamed: 'updateAction'
					   type: 'string'
					   description:
					   'The update action performed when operation=update.').
				  self updatePlanOutputSchemaProperty.
				  self appliedChangeOutputSchemaProperty.
				  (self
					   schemaPropertyNamed: 'className'
					   type: 'string'
					   description: 'The class name after the operation completes.').
				  (self
					   schemaPropertyNamed: 'superclassName'
					   type: 'string'
					   description:
					   'The superclass of the class after the operation.').
				  (self
					   schemaPropertyNamed: 'packageName'
					   type: 'string'
					   description:
					   'The owning package of the class after the operation.').
				  (self
					   schemaPropertyNamed: 'tag'
					   type: 'string'
					   description:
					   'The package tag assigned to the class after the operation.').
				  (self
					   schemaPropertyNamed: 'classComment'
					   type: 'string'
					   description: 'The class comment after the operation.').
				  (self
					   stringArraySchemaNamed: 'instanceSlotNames'
					   description:
					   'The instance-side slots present on the class after the operation.'
					   itemDescription: 'An instance-side slot name.').
				  (self
					   stringArraySchemaNamed: 'classSlotNames'
					   description:
					   'The class-side slots present on the class after the operation.'
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
					   'The traits used by the class after the operation.'
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
					   'The traits used by the class side after the operation.'
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
					   'The class variables defined on the class after the operation.'
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
					   'The shared pools referenced by the class after the operation.'
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
					   'The layout class used by the class after the operation.').
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
						    'The direct subclasses of the class after the operation.')
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
			  #( 'operation' 'className' 'superclassName' 'packageName'
			     'tag' 'classComment' 'instanceSlotNames' 'classSlotNames'
			     'traitNames' 'classTraitNames' 'sharedVariableNames'
			     'sharedPoolNames' 'layoutClassName' 'subclassNames' )
]

{ #category : 'defaults' }
MCPToolEditClass >> defaultTitle [

	^ 'Edit Class'
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
