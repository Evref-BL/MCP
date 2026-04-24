"
Edits class structure and metadata in the running image. Use it for class-level changes such as creation, moves, renames, reparenting, slot additions, removals, renames, pull-ups, push-downs, and comment updates. Class-side slot renaming is intentionally unsupported for now; it needs a dedicated refactoring that preserves values and renames accessors.
"
Class {
	#name : 'MCPToolEditClass',
	#superclass : 'MCPToolEdit',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'private - request' }
MCPToolEditClass >> classCommentFromRequest: request [

	| value |
	value := request argumentNamed: 'classComment' ifAbsent: [ ^ nil ].
	^ value ifNil: [ '' ] ifNotNil: [ value asString ]
]

{ #category : 'private' }
MCPToolEditClass >> dataForResult: aResult operation: operation [

	| class data |
	data := aResult asDictionary copy.
	data at: #operation put: operation.
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

	^ 'Create, move, rename, or reparent classes; add, remove, rename, pull up, or push down slots; or set a class comment in the running image. Use this for class-level definition and structural updates; use edit-method for methods and remove-classes for deletion.'
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
						   'The class edit operation to perform.'
					   supportedValuesLeadIn: 'Supported values are').
				  (MCPStructureProperties new
					   name: 'className';
					   type: 'string';
					   description: 'The class to edit, or the class name to create.';
					   yourself).
				  (MCPStructureProperties new
					   name: 'superclassName';
					   type: 'string';
					   description:
						   'The superclass to use when operation=create, or the new superclass when operation=reparent.';
					   yourself).
				  (MCPStructureProperties new
					   name: 'packageName';
					   type: 'string';
					   description:
						   'The package to create into when operation=create, or the destination package when operation=move. Missing destination packages are created automatically.';
					   yourself).
				  (MCPStructureProperties new
					   name: 'tag';
					   type: 'string';
					   description:
						   'An optional package tag for operation=create, or the destination tag when operation=move. Missing destination tags are created automatically.';
					   yourself).
				  (self
					   stringArraySchemaNamed: 'slots'
					   description:
					   'Optional instance-side slot names for operation=create.'
					   itemDescription: 'An instance-side slot name.').
				  (self
					   stringArraySchemaNamed: 'classSlots'
					   description:
					   'Optional class-side slot names for operation=create.'
					   itemDescription: 'A class-side slot name.').
				  (self
					   stringArraySchemaNamed: 'traits'
					   description: 'Optional trait names for operation=create.'
					   itemDescription: 'A trait name.').
				  (self
					   stringArraySchemaNamed: 'classTraits'
					   description:
					   'Optional class-side trait names for operation=create. Use names like TraitName classTrait or TraitName.'
					   itemDescription: 'A class-side trait name.').
				  (self
					   stringArraySchemaNamed: 'sharedVariables'
					   description:
					   'Optional class variable names for operation=create.'
					   itemDescription: 'A class variable name.').
				  (self
					   stringArraySchemaNamed: 'sharedPools'
					   description:
					   'Optional shared pool names for operation=create.'
					   itemDescription: 'A shared pool name.').
				  (MCPStructureProperties new
					   name: 'layout';
					   type: 'string';
					   description:
						   'An optional layout class name for operation=create.';
					   yourself).
				  (MCPStructureProperties new
					   name: 'newClassName';
					   type: 'string';
					   description:
						   'The new class name to assign when operation=rename.';
					   yourself).
				  self refactoringScopeSchemaProperty.
				  self refactoringScopePackageNamesSchemaProperty.
				  self refactoringScopeClassNamesSchemaProperty.
				  (MCPStructureProperties new
					   name: 'slotName';
					   type: 'string';
					   description:
						   'The slot name to add, remove, rename, pull up, or push down when operation=addSlot, operation=removeSlot, operation=renameSlot, operation=pullUpSlot, or operation=pushDownSlot.';
					   yourself).
				  (MCPStructureProperties new
					   name: 'newSlotName';
					   type: 'string';
					   description:
						   'The new slot name to assign when operation=renameSlot. Only instance-side slot renames are currently supported.';
					   yourself).
				  (self
					   booleanSchemaPropertyNamed: 'classSide'
					   description:
					   'Whether slot editing targets class-side slots instead of instance-side slots when operation=addSlot, operation=removeSlot, operation=renameSlot, operation=pullUpSlot, or operation=pushDownSlot. operation=renameSlot currently supports only false.'
					   default: false).
				  self forceSchemaProperty.
				  (MCPStructureProperties new
					   name: 'classComment';
					   type: 'string';
					   description:
						   'The class comment to assign when operation=create or operation=setComment. Use an empty string to clear the comment.';
					   yourself) };
		  required: #( 'operation' 'className' );
		  oneOf: self operationBranchSchemas;
		  allOf:
		  (self refactoringScopeConditionSchemasForOperationNamed: 'rename');
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
					   description: 'The class edit operation that was performed.').
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
					   stringArraySchemaNamed: 'traitNames'
					   description:
					   'The traits used by the class after the operation.'
					   itemDescription: 'A trait name.').
				  (self
					   stringArraySchemaNamed: 'classTraitNames'
					   description:
					   'The traits used by the class side after the operation.'
					   itemDescription: 'A class-side trait name.').
				  (self
					   stringArraySchemaNamed: 'sharedVariableNames'
					   description:
					   'The class variables defined on the class after the operation.'
					   itemDescription: 'A class variable name.').
				  (self
					   stringArraySchemaNamed: 'sharedPoolNames'
					   description:
					   'The shared pools referenced by the class after the operation.'
					   itemDescription: 'A shared pool name.').
				  (self
					   schemaPropertyNamed: 'layoutClassName'
					   type: 'string'
					   description:
					   'The layout class used by the class after the operation.').
				  (self
					   schemaPropertyNamed: 'slotName'
					   type: 'string'
					   description:
					   'The slot name that was added, removed, pulled up, or pushed down when operation=addSlot, operation=removeSlot, operation=pullUpSlot, or operation=pushDownSlot.').
				  (self
					   schemaPropertyNamed: 'oldSlotName'
					   type: 'string'
					   description:
					   'The previous slot name when operation=renameSlot.').
				  (self
					   schemaPropertyNamed: 'newSlotName'
					   type: 'string'
					   description: 'The new slot name when operation=renameSlot.').
				  (self
					   booleanSchemaPropertyNamed: 'classSide'
					   description:
					   'Whether the slot edit targeted class-side slots instead of instance-side slots. operation=renameSlot currently supports only false.'
					   default: false).
				  ((self
					    schemaPropertyNamed: 'affectedClassNames'
					    type: 'array'
					    description:
						    'The other classes whose slot definitions were changed by operation=pullUpSlot or operation=pushDownSlot.')
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
					   description: 'The previous package when operation=move.').
				  (self
					   schemaPropertyNamed: 'oldTag'
					   type: 'string'
					   description: 'The previous package tag when operation=move.').
				  (self
					   schemaPropertyNamed: 'oldClassName'
					   type: 'string'
					   description: 'The previous class name when operation=rename.').
				  (self
					   schemaPropertyNamed: 'newClassName'
					   type: 'string'
					   description: 'The new class name when operation=rename.').
				  (self
					   schemaPropertyNamed: 'oldSuperclassName'
					   type: 'string'
					   description:
					   'The previous superclass when operation=reparent.').
				  (self
					   schemaPropertyNamed: 'oldClassComment'
					   type: 'string'
					   description:
					   'The previous class comment when operation=setComment.').
				  (self
					   schemaPropertyNamed: 'newClassComment'
					   type: 'string'
					   description:
					   'The new class comment when operation=setComment.') }
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

