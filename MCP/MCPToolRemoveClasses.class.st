Class {
	#name : 'MCPToolRemoveClasses',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'private' }
MCPToolRemoveClasses >> classNamesFromArguments: arguments [

	| classNames normalized |
	classNames := arguments at: #classNames ifAbsent: [ #(  ) ].
	classNames ifNil: [ classNames := #(  ) ].
	normalized := OrderedCollection new.
	classNames do: [ :each |
		| className |
		className := each asString trimBoth.
		className isEmpty ifTrue: [
			Error signal:
				'classNames must contain only non-empty class name strings.' ].
		(normalized includes: className) ifFalse: [
			normalized add: className ] ].
	normalized ifEmpty: [
		Error signal: 'classNames must contain at least one class name.' ].
	^ normalized asArray
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
MCPToolRemoveClasses >> executeWithArguments: arguments [

	| classNames result |
	classNames := self classNamesFromArguments: arguments.
	^ [
	  result := (MCPRemoveClassesCommand classNames: classNames) execute.
	  self
		  successResultText: (self
				   successSummaryForClassNames: classNames
				   removedClasses: result removedClasses
				   removedPackageNames: result removedPackageNames)
		  data: result asDictionary ]
		  on: Exception
		  do: [ :error |
		  self errorResultForError: error classNames: classNames ]
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

{ #category : 'initialization' }
MCPToolRemoveClasses >> initialize [

	super initialize.
	name := 'remove-classes'.
	title := 'Remove Pharo Classes'.
	description := 'Remove multiple classes from the running Pharo image as one batch using ReRemoveClassRefactoring safety checks. Empty classes may be removed with subclasses by reparenting those subclasses to the removed class superclass. If a removed class was the last defined class in its package, that package is removed too.'.
	inputSchema := MCPStructureInputSchema new
		               type: 'object';
		               properties: { ((MCPStructureProperties new
				                 name: 'classNames';
				                 type: 'array';
				                 description:
					                 'The class names to remove as a single safe-removal batch.')
				                items: (MCPStructureProperties new
						                 type: 'string';
						                 description: 'A class name to remove.';
						                 yourself);
				                yourself) };
		               required: #( 'classNames' );
		               yourself.
	outputSchema := self
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
										                   description:
											                   'The class that was removed.').
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
										                   schemaPropertyNamed:
											                   'reparentedToSuperclassName'
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
												                    description:
													                    'An instance-side slot name.';
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
										                    schemaPropertyNamed:
											                    'reparentedSubclassNames'
										                    type: 'array'
										                    description:
											                    'The direct subclasses that were reparented as part of the removal.')
										                   items: (MCPStructureProperties new
												                    type: 'string';
												                    description:
													                    'A reparented direct subclass name.';
												                    yourself);
										                   yourself) };
							                  required:
								                  #( 'className' 'superclassName'
								                     'packageName' 'tag' 'wasEmpty' 'reparentedToSuperclassName'
								                     'instanceSlotNames' 'classSlotNames'
								                     'subclassNames' 'reparentedSubclassNames' );
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
		                required:
		                #( 'classNames' 'removedClasses' 'removedPackageNames' ).
	icons := { self pngCompositeBaseIconNamed: #class badgeIconNamed: #delete }
]

{ #category : 'private' }
MCPToolRemoveClasses >> successSummaryForClassNames: classNames removedClasses: removedClasses removedPackageNames: removedPackageNames [

	| reparentedSubclassNames |
	reparentedSubclassNames := OrderedCollection new.
	removedClasses do: [ :each |
		each reparentedSubclassNames do: [ :subclassName |
			(reparentedSubclassNames includes: subclassName) ifFalse: [
				reparentedSubclassNames add: subclassName ] ] ].
	^ String streamContents: [ :stream |
		  classNames size = 1
			  ifTrue: [
				  stream
					  nextPutAll: 'Removed class ';
					  nextPutAll: classNames first;
					  nextPut: $. ]
			  ifFalse: [
				  stream
					  nextPutAll: 'Removed ';
					  nextPutAll: classNames size asString;
					  nextPutAll: ' classes: ';
					  nextPutAll: (', ' join: classNames);
					  nextPut: $. ].
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
