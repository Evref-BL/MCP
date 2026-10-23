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

	| classSideProperty includeVariableDetailsProperty selectorProperty |
	classSideProperty := MCPStructureProperties new
		                     name: 'side';
		                     type: 'string';
		                     enum: #( 'instance' 'class' );
		                     description: 'Which side a bare selector is on. A method written as Class class>>selector says so itself.';
		                     default: 'instance';
		                     yourself.
	includeVariableDetailsProperty := MCPStructureProperties new
		                                  name: 'includeVariableDetails';
		                                  type: 'boolean';
		                                  description: 'Whether to include variable reference summaries and counts.';
		                                  default: false;
		                                  yourself.
	selectorProperty := MCPStructureProperties new
		                    name: 'selector';
		                    type: #( 'string' 'array' );
		                    description:
		                    'A method as Class>>selector or Class class>>selector, or a bare selector when className is given. One of them, or several.';
		                    items: (MCPStructureProperties new
			                     type: 'string';
			                     description: 'One method.';
			                     yourself);
		                    yourself.
	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  (MCPStructureProperties new
					   name: 'class';
					   type: 'string';
					   description: 'The class defining the methods, for selectors that do not name their own.';
					   yourself).
				  selectorProperty.
				  classSideProperty.
				  includeVariableDetailsProperty };
		  required: #( 'selector' );
		  yourself
]

{ #category : 'private - errors' }
MCPToolGetMethod >> classNameForErrorFromParsedRequest: getRequest rawRequest: rawRequest [

	getRequest ifNotNil: [ ^ getRequest className ].
	^ (rawRequest stringArgumentNamed: 'class') ifNil: [ '' ]
]

{ #category : 'private - errors' }
MCPToolGetMethod >> classSideForErrorFromParsedRequest: getRequest rawRequest: rawRequest [

	getRequest ifNotNil: [ ^ getRequest classSide ].
	^ (rawRequest stringArgumentNamed: 'side' default: 'instance') = 'class'
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

	^ 'Get known methods and return their source plus structured variable-reference context. Takes methods as Class>>selector, as a search prints them, or bare selectors with className. Use method_search or reference lookup tools to discover methods first.'
]

{ #category : 'private' }
MCPToolGetMethod >> errorResultForError: anError className: className selector: selectorString classSide: classSide [

	^ anError
		  mcpCommandErrorDo: [ :commandError |
				  | details |
				  details := commandError structuredDetails copy.
				  details at: #class ifAbsentPut: [ className ].
				  details at: #selector ifAbsentPut: [ selectorString ].
				  classSide ifTrue: [ details at: #side put: 'class' ].
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
							  (#side -> (classSide ifTrue: [ 'class' ] ifFalse: [ 'instance' ])) } asDictionary ]
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
						  successResultText: (self
								   successSummaryForClassName: getRequest className
								   selector: getRequest selectorString
								   classSide: getRequest classSide
								   externalVariableCount: commandResult externalVariableCount)
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

	| binding definingClassName |
	(#( 'argument' 'temporary' ) includes: aKind) ifTrue: [ ^ 'method' ].
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
			  nextPutAll: (self methodReferenceTextForClassName: className selector: selector classSide: classSide).
		  externalVariableCount ifNotNil: [
				  stream
					  nextPutAll: ' with ';
					  nextPutAll: (self textForCount: externalVariableCount noun: 'external variable reference') ].
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
