"
Returns structured information for one method, including source and optional variable reference details. It is meant for focused method inspection.
"
Class {
	#name : 'MCPToolInspectMethod',
	#superclass : 'MCPTool',
	#traits : '{} + TMCPMethodTool',
	#classTraits : '{} + TMCPMethodTool classTrait',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'private - analysis' }
MCPToolInspectMethod >> bindingClassNameFor: aBinding [

	^ aBinding
		  ifNil: [ 'UnknownBinding' ]
		  ifNotNil: [ :binding | binding class name asString ]
]

{ #category : 'private - execution' }
MCPToolInspectMethod >> commandForRequest: inspectRequest [

	^ MCPInspectMethodCommand tool: self request: inspectRequest
]

{ #category : 'defaults' }
MCPToolInspectMethod >> defaultDescription [

	^ 'Inspect one known method and return its source plus structured variable-reference context. Use find-methods or references to discover methods first.'
]

{ #category : 'defaults' }
MCPToolInspectMethod >> defaultIcons [

	^ { (self pngCompositeBaseIconNamed: #page badgeIconNamed: #inspect) }
]

{ #category : 'defaults' }
MCPToolInspectMethod >> defaultInputSchema [

	| includeVariableDetailsProperty sideProperty |
	sideProperty := MCPStructureProperties new
		                name: 'side';
		                type: 'string';
		                description:
			                'Which side of the class defines the method.';
		                enum: #( 'instance' 'class' );
		                default: 'instance';
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
					   description: 'The selector of the method to inspect.';
					   yourself).
				  sideProperty.
				  includeVariableDetailsProperty };
		  required: #( 'className' 'selector' );
		  yourself
]

{ #category : 'defaults' }
MCPToolInspectMethod >> defaultName [

	^ 'inspect-method'
]

{ #category : 'defaults' }
MCPToolInspectMethod >> defaultOutputSchema [

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

{ #category : 'defaults' }
MCPToolInspectMethod >> defaultTitle [

	^ 'Inspect Method'
]

{ #category : 'private' }
MCPToolInspectMethod >> errorResultForError: anError className: className selector: selectorString side: side [

	| details |
	(anError isKindOf: MCPCommandError) ifTrue: [
		details := anError structuredDetails copy.
		details at: #className ifAbsentPut: [ className ].
		details at: #selector ifAbsentPut: [ selectorString ].
		details at: #side put: side.
		^ self errorResultText: anError messageText details: details ].
	^ self
		  errorResultText: (self
				   failureMessageForClassNamed: className
				   selector: selectorString
				   side: side
				   error: anError)
		  details: {
				  (#errorClass -> anError class name).
				  (#message -> anError messageText).
				  (#className -> className).
				  (#selector -> selectorString).
				  (#side -> side) } asDictionary
]

{ #category : 'executing' }
MCPToolInspectMethod >> executeWithRequest: request [

	| commandResult inspectRequest |
	inspectRequest := self parsedRequestFromToolRequest: request.
	^ [
	  commandResult := (self commandForRequest: inspectRequest) execute.
	  self
		  successResultText: (self
				   successSummaryForClassName: inspectRequest className
				   selector: inspectRequest selectorString
				   side: inspectRequest side
				   externalVariableCount: commandResult externalVariableCount)
		  data: commandResult data ]
		  on: Error
		  do: [ :error |
			  self
				  errorResultForError: error
				  className: inspectRequest className
				  selector: inspectRequest selectorString
				  side: inspectRequest side ]
]

{ #category : 'private - results' }
MCPToolInspectMethod >> failureMessageForClassNamed: className selector: selectorString side: side error: anError [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Unable to inspect method ';
			  nextPutAll: className;
			  nextPutAll: '>>';
			  nextPutAll: selectorString;
			  nextPutAll: ' [side=';
			  nextPutAll: side;
			  nextPutAll: '] (';
			  nextPutAll: anError class name;
			  nextPutAll: '): ';
			  nextPutAll: anError messageText ]
]

{ #category : 'private - analysis' }
MCPToolInspectMethod >> incrementReferenceCountInSummary: aSummary [

	aSummary at: #referenceCount put: (aSummary at: #referenceCount) + 1
]

{ #category : 'private - analysis' }
MCPToolInspectMethod >> matchingSummaryForNodeName: aName kind: aKind ownerName: anOwnerName in: summaries [

	^ summaries
		  detect: [ :each |
			  (each at: #name) = aName and: [
				  (each at: #kind) = aKind and: [
					  (each at: #ownerName ifAbsent: [ nil ]) = anOwnerName ] ] ]
		  ifNone: [ nil ]
]

{ #category : 'private - analysis' }
MCPToolInspectMethod >> newVariableSummaryForNode: aVariableNode kind: aKind methodBehavior: aBehavior [

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
MCPToolInspectMethod >> ownerNameForNode: aVariableNode kind: aKind methodBehavior: aBehavior [

	| binding owner |
	binding := aVariableNode binding.
	owner := (#( 'argument' 'temporary' ) includes: aKind)
		         ifTrue: [ 'method' ]
		         ifFalse: [
			         (#( 'self' 'super' ) includes: aKind)
				         ifTrue: [ aBehavior name ]
				         ifFalse: [
					         aKind = 'thisContext'
						         ifTrue: [ 'execution context' ]
						         ifFalse: [
							         (#( 'instanceVariable' 'classInstanceVariable'
							             'classVariable' ) includes: aKind)
								         ifTrue: [
									         ((binding respondsTo: #definingClass) and: [
										          binding definingClass notNil ])
										         ifTrue: [ binding definingClass name ]
										         ifFalse: [ aBehavior name ] ]
								         ifFalse: [
									         aKind = 'poolVariable'
										         ifTrue: [
											         ((binding respondsTo: #definingClass) and: [
												          binding definingClass notNil ])
												         ifTrue: [ binding definingClass name ]
												         ifFalse: [ 'shared pool' ] ]
										         ifFalse: [
											         (#( 'class' 'global' ) includes: aKind)
												         ifTrue: [ 'Smalltalk globals' ]
												         ifFalse: [
													         aKind = 'undeclared'
														         ifTrue: [ 'Undeclared' ]
														         ifFalse: [ nil ] ] ] ] ] ] ].
	^ owner ifNil: [ nil ] ifNotNil: [ owner asString ]
]

{ #category : 'private - request' }
MCPToolInspectMethod >> parsedRequestFromToolRequest: request [

	^ MCPInspectMethodRequest fromRequest: request tool: self
]

{ #category : 'private - request' }
MCPToolInspectMethod >> sideFromRequest: request [

	^ request stringArgumentNamed: 'side' default: 'instance'
]

{ #category : 'private - results' }
MCPToolInspectMethod >> successSummaryForClassName: className selector: selector side: side externalVariableCount: externalVariableCount [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Inspected method ';
			  nextPutAll: className;
			  nextPutAll: '>>';
			  nextPutAll: selector;
			  nextPutAll: ' [side=';
			  nextPutAll: side;
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

{ #category : 'private - analysis' }
MCPToolInspectMethod >> variableKindForNode: aVariableNode methodBehavior: aBehavior [

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
	aVariableNode isGlobalVariable ifTrue: [
		binding := aVariableNode binding.
		binding class name = 'UndeclaredVariable' ifTrue: [ ^ 'undeclared' ].
		((binding respondsTo: #isPoolVariable) and: [
			 binding isPoolVariable ]) ifTrue: [ ^ 'poolVariable' ].
		((binding respondsTo: #value) and: [ binding value isBehavior ])
			ifTrue: [ ^ 'class' ].
		^ 'global' ].
	^ 'unknown'
]

{ #category : 'private - schema' }
MCPToolInspectMethod >> variableReferenceSchema [

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
MCPToolInspectMethod >> variableSummariesForMethod: aCompiledMethod methodBehavior: aBehavior [

	| summaries |
	summaries := OrderedCollection new.
	aCompiledMethod ast allChildren do: [ :node |
		(node isKindOf: RBVariableNode) ifTrue: [
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
