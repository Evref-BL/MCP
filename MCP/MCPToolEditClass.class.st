Class {
	#name : 'MCPToolEditClass',
	#superclass : 'MCPEditTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'private - arguments' }
MCPToolEditClass >> classCommentFromArguments: arguments [

	| value |
	value := self
		         argumentNamed: 'classComment'
		         in: arguments
		         ifAbsent: [ ^ nil ].
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

	^ 'Create, move, rename, reparent, pull up or push down slots, or set the comment of a class in the running image. Use this for class-level definition and structural updates; use edit-method for methods and remove-classes for deletion.'
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
				  ((MCPStructureProperties new
					    name: 'slots';
					    type: 'array';
					    description:
						    'Optional instance-side slot names for operation=create.')
					   items: (MCPStructureProperties new
							    type: 'string';
							    description: 'An instance-side slot name.';
							    yourself);
					   yourself).
				  ((MCPStructureProperties new
					    name: 'classSlots';
					    type: 'array';
					    description:
						    'Optional class-side slot names for operation=create.')
					   items: (MCPStructureProperties new
							    type: 'string';
							    description: 'A class-side slot name.';
							    yourself);
					   yourself).
				  (MCPStructureProperties new
					   name: 'newClassName';
					   type: 'string';
					   description:
						   'The new class name to assign when operation=rename.';
					   yourself).
				  (MCPStructureProperties new
					   name: 'slotName';
					   type: 'string';
					   description:
						   'The slot name to pull up or push down when operation=pullUpSlot or operation=pushDownSlot.';
					   yourself).
				  (self
					   booleanSchemaPropertyNamed: 'classSide'
					   description:
					   'Whether slot movement targets class-side slots instead of instance-side slots when operation=pullUpSlot or operation=pushDownSlot.'
					   default: false).
				  (MCPStructureProperties new
					   name: 'classComment';
					   type: 'string';
					   description:
						   'The class comment to assign when operation=setComment. Use an empty string to clear the comment.';
					   yourself) };
		  required: #( 'operation' 'className' );
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
				  ((self
					    schemaPropertyNamed: 'instanceSlotNames'
					    type: 'array'
					    description:
						    'The instance-side slots present on the class after the operation.')
					   items: (MCPStructureProperties new
							    type: 'string';
							    description: 'An instance-side slot name.';
							    yourself);
					   yourself).
				  ((self
					    schemaPropertyNamed: 'classSlotNames'
					    type: 'array'
					    description:
						    'The class-side slots present on the class after the operation.')
					   items: (MCPStructureProperties new
							    type: 'string';
							    description: 'A class-side slot name.';
							    yourself);
					   yourself).
				  (self
					   schemaPropertyNamed: 'slotName'
					   type: 'string'
					   description:
					   'The slot name that was pulled up or pushed down when operation=pullUpSlot or operation=pushDownSlot.').
				  (self
					   booleanSchemaPropertyNamed: 'classSide'
					   description:
					   'Whether the slot move targeted class-side slots instead of instance-side slots.'
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
			     'subclassNames' )
]

