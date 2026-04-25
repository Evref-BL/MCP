"
Shared base class for mutating MCP tools. It centralizes operation selection, warning handling, and structured edit failure reporting.
"
Class {
	#name : 'MCPToolEdit',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'testing' }
MCPToolEdit class >> isAbstract [

	^ self = MCPToolEdit
]

{ #category : 'private - refactoring' }
MCPToolEdit >> addRefactoringScopeContextFromSpec: scopeSpec toRequestedContext: requestedContext [

	scopeSpec packageNames ifNotEmpty: [
		requestedContext at: #packageNames put: scopeSpec packageNames ].
	scopeSpec classNames ifNotEmpty: [
		requestedContext at: #classNames put: scopeSpec classNames ].
	scopeSpec hierarchyClassNames ifNotEmpty: [
		requestedContext
			at: #hierarchyClassNames
			put: scopeSpec hierarchyClassNames ]
]

{ #category : 'private - errors' }
MCPToolEdit >> addSupplementalDetailsForOperationError: anError to: details [

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
MCPToolEdit >> canonicalOperationNames [

	^ (self operationSpecifications collect: [ :each | each at: #name ])
		  asArray
]

{ #category : 'private - refactoring' }
MCPToolEdit >> classesRefactoringEnvironmentForClassNames: classNames baseEnvironment: baseEnvironment [

	^ baseEnvironment forClasses:
		  (self resolvedRefactoringScopeClassesFrom: classNames)
]

{ #category : 'private - execution' }
MCPToolEdit >> commandForRequest: editRequest [

	^ MCPEditToolCommand tool: self request: editRequest
]

{ #category : 'private - errors' }
MCPToolEdit >> errorDetailsForRequestedContext: requestedContext causedBy: anError [

	| details |
	details := requestedContext
		           ifNil: [ Dictionary new ]
		           ifNotNil: [ requestedContext copy ].
	details at: #causeClass put: anError class name asString.
	^ details
]

{ #category : 'private' }
MCPToolEdit >> errorResultForCommandError: anError operation: operation requestedContext: requestedContext [

	| details |
	details := anError structuredDetails copy.
	requestedContext ifNotNil: [
		requestedContext keysAndValuesDo: [ :key :value |
			value ifNotNil: [ details at: key ifAbsentPut: [ value ] ] ] ].
	details at: #operation put: operation.
	^ self errorResultText: anError messageText details: details
]

{ #category : 'private - errors' }
MCPToolEdit >> errorResultForOperationFailure: anError operation: operation requestedContext: requestedContext summary: summary [

	(anError isKindOf: RBRefactoringWarning) ifTrue: [
		^ self
			  errorResultForRefactoringWarning: anError
			  operation: operation
			  requestedContext: requestedContext ].
	(anError isKindOf: MCPCommandError) ifTrue: [
		^ self
			  errorResultForCommandError: anError
			  operation: operation
			  requestedContext: requestedContext ].
	^ self
		  errorResultForCommandError: (self
				   normalizedCommandErrorForOperationFailure: anError
				   operation: operation
				   requestedContext: requestedContext
				   summary: summary)
		  operation: operation
		  requestedContext: requestedContext
]

{ #category : 'private - warnings' }
MCPToolEdit >> errorResultForRefactoringWarning: aWarning operation: operation requestedContext: requestedContext [

	^ self
		  errorResultForCommandError: (self
				   normalizedCommandErrorForRefactoringWarning: aWarning
				   operation: operation
				   requestedContext: requestedContext)
		  operation: operation
		  requestedContext: requestedContext
]

{ #category : 'private - execution' }
MCPToolEdit >> executeEditOperation: operation force: forceRequested requestedContext: requestedContext work: operationBlock successResult: successBlock failureSummary: failureSummaryBlock [

	| executionOutcome |
	^ [
	  executionOutcome := self
		                      executeOperationBlock: operationBlock
		                      force: forceRequested
		                      operation: operation
		                      requestedContext: requestedContext.
	  (executionOutcome includesKey: #stoppedResult) ifTrue: [
		  ^ executionOutcome at: #stoppedResult ].
	  successBlock value: (executionOutcome at: #warnings) ]
		  on: Exception
		  do: [ :error |
			  self
				  errorResultForOperationFailure: error
				  operation: operation
				  requestedContext: requestedContext
				  summary: (failureSummaryBlock value: error) ]
]

{ #category : 'private - execution' }
MCPToolEdit >> executeOperationBlock: anOperationBlock force: forceRequested operation: operation requestedContext: requestedContext [

	| warningMessages |
	warningMessages := OrderedCollection new.
	[ anOperationBlock value ]
		on: RBRefactoringWarning
		do: [ :warning |
			| impactMessages |
			impactMessages := self impactMessagesForRefactoringWarning: warning.
			forceRequested
				ifTrue: [
					warningMessages addAll: impactMessages.
					warning resume: true ]
				ifFalse: [
					^ { (#stoppedResult -> (self
						    errorResultForRefactoringWarning: warning
						    operation: operation
						    requestedContext: requestedContext)) } asDictionary ] ].
	^ { (#warnings -> warningMessages asArray) } asDictionary
]

{ #category : 'private - execution' }
MCPToolEdit >> executeOperationRequest: editRequest [

	| specification |
	specification := self operationSpecificationNamed:
		                 editRequest operation.
	^ self
		  perform: (specification at: #executeSelector)
		  with: editRequest rawRequest
]

{ #category : 'executing' }
MCPToolEdit >> executeWithRequest: request [

	| editRequest operation requestedContext |
	[ editRequest := self parsedRequestFromToolRequest: request ]
		on: MCPCommandError
		do: [ :error |
			operation := request
				             stringArgumentNamed: 'operation'
				             default: 'edit'.
			requestedContext := request asDictionary copy.
			^ self
				  errorResultForCommandError: error
				  operation: operation
				  requestedContext: requestedContext ].
	^ (self commandForRequest: editRequest) execute
]

{ #category : 'private - request' }
MCPToolEdit >> forceFromRequest: request [

	^ request booleanArgumentNamed: 'force' default: false
]

{ #category : 'private - schema' }
MCPToolEdit >> forceSchemaProperty [

	^ self
		  booleanSchemaPropertyNamed: 'force'
		  description:
		  'Controls refactoring warning handling. force=false stops on RBRefactoringWarning and returns an error with impactMessages, howToProceed, and forceSupported=true. force=true resumes past the warning and returns the warning text in warnings.'
		  default: false
]

{ #category : 'private - refactoring' }
MCPToolEdit >> hierarchyRefactoringEnvironmentForClassNames: classNames baseEnvironment: baseEnvironment [

	| environment resolvedClasses |
	resolvedClasses := self resolvedRefactoringScopeClassesFrom:
		                   classNames.
	environment := nil.
	resolvedClasses do: [ :eachClass |
		environment := self
			               unionRefactoringEnvironment: environment
			               with: (baseEnvironment forClassHierarchy: eachClass) ].
	^ environment
]

{ #category : 'private - warnings' }
MCPToolEdit >> howToProceedForRefactoringWarning [

	^ 'Review impactMessages, then rerun the same request with force=true to continue despite these warnings.'
]

{ #category : 'private - warnings' }
MCPToolEdit >> impactMessageForRefactoringCondition: aCondition [

	| message |
	(aCondition respondsTo: #violationMessageOn:) ifFalse: [
		^ self normalizedSingleLineText: aCondition printString ].
	message := String streamContents: [ :stream |
		           aCondition violationMessageOn: stream ].
	^ self normalizedSingleLineText: message
]

{ #category : 'private - warnings' }
MCPToolEdit >> impactMessagesForRefactoringWarning: aWarning [

	| failedPreconditions impactMessages primaryMessage |
	impactMessages := OrderedCollection new.
	failedPreconditions := (aWarning respondsTo: #failedPreconditions)
		                       ifTrue: [ aWarning failedPreconditions ]
		                       ifFalse: [ nil ].
	failedPreconditions ifNotNil: [
		failedPreconditions do: [ :each |
			| message |
			message := self impactMessageForRefactoringCondition: each.
			message isEmpty ifFalse: [ impactMessages add: message ] ] ].
	impactMessages ifEmpty: [
		primaryMessage := self normalizedSingleLineText:
			                  aWarning messageText.
		primaryMessage isEmpty ifTrue: [
			primaryMessage := aWarning class name asString ].
		impactMessages add: primaryMessage ].
	^ impactMessages asArray
]

{ #category : 'private - errors' }
MCPToolEdit >> normalizedCauseMessageForOperationError: anError [

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
MCPToolEdit >> normalizedCommandErrorForOperationFailure: anError operation: operation requestedContext: requestedContext summary: summary [

	| details normalizedSummary |
	normalizedSummary := summary
		                     ifNil: [ '' ]
		                     ifNotNil: [ summary asString ].
	details := self
		           errorDetailsForRequestedContext: requestedContext
		           causedBy: anError.
	self addSupplementalDetailsForOperationError: anError to: details.
	^ MCPCommandError new
		  errorCode:
			  (self operationFailureErrorCodeFor: anError operation: operation);
		  details: details;
		  messageText: normalizedSummary;
		  yourself
]

{ #category : 'private - warnings' }
MCPToolEdit >> normalizedCommandErrorForRefactoringWarning: aWarning operation: operation requestedContext: requestedContext [

	| details impactMessages summary |
	impactMessages := self impactMessagesForRefactoringWarning: aWarning.
	summary := self
		           refactoringWarningSummaryFor: aWarning
		           operation: operation
		           requestedContext: requestedContext
		           impactMessages: impactMessages.
	details := self
		           errorDetailsForRequestedContext: requestedContext
		           causedBy: aWarning.
	details at: #impactMessages put: impactMessages.
	details at: #howToProceed put: self howToProceedForRefactoringWarning.
	details at: #forceSupported put: true.
	^ MCPCommandError new
		  errorCode:
			  (self operationFailureErrorCodeFor: aWarning operation: operation);
		  details: details;
		  messageText: summary;
		  yourself
]

{ #category : 'private - warnings' }
MCPToolEdit >> normalizedSingleLineText: aString [

	| text |
	text := aString ifNil: [ '' ] ifNotNil: [ aString asString ].
	text := text copyReplaceAll: '<n>' with: ' '.
	text := text copyReplaceAll: String cr with: ' '.
	text := text copyReplaceAll: String lf with: ' '.
	[ text includesSubstring: '  ' ] whileTrue: [
		text := text copyReplaceAll: '  ' with: ' ' ].
	^ text trimBoth
]

{ #category : 'private - schema' }
MCPToolEdit >> operationBranchSchemas [

	^ (self operationSpecifications collect: [ :each |
		   self
			   inputSchemaBranchForStringDiscriminatorNamed: 'operation'
			   value: (each at: #name)
			   required: { 'className' } , (each at: #requiredProperties)
			   requireDiscriminator: true ]) asArray
]

{ #category : 'private - errors' }
MCPToolEdit >> operationErrorCodePrefixFor: operation [

	operation ifNil: [ ^ 'Operation' ].
	operation isEmpty ifTrue: [ ^ 'Operation' ].
	^ operation first asUppercase asString , operation allButFirst
]

{ #category : 'private - errors' }
MCPToolEdit >> operationFailureErrorCodeFor: anError operation: operation [

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

{ #category : 'private - request' }
MCPToolEdit >> operationFromRequest: request [

	| operation specification |
	operation := request stringArgumentNamed: 'operation'.
	operation ifNil: [
		MCPInvalidToolInput
			signalMissingRequiredArgumentNamed: 'operation'
			forTool: self ].
	specification := self operationSpecifications
		                 detect: [ :each | (each at: #name) = operation ]
		                 ifNone: [
		                 Error signal: self operationValidationErrorMessage ].
	^ specification at: #name
]

{ #category : 'private - operations' }
MCPToolEdit >> operationNameListText [

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
MCPToolEdit >> operationSchemaPropertyWithDescription: baseDescription supportedValuesLeadIn: supportedValuesLeadIn [

	^ MCPStructureProperties new
		  name: 'operation';
		  type: 'string';
		  description: baseDescription , ' ' , supportedValuesLeadIn , ' '
			  , self operationNameListText , '.';
		  enum: self canonicalOperationNames;
		  yourself
]

{ #category : 'private - operations' }
MCPToolEdit >> operationSpecificationNamed: anOperationName [

	^ self operationSpecifications
		  detect: [ :each | (each at: #name) = anOperationName ]
		  ifNone: [ Error signal: self operationValidationErrorMessage ]
]

{ #category : 'private - operations' }
MCPToolEdit >> operationSpecifications [

	self subclassResponsibility
]

{ #category : 'private - warnings' }
MCPToolEdit >> operationTargetDescriptionForRequestedContext: requestedContext [

	| className selector slotName |
	requestedContext ifNil: [ ^ '' ].
	className := requestedContext at: #className ifAbsent: [ nil ].
	selector := requestedContext at: #selector ifAbsent: [ nil ].
	slotName := requestedContext at: #slotName ifAbsent: [ nil ].
	(className isNil and: [ selector isNil and: [ slotName isNil ] ])
		ifTrue: [ ^ '' ].
	^ String streamContents: [ :stream |
		  className ifNotNil: [
			  stream
				  nextPutAll: ' on ';
				  nextPutAll: className ].
		  selector ifNotNil: [
			  className
				  ifNil: [ stream nextPutAll: ' for selector ' ]
				  ifNotNil: [ stream nextPutAll: '>>' ].
			  stream nextPutAll: selector ].
		  slotName ifNotNil: [
			  stream
				  nextPutAll: ' slot ';
				  nextPutAll: slotName ] ]
]

{ #category : 'private - operations' }
MCPToolEdit >> operationValidationErrorMessage [

	^ 'operation must be one of ' , self operationNameListText , '.'
]

{ #category : 'private - request' }
MCPToolEdit >> parsedRequestFromToolRequest: request [

	^ MCPEditToolRequest fromRequest: request tool: self
]

{ #category : 'private - refactoring' }
MCPToolEdit >> refactoringEnvironmentForScopeSpec: scopeSpec [

	| baseEnvironment environment |
	baseEnvironment := RBBrowserEnvironment new.
	scopeSpec isDefaultImageScope ifTrue: [ ^ baseEnvironment ].
	environment := nil.
	scopeSpec packageNames ifNotEmpty: [
		environment := self
			               unionRefactoringEnvironment: environment
			               with:
			               (baseEnvironment forPackageNames:
				                scopeSpec packageNames) ].
	scopeSpec classNames ifNotEmpty: [
		environment := self
			               unionRefactoringEnvironment: environment
			               with: (self
					                classesRefactoringEnvironmentForClassNames:
					                scopeSpec classNames
					                baseEnvironment: baseEnvironment) ].
	scopeSpec hierarchyClassNames ifNotEmpty: [
		environment := self
			               unionRefactoringEnvironment: environment
			               with: (self
					                hierarchyRefactoringEnvironmentForClassNames:
					                scopeSpec hierarchyClassNames
					                baseEnvironment: baseEnvironment) ].
	^ environment ifNil: [ baseEnvironment ]
]

{ #category : 'private - refactoring' }
MCPToolEdit >> refactoringModelForScopeSpec: scopeSpec anchoredAtBehavior: aBehavior [

	| details environment |
	environment := self refactoringEnvironmentForScopeSpec: scopeSpec.
	(environment includesClass: aBehavior) ifFalse: [
		details := scopeSpec asDictionary copy.
		details at: #className put: aBehavior instanceSide name asString.
		details at: #classSide put: aBehavior isMeta.
		MCPCommandError
			signalErrorCode: #RefactoringScopeExcludesTargetClass
			message: 'Refactoring scope does not include ' , (aBehavior isMeta
					 ifTrue: [ 'the class side of ' ]
					 ifFalse: [ 'class ' ]) , aBehavior instanceSide name asString
				, '.'
			details: details ].
	^ RBNamespace onEnvironment: environment
]

{ #category : 'private - schema' }
MCPToolEdit >> refactoringScopeClassNamesSchemaProperty [

	^ self
		  stringArraySchemaNamed: 'classNames'
		  description:
		  'Exact class scope for scope-aware update actions. The refactoring is applied only inside these classes.'
		  itemDescription: 'A class name.'
]

{ #category : 'private - schema' }
MCPToolEdit >> refactoringScopeHierarchyClassNamesSchemaProperty [

	^ self
		  stringArraySchemaNamed: 'hierarchyClassNames'
		  description:
		  'Class hierarchy scope for scope-aware update actions. Each named class contributes its superclass and subclass hierarchy.'
		  itemDescription: 'A class name whose hierarchy is included.'
]

{ #category : 'private - schema' }
MCPToolEdit >> refactoringScopePackageNamesSchemaProperty [

	^ self
		  stringArraySchemaNamed: 'packageNames'
		  description:
		  'Package scope for scope-aware update actions. The refactoring is applied only inside these packages.'
		  itemDescription: 'A package name.'
]

{ #category : 'private - request' }
MCPToolEdit >> refactoringScopeSpecFromRequest: request [

	| classNames hierarchyClassNames packageNames |
	packageNames := request stringCollectionArgumentNamed: 'packageNames'.
	classNames := request stringCollectionArgumentNamed: 'classNames'.
	hierarchyClassNames := request stringCollectionArgumentNamed:
		                       'hierarchyClassNames'.
	self validateRefactoringScopePackageNamesExist: packageNames.
	^ MCPRefactoringScopeSpec
		  packageNames: packageNames
		  classNames: classNames
		  hierarchyClassNames: hierarchyClassNames
]

{ #category : 'private - warnings' }
MCPToolEdit >> refactoringWarningSummaryFor: aWarning operation: operation requestedContext: requestedContext impactMessages: impactMessages [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Refactoring warning for ';
			  nextPutAll: operation;
			  nextPutAll:
				  (self operationTargetDescriptionForRequestedContext:
						   requestedContext).
		  impactMessages isEmpty ifFalse: [
			  stream
				  nextPutAll: ': ';
				  nextPutAll: impactMessages first ].
		  stream
			  nextPutAll: ' ';
			  nextPutAll: self howToProceedForRefactoringWarning ]
]

{ #category : 'private - request' }
MCPToolEdit >> resolvedRefactoringScopeClassesFrom: classNames [

	^ classNames collect: [ :eachName |
		  Smalltalk globals
			  at: eachName asSymbol
			  ifAbsent: [ MCPCommandError signalMissingClassNamed: eachName ] ]
]

{ #category : 'private - errors' }
MCPToolEdit >> undeclaredVariableCauseMessageFor: anError [

	| variableName |
	variableName := self undeclaredVariableNameFor: anError.
	^ variableName
		  ifNil: [ 'Undeclared variable' ]
		  ifNotNil: [ 'Undeclared variable: ' , variableName ]
]

{ #category : 'private - errors' }
MCPToolEdit >> undeclaredVariableNameFor: anError [

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

{ #category : 'private - refactoring' }
MCPToolEdit >> unionRefactoringEnvironment: currentEnvironment with: addedEnvironment [

	^ currentEnvironment
		  ifNil: [ addedEnvironment ]
		  ifNotNil: [ currentEnvironment | addedEnvironment ]
]

{ #category : 'private - request' }
MCPToolEdit >> validateRefactoringScopePackageNamesExist: packageNames [

	packageNames do: [ :eachName |
		(PackageOrganizer default hasPackage: eachName) ifFalse: [
			MCPCommandError signalMissingPackageNamed: eachName ] ]
]

{ #category : 'private - request' }
MCPToolEdit >> validateRequiredPropertiesForOperation: operation inRequest: request [

	| specification |
	specification := self operationSpecificationNamed: operation.
	(specification at: #requiredProperties ifAbsent: [ #(  ) ]) do: [
		:each |
		(request argumentNamed: each ifAbsent: [ nil ]) ifNil: [
			MCPInvalidToolInput
				signalMissingRequiredArgumentNamed: each
				forTool: self ] ]
]
