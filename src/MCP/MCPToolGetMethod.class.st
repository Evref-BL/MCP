"
Returns structured information for one method, including source and optional variable reference details. It is meant for single-method lookup.
"
Class {
	#name : 'MCPToolGetMethod',
	#superclass : 'MCPTool',
	#traits : 'TMCPMethodTool',
	#classTraits : 'TMCPMethodTool classTrait',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolGetMethod class >> toolName [

	^ 'method_get'
]

{ #category : 'private - analysis' }
MCPToolGetMethod >> bindingClassNameFor: aBinding [

	^ aBinding
		  ifNil: [ 'UnknownBinding' ]
		  ifNotNil: [ :binding | binding class name asString ]
]

{ #category : 'metadata' }
MCPToolGetMethod >> buildInputSchema [

	| classSideProperty includeVariableDetailsProperty |
	classSideProperty := MCPStructureProperties new
		                     name: 'classSide';
		                     type: 'boolean';
		                     description:
			                     'Whether the target method is on the class side.';
		                     default: false;
		                     yourself.
	includeVariableDetailsProperty := MCPStructureProperties new
		                                  name: 'includeVariableDetails';
		                                  type: 'boolean';
		                                  description:
			                                  'Whether to include variable reference summaries and counts.';
		                                  default: false;
		                                  yourself.
	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  (MCPStructureProperties new
					   name: 'className';
					   type: 'string';
					   description: 'The class that defines the method.';
					   yourself).
				  (MCPStructureProperties new
					   name: 'selector';
					   type: 'string';
					   description: 'The selector of the method to return.';
					   yourself).
				  classSideProperty.
				  includeVariableDetailsProperty };
		  required: #( 'className' 'selector' );
		  yourself
]

{ #category : 'metadata' }
MCPToolGetMethod >> buildOutputSchema [

	^ self
		  standardOutputSchemaForDataProperties: {
				  (self
					   schemaPropertyNamed: 'protocol'
					   type: 'string'
					   description: 'The protocol/category containing the method.').
				  (self
					   schemaPropertyNamed: 'source'
					   type: 'string'
					   description: 'The formatted source code of the method.').
				  ((self
					    schemaPropertyNamed: 'variableReferences'
					    type: 'array'
					    description:
						    'Structured summaries of referenced variables in first-use order when variable details are included.')
					   items: self variableReferenceSchema;
					   yourself) }
		  required: #( 'protocol' 'source' )
]

{ #category : 'private - errors' }
MCPToolGetMethod >> classNameForErrorFromParsedRequest: getRequest rawRequest: rawRequest [

	getRequest ifNotNil: [ ^ getRequest className ].
	^ (rawRequest stringArgumentNamed: 'className') ifNil: [ '' ]
]

{ #category : 'private - errors' }
MCPToolGetMethod >> classSideForErrorFromParsedRequest: getRequest rawRequest: rawRequest [

	getRequest ifNotNil: [ ^ getRequest classSide ].
	^ rawRequest booleanArgumentNamed: 'classSide' default: false
]

{ #category : 'private - execution' }
MCPToolGetMethod >> commandForRequest: getRequest [

	^ MCPGetMethodCommand tool: self request: getRequest
]

{ #category : 'private - analysis' }
MCPToolGetMethod >> definingClassNameFromBinding: aBinding [

	^ aBinding ifNotNil: [ :binding |
		  binding definingClass ifNotNil: [ :definingClass |
			  definingClass name ] ]
]

{ #category : 'metadata' }
MCPToolGetMethod >> description [

	^ 'Get one known method and return its source plus structured variable-reference context. Use method_metadata_search or reference lookup tools to discover methods first.'
]

{ #category : 'private' }
MCPToolGetMethod >> errorResultForError: anError className: className selector: selectorString classSide: classSide [

	^ anError
		  mcpCommandErrorDo: [ :commandError |
				  | details |
				  details := commandError structuredDetails copy.
				  details at: #className ifAbsentPut: [ className ].
				  details at: #selector ifAbsentPut: [ selectorString ].
				  details at: #classSide put: classSide.
				  self errorResultText: commandError messageText details: details ]
		  otherwise: [ :toolError |
				  self
					  errorResultText: (self
							   failureMessageForClassNamed: className
							   selector: selectorString
							   classSide: classSide
							   error: toolError)
					  details: {
							  (#errorClass -> toolError class name).
							  (#message -> toolError messageText).
							  (#className -> className).
							  (#selector -> selectorString).
							  (#classSide -> classSide) } asDictionary ]
]

{ #category : 'executing' }
MCPToolGetMethod >> executeWithRequest: request [

	^ self
		  executeParsedRequestFrom: request
		  do: [ :getRequest |
				  | commandResult |
				  commandResult := (self commandForRequest: getRequest) execute.
				  self
					  successResultText: (self
							   successSummaryForClassName: getRequest className
							   selector: getRequest selectorString
							   classSide: getRequest classSide
							   externalVariableCount: commandResult externalVariableCount)
					  data: commandResult data ]
		  onError: [ :error :getRequest |
				  self
					  errorResultForError: error
					  className: (self
							   classNameForErrorFromParsedRequest: getRequest
							   rawRequest: request)
					  selector: (self
							   selectorForErrorFromParsedRequest: getRequest
							   rawRequest: request)
					  classSide: (self
							   classSideForErrorFromParsedRequest: getRequest
							   rawRequest: request) ]
]

{ #category : 'private - results' }
MCPToolGetMethod >> failureMessageForClassNamed: className selector: selectorString classSide: classSide error: anError [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Unable to get method ';
				  nextPutAll: className;
				  nextPutAll: '>>';
				  nextPutAll: selectorString;
				  nextPutAll: ' [classSide=';
				  print: classSide;
				  nextPutAll: '] (';
				  nextPutAll: anError class name;
				  nextPutAll: '): ';
				  nextPutAll: anError messageText ]
]

{ #category : 'private - analysis' }
MCPToolGetMethod >> incrementReferenceCountInSummary: aSummary [

	aSummary at: #referenceCount put: (aSummary at: #referenceCount) + 1
]

{ #category : 'private - analysis' }
MCPToolGetMethod >> matchingSummaryForNodeName: aName kind: aKind ownerName: anOwnerName in: summaries [

	^ summaries
		  detect: [ :each |
			  (each at: #name) = aName and: [
				  (each at: #kind) = aKind and: [
					  (each at: #ownerName ifAbsent: [ nil ]) = anOwnerName ] ] ]
		  ifNone: [ nil ]
]

{ #category : 'private - analysis' }
MCPToolGetMethod >> newVariableSummaryForNode: aVariableNode kind: aKind methodBehavior: aBehavior [

	| binding ownerName summary |
	binding := aVariableNode binding.
	ownerName := self
		             ownerNameForNode: aVariableNode
		             kind: aKind
		             methodBehavior: aBehavior.
	summary := Dictionary new.
	summary at: #name put: aVariableNode name asString.
	summary at: #kind put: aKind.
	summary at: #bindingClass put: (self bindingClassNameFor: binding).
	summary at: #referenceCount put: 0.
	ownerName ifNotNil: [ summary at: #ownerName put: ownerName ].
	^ summary
]

{ #category : 'private - analysis' }
MCPToolGetMethod >> ownerNameForNode: aVariableNode kind: aKind methodBehavior: aBehavior [

	| binding definingClassName |
	(#( 'argument' 'temporary' ) includes: aKind) ifTrue: [ ^ 'method' ].
	(#( 'self' 'super' ) includes: aKind) ifTrue: [
		^ aBehavior name asString ].
	aKind = 'thisContext' ifTrue: [ ^ 'execution context' ].
	binding := aVariableNode binding.
	(#( 'instanceVariable' 'classInstanceVariable'
	    'classVariable' ) includes: aKind) ifTrue: [
			definingClassName := self definingClassNameFromBinding: binding.
			^ definingClassName ifNil: [ aBehavior name asString ] ].
	aKind = 'poolVariable' ifTrue: [
			definingClassName := self definingClassNameFromBinding: binding.
			^ definingClassName ifNil: [ 'shared pool' ] ].
	(#( 'class' 'global' ) includes: aKind) ifTrue: [
		^ 'Smalltalk globals' ].
	aKind = 'undeclared' ifTrue: [ ^ 'Undeclared' ].
	^ nil
]

{ #category : 'private - request' }
MCPToolGetMethod >> parsedRequestFromToolRequest: request [

	^ MCPGetMethodRequest fromRequest: request tool: self
]

{ #category : 'private - errors' }
MCPToolGetMethod >> selectorForErrorFromParsedRequest: getRequest rawRequest: rawRequest [

	getRequest ifNotNil: [ ^ getRequest selectorString ].
	^ (rawRequest stringArgumentNamed: 'selector') ifNil: [ '' ]
]

{ #category : 'private - results' }
MCPToolGetMethod >> successSummaryForClassName: className selector: selector classSide: classSide externalVariableCount: externalVariableCount [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Got method ';
				  nextPutAll: className;
				  nextPutAll: '>>';
				  nextPutAll: selector;
				  nextPutAll: ' [classSide=';
				  print: classSide;
				  nextPutAll: ']'.
			  externalVariableCount ifNotNil: [
					  stream
						  nextPutAll: ' with ';
						  print: externalVariableCount;
						  nextPutAll: ' external variable reference';
						  nextPutAll: (externalVariableCount = 1
								   ifTrue: [ '' ]
								   ifFalse: [ 's' ]) ].
			  stream nextPutAll: '.' ]
]

{ #category : 'metadata' }
MCPToolGetMethod >> title [

	^ 'Get Method'
]

{ #category : 'private - analysis' }
MCPToolGetMethod >> variableKindForNode: aVariableNode methodBehavior: aBehavior [

	| binding |
	aVariableNode isSelfVariable ifTrue: [ ^ 'self' ].
	aVariableNode isSuperVariable ifTrue: [ ^ 'super' ].
	aVariableNode isThisContextVariable ifTrue: [ ^ 'thisContext' ].
	aVariableNode isArgumentVariable ifTrue: [ ^ 'argument' ].
	aVariableNode isTempVariable ifTrue: [ ^ 'temporary' ].
	aVariableNode isInstanceVariable ifTrue: [
			^ aBehavior isMeta
				  ifTrue: [ 'classInstanceVariable' ]
				  ifFalse: [ 'instanceVariable' ] ].
	aVariableNode isClassVariable ifTrue: [ ^ 'classVariable' ].
	aVariableNode isGlobalVariable ifFalse: [ ^ 'unknown' ].
	binding := aVariableNode binding.
	binding isUndeclaredVariable ifTrue: [ ^ 'undeclared' ].
	binding isPoolVariable ifTrue: [ ^ 'poolVariable' ].
	binding value isBehavior ifTrue: [ ^ 'class' ].
	^ 'global'
]

{ #category : 'private - schema' }
MCPToolGetMethod >> variableReferenceSchema [

	| ownerNameProperty |
	ownerNameProperty := self
		                     schemaPropertyNamed: 'ownerName'
		                     type: 'string'
		                     description:
		                     'The class, global environment, or pseudo-scope that provides the variable when known.'.
	^ MCPStructureProperties new
		  name: 'variableReference';
		  type: 'object';
		  description: 'A summary of one referenced variable in the method.';
		  properties: {
				  (self
					   schemaPropertyNamed: 'name'
					   type: 'string'
					   description: 'The variable name as it appears in source.').
				  ((self
					    schemaPropertyNamed: 'kind'
					    type: 'string'
					    description: 'How the variable resolves in Pharo.')
					   enum:
						   #( 'argument' 'temporary' 'instanceVariable'
						      'classInstanceVariable' 'classVariable' 'poolVariable'
						      'class' 'global' 'self' 'super' 'thisContext'
						      'undeclared' 'unknown' );
					   yourself).
				  ownerNameProperty.
				  (self
					   schemaPropertyNamed: 'bindingClass'
					   type: 'string'
					   description:
					   'The compiler binding class used to resolve the variable.').
				  (self
					   integerSchemaPropertyNamed: 'referenceCount'
					   description:
					   'How many times the variable is referenced in the method.') };
		  required: #( 'name' 'kind' 'bindingClass' 'referenceCount' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - analysis' }
MCPToolGetMethod >> variableSummariesForMethod: aCompiledMethod methodBehavior: aBehavior [

	| summaries |
	summaries := OrderedCollection new.
	aCompiledMethod ast allChildren do: [ :node |
			node isVariable ifTrue: [
					| kind ownerName summary |
					kind := self variableKindForNode: node methodBehavior: aBehavior.
					ownerName := self
						             ownerNameForNode: node
						             kind: kind
						             methodBehavior: aBehavior.
					summary := self
						           matchingSummaryForNodeName: node name asString
						           kind: kind
						           ownerName: ownerName
						           in: summaries.
					summary ifNil: [
							summary := self
								           newVariableSummaryForNode: node
								           kind: kind
								           methodBehavior: aBehavior.
							summaries add: summary ].
					self incrementReferenceCountInSummary: summary ] ].
	^ summaries asArray
]
