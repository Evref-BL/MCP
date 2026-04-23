Class {
	#name : 'MCPEditTool',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'testing' }
MCPEditTool class >> isAbstract [

	^ self = MCPEditTool
]

{ #category : 'private - errors' }
MCPEditTool >> addSupplementalDetailsForOperationError: anError to: details [

	| methodNode position selector variableName |
	(anError respondsTo: #methodNode) ifTrue: [
		methodNode := anError methodNode.
		methodNode ifNotNil: [
			selector := methodNode selector.
			selector ifNotNil: [
				details at: #selector ifAbsentPut: [ selector asString ] ] ] ].
	(anError respondsTo: #position) ifTrue: [
		position := anError position.
		position ifNotNil: [ details at: #position put: position ] ].
	(anError isKindOf: OCUndeclaredVariableWarning) ifTrue: [
		variableName := self undeclaredVariableNameFor: anError.
		variableName ifNotNil: [
			details at: #variableName put: variableName ] ]
]

{ #category : 'private - operations' }
MCPEditTool >> canonicalOperationNames [

	^ (self operationSpecifications collect: [ :each | each at: #name ])
		  asArray
]

{ #category : 'private' }
MCPEditTool >> errorResultForCommandError: anError operation: operation [

	| details |
	details := anError structuredDetails copy.
	details at: #operation put: operation.
	^ self errorResultText: anError messageText details: details
]

{ #category : 'private - errors' }
MCPEditTool >> errorResultForOperationFailure: anError operation: operation requestedContext: requestedContext summary: summary [

	(anError isKindOf: MCPCommandError) ifTrue: [
		^ self errorResultForCommandError: anError operation: operation ].
	^ self
		  errorResultForCommandError: (self
				   normalizedCommandErrorForOperationFailure: anError
				   operation: operation
				   requestedContext: requestedContext
				   summary: summary)
		  operation: operation
]

{ #category : 'executing' }
MCPEditTool >> executeWithArguments: arguments [

	| operation specification |
	operation := self operationFromArguments: arguments.
	self validateRequiredArgumentsForOperation: operation in: arguments.
	specification := self operationSpecificationNamed: operation.
	^ self perform: (specification at: #executeSelector) with: arguments
]

{ #category : 'private - errors' }
MCPEditTool >> normalizedCauseMessageForOperationError: anError [

	| descriptionText message |
	(anError isKindOf: OCUndeclaredVariableWarning) ifTrue: [
		^ self undeclaredVariableCauseMessageFor: anError ].
	message := anError messageText.
	message ifNil: [ message := '' ].
	message := message asString.
	message isEmpty ifFalse: [ ^ message ].
	(anError respondsTo: #description) ifTrue: [
		descriptionText := anError description.
		descriptionText ifNotNil: [
			descriptionText := descriptionText asString.
			descriptionText isEmpty ifFalse: [ ^ descriptionText ] ] ].
	^ anError class name asString
]

{ #category : 'private - errors' }
MCPEditTool >> normalizedCommandErrorForOperationFailure: anError operation: operation requestedContext: requestedContext summary: summary [

	| details normalizedSummary |
	normalizedSummary := summary
		                     ifNil: [ '' ]
		                     ifNotNil: [ summary asString ].
	details := requestedContext
		           ifNil: [ Dictionary new ]
		           ifNotNil: [ requestedContext copy ].
	details at: #causeClass put: anError class name asString.
	self addSupplementalDetailsForOperationError: anError to: details.
	^ MCPCommandError new
		  errorCode:
			  (self operationFailureErrorCodeFor: anError operation: operation);
		  details: details;
		  messageText: normalizedSummary;
		  yourself
]

{ #category : 'private - errors' }
MCPEditTool >> operationErrorCodePrefixFor: operation [

	operation ifNil: [ ^ 'Operation' ].
	operation isEmpty ifTrue: [ ^ 'Operation' ].
	^ operation first asUppercase asString , operation allButFirst
]

{ #category : 'private - errors' }
MCPEditTool >> operationFailureErrorCodeFor: anError operation: operation [

	| prefix |
	prefix := self operationErrorCodePrefixFor: operation.
	(anError isKindOf: OCUndeclaredVariableWarning) ifTrue: [
		^ prefix , 'UndeclaredVariable' ].
	(anError isKindOf: RuntimeSyntaxError) ifTrue: [
		^ prefix , 'SyntaxError' ].
	(anError isKindOf: SyntaxErrorNotification) ifTrue: [
		^ prefix , 'SyntaxError' ].
	(anError isKindOf: RBRefactoringWarning) ifTrue: [
		^ prefix , 'RefactoringWarning' ].
	(anError isKindOf: RBRefactoringError) ifTrue: [
		^ prefix , 'RefactoringError' ].
	^ prefix , 'ExecutionError'
]

{ #category : 'private - arguments' }
MCPEditTool >> operationFromArguments: arguments [

	| normalized operation specification |
	operation := self stringArgumentNamed: 'operation' in: arguments.
	operation ifNil: [ JRPCInvalidParameters signal ].
	normalized := operation asLowercase.
	specification := self operationSpecifications
		                 detect: [ :each |
		                 (each at: #name) asLowercase = normalized ]
		                 ifNone: [
		                 Error signal: self operationValidationErrorMessage ].
	^ specification at: #name
]

{ #category : 'private - operations' }
MCPEditTool >> operationNameListText [

	| operationNames |
	operationNames := self canonicalOperationNames.
	^ String streamContents: [ :stream |
		  operationNames doWithIndex: [ :each :index |
			  index > 1 ifTrue: [
				  index = operationNames size
					  ifTrue: [
						  operationNames size > 2
							  ifTrue: [ stream nextPutAll: ', or ' ]
							  ifFalse: [ stream nextPutAll: ' or ' ] ]
					  ifFalse: [ stream nextPutAll: ', ' ] ].
			  stream nextPutAll: each ] ]
]

{ #category : 'private - schema' }
MCPEditTool >> operationSchemaPropertyWithDescription: baseDescription supportedValuesLeadIn: supportedValuesLeadIn [

	^ MCPStructureProperties new
		  name: 'operation';
		  type: 'string';
		  description: baseDescription , ' ' , supportedValuesLeadIn , ' '
			  , self operationNameListText , '.';
		  enum: self canonicalOperationNames;
		  yourself
]

{ #category : 'private - operations' }
MCPEditTool >> operationSpecificationNamed: anOperationName [

	^ self operationSpecifications
		  detect: [ :each | (each at: #name) = anOperationName ]
		  ifNone: [ Error signal: self operationValidationErrorMessage ]
]

{ #category : 'private - operations' }
MCPEditTool >> operationSpecifications [

	self subclassResponsibility
]

{ #category : 'private - operations' }
MCPEditTool >> operationValidationErrorMessage [

	^ 'operation must be one of ' , self operationNameListText , '.'
]

{ #category : 'private - errors' }
MCPEditTool >> undeclaredVariableCauseMessageFor: anError [

	| variableName |
	variableName := self undeclaredVariableNameFor: anError.
	^ variableName
		  ifNil: [ 'Undeclared variable' ]
		  ifNotNil: [ 'Undeclared variable: ' , variableName ]
]

{ #category : 'private - errors' }
MCPEditTool >> undeclaredVariableNameFor: anError [

	| node notice |
	(anError respondsTo: #notice) ifFalse: [ ^ nil ].
	notice := anError notice.
	notice ifNil: [ ^ nil ].
	(notice respondsTo: #node) ifFalse: [ ^ nil ].
	node := notice node.
	node ifNil: [ ^ nil ].
	(node respondsTo: #name) ifFalse: [ ^ nil ].
	^ node name asString
]

{ #category : 'private - arguments' }
MCPEditTool >> validateRequiredArgumentsForOperation: operation in: arguments [

	| specification |
	specification := self operationSpecificationNamed: operation.
	(specification at: #requiredArguments ifAbsent: [ #(  ) ]) do: [
		:each |
		(self argumentNamed: each in: arguments ifAbsent: [ nil ]) ifNil: [
			JRPCInvalidParameters signal ] ]
]
