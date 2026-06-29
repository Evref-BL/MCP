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

{ #category : 'metadata' }
MCPToolRemoveClasses class >> toolName [

	^ 'class_remove'
]

{ #category : 'metadata' }
MCPToolRemoveClasses >> buildInputSchema [

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

{ #category : 'metadata' }
MCPToolRemoveClasses >> buildOutputSchema [

	^ self
		  standardOutputSchemaForDataProperties: {
				  (self
					   stringArraySchemaNamed: 'removedPackageNames'
					   description: 'Packages removed during cleanup.'
					   itemDescription: nil).
				  (self
					   stringArraySchemaNamed: 'reparentedSubclassNames'
					   description: 'Subclasses reparented during removal.'
					   itemDescription: nil) }
		  required: #(  )
]

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

{ #category : 'metadata' }
MCPToolRemoveClasses >> description [

	^ 'Remove classes as one batch. Safe-removal warnings stop the removal unless force is true. With force=true, the tool still returns those warnings.'
]

{ #category : 'private' }
MCPToolRemoveClasses >> errorResultForError: anError classNames: classNames [

	^ anError
		  mcpCommandErrorDo: [ :commandError |
				  self
					  errorResultText: commandError messageText
					  details: commandError structuredDetails ]
		  otherwise: [ :toolError |
				  self
					  errorResultText:
					  (self failureMessageForClassNames: classNames error: toolError)
					  details: {
							  (#errorClass -> toolError class name).
							  (#message -> toolError messageText).
							  (#classNames -> classNames asArray) } asDictionary ]
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

{ #category : 'metadata' }
MCPToolRemoveClasses >> title [

	^ 'Remove Classes'
]
