"
Shared base class for mutating MCP tools.

It centralizes refactoring warning handling and structured mutation failure reporting. Concrete tools choose their public request shape in their own tool classes and pass a concrete action name only for result and error metadata.
"
Class {
	#name : 'MCPToolMutation',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'testing' }
MCPToolMutation class >> isAbstract [

	^ self = MCPToolMutation
]

{ #category : 'private - errors' }
MCPToolMutation >> actionErrorCodePrefixFor: action [

	action ifNil: [ ^ 'Action' ].
	action isEmpty ifTrue: [ ^ 'Action' ].
	^ action first asUppercase asString , action allButFirst
]

{ #category : 'private - refactoring' }
MCPToolMutation >> addRefactoringScopeContextFromSpec: scopeSpec toRequestedContext: requestedContext [

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
MCPToolMutation >> addSupplementalDetailsForMutationError: anError to: details [

	| cause methodNode position undeclaredVariableNode variableName |
	cause := self mutationFailureCauseFor: anError.
	methodNode := self methodNodeFromError: cause.
	methodNode ifNotNil: [
		self addSupplementalSelectorFromMethodNode: methodNode to: details ].
	(PharoCompatibility compilationAstFromException: cause) ifNotNil: [
		:ast | self addSupplementalSelectorFromMethodNode: ast to: details ].
	anError == cause ifFalse: [
			methodNode := self methodNodeFromError: anError.
			methodNode ifNotNil: [
				self addSupplementalSelectorFromMethodNode: methodNode to: details ].
			(PharoCompatibility compilationAstFromException: anError)
				ifNotNil: [ :ast |
				self addSupplementalSelectorFromMethodNode: ast to: details ] ].
	position := self positionFromError: cause.
	position ifNotNil: [ details at: #position put: position ].
	undeclaredVariableNode := self undeclaredVariableNodeFrom: cause.
	undeclaredVariableNode ifNotNil: [
			variableName := self undeclaredVariableNameFor: cause.
			variableName ifNotNil: [
				details at: #variableName put: variableName ].
			(self startPositionFromNode: undeclaredVariableNode) ifNotNil: [
				:start | details at: #position put: start ] ]
]

{ #category : 'private - errors' }
MCPToolMutation >> addSupplementalSelectorFromMethodNode: methodNode to: details [

	| selector |
	selector := methodNode selector.
	selector ifNotNil: [
		details at: #selector ifAbsentPut: [ selector asString ] ]
]

{ #category : 'private - refactoring' }
MCPToolMutation >> classesRefactoringEnvironmentForClassNames: classNames baseEnvironment: baseEnvironment [

	^ baseEnvironment forClasses:
		  (self resolvedRefactoringScopeClassesFrom: classNames)
]

{ #category : 'private - execution' }
MCPToolMutation >> commandForRequest: mutationRequest [

	^ mutationRequest commandForTool: self
]

{ #category : 'private - errors' }
MCPToolMutation >> errorDetailsForRequestedContext: requestedContext causedBy: anError [

	| cause details |
	cause := self mutationFailureCauseFor: anError.
	details := requestedContext
		           ifNil: [ Dictionary new ]
		           ifNotNil: [ requestedContext copy ].
	details at: #causeClass put: cause class name asString.
	^ details
]

{ #category : 'private - errors' }
MCPToolMutation >> errorResultForActionFailure: anError action: action requestedContext: requestedContext summary: summary [

	^ anError
		  mcpErrorResultForMutationTool: self
		  action: action
		  requestedContext: requestedContext
		  summary: summary
]

{ #category : 'private' }
MCPToolMutation >> errorResultForCommandError: anError action: action requestedContext: requestedContext [

	| details |
	details := anError structuredDetails copy.
	requestedContext ifNotNil: [
			requestedContext keysAndValuesDo: [ :key :value |
				value ifNotNil: [ details at: key ifAbsentPut: [ value ] ] ] ].
	(#( 'create' 'update' ) includes: action)
		ifTrue: [ details at: #action put: action ]
		ifFalse: [
				details at: #action put: 'update'.
				details at: #updateAction put: action ].
	^ self errorResultText: anError messageText details: details
]

{ #category : 'private - warnings' }
MCPToolMutation >> errorResultForRefactoringWarning: aWarning action: action requestedContext: requestedContext [

	^ self
		  errorResultForCommandError: (self
				   normalizedCommandErrorForRefactoringWarning: aWarning
				   action: action
				   requestedContext: requestedContext)
		  action: action
		  requestedContext: requestedContext
]

{ #category : 'private - execution' }
MCPToolMutation >> executeActionBlock: actionBlock force: forceRequested action: action requestedContext: requestedContext [

	| warningMessages |
	warningMessages := OrderedCollection new.
	[ actionBlock value ]
		on: RBRefactoringWarning
		do: [ :warning |
				| impactMessages |
				impactMessages := self impactMessagesForRefactoringWarning:
					                  warning.
				forceRequested
					ifTrue: [
							warningMessages addAll: impactMessages.
							warning resume: true ]
					ifFalse: [
							^ { (#stoppedResult -> (self
								    errorResultForRefactoringWarning: warning
								    action: action
								    requestedContext: requestedContext)) } asDictionary ] ].
	^ { (#warnings -> warningMessages asArray) } asDictionary
]

{ #category : 'private - execution' }
MCPToolMutation >> executeMutationAction: action force: forceRequested requestedContext: requestedContext work: actionBlock successResult: successBlock failureSummary: failureSummaryBlock [

	| executionOutcome |
	^ [
		  executionOutcome := self
			                      executeActionBlock: actionBlock
			                      force: forceRequested
			                      action: action
			                      requestedContext: requestedContext.
		  (executionOutcome includesKey: #stoppedResult) ifTrue: [
			  ^ executionOutcome at: #stoppedResult ].
		  successBlock value: (executionOutcome at: #warnings) ]
		  on: Exception
		  do: [ :error |
				  self
					  errorResultForActionFailure: error
					  action: action
					  requestedContext: requestedContext
					  summary: (failureSummaryBlock value: error) ]
]

{ #category : 'executing' }
MCPToolMutation >> executeWithRequest: request [

	^ self
		  executeParsedRequestFrom: request
		  do: [ :mutationRequest |
		  (self commandForRequest: mutationRequest) execute ]
		  onError: [ :error :mutationRequest |
				  | action requestedContext |
				  action := self
					            mutationActionForErrorFromParsedRequest: mutationRequest
					            rawRequest: request.
				  requestedContext := self
					                      requestedContextForErrorFromParsedRequest:
					                      mutationRequest
					                      rawRequest: request.
				  error
					  mcpCommandErrorDo: [ :commandError |
							  self
								  errorResultForCommandError: commandError
								  action: action
								  requestedContext: requestedContext ]
					  otherwise: [ :actionError |
							  self
								  errorResultForActionFailure: actionError
								  action: action
								  requestedContext: requestedContext
								  summary: (actionError messageText
										   ifNil: [ actionError asString ]
										   ifNotNil: [ :text | text ]) ] ]
]

{ #category : 'private - errors' }
MCPToolMutation >> failureErrorCodeFor: anError action: action [

	| cause prefix |
	cause := self mutationFailureCauseFor: anError.
	prefix := self actionErrorCodePrefixFor: action.
	(self undeclaredVariableNodeFrom: cause) ifNotNil: [
		^ prefix , 'UndeclaredVariable' ].
	^ prefix , cause mcpMutationFailureErrorCodeSuffix
]

{ #category : 'private - request' }
MCPToolMutation >> forceFromRequest: request [

	^ request booleanArgumentNamed: 'force' default: false
]

{ #category : 'private - schema' }
MCPToolMutation >> forceSchemaProperty [

	^ self
		  booleanSchemaPropertyNamed: 'force'
		  description:
		  'Resume through refactoring warnings instead of stopping.'
		  default: false
]

{ #category : 'private - refactoring' }
MCPToolMutation >> hierarchyRefactoringEnvironmentForClassNames: classNames baseEnvironment: baseEnvironment [

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
MCPToolMutation >> howToProceedForRefactoringWarning [

	^ 'Review impactMessages, then rerun the same request with force=true to continue despite these warnings.'
]

{ #category : 'private - warnings' }
MCPToolMutation >> impactMessageForRefactoringCondition: aCondition [

	| message |
	message := String streamContents: [ :stream |
		aCondition violationMessageOn: stream ].
	^ self normalizedRefactoringConditionMessage:
		(self normalizedSingleLineText: message)
]

{ #category : 'private - warnings' }
MCPToolMutation >> impactMessagesForRefactoringWarning: aWarning [

	| failedPreconditions impactMessages primaryMessage |
	impactMessages := OrderedCollection new.
	failedPreconditions := aWarning failedPreconditions.
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
MCPToolMutation >> methodNodeFromError: anError [

	^ anError mcpMethodNode
]

{ #category : 'private - errors' }
MCPToolMutation >> mutationActionForErrorFromParsedRequest: mutationRequest rawRequest: rawRequest [

	^ 'mutation'
]

{ #category : 'private - errors' }
MCPToolMutation >> mutationFailureCauseFor: anError [

	(PharoCompatibility
		 noticeFromException: anError
		 ifKindOfAnyNamed:
			 #( OCUndeclaredVariableNotice OCUndeclaredVariableWarning
			    OCSyntaxErrorNotice RBSyntaxErrorNotice SyntaxErrorNotification ))
		ifNotNil: [ :notice | ^ notice ].
	^ anError mcpMutationFailureNotice
]

{ #category : 'private - errors' }
MCPToolMutation >> normalizedCauseMessageForMutationError: anError [

	| cause descriptionText message |
	cause := self mutationFailureCauseFor: anError.
	(self undeclaredVariableNodeFrom: cause) ifNotNil: [
		^ self undeclaredVariableCauseMessageFor: cause ].
	message := cause messageText.
	message ifNil: [ message := '' ].
	message := message asString.
	message isEmpty ifFalse: [ ^ message ].
	descriptionText := cause description.
	descriptionText ifNotNil: [
			descriptionText := descriptionText asString.
			descriptionText isEmpty ifFalse: [ ^ descriptionText ] ].
	^ cause class name asString
]

{ #category : 'private - errors' }
MCPToolMutation >> normalizedCommandErrorForActionFailure: anError action: action requestedContext: requestedContext summary: summary [

	| details normalizedSummary |
	normalizedSummary := summary
		                     ifNil: [ String new ]
		                     ifNotNil: [ summary asString ].
	details := self
		           errorDetailsForRequestedContext: requestedContext
		           causedBy: anError.
	self addSupplementalDetailsForMutationError: anError to: details.
	^ MCPCommandError new
		  errorCode:
			  (self failureErrorCodeFor: anError action: action);
		  details: details;
		  messageText: normalizedSummary;
		  yourself
]

{ #category : 'private - warnings' }
MCPToolMutation >> normalizedCommandErrorForRefactoringWarning: aWarning action: action requestedContext: requestedContext [

	| details impactMessages summary |
	impactMessages := self impactMessagesForRefactoringWarning: aWarning.
	summary := self
		           refactoringWarningSummaryFor: aWarning
		           action: action
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
			  (self failureErrorCodeFor: aWarning action: action);
		  details: details;
		  messageText: summary;
		  yourself
]

{ #category : 'private - warnings' }
MCPToolMutation >> normalizedRefactoringConditionMessage: aString [

	(aString beginsWith: 'NOT ') ifTrue: [
		^ (aString allButFirst: 4) trimBoth ].
	^ aString
]

{ #category : 'private - warnings' }
MCPToolMutation >> normalizedSingleLineText: aString [

	| text |
	text := aString ifNil: [ '' ] ifNotNil: [ aString asString ].
	text := text copyReplaceAll: '<n>' with: ' '.
	text := text copyReplaceAll: String cr with: ' '.
	text := text copyReplaceAll: String lf with: ' '.
	[ text includesSubstring: '  ' ] whileTrue: [
		text := text copyReplaceAll: '  ' with: ' ' ].
	^ text trimBoth
]

{ #category : 'private - request' }
MCPToolMutation >> parsedRequestFromToolRequest: request [

	self subclassResponsibility
]

{ #category : 'private - errors' }
MCPToolMutation >> positionFromError: anError [

	^ anError mcpErrorPosition
]

{ #category : 'private - refactoring' }
MCPToolMutation >> refactoringEnvironmentForScopeSpec: scopeSpec [

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
MCPToolMutation >> refactoringModelForScopeSpec: scopeSpec anchoredAtBehavior: aBehavior [

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
MCPToolMutation >> refactoringScopeClassNamesSchemaProperty [

	^ self
		  stringArraySchemaNamed: 'classNames'
		  description:
		  'Refactoring scope exact classes; target class must be included.'
		  itemDescription: 'Class name.'
]

{ #category : 'private - schema' }
MCPToolMutation >> refactoringScopeHierarchyClassNamesSchemaProperty [

	^ self
		  stringArraySchemaNamed: 'hierarchyClassNames'
		  description:
		  'Refactoring scope hierarchies; target class must be included.'
		  itemDescription: 'Hierarchy root class.'
]

{ #category : 'private - schema' }
MCPToolMutation >> refactoringScopePackageNamesSchemaProperty [

	^ self
		  stringArraySchemaNamed: 'packageNames'
		  description:
		  'Refactoring scope packages; target class must be included.'
		  itemDescription: 'Package name.'
]

{ #category : 'private - request' }
MCPToolMutation >> refactoringScopeSpecFromRequest: request [

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
MCPToolMutation >> refactoringWarningSummaryFor: aWarning action: action requestedContext: requestedContext impactMessages: impactMessages [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Refactoring warning for ';
				  nextPutAll: action;
				  nextPutAll:
					  (self targetDescriptionForRequestedContext: requestedContext).
			  impactMessages isEmpty ifFalse: [
					  stream
						  nextPutAll: ': ';
						  nextPutAll: impactMessages first ].
			  stream
				  nextPutAll: ' ';
				  nextPutAll: self howToProceedForRefactoringWarning ]
]

{ #category : 'private - errors' }
MCPToolMutation >> requestedContextForErrorFromParsedRequest: mutationRequest rawRequest: rawRequest [

	mutationRequest ifNil: [ ^ rawRequest asDictionary copy ].
	^ mutationRequest requestedContext
]

{ #category : 'private - request' }
MCPToolMutation >> resolvedRefactoringScopeClassesFrom: classNames [

	^ classNames collect: [ :eachName |
		  MCPImageLookup classNamed: eachName ]
]

{ #category : 'testing' }
MCPToolMutation >> shouldSaveImageAfterSuccessfulExecution [

	^ true
]

{ #category : 'private - errors' }
MCPToolMutation >> startPositionFromNode: aNode [

	^ aNode start
]

{ #category : 'private - warnings' }
MCPToolMutation >> targetDescriptionForRequestedContext: requestedContext [

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

{ #category : 'private - errors' }
MCPToolMutation >> undeclaredVariableCauseMessageFor: anError [

	| variableName |
	variableName := self undeclaredVariableNameFor: anError.
	^ variableName
		  ifNil: [ 'Undeclared variable' ]
		  ifNotNil: [ 'Undeclared variable: ' , variableName ]
]

{ #category : 'private - errors' }
MCPToolMutation >> undeclaredVariableNameFor: anError [

	| node notice |
	node := self undeclaredVariableNodeFrom: anError.
	(self variableNameFromNode: node) ifNotNil: [ :variableName |
		^ variableName ].
	notice := self undeclaredVariableNoticeFrom: anError.
	notice ifNil: [ ^ nil ].
	node := notice mcpNoticeNode.
	^ self variableNameFromNode: node
]

{ #category : 'private - errors' }
MCPToolMutation >> undeclaredVariableNodeFrom: anError [

	^ PharoCompatibility undeclaredVariableNodeFromException: anError
]

{ #category : 'private - errors' }
MCPToolMutation >> undeclaredVariableNoticeFrom: anError [

	(PharoCompatibility
		 noticeFromException: anError
		 ifKindOfAnyNamed:
		 #( OCUndeclaredVariableNotice OCUndeclaredVariableWarning ))
		ifNotNil: [ :notice | ^ notice ].
	(#( 'OCUndeclaredVariableNotice' 'OCUndeclaredVariableWarning' )
		 includes: anError class name asString) ifTrue: [ ^ anError ].
	^ nil
]

{ #category : 'private - refactoring' }
MCPToolMutation >> unionRefactoringEnvironment: currentEnvironment with: addedEnvironment [

	^ currentEnvironment
		  ifNil: [ addedEnvironment ]
		  ifNotNil: [ currentEnvironment | addedEnvironment ]
]

{ #category : 'private - request' }
MCPToolMutation >> validateRefactoringScopePackageNamesExist: packageNames [

	packageNames do: [ :eachName | MCPImageLookup packageNamed: eachName ]
]

{ #category : 'private - errors' }
MCPToolMutation >> variableNameFromNode: aNode [

	aNode ifNil: [ ^ nil ].
	^ aNode name asString
]
