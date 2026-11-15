"
Removes methods from one class in one batch. It is intentionally direct and does not perform sender safety checks.
"
Class {
	#name : 'MCPToolRemoveMethods',
	#superclass : 'MCPTool',
	#traits : 'TMCPMethodTool',
	#classTraits : 'TMCPMethodTool classTrait',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolRemoveMethods class >> groupName [

	^ self methodsGroupName
]

{ #category : 'metadata' }
MCPToolRemoveMethods class >> toolName [

	^ 'method_remove'
]

{ #category : 'metadata' }
MCPToolRemoveMethods >> buildInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  (MCPStructureProperties new
					   name: 'class';
					   type: 'string';
					   description: 'The class to remove the methods from.';
					   yourself).
				  (self targetSideSchemaPropertyDescribedAs: 'Which side to remove from.').
				  ((MCPStructureProperties new
					    name: 'selector';
					    type: #( 'string' 'array' );
					    description: 'The selector to remove, or several removed together as one change.')
					   items: (MCPStructureProperties new
							    type: 'string';
							    yourself);
					   yourself) };
		  required: #( 'class' 'selector' );
		  yourself
]

{ #category : 'private - errors' }
MCPToolRemoveMethods >> classNameForErrorFromParsedRequest: removeRequest rawRequest: rawRequest [
	"The request did not parse, so the class is read from the raw text, without the side it may name."

	removeRequest ifNotNil: [ ^ removeRequest className ].
	^ (rawRequest stringArgumentNamed: 'class') ifNil: [ '' ] ifNotNil: [ :className | MCPImageLookup baseNameOf: className ]
]

{ #category : 'private - errors' }
MCPToolRemoveMethods >> classSideForErrorFromParsedRequest: removeRequest rawRequest: rawRequest [
	"The request did not parse: the class side is meant when the call said so, by side or by a class written as Foo class."

	removeRequest ifNotNil: [ ^ removeRequest classSide ].
	^ (rawRequest stringArgumentNamed: 'side') = 'class' or: [
		  (rawRequest stringArgumentNamed: 'class') ifNil: [ false ] ifNotNil: [ :className | MCPImageLookup namesClassSide: className ] ]
]

{ #category : 'private - execution' }
MCPToolRemoveMethods >> commandForRequest: removeRequest [

	^ MCPRemoveMethodsCommand tool: self request: removeRequest
]

{ #category : 'metadata' }
MCPToolRemoveMethods >> defaultExposure [

	^ 'static'
]

{ #category : 'metadata' }
MCPToolRemoveMethods >> description [

	^ 'Remove methods from one class. Senders are not checked.'
]

{ #category : 'private' }
MCPToolRemoveMethods >> errorResultForError: anError className: className classSide: classSide selectors: selectors [

	^ anError
		  mcpCommandErrorDo: [ :commandError | self errorResultText: commandError messageText details: commandError structuredDetails ]
		  otherwise: [ :toolError |
				  self
					  errorResultText: (self
							   failureMessageForClassNamed: className
							   classSide: classSide
							   selectors: selectors
							   error: toolError)
					  details: {
							  (#errorClass -> toolError class name).
							  (#message -> toolError messageText).
							  (#class -> className).
							  (#side -> (classSide ifTrue: [ 'class' ] ifFalse: [ 'instance' ])).
							  (#selectors -> selectors asArray) } asDictionary ]
]

{ #category : 'executing' }
MCPToolRemoveMethods >> executeWithRequest: request [

	^ self
		  executeParsedRequestFrom: request
		  do: [ :removeRequest |
				  | result |
				  result := (self commandForRequest: removeRequest) execute.
				  self
					  successResultText:
					  (self successSummaryForClassName: result className classSide: result classSide selectors: result selectors)
					  data: result asDictionary
					  warnings: result warningMessages ]
		  onError: [ :error :removeRequest |
				  self
					  errorResultForError: error
					  className: (self classNameForErrorFromParsedRequest: removeRequest rawRequest: request)
					  classSide: (self classSideForErrorFromParsedRequest: removeRequest rawRequest: request)
					  selectors: (self selectorsForErrorFromParsedRequest: removeRequest rawRequest: request) ]
]

{ #category : 'private' }
MCPToolRemoveMethods >> failureMessageForClassNamed: className classSide: classSide selectors: selectors error: anError [

	| targetName |
	targetName := classSide
		              ifTrue: [ className , ' class' ]
		              ifFalse: [ className ].
	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Unable to remove methods from ';
				  nextPutAll: targetName;
				  nextPutAll: ': ';
				  nextPutAll: (', ' join: selectors);
				  nextPutAll: ' (';
				  nextPutAll: anError class name;
				  nextPutAll: '): ';
				  nextPutAll: anError messageText ]
]

{ #category : 'private - request' }
MCPToolRemoveMethods >> parsedRequestFromToolRequest: request [

	^ MCPRemoveMethodsRequest fromRequest: request tool: self
]

{ #category : 'private - errors' }
MCPToolRemoveMethods >> selectorsForErrorFromParsedRequest: removeRequest rawRequest: rawRequest [

	removeRequest ifNotNil: [ ^ removeRequest selectors ].
	^ rawRequest stringCollectionArgumentNamed: 'selector'
]

{ #category : 'private' }
MCPToolRemoveMethods >> selectorsFromRequest: request [

	| selectors |
	selectors := request uniqueStringCollectionArgumentNamed: 'selector'.
	selectors ifEmpty: [ Error signal: 'selector must hold at least one selector.' ].
	^ selectors
]

{ #category : 'private' }
MCPToolRemoveMethods >> successSummaryForClassName: className classSide: classSide selectors: selectors [

	| targetName |
	targetName := classSide
		              ifTrue: [ className , ' class' ]
		              ifFalse: [ className ].
	^ String streamContents: [ :stream |
		  stream << 'Force-removed ' << selectors size asString << ' methods from ' << targetName << ': ' << (', ' join: selectors)
		  << '.' ]
]

{ #category : 'metadata' }
MCPToolRemoveMethods >> title [

	^ 'Remove Methods'
]
