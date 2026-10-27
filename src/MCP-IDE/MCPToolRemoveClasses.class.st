"
Removes classes from the image in one batch. It surfaces safe-removal warnings before destructive changes unless forced.
"
Class {
	#name : 'MCPToolRemoveClasses',
	#superclass : 'MCPTool',
	#traits : 'TMCPClassTool',
	#classTraits : 'TMCPClassTool classTrait',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolRemoveClasses class >> groupName [

	^ self classesGroupName
]

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
					    name: 'name';
					    type: #( 'string' 'array' );
					    description:
						    'Name of the class to remove, or several names removed together as one change, so references between them do not block the removal.')
					   items: (MCPStructureProperties new
							    type: 'string';
							    description: 'A class name to remove.';
							    yourself);
					   yourself).
				  (MCPStructureProperties new
					   name: 'force';
					   type: 'boolean';
					   description: 'Remove even when safe-removal warnings are raised. The warnings are reported either way.';
					   default: false;
					   yourself) };
		  required: #( 'name' );
		  yourself
]

{ #category : 'private - errors' }
MCPToolRemoveClasses >> classNamesForErrorFromParsedRequest: removeRequest rawRequest: rawRequest [

	removeRequest ifNotNil: [ ^ removeRequest classNames ].
	^ rawRequest stringCollectionArgumentNamed: 'name'
]

{ #category : 'private' }
MCPToolRemoveClasses >> classNamesFromRequest: request [

	| classNames |
	classNames := request uniqueStringCollectionArgumentNamed: 'name'.
	classNames ifEmpty: [ Error signal: 'name must hold at least one class name.' ].
	^ classNames
]

{ #category : 'private - execution' }
MCPToolRemoveClasses >> commandForRequest: removeRequest [

	^ MCPRemoveClassesCommand classNames: removeRequest classNames force: removeRequest force
]

{ #category : 'metadata' }
MCPToolRemoveClasses >> defaultExposure [

	^ 'static'
]

{ #category : 'metadata' }
MCPToolRemoveClasses >> description [

	^ 'Remove classes as one batch. Safe-removal warnings stop the removal unless force is true. With force=true, the tool still returns those warnings. history_entry_revert undoes a removal in the running image.'
]

{ #category : 'private' }
MCPToolRemoveClasses >> errorResultForError: anError classNames: classNames [

	^ anError
		  mcpCommandErrorDo: [ :commandError | self errorResultText: commandError messageText details: commandError structuredDetails ]
		  otherwise: [ :toolError |
				  self errorResultText: (self failureMessageForClassNames: classNames error: toolError) details: {
						  (#errorClass -> toolError class name).
						  (#message -> toolError messageText).
						  (#classes -> classNames asArray) } asDictionary ]
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
			  self errorResultForError: error classNames: (self classNamesForErrorFromParsedRequest: removeRequest rawRequest: request) ]
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

{ #category : 'private - results' }
MCPToolRemoveClasses >> keysStatedInSummary [
	"The summary already reads 'Removed class Foo. Removed packages: Bar.'"

	^ #( removedClasses removedPackageNames )
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
				(reparentedSubclassNames includes: subclassName) ifFalse: [ reparentedSubclassNames add: subclassName ] ] ].
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
