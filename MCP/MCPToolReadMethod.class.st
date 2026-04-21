Class {
	#name : 'MCPToolReadMethod',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'private - arguments' }
MCPToolReadMethod >> argumentNamed: anArgumentName in: arguments ifAbsent: aBlock [

	arguments ifNil: [ ^ aBlock value ].
	^ arguments
		  at: anArgumentName asSymbol
		  ifAbsent: [
		  arguments at: anArgumentName asString ifAbsent: aBlock ]
]

{ #category : 'private - analysis' }
MCPToolReadMethod >> bindingClassNameFor: aBinding [

	^ aBinding
		  ifNil: [ 'UnknownBinding' ]
		  ifNotNil: [ :binding | binding class name asString ]
]

{ #category : 'private - reading' }
MCPToolReadMethod >> compiledMethodForClassNamed: className selector: selectorString side: side [

	| behavior selectorSymbol |
	behavior := self methodBehaviorForClassNamed: className side: side.
	selectorSymbol := selectorString asSymbol.
	(behavior includesSelector: selectorSymbol) ifFalse: [
		Error signal:
			'No method named ' , selectorString , ' found on ' , behavior name
			, '.' ].
	^ behavior compiledMethodAt: selectorSymbol
]

{ #category : 'private - analysis' }
MCPToolReadMethod >> declaredInMethodForKind: aKind [

	^ #( 'argument' 'temporary' ) includes: aKind
]

{ #category : 'executing' }
MCPToolReadMethod >> executeWithArguments: arguments [

	| argumentNames className compiledMethod data externalVariableReferences methodBehavior methodReference methodNode protocolName selectorString side temporaryNames variableReferences |
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
	  methodReference := self
		                     methodReferenceForClassName: className
		                     selector: selectorString
		                     isClassSide: side = 'class'.
	  argumentNames := (methodNode arguments collect: [ :each |
		                    each name asString ]) asArray.
	  temporaryNames := (methodNode temporaries collect: [ :each |
		                     each name asString ]) asArray.
	  variableReferences := self
		                        variableSummariesForMethod: compiledMethod
		                        methodBehavior: methodBehavior.
	  externalVariableReferences := (variableReferences select: [ :each |
		                                 each at: #external ]) asArray.
	  data := {
		          (#className -> className).
		          (#selector -> selectorString).
		          (#side -> side).
		          (#protocol -> protocolName).
		          (#methodReference -> methodReference).
		          (#source -> (compiledMethod sourceCode ifNil: [ '' ])).
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
				  errorResultText: (self
						   failureMessageForClassNamed: className
						   selector: selectorString
						   side: side
						   error: error)
				  details: {
						  (#errorClass -> error class name).
						  (#message -> error messageText).
						  (#className -> className).
						  (#selector -> selectorString).
						  (#side -> side) } asDictionary ]
]

{ #category : 'private - results' }
MCPToolReadMethod >> failureMessageForClassNamed: className selector: selectorString side: side error: anError [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Unable to read method ';
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
MCPToolReadMethod >> finalizedVariableSummariesFrom: summaries [

	^ (summaries asSortedCollection: [ :left :right |
		   ((left at: #sourceIntervals) first at: #start)
		   <= ((right at: #sourceIntervals) first at: #start) ])
		  collect: [ :each |
			  | finalized |
			  finalized := each copy.
			  finalized
				  at: #sourceIntervals
				  put: (each at: #sourceIntervals) asArray.
			  finalized ]
		  as: Array
]

{ #category : 'initialization' }
MCPToolReadMethod >> initialize [

	| sideProperty variableNameItemSchema |
	super initialize.
	name := 'pharo-read-method'.
	title := 'Read Pharo Method'.
	description := 'Read a single method from the running Pharo image, including structured variable-resolution context.'.
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
						                'The selector of the method to read.';
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
					                 description: 'The selector that was read.').
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
					                 schemaPropertyNamed: 'methodReference'
					                 type: 'string'
					                 description:
					                 'A readable method reference such as Class>>selector or Class class>>selector.').
				                (self
					                 schemaPropertyNamed: 'source'
					                 type: 'string'
					                 description:
					                 'The formatted source code of the method.').
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
					                 schemaPropertyNamed: 'variableReferenceCount'
					                 type: 'number'
					                 description:
					                 'The number of unique referenced variables summarized in the result.').
				                (self
					                 schemaPropertyNamed: 'externalVariableCount'
					                 type: 'number'
					                 description:
					                 'The number of unique referenced variables that are not declared locally in the method.').
				                ((self
					                  schemaPropertyNamed: 'variableReferences'
					                  type: 'array'
					                  description:
						                  'Structured summaries of all referenced variables in source order.')
					                 items: self variableReferenceSchema;
					                 yourself).
				                ((self
					                  schemaPropertyNamed:
						                  'externalVariableReferences'
					                  type: 'array'
					                  description:
						                  'Structured summaries of referenced variables that come from outside the method''s local declarations.')
					                 items: self variableReferenceSchema;
					                 yourself) }
		                required:
			                #( 'className' 'selector' 'side' 'protocol'
			                   'methodReference' 'source' 'argumentNames'
			                   'temporaryNames' 'variableReferenceCount'
			                   'externalVariableCount' 'variableReferences'
			                   'externalVariableReferences' ).
	icons := {  }
]

{ #category : 'private - analysis' }
MCPToolReadMethod >> matchingSummaryForNodeName: aName kind: aKind ownerName: anOwnerName in: summaries [

	^ summaries
		  detect: [ :each |
			  (each at: #name) = aName and: [
				  (each at: #kind) = aKind and: [
					  (each at: #ownerName ifAbsent: [ nil ]) = anOwnerName ] ] ]
		  ifNone: [ nil ]
]

{ #category : 'private - reading' }
MCPToolReadMethod >> methodBehaviorForClassNamed: className side: side [

	| baseClass |
	baseClass := self class environment at: className asSymbol.
	^ side = 'class'
		  ifTrue: [ baseClass classSide ]
		  ifFalse: [ baseClass ]
]

{ #category : 'private - reading' }
MCPToolReadMethod >> methodReferenceForClassName: aClassName selector: aSelector isClassSide: isClassSide [

	^ String streamContents: [ :stream |
		  stream nextPutAll: aClassName.
		  isClassSide ifTrue: [ stream nextPutAll: ' class' ].
		  stream
			  nextPutAll: '>>';
			  nextPutAll: aSelector ]
]

{ #category : 'private - analysis' }
MCPToolReadMethod >> newVariableSummaryForNode: aVariableNode kind: aKind methodBehavior: aBehavior [

	| binding ownerName summary |
	binding := aVariableNode binding.
	ownerName := self
		             ownerNameForNode: aVariableNode
		             kind: aKind
		             methodBehavior: aBehavior.
	summary := Dictionary new.
	summary at: #name put: aVariableNode name asString.
	summary at: #kind put: aKind.
	summary
		at: #declaredInMethod
		put: (self declaredInMethodForKind: aKind).
	summary at: #external put: (self declaredInMethodForKind: aKind) not.
	summary at: #bindingClass put: (self bindingClassNameFor: binding).
	summary at: #referenceCount put: 0.
	summary at: #sourceIntervals put: OrderedCollection new.
	ownerName ifNotNil: [ summary at: #ownerName put: ownerName ].
	^ summary
]

{ #category : 'private - arguments' }
MCPToolReadMethod >> normalizedSideFrom: arguments [

	| side |
	side := (self stringArgumentNamed: 'side' in: arguments) ifNil: [
		        ^ 'instance' ].
	side := side asLowercase.
	(#( 'instance' 'class' ) includes: side) ifFalse: [
		Error signal: 'side must be either instance or class.' ].
	^ side
]

{ #category : 'private - analysis' }
MCPToolReadMethod >> ownerNameForNode: aVariableNode kind: aKind methodBehavior: aBehavior [

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

{ #category : 'private - analysis' }
MCPToolReadMethod >> recordReferenceFromNode: aVariableNode inSummary: aSummary [

	(aSummary at: #sourceIntervals) add: {
			(#start -> aVariableNode start).
			(#stop -> aVariableNode stop) } asDictionary.
	aSummary at: #referenceCount put: (aSummary at: #referenceCount) + 1
]

{ #category : 'private - arguments' }
MCPToolReadMethod >> selectorStringFrom: arguments [

	^ self stringArgumentNamed: 'selector' in: arguments
]

{ #category : 'private - schema' }
MCPToolReadMethod >> sourceIntervalSchema [

	^ MCPStructureProperties new
		  name: 'sourceInterval';
		  type: 'object';
		  description: 'A source interval where the variable is referenced.';
		  properties: {
				  (self
					   schemaPropertyNamed: 'start'
					   type: 'number'
					   description:
						   'The 1-based start position in the method source.').
				  (self
					   schemaPropertyNamed: 'stop'
					   type: 'number'
					   description: 'The 1-based end position in the method source.') };
		  required: #( 'start' 'stop' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - arguments' }
MCPToolReadMethod >> stringArgumentNamed: anArgumentName in: arguments [

	| value |
	value := self
		         argumentNamed: anArgumentName
		         in: arguments
		         ifAbsent: [ ^ nil ].
	value ifNil: [ ^ nil ].
	value := value asString trimBoth.
	^ value isEmpty
		  ifTrue: [ nil ]
		  ifFalse: [ value ]
]

{ #category : 'private - results' }
MCPToolReadMethod >> successSummaryForClassName: className selector: selector side: side externalVariableCount: externalVariableCount [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Read method ';
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
MCPToolReadMethod >> variableKindForNode: aVariableNode methodBehavior: aBehavior [

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
MCPToolReadMethod >> variableReferenceSchema [

	| intervalsProperty ownerNameProperty |
	intervalsProperty := self
		                     schemaPropertyNamed: 'sourceIntervals'
		                     type: 'array'
		                     description:
		                     'Source intervals where the variable is referenced.'.
	intervalsProperty items: self sourceIntervalSchema.
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
				  (self
					   schemaPropertyNamed: 'declaredInMethod'
					   type: 'boolean'
					   description:
					   'Whether the variable is declared locally in the method source.').
				  (self
					   schemaPropertyNamed: 'external'
					   type: 'boolean'
					   description:
					   'Whether the variable comes from outside the method''s local declarations.').
				  ownerNameProperty.
				  (self
					   schemaPropertyNamed: 'bindingClass'
					   type: 'string'
					   description:
					   'The compiler binding class used to resolve the variable.').
				  (self
					   schemaPropertyNamed: 'referenceCount'
					   type: 'number'
					   description:
					   'How many times the variable is referenced in the method.').
				  intervalsProperty };
		  required:
			  #( 'name' 'kind' 'declaredInMethod' 'external' 'bindingClass'
			     'referenceCount' 'sourceIntervals' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - analysis' }
MCPToolReadMethod >> variableSummariesForMethod: aCompiledMethod methodBehavior: aBehavior [

	| summaries |
	summaries := OrderedCollection new.
	aCompiledMethod ast allChildren do: [ :node |
		(node isKindOf: RBVariableNode) ifTrue: [
			| kind summary ownerName |
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
			self recordReferenceFromNode: node inSummary: summary ] ].
	^ self finalizedVariableSummariesFrom: summaries
]