{ #category : 'defaults' }
MCPToolEditClass >> defaultTitle [

	^ 'Edit Pharo Class'
]

{ #category : 'executing' }
MCPToolEditClass >> executeCreateWithArguments: arguments [

	| className packageName result slots superclassName tag |
	className := self stringArgumentNamed: 'className' in: arguments.
	superclassName := self
		                  stringArgumentNamed: 'superclassName'
		                  in: arguments.
	packageName := self stringArgumentNamed: 'packageName' in: arguments.
	tag := self stringArgumentNamed: 'tag' in: arguments.
	slots := self argumentNamed: 'slots' in: arguments ifAbsent: [ nil ].
	^ [
	  [
	  result := (MCPCreateClassCommand
		             className: className
		             superclassName: superclassName
		             packageName: packageName
		             tag: tag
		             slots: slots
		             classSlots:
		             (self
			              argumentNamed: 'classSlots'
			              in: arguments
			              ifAbsent: [ nil ])) execute.
	  self
		  successResultText: 'Created class ' , className , '.'
		  data: (self dataForResult: result operation: 'create') ]
		  on: MCPCommandError
		  do: [ :error |
		  self errorResultForCommandError: error operation: 'create' ] ]
		  on: Exception
		  do: [ :error |
			  self
				  errorResultForOperationFailure: error
				  operation: 'create'
				  requestedContext: {
						  (#className -> className).
						  (#superclassName -> superclassName).
						  (#packageName -> packageName).
						  (#tag -> (tag ifNil: [ '' ] ifNotNil: [ tag ])) } asDictionary
				  summary: (self
						   failureMessageForCreateClassNamed: className
						   superclassName: superclassName
						   packageName: packageName
						   error: error) ]
]

{ #category : 'executing' }
MCPToolEditClass >> executeMoveSlotWithArguments: arguments operation: operation [

	| className classSide result slotName |
	className := self stringArgumentNamed: 'className' in: arguments.
	slotName := self stringArgumentNamed: 'slotName' in: arguments.
	classSide := self
		             booleanArgumentNamed: 'classSide'
		             in: arguments
		             default: false.
	^ [
	  [
	  result := (MCPMoveSlotCommand
		             className: className
		             slotName: slotName
		             direction: operation
		             classSide: classSide) execute.
	  self
		  successResultText: (operation = 'pullUpSlot'
				   ifTrue: [
					   'Pulled up ' , (self slotDescriptionForClassSide: classSide)
					   , ' ' , slotName , ' to class ' , className , '.' ]
				   ifFalse: [
					   'Pushed down ' , (self slotDescriptionForClassSide: classSide)
					   , ' ' , slotName , ' from class ' , className , '.' ])
		  data: (self dataForResult: result operation: operation) ]
		  on: MCPCommandError
		  do: [ :error |
			  | details |
			  details := error structuredDetails copy.
			  details at: #operation put: operation.
			  details at: #slotName put: slotName.
			  details at: #classSide put: classSide.
			  self errorResultText: error messageText details: details ] ]
		  on: Exception
		  do: [ :error |
			  self
				  errorResultForOperationFailure: error
				  operation: operation
				  requestedContext: {
						  (#className -> className).
						  (#slotName -> slotName).
						  (#classSide -> classSide) } asDictionary
				  summary: (self
						   failureMessageForMoveSlotNamed: slotName
						   onClassNamed: className
						   classSide: classSide
						   operation: operation
						   error: error) ]
]

{ #category : 'executing' }
MCPToolEditClass >> executeMoveWithArguments: arguments [

	| className packageName result tag |
	className := self stringArgumentNamed: 'className' in: arguments.
	packageName := self stringArgumentNamed: 'packageName' in: arguments.
	tag := self stringArgumentNamed: 'tag' in: arguments.
	^ [
	  [
	  result := (MCPMoveClassCommand
		             className: className
		             packageName: packageName
		             tag: tag) execute.
	  self
		  successResultText:
		  'Moved class ' , className , ' to package ' , packageName , '.'
		  data: (self dataForResult: result operation: 'move') ]
		  on: MCPCommandError
		  do: [ :error |
		  self errorResultForCommandError: error operation: 'move' ] ]
		  on: Exception
		  do: [ :error |
			  self
				  errorResultForOperationFailure: error
				  operation: 'move'
				  requestedContext: {
						  (#className -> className).
						  (#packageName -> packageName).
						  (#tag -> (tag ifNil: [ '' ] ifNotNil: [ tag ])) } asDictionary
				  summary: (self
						   failureMessageForMoveClassNamed: className
						   packageName: packageName
						   tag: tag
						   error: error) ]
]

{ #category : 'executing' }
MCPToolEditClass >> executePullUpSlotWithArguments: arguments [

	^ self
		  executeMoveSlotWithArguments: arguments
		  operation: 'pullUpSlot'
]

{ #category : 'executing' }
MCPToolEditClass >> executePushDownSlotWithArguments: arguments [

	^ self
		  executeMoveSlotWithArguments: arguments
		  operation: 'pushDownSlot'
]

{ #category : 'executing' }
MCPToolEditClass >> executeRenameWithArguments: arguments [

	| className newClassName result |
	className := self stringArgumentNamed: 'className' in: arguments.
	newClassName := self
		                stringArgumentNamed: 'newClassName'
		                in: arguments.
	^ [
	  [
	  result := (MCPRenameClassCommand
		             className: className
		             newClassName: newClassName) execute.
	  self
		  successResultText:
		  'Renamed class ' , className , ' to ' , newClassName , '.'
		  data: (self dataForResult: result operation: 'rename') ]
		  on: MCPCommandError
		  do: [ :error |
		  self errorResultForCommandError: error operation: 'rename' ] ]
		  on: Exception
		  do: [ :error |
			  self
				  errorResultForOperationFailure: error
				  operation: 'rename'
				  requestedContext: {
						  (#className -> className).
						  (#newClassName -> newClassName) } asDictionary
				  summary: (self
						   failureMessageForRenameClassNamed: className
						   to: newClassName
						   error: error) ]
]

{ #category : 'executing' }
MCPToolEditClass >> executeReparentWithArguments: arguments [

	| className result superclassName |
	className := self stringArgumentNamed: 'className' in: arguments.
	superclassName := self
		                  stringArgumentNamed: 'superclassName'
		                  in: arguments.
	^ [
	  [
	  result := (MCPReparentClassCommand
		             className: className
		             superclassName: superclassName) execute.
	  self
		  successResultText:
			  'Reparented class ' , className , ' to superclass '
			  , superclassName , '.'
		  data: (self dataForResult: result operation: 'reparent') ]
		  on: MCPCommandError
		  do: [ :error |
			  self errorResultForCommandError: error operation: 'reparent' ] ]
		  on: Exception
		  do: [ :error |
			  self
				  errorResultForOperationFailure: error
				  operation: 'reparent'
				  requestedContext: {
						  (#className -> className).
						  (#superclassName -> superclassName) } asDictionary
				  summary: (self
						   failureMessageForReparentClassNamed: className
						   superclassName: superclassName
						   error: error) ]
]

{ #category : 'executing' }
MCPToolEditClass >> executeSetCommentWithArguments: arguments [

	| classComment className result |
	className := self stringArgumentNamed: 'className' in: arguments.
	classComment := self classCommentFromArguments: arguments.
	^ [
	  [
	  result := (MCPChangeClassCommentCommand
		             className: className
		             classComment: classComment) execute.
	  self
		  successResultText: 'Set comment for class ' , className , '.'
		  data: (self dataForResult: result operation: 'setComment') ]
		  on: MCPCommandError
		  do: [ :error |
			  self errorResultForCommandError: error operation: 'setComment' ] ]
		  on: Exception
		  do: [ :error |
			  self
				  errorResultForOperationFailure: error
				  operation: 'setComment'
				  requestedContext: {
						  (#className -> className).
						  (#classComment -> classComment) } asDictionary
				  summary:
				  (self
					   failureMessageForSetCommentOnClassNamed: className
					   error: error) ]
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
			  (#requiredArguments -> #( 'superclassName' 'packageName' )).
			  (#executeSelector -> #executeCreateWithArguments:) } asDictionary.
		  {
			  (#name -> 'move').
			  (#requiredArguments -> #( 'packageName' )).
			  (#executeSelector -> #executeMoveWithArguments:) } asDictionary.
		  {
			  (#name -> 'rename').
			  (#requiredArguments -> #( 'newClassName' )).
			  (#executeSelector -> #executeRenameWithArguments:) } asDictionary.
		  {
			  (#name -> 'reparent').
			  (#requiredArguments -> #( 'superclassName' )).
			  (#executeSelector -> #executeReparentWithArguments:) }
			  asDictionary.
		  {
			  (#name -> 'setComment').
			  (#requiredArguments -> #( 'classComment' )).
			  (#executeSelector -> #executeSetCommentWithArguments:) }
			  asDictionary.
		  {
			  (#name -> 'pullUpSlot').
			  (#requiredArguments -> #( 'slotName' )).
			  (#executeSelector -> #executePullUpSlotWithArguments:) }
			  asDictionary.
		  {
			  (#name -> 'pushDownSlot').
			  (#requiredArguments -> #( 'slotName' )).
			  (#executeSelector -> #executePushDownSlotWithArguments:) }
			  asDictionary }
]

{ #category : 'private' }
MCPToolEditClass >> slotDescriptionForClassSide: aBoolean [

	^ aBoolean
		  ifTrue: [ 'class-side slot' ]
		  ifFalse: [ 'slot' ]
]
