"
Shared base class for mutating MCP tools.

A concrete tool gives its metadata and its contract in toolSpec. It runs each target of a call through one checked flow: checkArguments: refuses what the schema cannot, then mutateWith: makes the change and answers the result. An error raised before the check echoes the arguments as the caller wrote them; one raised after reports them as the tool read them, through requestedContextFor:. mutationActionFor:checked: names the action an error reports.

It also centralizes refactoring warning handling and structured mutation failure reporting.
"
Class {
	#name : 'MCPToolMutation',
	#superclass : 'MCPTool',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'private - errors' }
MCPToolMutation >> actionErrorCodePrefixFor: action [

	action ifNil: [ ^ 'Action' ].
	action isEmpty ifTrue: [ ^ 'Action' ].
	^ action first asUppercase asString , action allButFirst
]

{ #category : 'private - errors' }
MCPToolMutation >> addAction: action to: details [
	"compile, create and update are actions of their own; any other action is a kind of update."

	(#( 'compile' 'create' 'update' ) includes: action)
		ifTrue: [ details at: #action put: action ]
		ifFalse: [
				details
					at: #action put: 'update';
					at: #updateAction put: action ]
]

{ #category : 'private - refactoring' }
MCPToolMutation >> addRefactoringScopeContextFromSpec: scopeSpec toRequestedContext: requestedContext [
	"Each scope entry under the key the schema gives it."

	scopeSpec packageNames ifNotEmpty: [ requestedContext at: #packages put: scopeSpec packageNames ].
	scopeSpec classNames ifNotEmpty: [ requestedContext at: #classes put: scopeSpec classNames ].
	scopeSpec hierarchyClassNames ifNotEmpty: [ requestedContext at: #hierarchyOf put: scopeSpec hierarchyClassNames ]
]

{ #category : 'private - errors' }
MCPToolMutation >> addSupplementalDetailsForMutationError: anError to: details [

	| cause |
	cause := self mutationFailureCauseFor: anError.
	cause mcpMethodNode ifNotNil: [ :methodNode | self addSupplementalSelectorFromMethodNode: methodNode to: details ].
	anError mcpCompilationAst ifNotNil: [ :ast | self addSupplementalSelectorFromMethodNode: ast to: details ].
	anError == cause ifFalse: [
		anError mcpMethodNode ifNotNil: [ :methodNode | self addSupplementalSelectorFromMethodNode: methodNode to: details ] ].
	cause mcpErrorPosition ifNotNil: [ :position | details at: #position put: position ].
	cause mcpNoticeNode ifNotNil: [ :node |
			details at: #variableName put: node name asString.
			node start ifNotNil: [ :start | details at: #position put: start ] ].
	(self readOnlyAssignmentNodesFrom: cause) ifNotEmpty: [ :nodes |
			details at: #variableName put: nodes first variable name asString.
			details at: #position put: nodes first start ]
]

{ #category : 'private - errors' }
MCPToolMutation >> addSupplementalSelectorFromMethodNode: methodNode to: details [

	| selector |
	selector := methodNode selector.
	selector ifNotNil: [ details at: #selector ifAbsentPut: [ selector asString ] ]
]

{ #category : 'private - specs' }
MCPToolMutation >> atLeastOneInputProperties [
	"Properties of which a request must carry at least one. Empty means no such constraint."

	^ self toolSpec at: #atLeastOneProperties ifAbsent: [ #(  ) ]
]

{ #category : 'metadata' }
MCPToolMutation >> buildInputSchema [

	^ MCPStructureInputSchema properties: self inputProperties required: self requiredInputProperties
]

{ #category : 'private - execution' }
MCPToolMutation >> checkArguments: request [
	"Refuse, before anything changes, what the arguments ask that the schema cannot refuse."

	self subclassResponsibility
]

{ #category : 'private - refactoring' }
MCPToolMutation >> classesRefactoringEnvironmentForClassNames: classNames baseEnvironment: baseEnvironment [

	^ baseEnvironment forClasses: (self resolvedRefactoringScopeClassesFrom: classNames inScope: 'scope.classes')
]

{ #category : 'metadata' }
MCPToolMutation >> description [

	^ self toolSpec at: #description
]

{ #category : 'private - errors' }
MCPToolMutation >> errorDetailsForRequestedContext: requestedContext causedBy: anError [

	| cause details |
	cause := self mutationFailureCauseFor: anError.
	details := requestedContext ifNil: [ Dictionary new ] ifNotNil: [ requestedContext copy ].
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

{ #category : 'error handling' }
MCPToolMutation >> errorResultForCommandError: anError action: action requestedContext: requestedContext [

	| details |
	details := anError structuredDetails copy.
	requestedContext ifNotNil: [
		requestedContext keysAndValuesDo: [ :key :value | value ifNotNil: [ details at: key ifAbsentPut: [ value ] ] ] ].
	self addAction: action to: details.
	^ self errorResultText: anError messageText details: details
]

{ #category : 'error handling' }
MCPToolMutation >> errorResultForRefactoringWarning: aWarning action: action requestedContext: requestedContext [

	^ self
		  errorResultForCommandError:
		  (self normalizedCommandErrorForRefactoringWarning: aWarning action: action requestedContext: requestedContext)
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
				impactMessages := self impactMessagesForRefactoringWarning: warning action: action requestedContext: requestedContext.
				forceRequested
					ifTrue: [
							warningMessages addAll: impactMessages.
							warning resume: true ]
					ifFalse: [
							^ { (#stoppedResult -> (self errorResultForRefactoringWarning: warning action: action requestedContext: requestedContext)) }
								  asDictionary ] ].
	^ { (#warnings -> warningMessages asArray) } asDictionary
]

{ #category : 'private - execution' }
MCPToolMutation >> executeMutationAction: action force: forceRequested requestedContext: requestedContext work: actionBlock successResult: successBlock failureSummary: failureSummaryBlock [
	"Pharo and its refactorings notify partway through a change, and a notification is no failure: it is resumed as at the boundary of the call, before the handler here would answer it as one with part of the change made. A warning so resumed is one the change went past, as a load goes past what it cannot load, so the answer says what it warned of, whether the change then succeeds or not."

	| resumedWarnings result |
	resumedWarnings := OrderedCollection new.
	result := [
		          self resumingNotificationsDuring: [
				          | executionOutcome |
				          executionOutcome := [
					                              self
						                              executeActionBlock: actionBlock
						                              force: forceRequested
						                              action: action
						                              requestedContext: requestedContext ]
					                              on: Warning
					                              do: [ :warning |
							                              resumedWarnings addIfNotPresent: (MCPRefactoringText singleLine: warning messageText).
							                              warning pass ].
				          executionOutcome at: #stoppedResult ifAbsent: [ successBlock value: (executionOutcome at: #warnings) ] ] ]
		          on: Exception
		          do: [ :error |
				          self
					          errorResultForActionFailure: error
					          action: action
					          requestedContext: requestedContext
					          summary: (failureSummaryBlock value: error) ].
	^ self result: result addingWarnings: resumedWarnings
]

{ #category : 'executing' }
MCPToolMutation >> executeWithRequest: request [
	"Each target is checked, then changed. An error raised before its arguments are checked echoes them as the caller wrote them."

	^ self executeBatchedRequest: request do: [ :targetRequest |
			  | checked |
			  checked := false.
			  self
				  executeRequest: targetRequest
				  do: [
						  self checkArguments: targetRequest.
						  checked := true.
						  self mutateWith: targetRequest ]
				  onError: [ :error |
						  | action requestedContext |
						  action := self mutationActionFor: targetRequest checked: checked.
						  requestedContext := self requestedContextFor: targetRequest checked: checked.
						  error
							  mcpCommandErrorDo: [ :commandError |
							  self errorResultForCommandError: commandError action: action requestedContext: requestedContext ]
							  otherwise: [ :actionError |
									  self
										  errorResultForActionFailure: actionError
										  action: action
										  requestedContext: requestedContext
										  summary: actionError mcpMessageText ] ] ]
]

{ #category : 'private - errors' }
MCPToolMutation >> failureErrorCodeFor: anError action: action [

	^ (self actionErrorCodePrefixFor: action) , (self failureErrorCodeSuffixFor: (self mutationFailureCauseFor: anError))
]

{ #category : 'private - errors' }
MCPToolMutation >> failureMessage: aPhrase error: anError [
	"Unable to rename class Foo to Bar: and what caused the failure."

	^ String streamContents: [ :stream | stream << aPhrase << ': ' << (self normalizedCauseMessageForMutationError: anError) ]
]

{ #category : 'private - schema' }
MCPToolMutation >> forceSchemaProperty [

	^ self
		  booleanSchemaPropertyNamed: 'force'
		  description: 'Continue through refactoring warnings instead of stopping.'
		  default: false
]

{ #category : 'private - refactoring' }
MCPToolMutation >> hierarchyRefactoringEnvironmentForClassNames: classNames baseEnvironment: baseEnvironment [

	| environment resolvedClasses |
	resolvedClasses := self resolvedRefactoringScopeClassesFrom: classNames inScope: 'scope.hierarchyOf'.
	environment := nil.
	resolvedClasses do: [ :eachClass |
		environment := self unionRefactoringEnvironment: environment with: (baseEnvironment forClassHierarchy: eachClass) ].
	^ environment
]

{ #category : 'private - warnings' }
MCPToolMutation >> howToProceedForRefactoringWarning [

	^ 'Rerun the same request with force: true to proceed anyway.'
]

{ #category : 'private - warnings' }
MCPToolMutation >> impactMessageForRefactoringCondition: aCondition [

	| message |
	message := String streamContents: [ :stream | aCondition violationMessageOn: stream ].
	^ MCPRefactoringText conditionText: message
]

{ #category : 'private - warnings' }
MCPToolMutation >> impactMessagesForRefactoringWarning: aWarning [

	| failedPreconditions impactMessages primaryMessage |
	impactMessages := OrderedCollection new.
	failedPreconditions := aWarning mcpFailedPreconditions.
	failedPreconditions ifNotNil: [
			failedPreconditions do: [ :each |
					| message |
					message := self impactMessageForRefactoringCondition: each.
					message isEmpty ifFalse: [ impactMessages add: message ] ] ].
	impactMessages ifEmpty: [
			primaryMessage := MCPRefactoringText singleLine: aWarning messageText.
			primaryMessage isEmpty ifTrue: [ primaryMessage := aWarning class name asString ].
			impactMessages add: primaryMessage ].
	^ impactMessages asArray
]

{ #category : 'private - warnings' }
MCPToolMutation >> impactMessagesForRefactoringWarning: aWarning action: action requestedContext: requestedContext [
	"What the change a warning stopped would break, as the warning says it. A tool that knows better for one of its actions says it instead."

	^ self impactMessagesForRefactoringWarning: aWarning
]

{ #category : 'private - schema' }
MCPToolMutation >> inputProperties [

	^ self toolSpec at: #inputProperties
]

{ #category : 'private' }
MCPToolMutation >> isPackageNamed: aName inTheProjectOf: anotherName [
	"Whether two packages, by their names, are of one project, by the convention that names a project's packages with its name and then a dash, as MCP, MCP-IDE and MCP-Tests. A class of another project, as one of Pharo's own, is not the caller's to change. Code in no package, whose package name is nil, is of no project. Names rather than packages, since the package a call names may not exist yet."

	^ aName isNotNil and: [ anotherName isNotNil and: [ (aName asString copyUpTo: $-) = (anotherName asString copyUpTo: $-) ] ]
]

{ #category : 'private - execution' }
MCPToolMutation >> mutateWith: request [
	"Make the change the checked arguments ask for, and answer the tool result."

	self subclassResponsibility
]

{ #category : 'private - errors' }
MCPToolMutation >> mutationActionFor: request checked: aBoolean [
	"The action an error names."

	^ self toolSpec at: #action
]

{ #category : 'private - mutation failures' }
MCPToolMutation >> mutationFailureCauseFor: anError [

	^ anError mcpSyntaxNotice ifNil: [ anError ]
]

{ #category : 'private - errors' }
MCPToolMutation >> normalizedCauseMessageForMutationError: anError [

	| cause descriptionText message |
	cause := self mutationFailureCauseFor: anError.
	(self undeclaredVariableNameFor: cause) ifNotNil: [ :name | ^ 'Undeclared variable: ' , name ].
	(self readOnlyAssignmentCauseMessageFor: cause) ifNotNil: [ :readOnlyMessage | ^ readOnlyMessage ].
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

{ #category : 'error handling' }
MCPToolMutation >> normalizedCommandErrorForActionFailure: anError action: action requestedContext: requestedContext summary: summary [

	| details normalizedSummary |
	normalizedSummary := summary ifNil: [ String new ] ifNotNil: [ summary asString ].
	details := self errorDetailsForRequestedContext: requestedContext causedBy: anError.
	self addSupplementalDetailsForMutationError: anError to: details.
	^ MCPCommandError new
		  errorCode: (self failureErrorCodeFor: anError action: action);
		  details: details;
		  messageText: normalizedSummary;
		  yourself
]

{ #category : 'private - warnings' }
MCPToolMutation >> normalizedCommandErrorForRefactoringWarning: aWarning action: action requestedContext: requestedContext [

	| details impactMessages summary |
	impactMessages := self impactMessagesForRefactoringWarning: aWarning action: action requestedContext: requestedContext.
	summary := self refactoringWarningSummaryForAction: action requestedContext: requestedContext impactMessages: impactMessages.
	details := self errorDetailsForRequestedContext: requestedContext causedBy: aWarning.
	details at: #impactMessages put: impactMessages.
	details at: #howToProceed put: self howToProceedForRefactoringWarning.
	details at: #forceSupported put: true.
	^ MCPCommandError new
		  errorCode: (self failureErrorCodeFor: aWarning action: action);
		  details: details;
		  messageText: summary;
		  yourself
]

{ #category : 'private - errors' }
MCPToolMutation >> printReadOnlyAssignmentOf: aVariable on: aStream [

	aStream
		nextPutAll: 'Cannot assign to ';
		nextPutAll: aVariable name;
		nextPutAll: ': '.
	aVariable isArgumentVariable ifTrue: [
		^ aStream nextPutAll:
			  'it is an argument, and arguments are read-only. Assign its value to a temporary variable and change that.' ].
	aVariable isPseudoVariable ifTrue: [ ^ aStream nextPutAll: 'it is a pseudo-variable.' ].
	aStream nextPutAll: 'it is read-only.'
]

{ #category : 'private - errors' }
MCPToolMutation >> readOnlyAssignmentCauseMessageFor: anError [

	| nodes variables |
	nodes := self readOnlyAssignmentNodesFrom: anError.
	nodes ifEmpty: [ ^ nil ].
	variables := OrderedCollection new.
	nodes do: [ :each | variables addIfNotPresent: each variable variable ].
	^ String streamContents: [ :stream |
		  variables do: [ :variable | self printReadOnlyAssignmentOf: variable on: stream ] separatedBy: [ stream space ] ]
]

{ #category : 'private - refactoring' }
MCPToolMutation >> refactoringEnvironmentForScopeSpec: scopeSpec [

	| baseEnvironment environment |
	baseEnvironment := RBBrowserEnvironment new.
	scopeSpec isDefaultImageScope ifTrue: [ ^ baseEnvironment ].
	environment := nil.
	scopeSpec packageNames ifNotEmpty: [
		environment := self unionRefactoringEnvironment: environment with: (baseEnvironment forPackageNames: scopeSpec packageNames) ].
	scopeSpec classNames ifNotEmpty: [
			environment := self
				               unionRefactoringEnvironment: environment
				               with: (self classesRefactoringEnvironmentForClassNames: scopeSpec classNames baseEnvironment: baseEnvironment) ].
	scopeSpec hierarchyClassNames ifNotEmpty: [
			environment := self
				               unionRefactoringEnvironment: environment
				               with:
				               (self
					                hierarchyRefactoringEnvironmentForClassNames: scopeSpec hierarchyClassNames
					                baseEnvironment: baseEnvironment) ].
	^ environment ifNil: [ baseEnvironment ]
]

{ #category : 'private - refactoring' }
MCPToolMutation >> refactoringEnvironmentForScopeSpec: scopeSpec anchoredAtBehavior: aBehavior [

	| details environment |
	environment := self refactoringEnvironmentForScopeSpec: scopeSpec.
	(environment includesClass: aBehavior) ifFalse: [
			details := scopeSpec asDictionary copy.
			details at: #class put: aBehavior instanceSide name asString.
			aBehavior isMeta ifTrue: [ details at: #side put: 'class' ].
			MCPCommandError
				signalErrorCode: #RefactoringScopeExcludesTargetClass
				message: (String streamContents: [ :stream |
							 stream << 'Refactoring scope does not include ' << (aBehavior isMeta
								  ifTrue: [ 'the class side of ' ]
								  ifFalse: [ 'class ' ]) << aBehavior instanceSide name asString << '.' ])
				details: details ].
	^ environment
]

{ #category : 'private - request' }
MCPToolMutation >> refactoringScopeSpecFromRequest: request [
	"The scope object the sweeping tools take, with the entries a refactoring environment reads: packages, classes and hierarchies."

	| classNames hierarchyClassNames packageNames |
	packageNames := self searchScopeStringCollectionNamed: 'packages' fromRequest: request.
	classNames := self searchScopeStringCollectionNamed: 'classes' fromRequest: request.
	hierarchyClassNames := self searchScopeStringCollectionNamed: 'hierarchyOf' fromRequest: request.
	self validateRefactoringScopePackageNamesExist: packageNames.
	^ MCPRefactoringScopeSpec packageNames: packageNames classNames: classNames hierarchyClassNames: hierarchyClassNames
]

{ #category : 'private - warnings' }
MCPToolMutation >> refactoringWarningSummaryForAction: action requestedContext: requestedContext impactMessages: impactMessages [
	"Refactoring warning for pullUpSlot on X slot y: <impact>; <impact>. Rerun with force: true to proceed anyway. Every impact is named, since a client reading text sees nothing else of them; one that ends on a question keeps its question mark."

	| sentence |
	sentence := String streamContents: [ :stream |
			            stream
				            nextPutAll: 'Refactoring warning for ';
				            nextPutAll: action;
				            nextPutAll: (self targetDescriptionForRequestedContext: requestedContext).
			            impactMessages isEmpty ifFalse: [
					            stream nextPutAll: ': '.
					            impactMessages
						            do: [ :each | stream nextPutAll: (self textWithoutFinalPeriod: each trimRight) ]
						            separatedBy: [ stream nextPutAll: '; ' ] ] ].
	^ String streamContents: [ :stream |
			  stream nextPutAll: sentence.
			  ('?!' includes: sentence last) ifFalse: [ stream nextPut: $. ].
			  stream nextPutAll: ' Rerun with force: true to proceed anyway.' ]
]

{ #category : 'private - errors' }
MCPToolMutation >> requestedContextFor: request [
	"The arguments as the tool read them, for the details of an error raised once they were checked."

	self subclassResponsibility
]

{ #category : 'private - errors' }
MCPToolMutation >> requestedContextFor: request checked: aBoolean [
	"What an error echoes of the call: its arguments as the caller wrote them until they are checked, then as the tool read them."

	aBoolean ifFalse: [ ^ request asDictionary copy ].
	^ self requestedContextFor: request
]

{ #category : 'private - schema' }
MCPToolMutation >> requiredInputProperties [

	^ self toolSpec at: #requiredProperties
]

{ #category : 'private - request' }
MCPToolMutation >> resolvedRefactoringScopeClassesFrom: classNames inScope: aScopeKey [
	"A refactoring scope must be complete: an entry that names no class refuses the call, under its key as the schema spells it."

	^ classNames collect: [ :eachName | MCPImageLookup classNamed: eachName inScope: aScopeKey ]
]

{ #category : 'private - warnings' }
MCPToolMutation >> result: aResult addingWarnings: someWarnings [
	"aResult, saying after its own warnings what someWarnings say."

	| structuredContent |
	someWarnings ifEmpty: [ ^ aResult ].
	structuredContent := aResult structuredContent copy.
	structuredContent at: #warnings put: (structuredContent at: #warnings ifAbsent: [ #(  ) ]) , someWarnings asArray.
	^ aResult
		  content: { (self textContent: (self contentTextForStructuredContent: structuredContent)) };
		  structuredContent: structuredContent;
		  yourself
]

{ #category : 'private - warnings' }
MCPToolMutation >> targetDescriptionForRequestedContext: requestedContext [

	| className selector slotName |
	requestedContext ifNil: [ ^ '' ].
	className := requestedContext at: #class ifAbsent: [ nil ].
	selector := requestedContext at: #selector ifAbsent: [ nil ].
	slotName := requestedContext at: #slot ifAbsent: [ nil ].
	(className isNil and: [ selector isNil and: [ slotName isNil ] ]) ifTrue: [ ^ '' ].
	^ String streamContents: [ :stream |
			  className ifNotNil: [
					  stream
						  nextPutAll: ' on ';
						  nextPutAll: className ].
			  selector ifNotNil: [
					  className ifNil: [ stream nextPutAll: ' for selector ' ] ifNotNil: [ stream nextPutAll: '>>' ].
					  stream nextPutAll: selector ].
			  slotName ifNotNil: [
					  stream
						  nextPutAll: ' slot ';
						  nextPutAll: slotName ] ]
]

{ #category : 'metadata' }
MCPToolMutation >> title [

	^ self toolSpec at: #title
]

{ #category : 'private - specs' }
MCPToolMutation >> toolSpec [
	"The tool's metadata and contract, by key: title, description, the action an error names, inputProperties, requiredProperties, and atLeastOneProperties when a call must carry one of them."

	self subclassResponsibility
]

{ #category : 'private - errors' }
MCPToolMutation >> undeclaredVariableNameFor: anError [

	^ anError mcpNoticeNode ifNotNil: [ :node | node name asString ]
]

{ #category : 'private - refactoring' }
MCPToolMutation >> unionRefactoringEnvironment: currentEnvironment with: addedEnvironment [

	^ currentEnvironment ifNil: [ addedEnvironment ] ifNotNil: [ currentEnvironment | addedEnvironment ]
]

{ #category : 'validating' }
MCPToolMutation >> validateAtLeastOneInputPropertyIn: request [

	| propertyNames requiredName |
	propertyNames := self atLeastOneInputProperties.
	propertyNames ifEmpty: [ ^ self ].
	(propertyNames anySatisfy: [ :each | request hasArgumentNamed: each ]) ifTrue: [ ^ self ].
	requiredName := String streamContents: [ :stream |
		                propertyNames do: [ :each | stream nextPutAll: each ] separatedBy: [ stream nextPutAll: ' or ' ] ].
	MCPInvalidToolInput signalMissingRequiredArgumentNamed: requiredName forTool: self
]

{ #category : 'private - request' }
MCPToolMutation >> validateRefactoringScopePackageNamesExist: packageNames [

	packageNames do: [ :eachName | MCPImageLookup packageNamed: eachName inScope: 'scope.packages' ]
]

{ #category : 'validating' }
MCPToolMutation >> validateRequest: request [
	"A mutation names at least one of the properties its tool lists as such, beyond the required ones."

	super validateRequest: request.
	self validateAtLeastOneInputPropertyIn: request
]
