"
Removes classes from the image in one batch. It surfaces safe-removal warnings before destructive changes unless forced.
"
Class {
	#name : 'MCPToolRemoveClasses',
	#superclass : 'MCPTool',
	#traits : 'TMCPClassTool',
	#classTraits : 'TMCPClassTool classTrait',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'private - errors' }
MCPToolRemoveClasses >> classNamesForErrorFromParsedRequest: removeRequest rawRequest: rawRequest [

	removeRequest ifNotNil: [ ^ removeRequest classNames ].
	^ rawRequest stringCollectionArgumentNamed: 'classNames'
]

{ #category : 'private' }
MCPToolRemoveClasses >> classNamesFromRequest: request [

	| classNames |
	classNames := request uniqueStringCollectionArgumentNamed:
		              'classNames'.
	classNames ifEmpty: [
		Error signal: 'classNames must contain at least one class name.' ].
	^ classNames
]

{ #category : 'private - execution' }
MCPToolRemoveClasses >> commandForRequest: removeRequest [

	^ MCPRemoveClassesCommand
		  classNames: removeRequest classNames
		  force: removeRequest force
]

{ #category : 'defaults' }
MCPToolRemoveClasses >> defaultDescription [

	^ 'Remove classes as one batch. Safe-removal warnings stop the removal unless force is true. With force=true, the tool still returns those warnings.'
]

{ #category : 'defaults' }
MCPToolRemoveClasses >> defaultIcons [

	^ { (self pngCompositeBaseIconNamed: #class badgeIconNamed: #delete) }
]

{ #category : 'defaults' }
MCPToolRemoveClasses >> defaultInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  ((MCPStructureProperties new
					    name: 'classNames';
					    type: 'array';
					    description: 'The class names to remove as a single batch.')
					   items: (MCPStructureProperties new
							    type: 'string';
							    description: 'A class name to remove.';
							    yourself);
					   yourself).
				  (MCPStructureProperties new
					   name: 'force';
					   type: 'boolean';
					   description:
						   'When true, proceed even if safe-removal warnings are raised. Those warnings are returned in the tool result warnings.';
					   default: false;
					   yourself) };
		  required: #( 'classNames' );
		  yourself
]

{ #category : 'defaults' }
MCPToolRemoveClasses >> defaultName [

	^ 'remove-classes'
]

{ #category : 'defaults' }
MCPToolRemoveClasses >> defaultOutputSchema [

	^ self
		  standardOutputSchemaForDataProperties: {
				  ((self
					    schemaPropertyNamed: 'classNames'
					    type: 'array'
					    description:
						    'The class names removed by the batch operation.')
					   items: (MCPStructureProperties new
							    type: 'string';
							    description: 'A removed class name.';
							    yourself);
					   yourself).
				  ((self
					    schemaPropertyNamed: 'removedClasses'
					    type: 'array'
					    description:
						    'Structured details for each removed class in the batch.')
					   items: (MCPStructureProperties new
							    type: 'object';
							    properties: {
									    (self
										     schemaPropertyNamed: 'className'
										     type: 'string'
										     description: 'The class that was removed.').
									    (self
										     schemaPropertyNamed: 'superclassName'
										     type: 'string'
										     description:
											     'The superclass of the removed class before removal.').
									    (self
										     schemaPropertyNamed: 'packageName'
										     type: 'string'
										     description:
											     'The package that owned the removed class before removal.').
									    (self
										     schemaPropertyNamed: 'tag'
										     type: 'string'
										     description:
											     'The package tag that was assigned to the removed class before removal.').
									    (self
										     schemaPropertyNamed: 'wasEmpty'
										     type: 'boolean'
										     description:
											     'Whether the removed class was considered empty by the safe-removal rules.').
									    (self
										     schemaPropertyNamed: 'reparentedToSuperclassName'
										     type: 'string'
										     description:
											     'The superclass that direct subclasses were reparented to when applicable.').
									    ((self
										      schemaPropertyNamed: 'instanceSlotNames'
										      type: 'array'
										      description:
											      'The instance-side slots that were present on the removed class.')
										     items: (MCPStructureProperties new
												      type: 'string';
												      description: 'An instance-side slot name.';
												      yourself);
										     yourself).
									    ((self
										      schemaPropertyNamed: 'classSlotNames'
										      type: 'array'
										      description:
											      'The class-side slots that were present on the removed class.')
										     items: (MCPStructureProperties new
												      type: 'string';
												      description: 'A class-side slot name.';
												      yourself);
										     yourself).
									    ((self
										      schemaPropertyNamed: 'subclassNames'
										      type: 'array'
										      description:
											      'The direct subclasses that existed before removal.')
										     items: (MCPStructureProperties new
												      type: 'string';
												      description: 'A direct subclass name.';
												      yourself);
										     yourself).
									    ((self
										      schemaPropertyNamed: 'reparentedSubclassNames'
										      type: 'array'
										      description:
											      'The direct subclasses that were reparented as part of the removal.')
										     items: (MCPStructureProperties new
												      type: 'string';
												      description: 'A reparented direct subclass name.';
												      yourself);
										     yourself) };
							    required:
								    #( 'className' 'superclassName' 'packageName'
								       'tag' 'wasEmpty' 'reparentedToSuperclassName'
								       'instanceSlotNames' 'classSlotNames' 'subclassNames'
								       'reparentedSubclassNames' );
							    additionalProperties: false;
							    yourself);
					   yourself).
				  ((self
					    schemaPropertyNamed: 'removedPackageNames'
					    type: 'array'
					    description:
						    'Packages removed because the batch removed their last defined class.')
					   items: (MCPStructureProperties new
							    type: 'string';
							    description: 'A removed package name.';
							    yourself);
					   yourself) }
		  required: #( 'classNames' 'removedClasses' 'removedPackageNames' )
]

{ #category : 'defaults' }
MCPToolRemoveClasses >> defaultTitle [

	^ 'Remove Classes'
]

{ #category : 'private' }
MCPToolRemoveClasses >> errorResultForError: anError classNames: classNames [

	(anError isKindOf: MCPCommandError) ifTrue: [
		^ self
			  errorResultText: anError messageText
			  details: anError structuredDetails ].
	^ self
		  errorResultText:
		  (self failureMessageForClassNames: classNames error: anError)
		  details: {
				  (#errorClass -> anError class name).
				  (#message -> anError messageText).
				  (#classNames -> classNames asArray) } asDictionary
]

{ #category : 'executing' }
MCPToolRemoveClasses >> executeWithRequest: request [

	^ self
		  executeParsedRequestFrom: request
		  do: [ :removeRequest |
			  | result |
			  result := (self commandForRequest: removeRequest) execute.
			  self
				  successResultText: (self
						   successSummaryForClassNames: removeRequest classNames
						   removedClasses: result removedClasses
						   removedPackageNames: result removedPackageNames
						   forced: result warningMessages notEmpty)
				  data: result asDictionary
				  warnings: result warningMessages ]
		  onError: [ :error :removeRequest |
			  self errorResultForError: error classNames: (self
					   classNamesForErrorFromParsedRequest: removeRequest
					   rawRequest: request) ]
]

{ #category : 'private' }
MCPToolRemoveClasses >> failureMessageForClassNames: classNames error: anError [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Unable to remove classes: ';
			  nextPutAll: (', ' join: classNames);
			  nextPutAll: ' (';
			  nextPutAll: anError class name;
			  nextPutAll: '): ';
			  nextPutAll: anError messageText ]
]

{ #category : 'private - request' }
MCPToolRemoveClasses >> parsedRequestFromToolRequest: request [

	^ MCPRemoveClassesRequest fromRequest: request tool: self
]

{ #category : 'testing' }
MCPToolRemoveClasses >> shouldSaveImageAfterSuccessfulExecution [

	^ true
]

{ #category : 'private' }
MCPToolRemoveClasses >> successSummaryForClassNames: classNames removedClasses: removedClasses removedPackageNames: removedPackageNames forced: wasForced [

	| reparentedSubclassNames |
	reparentedSubclassNames := OrderedCollection new.
	removedClasses do: [ :each |
		each reparentedSubclassNames do: [ :subclassName |
			(reparentedSubclassNames includes: subclassName) ifFalse: [
				reparentedSubclassNames add: subclassName ] ] ].
	^ String streamContents: [ :stream |
		  classNames size = 1
			  ifTrue: [
				  wasForced
					  ifTrue: [
						  stream
							  nextPutAll: 'Force-removed class ';
							  nextPutAll: classNames first;
							  nextPut: $. ]
					  ifFalse: [
						  stream
							  nextPutAll: 'Removed class ';
							  nextPutAll: classNames first;
							  nextPut: $. ] ]
			  ifFalse: [
				  wasForced
					  ifTrue: [
						  stream
							  nextPutAll: 'Force-removed ';
							  nextPutAll: classNames size asString;
							  nextPutAll: ' classes: ';
							  nextPutAll: (', ' join: classNames);
							  nextPut: $. ]
					  ifFalse: [
						  stream
							  nextPutAll: 'Removed ';
							  nextPutAll: classNames size asString;
							  nextPutAll: ' classes: ';
							  nextPutAll: (', ' join: classNames);
							  nextPut: $. ] ].
		  reparentedSubclassNames ifNotEmpty: [
			  stream
				  space;
				  nextPutAll: 'Reparented subclasses: ';
				  nextPutAll: (', ' join: reparentedSubclassNames);
				  nextPut: $. ].
		  removedPackageNames ifNotEmpty: [
			  stream
				  space;
				  nextPutAll: 'Removed packages: ';
				  nextPutAll: (', ' join: removedPackageNames);
				  nextPut: $. ] ]
]