{ #category : 'executing' }
MCPToolEditClass >> executeAddSlotWithRequest: request [

	^ self
		  executeSlotOperation: 'addSlot'
		  withRequest: request
		  work: [ :className :slotName :classSide |
			  (MCPAddSlotCommand
				   className: className
				   slotName: slotName
				   classSide: classSide) execute ]
		  successSummary: [ :className :slotName :classSide |
			  'Added ' , (self slotDescriptionForClassSide: classSide) , ' '
			  , slotName , ' to class ' , className , '.' ]
		  failureSummary: [ :className :slotName :classSide :error |
			  self
				  failureMessageForAddSlotNamed: slotName
				  onClassNamed: className
				  classSide: classSide
				  error: error ]
]

{ #category : 'executing' }
MCPToolEditClass >> executeCreateWithRequest: request [

	| classComment className classSlotNames classSlots classTraits force layout packageName requestedContext result sharedPools sharedVariables slotNames slots superclassName tag traits |
	className := request stringArgumentNamed: 'className'.
	superclassName := request stringArgumentNamed: 'superclassName'.
	packageName := request stringArgumentNamed: 'packageName'.
	tag := request stringArgumentNamed: 'tag'.
	classComment := (request hasArgumentNamed: 'classComment')
		                ifTrue: [ self classCommentFromRequest: request ]
		                ifFalse: [ nil ].
	force := self forceFromRequest: request.
	slotNames := request stringCollectionArgumentNamed: 'slots'.
	classSlotNames := request stringCollectionArgumentNamed: 'classSlots'.
	slots := request symbolCollectionArgumentNamed: 'slots'.
	classSlots := request symbolCollectionArgumentNamed: 'classSlots'.
	traits := request stringCollectionArgumentNamed: 'traits'.
	classTraits := request stringCollectionArgumentNamed: 'classTraits'.
	sharedVariables := request stringCollectionArgumentNamed:
		                   'sharedVariables'.
	sharedPools := request stringCollectionArgumentNamed: 'sharedPools'.
	layout := request stringArgumentNamed: 'layout'.
	requestedContext := {
		                    (#className -> className).
		                    (#superclassName -> superclassName).
		                    (#packageName -> packageName).
		                    (#tag -> (tag ifNil: [ '' ] ifNotNil: [ tag ])).
		                    (#classComment
		                     ->
		                     (classComment
			                      ifNil: [ '' ]
			                      ifNotNil: [ classComment ])).
		                    (#slots -> slotNames).
		                    (#classSlots -> classSlotNames).
		                    (#traits -> traits).
		                    (#classTraits -> classTraits).
		                    (#sharedVariables -> sharedVariables).
		                    (#sharedPools -> sharedPools).
		                    (#layout
		                     -> (layout ifNil: [ '' ] ifNotNil: [ layout ])) }
		                    asDictionary.
	^ self
		  executeEditOperation: 'create'
		  force: force
		  requestedContext: requestedContext
		  work: [
			  result := (MCPCreateClassCommand
				             className: className
				             superclassName: superclassName
				             packageName: packageName
				             tag: tag
				             slots: slots
				             classSlots: classSlots
				             traits: traits
				             classTraits: classTraits
				             sharedVariables: sharedVariables
				             sharedPools: sharedPools
				             layout: layout) execute.
			  classComment ifNotNil: [
				  (MCPChangeClassCommentCommand
					   className: className
					   classComment: classComment) execute ] ]
		  successResult: [ :warningMessages |
			  self
				  successResultText: 'Created class ' , className , '.'
				  data: (self dataForResult: result operation: 'create')
				  warnings: warningMessages ]
		  failureSummary: [ :error |
			  self
				  failureMessageForCreateClassNamed: className
				  superclassName: superclassName
				  packageName: packageName
				  error: error ]
]

{ #category : 'executing' }
MCPToolEditClass >> executeMoveSlotWithRequest: request operation: operation [

	^ self
		  executeSlotOperation: operation
		  withRequest: request
		  work: [ :className :slotName :classSide |
			  (MCPMoveSlotCommand
				   className: className
				   slotName: slotName
				   direction: operation
				   classSide: classSide) execute ]
		  successSummary: [ :className :slotName :classSide |
			  operation = 'pullUpSlot'
				  ifTrue: [
					  'Pulled up ' , (self slotDescriptionForClassSide: classSide)
					  , ' ' , slotName , ' to class ' , className , '.' ]
				  ifFalse: [
					  'Pushed down ' , (self slotDescriptionForClassSide: classSide)
					  , ' ' , slotName , ' from class ' , className , '.' ] ]
		  failureSummary: [ :className :slotName :classSide :error |
			  self
				  failureMessageForMoveSlotNamed: slotName
				  onClassNamed: className
				  classSide: classSide
				  operation: operation
				  error: error ]
]

{ #category : 'executing' }
MCPToolEditClass >> executeMoveWithRequest: request [

	| className force packageName requestedContext result tag |
	className := request stringArgumentNamed: 'className'.
	packageName := request stringArgumentNamed: 'packageName'.
	tag := request stringArgumentNamed: 'tag'.
	force := self forceFromRequest: request.
	requestedContext := {
		                    (#className -> className).
		                    (#packageName -> packageName).
		                    (#tag -> (tag ifNil: [ '' ] ifNotNil: [ tag ])) }
		                    asDictionary.
	^ self
		  executeEditOperation: 'move'
		  force: force
		  requestedContext: requestedContext
		  work: [
			  result := (MCPMoveClassCommand
				             className: className
				             packageName: packageName
				             tag: tag) execute ]
		  successResult: [ :warningMessages |
			  self
				  successResultText:
				  'Moved class ' , className , ' to package ' , packageName , '.'
				  data: (self dataForResult: result operation: 'move')
				  warnings: warningMessages ]
		  failureSummary: [ :error |
			  self
				  failureMessageForMoveClassNamed: className
				  packageName: packageName
				  tag: tag
				  error: error ]
]

{ #category : 'executing' }
MCPToolEditClass >> executePullUpSlotWithRequest: request [

	^ self
		  executeMoveSlotWithRequest: request
		  operation: 'pullUpSlot'
]

{ #category : 'executing' }
MCPToolEditClass >> executePushDownSlotWithRequest: request [

	^ self
		  executeMoveSlotWithRequest: request
		  operation: 'pushDownSlot'
]

{ #category : 'executing' }
MCPToolEditClass >> executeRemoveSlotWithRequest: request [

	^ self
		  executeSlotOperation: 'removeSlot'
		  withRequest: request
		  work: [ :className :slotName :classSide |
			  (MCPRemoveSlotCommand
				   className: className
				   slotName: slotName
				   classSide: classSide) execute ]
		  successSummary: [ :className :slotName :classSide |
			  'Removed ' , (self slotDescriptionForClassSide: classSide) , ' '
			  , slotName , ' from class ' , className , '.' ]
		  failureSummary: [ :className :slotName :classSide :error |
			  self
				  failureMessageForRemoveSlotNamed: slotName
				  onClassNamed: className
				  classSide: classSide
				  error: error ]
]

{ #category : 'executing' }
MCPToolEditClass >> executeRenameSlotWithRequest: request [

	| className classSide force newSlotName requestedContext result slotName |
	className := request stringArgumentNamed: 'className'.
	slotName := request stringArgumentNamed: 'slotName'.
	newSlotName := request stringArgumentNamed: 'newSlotName'.
	classSide := request booleanArgumentNamed: 'classSide' default: false.
	force := self forceFromRequest: request.
	requestedContext := {
		                    (#className -> className).
		                    (#slotName -> slotName).
		                    (#newSlotName -> newSlotName).
		                    (#classSide -> classSide) } asDictionary.
	^ self
		  executeEditOperation: 'renameSlot'
		  force: force
		  requestedContext: requestedContext
		  work: [
			  result := (MCPRenameSlotCommand
				             className: className
				             slotName: slotName
				             newSlotName: newSlotName
				             classSide: classSide) execute ]
		  successResult: [ :warningMessages |
			  self
				  successResultText:
					  'Renamed slot ' , slotName , ' to ' , newSlotName
					  , ' in class ' , className , '.'
				  data: (self dataForResult: result operation: 'renameSlot')
				  warnings: warningMessages ]
		  failureSummary: [ :error |
			  self
				  failureMessageForRenameSlotNamed: slotName
				  to: newSlotName
				  onClassNamed: className
				  classSide: classSide
				  error: error ]
]

{ #category : 'executing' }
MCPToolEditClass >> executeRenameWithRequest: request [

	| className force newClassName refactoringModel requestedContext result scopeParameters targetClass |
	className := request stringArgumentNamed: 'className'.
	newClassName := request stringArgumentNamed: 'newClassName'.
	force := self forceFromRequest: request.
	requestedContext := {
		                    (#className -> className).
		                    (#newClassName -> newClassName) } asDictionary.
	^ self
		  executeEditOperation: 'rename'
		  force: force
		  requestedContext: requestedContext
		  work: [
			  scopeParameters := self refactoringScopeParametersFromRequest:
				                     request.
			  self
				  addRefactoringScopeContextFrom: scopeParameters
				  toRequestedContext: requestedContext.
			  targetClass := Smalltalk globals
				                 at: className asSymbol
				                 ifAbsent: [
				                 MCPCommandError signalMissingClassNamed:
					                 className ].
			  refactoringModel := self
				                      refactoringModelForScopeParameters:
				                      scopeParameters
				                      anchoredAtBehavior: targetClass.
			  result := (MCPRenameClassCommand
				             className: className
				             newClassName: newClassName
				             model: refactoringModel) execute ]
		  successResult: [ :warningMessages |
			  self
				  successResultText:
				  'Renamed class ' , className , ' to ' , newClassName , '.'
				  data: (self dataForResult: result operation: 'rename')
				  warnings: warningMessages ]
		  failureSummary: [ :error |
			  self
				  failureMessageForRenameClassNamed: className
				  to: newClassName
				  error: error ]
]

{ #category : 'executing' }
MCPToolEditClass >> executeReparentWithRequest: request [

	| className force requestedContext result superclassName |
	className := request stringArgumentNamed: 'className'.
	superclassName := request stringArgumentNamed: 'superclassName'.
	force := self forceFromRequest: request.
	requestedContext := {
		                    (#className -> className).
		                    (#superclassName -> superclassName) }
		                    asDictionary.
	^ self
		  executeEditOperation: 'reparent'
		  force: force
		  requestedContext: requestedContext
		  work: [
			  result := (MCPReparentClassCommand
				             className: className
				             superclassName: superclassName) execute ]
		  successResult: [ :warningMessages |
			  self
				  successResultText:
					  'Reparented class ' , className , ' to superclass '
					  , superclassName , '.'
				  data: (self dataForResult: result operation: 'reparent')
				  warnings: warningMessages ]
		  failureSummary: [ :error |
			  self
				  failureMessageForReparentClassNamed: className
				  superclassName: superclassName
				  error: error ]
]

{ #category : 'executing' }
MCPToolEditClass >> executeSetCommentWithRequest: request [

	| classComment className force requestedContext result |
	className := request stringArgumentNamed: 'className'.
	classComment := self classCommentFromRequest: request.
	force := self forceFromRequest: request.
	requestedContext := {
		                    (#className -> className).
		                    (#classComment -> classComment) } asDictionary.
	^ self
		  executeEditOperation: 'setComment'
		  force: force
		  requestedContext: requestedContext
		  work: [
			  result := (MCPChangeClassCommentCommand
				             className: className
				             classComment: classComment) execute ]
		  successResult: [ :warningMessages |
			  self
				  successResultText: 'Set comment for class ' , className , '.'
				  data: (self dataForResult: result operation: 'setComment')
				  warnings: warningMessages ]
		  failureSummary: [ :error |
			  self
				  failureMessageForSetCommentOnClassNamed: className
				  error: error ]
]

{ #category : 'private - execution' }
MCPToolEditClass >> executeSlotOperation: operation withRequest: request work: operationBlock successSummary: successSummaryBlock failureSummary: failureSummaryBlock [

	| className classSide force requestedContext result slotName |
	className := request stringArgumentNamed: 'className'.
	slotName := request stringArgumentNamed: 'slotName'.
	classSide := request booleanArgumentNamed: 'classSide' default: false.
	force := self forceFromRequest: request.
	requestedContext := {
		                    (#className -> className).
		                    (#slotName -> slotName).
		                    (#classSide -> classSide) } asDictionary.
	^ self
		  executeEditOperation: operation
		  force: force
		  requestedContext: requestedContext
		  work: [
			  result := operationBlock
				            value: className
				            value: slotName
				            value: classSide ]
		  successResult: [ :warningMessages |
			  self
				  successResultText:
				  (successSummaryBlock
					   value: className
					   value: slotName
					   value: classSide)
				  data: (self dataForResult: result operation: operation)
				  warnings: warningMessages ]
		  failureSummary: [ :error |
			  failureSummaryBlock
				  value: className
				  value: slotName
				  value: classSide
				  value: error ]
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
			  (#requiredProperties -> #( 'superclassName' 'packageName' )).
			  (#executeSelector -> #executeCreateWithRequest:) } asDictionary.
		  {
			  (#name -> 'move').
			  (#requiredProperties -> #( 'packageName' )).
			  (#executeSelector -> #executeMoveWithRequest:) } asDictionary.
		  {
			  (#name -> 'rename').
			  (#requiredProperties -> #( 'newClassName' )).
			  (#executeSelector -> #executeRenameWithRequest:) } asDictionary.
		  {
			  (#name -> 'reparent').
			  (#requiredProperties -> #( 'superclassName' )).
			  (#executeSelector -> #executeReparentWithRequest:) }
			  asDictionary.
		  {
			  (#name -> 'setComment').
			  (#requiredProperties -> #( 'classComment' )).
			  (#executeSelector -> #executeSetCommentWithRequest:) }
			  asDictionary.
		  {
			  (#name -> 'addSlot').
			  (#requiredProperties -> #( 'slotName' )).
			  (#executeSelector -> #executeAddSlotWithRequest:) }
			  asDictionary.
		  {
			  (#name -> 'removeSlot').
			  (#requiredProperties -> #( 'slotName' )).
			  (#executeSelector -> #executeRemoveSlotWithRequest:) }
			  asDictionary.
		  {
			  (#name -> 'renameSlot').
			  (#requiredProperties -> #( 'slotName' 'newSlotName' )).
			  (#executeSelector -> #executeRenameSlotWithRequest:) }
			  asDictionary.
		  {
			  (#name -> 'pullUpSlot').
			  (#requiredProperties -> #( 'slotName' )).
			  (#executeSelector -> #executePullUpSlotWithRequest:) }
			  asDictionary.
		  {
			  (#name -> 'pushDownSlot').
			  (#requiredProperties -> #( 'slotName' )).
			  (#executeSelector -> #executePushDownSlotWithRequest:) }
			  asDictionary }
]

{ #category : 'private' }
MCPToolEditClass >> slotDescriptionForClassSide: aBoolean [

	^ aBoolean
		  ifTrue: [ 'class-side slot' ]
		  ifFalse: [ 'slot' ]
]
