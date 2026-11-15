"
Returns structured information for one method, including source and optional variable reference details. It is meant for single-method lookup.
"
Class {
	#name : 'MCPToolGetMethod',
	#superclass : 'MCPTool',
	#traits : 'TMCPMethodTool',
	#classTraits : 'TMCPMethodTool classTrait',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolGetMethod class >> groupName [

	^ self methodsGroupName
]

{ #category : 'metadata' }
MCPToolGetMethod class >> toolName [

	^ 'method_get'
]

{ #category : 'metadata' }
MCPToolGetMethod >> annotations [

	^ MCPStructureToolAnnotations readOnly
]

{ #category : 'metadata' }
MCPToolGetMethod >> batchArgumentName [

	^ 'selector'
]

{ #category : 'metadata' }
MCPToolGetMethod >> batchSummaryNoun [

	^ 'methods'
]

{ #category : 'metadata' }
MCPToolGetMethod >> batchSummaryVerb [

	^ 'Got'
]

{ #category : 'private - analysis' }
MCPToolGetMethod >> bindingClassNameFor: aBinding [

	^ aBinding ifNil: [ 'UnknownBinding' ] ifNotNil: [ :binding | binding class name asString ]
]

{ #category : 'metadata' }
MCPToolGetMethod >> buildInputSchema [

	| includeVariableDetailsProperty selectorProperty |
	includeVariableDetailsProperty := MCPStructureProperties new
		                                  name: 'includeVariableDetails';
		                                  type: 'boolean';
		                                  description:
			                                  'Also report, for every variable the method reads or writes, where it is defined and how often it is used.';
		                                  default: false;
		                                  yourself.
	selectorProperty := MCPStructureProperties new
		                    name: 'selector';
		                    type: #( 'string' 'array' );
		                    description: 'Class>>selector, Class class>>selector, or a bare selector with class. One or several.';
		                    items: (MCPStructureProperties new
				                     type: 'string';
				                     yourself);
		                    yourself.
	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  (MCPStructureProperties new
					   name: 'class';
					   type: 'string';
					   description: 'Class for bare selectors.';
					   yourself).
				  selectorProperty.
				  (self targetSideSchemaPropertyDescribedAs: 'Which side a bare selector is on.').
				  includeVariableDetailsProperty };
		  required: #( 'selector' );
		  yourself
]

{ #category : 'private - errors' }
MCPToolGetMethod >> classNameForErrorFromParsedRequest: getRequest rawRequest: rawRequest [
	"The request did not parse, so the class is read from the raw text, without the side it may name."

	getRequest ifNotNil: [ ^ getRequest className ].
	^ (rawRequest stringArgumentNamed: 'class') ifNil: [ '' ] ifNotNil: [ :className | MCPImageLookup baseNameOf: className ]
]

{ #category : 'private - errors' }
MCPToolGetMethod >> classSideForErrorFromParsedRequest: getRequest rawRequest: rawRequest [
	"The request did not parse: the class side is meant when the call said so, by side or by a class written as Foo class."

	getRequest ifNotNil: [ ^ getRequest classSide ].
	^ (rawRequest stringArgumentNamed: 'side') = 'class' or: [
		  (rawRequest stringArgumentNamed: 'class') ifNil: [ false ] ifNotNil: [ :className | MCPImageLookup namesClassSide: className ] ]
]

{ #category : 'private - execution' }
MCPToolGetMethod >> commandForRequest: getRequest [

	^ MCPGetMethodCommand tool: self request: getRequest
]

{ #category : 'metadata' }
MCPToolGetMethod >> defaultExposure [

	^ 'static'
]

{ #category : 'private - analysis' }
MCPToolGetMethod >> definingClassNameFromBinding: aBinding [

	^ aBinding ifNotNil: [ :binding | binding definingClass ifNotNil: [ :definingClass | definingClass name ] ]
]

{ #category : 'metadata' }
MCPToolGetMethod >> description [

	^ 'Get the source of methods named Class>>selector or Class class>>selector, one or several.'
]

{ #category : 'private - results' }
MCPToolGetMethod >> entryNameKeys [
	"A variable record is the variable of its name."

	^ #( name )
]

{ #category : 'private' }
MCPToolGetMethod >> errorResultForError: anError className: className selector: selectorString classSide: classSide [

	^ anError
		  mcpCommandErrorDo: [ :commandError |
				  | details |
				  details := commandError structuredDetails copy.
				  details at: #class ifAbsentPut: [ className ].
				  details at: #selector ifAbsentPut: [ selectorString ].
				  "A side the error states, such as the one a ClassSideConflict was sent, is kept."
				  classSide ifTrue: [ details at: #side ifAbsentPut: [ 'class' ] ].
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
							  (#class -> className).
							  (#selector -> selectorString).
							  (#side -> (classSide
								    ifTrue: [ 'class' ]
								    ifFalse: [ 'instance' ])) } asDictionary ]
]

{ #category : 'executing' }
MCPToolGetMethod >> executeWithRequest: request [

	^ self executeBatchedRequest: request do: [ :targetRequest |
			  self
				  executeParsedRequestFrom: targetRequest
				  do: [ :getRequest |
						  | commandResult |
						  commandResult := (self commandForRequest: getRequest) execute.
						  self
							  successResultText:
							  (self
								   successSummaryForClassName: getRequest className
								   selector: getRequest selectorString
								   classSide: getRequest classSide)
							  data: commandResult data ]
				  onError: [ :error :getRequest |
						  self
							  errorResultForError: error
							  className: (self classNameForErrorFromParsedRequest: getRequest rawRequest: targetRequest)
							  selector: (self selectorForErrorFromParsedRequest: getRequest rawRequest: targetRequest)
							  classSide: (self classSideForErrorFromParsedRequest: getRequest rawRequest: targetRequest) ] ]
]

{ #category : 'private - results' }
MCPToolGetMethod >> failureMessageForClassNamed: className selector: selectorString classSide: classSide error: anError [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Unable to get method ';
			  nextPutAll: (self methodReferenceTextForClassName: className selector: selectorString classSide: classSide);
			  nextPutAll: ' (';
			  nextPutAll: anError class name;
			  nextPutAll: '): ';
			  nextPutAll: anError messageText ]
]

{ #category : 'private - analysis' }
MCPToolGetMethod >> incrementReferenceCountInSummary: aSummary [

	aSummary at: #referenceCount put: (aSummary at: #referenceCount) + 1
]

{ #category : 'private - results' }
MCPToolGetMethod >> keyOrder [
	"Where the method is defined comes before anything about it: a method a class got from a trait is read in the trait and changed there."

	^ #( trait protocol )
]

{ #category : 'private - analysis' }
MCPToolGetMethod >> matchingSummaryForNodeName: aName kind: aKind ownerName: anOwnerName in: summaries [

	^ summaries
		  detect: [ :each |
			  (each at: #name) = aName and: [ (each at: #kind) = aKind and: [ (each at: #ownerName ifAbsent: [ nil ]) = anOwnerName ] ] ]
		  ifNone: [ nil ]
]

{ #category : 'private - results' }
MCPToolGetMethod >> methodReferenceTextForClassName: className selector: selector classSide: classSide [

	^ className , (classSide
		   ifTrue: [ ' class>>' ]
		   ifFalse: [ '>>' ]) , selector
]

{ #category : 'private - analysis' }
MCPToolGetMethod >> newVariableSummaryForNode: aVariableNode kind: aKind methodBehavior: aBehavior [

	| binding ownerName summary |
	binding := aVariableNode binding.
	ownerName := self ownerNameForNode: aVariableNode kind: aKind methodBehavior: aBehavior.
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
	"Where the variable is defined, for a variable defined outside the method. An argument or a temporary is the method's own, which its kind already says, so it has none."

	| binding definingClassName |
	(#( 'argument' 'temporary' ) includes: aKind) ifTrue: [ ^ nil ].
	(#( 'self' 'super' ) includes: aKind) ifTrue: [ ^ aBehavior name asString ].
	aKind = 'thisContext' ifTrue: [ ^ 'execution context' ].
	binding := aVariableNode binding.
	(#( 'instanceVariable' 'classInstanceVariable' 'classVariable' ) includes: aKind) ifTrue: [
			definingClassName := self definingClassNameFromBinding: binding.
			^ definingClassName ifNil: [ aBehavior name asString ] ].
	aKind = 'poolVariable' ifTrue: [
			definingClassName := self definingClassNameFromBinding: binding.
			^ definingClassName ifNil: [ 'shared pool' ] ].
	(#( 'class' 'global' ) includes: aKind) ifTrue: [ ^ 'Smalltalk globals' ].
	aKind = 'undeclared' ifTrue: [ ^ 'Undeclared' ].
	^ nil
]

{ #category : 'private - request' }
MCPToolGetMethod >> parsedRequestFromToolRequest: request [

	^ MCPGetMethodRequest fromRequest: request tool: self
]

{ #category : 'private - results' }
MCPToolGetMethod >> redundantKeys [
	"A variable's binding class restates its kind in Pharo's terms."

	^ #( bindingClass )
]

{ #category : 'private - errors' }
MCPToolGetMethod >> selectorForErrorFromParsedRequest: getRequest rawRequest: rawRequest [

	getRequest ifNotNil: [ ^ getRequest selectorString ].
	^ (rawRequest stringArgumentNamed: 'selector') ifNil: [ '' ]
]

{ #category : 'private - results' }
MCPToolGetMethod >> successSummaryForClassName: className selector: selector classSide: classSide [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Got method ';
				  nextPutAll: (self methodReferenceTextForClassName: className selector: selector classSide: classSide);
				  nextPut: $. ]
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

{ #category : 'private - analysis' }
MCPToolGetMethod >> variableSummariesForMethod: aCompiledMethod methodBehavior: aBehavior [

	| summaries |
	summaries := OrderedCollection new.
	aCompiledMethod ast allChildren do: [ :node |
			node isVariable ifTrue: [
					| kind ownerName summary |
					kind := self variableKindForNode: node methodBehavior: aBehavior.
					ownerName := self ownerNameForNode: node kind: kind methodBehavior: aBehavior.
					summary := self
						           matchingSummaryForNodeName: node name asString
						           kind: kind
						           ownerName: ownerName
						           in: summaries.
					summary ifNil: [
							summary := self newVariableSummaryForNode: node kind: kind methodBehavior: aBehavior.
							summaries add: summary ].
					self incrementReferenceCountInSummary: summary ] ].
	^ summaries asArray
]
