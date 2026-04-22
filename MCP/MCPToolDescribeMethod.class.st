Class {
	#name : 'MCPToolDescribeMethod',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'private - analysis' }
MCPToolDescribeMethod >> bindingClassNameFor: aBinding [

	^ aBinding
		  ifNil: [ 'UnknownBinding' ]
		  ifNotNil: [ :binding | binding class name asString ]
]

{ #category : 'private - reading' }
MCPToolDescribeMethod >> compiledMethodForClassNamed: className selector: selectorString side: side [

	| behavior selectorSymbol |
	behavior := self methodBehaviorForClassNamed: className side: side.
	selectorSymbol := selectorString asSymbol.
	(behavior includesSelector: selectorSymbol) ifFalse: [
		MCPCommandError
			signalMissingMethodInClassName: className
			classSide: side = 'class'
			selector: selectorString ].
	^ behavior compiledMethodAt: selectorSymbol
]

{ #category : 'private' }
MCPToolDescribeMethod >> errorResultForError: anError className: className selector: selectorString side: side [

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
MCPToolDescribeMethod >> executeWithArguments: arguments [

	| argumentNames className compiledMethod data externalVariableReferences methodBehavior methodNode protocolName selectorString side temporaryNames variableReferences |
	className := self
		             argumentNamed: 'className'
		             in: arguments
		             ifAbsent: [ nil ].
	selectorString := self selectorStringFrom: arguments.
	side := self normalizedSideFrom: arguments.
	^ [
	  methodBehavior := self
		                    methodBehaviorForClassNamed: className
		                    side: side.
	  compiledMethod := self
		                    compiledMethodForClassNamed: className
		                    selector: selectorString
		                    side: side.
	  methodNode := compiledMethod ast.
	  protocolName := compiledMethod protocol
		                  ifNil: [ '' ]
		                  ifNotNil: [ :protocol | protocol name asString ].
	  argumentNames := (methodNode arguments collect: [ :each |
		                    each name asString ]) asArray.
	  temporaryNames := (methodNode temporaries collect: [ :each |
		                     each name asString ]) asArray.
	  variableReferences := self
		                        variableSummariesForMethod: compiledMethod
		                        methodBehavior: methodBehavior.
	  externalVariableReferences := (variableReferences select: [ :each |
		                                 self isExternalVariableKind:
			                                 (each at: #kind) ]) asArray.
	  data := {
		          (#className -> className).
		          (#selector -> selectorString).
		          (#side -> side).
		          (#protocol -> protocolName).
		          (#source
		           -> (self normalizedSourceText: compiledMethod sourceCode)).
		          (#argumentNames -> argumentNames).
		          (#temporaryNames -> temporaryNames).
		          (#variableReferenceCount -> variableReferences size).
		          (#externalVariableCount -> externalVariableReferences size).
		          (#variableReferences -> variableReferences).
		          (#externalVariableReferences -> externalVariableReferences) }
		          asDictionary.
	  self
		  successResultText: (self
				   successSummaryForClassName: className
				   selector: selectorString
				   side: side
				   externalVariableCount: externalVariableReferences size)
		  data: data ]
		  on: Error
		  do: [ :error |
			  self
				  errorResultForError: error
				  className: className
				  selector: selectorString
				  side: side ]
]

{ #category : 'private - results' }
MCPToolDescribeMethod >> failureMessageForClassNamed: className selector: selectorString side: side error: anError [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Unable to describe method ';
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
MCPToolDescribeMethod >> incrementReferenceCountInSummary: aSummary [

	aSummary at: #referenceCount put: (aSummary at: #referenceCount) + 1
]

{ #category : 'initialization' }
MCPToolDescribeMethod >> initialize [

	| sideProperty variableNameItemSchema |
	super initialize.
	name := 'describe-method'.
	title := 'Describe Pharo Method'.
	description := 'Describe a single method from the running Pharo image, including structured variable-resolution context.'.
	sideProperty := MCPStructureProperties new
		                name: 'side';
		                type: 'string';
		                description:
			                'Which side of the class defines the method. Defaults to instance.';
		                enum: #( 'instance' 'class' );
		                yourself.
	inputSchema := MCPStructureInputSchema new
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
					                description:
						                'The selector of the method to describe.';
					                yourself).
				               sideProperty };
		               required: #( 'className' 'selector' );
		               yourself.
	variableNameItemSchema := MCPStructureProperties new
		                          type: 'string';
		                          description: 'A variable name.';
		                          yourself.
	outputSchema := self
		                standardOutputSchemaForDataProperties: {
				                (self
					                 schemaPropertyNamed: 'className'
					                 type: 'string'
					                 description:
					                 'The class that defines the method.').
				                (self
					                 schemaPropertyNamed: 'selector'
					                 type: 'string'
					                 description: 'The selector that was described.').
				                ((self
					                  schemaPropertyNamed: 'side'
					                  type: 'string'
					                  description: 'The requested method side.')
					                 enum: #( 'instance' 'class' );
					                 yourself).
				                (self
					                 schemaPropertyNamed: 'protocol'
					                 type: 'string'
					                 description:
					                 'The protocol/category containing the method.').
				                (self
					                 schemaPropertyNamed: 'source'
					                 type: 'string'
					                 description:
					                 'The normalized source code of the method.').
				                ((self
					                  schemaPropertyNamed: 'argumentNames'
					                  type: 'array'
					                  description:
						                  'The top-level argument names declared by the method.')
					                 items: variableNameItemSchema;
					                 yourself).
				                ((self
					                  schemaPropertyNamed: 'temporaryNames'
					                  type: 'array'
					                  description:
						                  'The top-level temporary variable names declared by the method.')
					                 items: variableNameItemSchema;
					                 yourself).
				                (self
					                 integerSchemaPropertyNamed:
					                 'variableReferenceCount'
					                 description:
					                 'The number of unique referenced variables summarized in the result.').
				                (self
					                 integerSchemaPropertyNamed:
					                 'externalVariableCount'
					                 description:
					                 'The number of unique referenced variables that are external to the method, excluding self.').
				                ((self
					                  schemaPropertyNamed: 'variableReferences'
					                  type: 'array'
					                  description:
						                  'Structured summaries of all referenced variables in first-use order.')
					                 items: self variableReferenceSchema;
					                 yourself).
				                ((self
					                  schemaPropertyNamed:
						                  'externalVariableReferences'
					                  type: 'array'
					                  description:
						                  'Structured summaries of referenced variables that are external to the method, excluding self.')
					                 items: self variableReferenceSchema;
					                 yourself) }
		                required:
			                #( 'className' 'selector' 'side' 'protocol'
			                   'source' 'argumentNames' 'temporaryNames'
			                   'variableReferenceCount'
			                   'externalVariableCount' 'variableReferences'
			                   'externalVariableReferences' ).
	icons := { (self
		          pngCompositeBaseIconNamed: #page
		          badgeIconNamed: #inspect) }
]

{ #category : 'private - analysis' }
MCPToolDescribeMethod >> isExternalVariableKind: aKind [

	^ (#( 'argument' 'temporary' 'self' ) includes: aKind) not
]

{ #category : 'private - analysis' }
MCPToolDescribeMethod >> matchingSummaryForNodeName: aName kind: aKind ownerName: anOwnerName in: summaries [

	^ summaries
		  detect: [ :each |
			  (each at: #name) = aName and: [
				  (each at: #kind) = aKind and: [
					  (each at: #ownerName ifAbsent: [ nil ]) = anOwnerName ] ] ]
		  ifNone: [ nil ]
]

{ #category : 'private - reading' }
MCPToolDescribeMethod >> methodBehaviorForClassNamed: className side: side [

	| baseClass |
	baseClass := self class environment
		             at: className asSymbol
		             ifAbsent: [
		             MCPCommandError signalMissingClassNamed: className ].
	^ side = 'class'
		  ifTrue: [ baseClass classSide ]
		  ifFalse: [ baseClass ]
]

{ #category : 'private - analysis' }
MCPToolDescribeMethod >> newVariableSummaryForNode: aVariableNode kind: aKind methodBehavior: aBehavior [

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

{ #category : 'private - arguments' }
MCPToolDescribeMethod >> normalizedSideFrom: arguments [

	| side |
	side := (self stringArgumentNamed: 'side' in: arguments) ifNil: [
		        ^ 'instance' ].
	side := side asLowercase.
	(#( 'instance' 'class' ) includes: side) ifFalse: [
		Error signal: 'side must be either instance or class.' ].
	^ side
]

{ #category : 'private - analysis' }
MCPToolDescribeMethod >> ownerNameForNode: aVariableNode kind: aKind methodBehavior: aBehavior [

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

{ #category : 'private - results' }
MCPToolDescribeMethod >> successSummaryForClassName: className selector: selector side: side externalVariableCount: externalVariableCount [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Described method ';
			  nextPutAll: className;
			  nextPutAll: '>>';
			  nextPutAll: selector;
			  nextPutAll: ' [side=';
			  nextPutAll: side;
			  nextPutAll: '] with ';
			  print: externalVariableCount;
			  nextPutAll: ' external variable reference';
			  nextPutAll: (externalVariableCount = 1
					   ifTrue: [ '' ]
					   ifFalse: [ 's' ]);
			  nextPutAll: '.' ]
]

{ #category : 'private - analysis' }
MCPToolDescribeMethod >> variableKindForNode: aVariableNode methodBehavior: aBehavior [

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
MCPToolDescribeMethod >> variableReferenceSchema [

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
MCPToolDescribeMethod >> variableSummariesForMethod: aCompiledMethod methodBehavior: aBehavior [

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
