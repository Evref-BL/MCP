"
Tool that changes one class definition: any of its name, superclass, package, tag, comment, slots, traits, shared variables, shared pools and layout, in one call.

Every change asked for is planned as an MCPClassUpdatePlanInfo before the first is made. The plans are then applied in dependency order, stopping at the first that fails.
"
Class {
	#name : 'MCPToolUpdateClass',
	#superclass : 'MCPToolClassMutation',
	#traits : 'TMCPSequencedUpdate',
	#classTraits : 'TMCPSequencedUpdate classTrait',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolUpdateClass class >> toolName [

	^ 'class_update'
]

{ #category : 'private - planning' }
MCPToolUpdateClass >> actionApplicationOrder [
	"Changes to one class are not independent, so the caller does not choose their order. The superclass goes first because it decides what everything after it validates against; slots are added before anything can refer to them and removed last, after any move that needed them; the name goes last because every other change resolves the class by the name the caller wrote."

	^ #( 'reparent' 'replaceLayout' 'replaceDefinition' 'addSlot' 'renameSlot' 'pullUpSlot' 'pushDownSlot' 'removeSlot' 'replaceTraits'
	     'replaceSharedVariables' 'replaceSharedPools' 'setComment' 'move' 'rename' )
]

{ #category : 'private - planning' }
MCPToolUpdateClass >> actionsInApplicationOrder: plans [
	"Order by what each plan does, keeping plans that do the same thing in the order they were asked for."

	| order |
	order := self actionApplicationOrder.
	^ ((plans asArray withIndexCollect: [ :plan :index |
			    {
				    (order indexOf: plan updateAction).
				    index.
				    plan } ]) sorted: [ :left :right |
			   left first = right first
				   ifTrue: [ (left at: 2) <= (right at: 2) ]
				   ifFalse: [ left first < right first ] ]) collect: [ :each | each last ]
]

{ #category : 'private - specs' }
MCPToolUpdateClass >> additionalKeywords [
	"This tool answers for everything the per-property update tools used to, so it has to be findable by the words that led to each of them."

	^ super additionalKeywords
	  , #( 'rename' 'superclass' 'reparent' 'package' 'tag' 'recategorize' 'comment' 'slot' 'definition' 'trait' 'side' 'metaclass'
		     'composition' 'variable' 'shared' 'classvar' 'binding' 'pool' 'pooldictionary' 'dictionary' 'layout' 'shape' 'format'
		     'fixed' 'weak' 'immediate' 'word' 'byte' )
]

{ #category : 'private - execution' }
MCPToolUpdateClass >> apply: plan force: aBoolean work: workBlock summary: summaryBlock failureSummary: failureSummaryBlock [
	"Make one planned change. Its answer carries no data, so that several changes in one call each add only their action. summaryBlock receives what workBlock answered."

	| outcome |
	^ self
		  executeMutationAction: plan updateAction
		  force: aBoolean
		  requestedContext: plan requestedContext
		  work: [ outcome := workBlock value ]
		  successResult: [ :warningMessages |
		  self successResultText: (summaryBlock value: outcome) data: Dictionary new warnings: warningMessages ]
		  failureSummary: failureSummaryBlock
]

{ #category : 'private - execution' }
MCPToolUpdateClass >> applyUpdate: plan of: request [

	| actionBlock |
	actionBlock := self executeBlockForAction: plan updateAction.
	actionBlock ifNotNil: [ ^ actionBlock value: plan value: request ].
	^ self
		  errorResultForCommandError: (MCPCommandError new
				   errorCode: #UnknownClassUpdateAction;
				   messageText: 'Unknown class update action: ' , plan updateAction;
				   details: plan requestedContext;
				   yourself)
		  action: 'update'
		  requestedContext: plan requestedContext
]

{ #category : 'private - arguments' }
MCPToolUpdateClass >> checkArguments: request [
	"Foo class is refused before anything is planned: read as Foo, it would change the class instead of its class side."

	MCPImageLookup wholeClassName: (request stringArgumentNamed: 'name') for: 'class_update'
]

{ #category : 'private - specs' }
MCPToolUpdateClass >> classToolSpec [

	^ {
		  (#title -> 'Update Class').
		  (#description
		   ->
		   'Change one class definition in one call. Its name, superclass, package, tag, comment and layout are replaced by value, its slots are patched. The changes asked for are applied in dependency order, stopping at the first that fails.').
		  (#inputProperties -> {
			   self classNameSchemaProperty.
			   self renameNewClassNameSchemaProperty.
			   self superclassNameSchemaProperty.
			   self packageNameSchemaProperty.
			   self tagSchemaProperty.
			   self commentSchemaProperty.
			   (self slotDeltaSchemaPropertyNamed: 'slots' describedAs: 'Patch over the instance-side slots.').
			   (self slotDeltaSchemaPropertyNamed: 'classSlots' describedAs: 'Patch over the class-side slots.').
			   self traitsSchemaProperty.
			   self sharedVariablesSchemaProperty.
			   self sharedPoolsSchemaProperty.
			   self layoutSchemaProperty.
			   self forceSchemaProperty }).
		  (#requiredProperties -> #( 'name' )).
		  (#atLeastOneProperties
		   ->
		   #( 'newName' 'superclass' 'package' 'tag' 'comment' 'slots' 'classSlots' 'traits' 'sharedVariables' 'sharedPools'
		      'layout' )) } asDictionary
]

{ #category : 'private - errors' }
MCPToolUpdateClass >> contextValueOf: propertyName in: request [
	"What an error reports for a property the call supplied, as the update reads it: a slot patch reports the parts the caller asked for, and a blank tag or layout reads as empty."

	(#( 'slots' 'classSlots' ) includes: propertyName) ifTrue: [
		^ (MCPSlotDelta fromRequest: request named: propertyName) asContextValue ].
	(#( 'traits' 'sharedVariables' 'sharedPools' ) includes: propertyName) ifTrue: [
		^ request stringCollectionArgumentNamed: propertyName ].
	(#( 'tag' 'layout' ) includes: propertyName) ifTrue: [ ^ request stringArgumentNamed: propertyName default: '' ].
	propertyName = 'comment' ifTrue: [ ^ self classCommentIn: request ].
	^ request stringArgumentNamed: propertyName
]

{ #category : 'metadata' }
MCPToolUpdateClass >> defaultExposure [

	^ 'static'
]

{ #category : 'private - execution' }
MCPToolUpdateClass >> executeAddSlotWithPlan: plan request: request [

	| className |
	className := request stringArgumentNamed: 'name'.
	^ self
		  apply: plan
		  force: false
		  work: [ (MCPAddSlotCommand className: className slotName: plan slotName classSide: plan classSide) execute ]
		  summary: [ :updatedClass |
				  String streamContents: [ :stream |
						  stream << 'Added ' << (self slotDescriptionForClassSide: plan classSide) << ' ' << plan slotName << ' to class '
						  << className << '.' ] ]
		  failureSummary: [ :error |
				  self
					  failureMessageForAddSlotNamed: plan slotName
					  onClassNamed: className
					  classSide: plan classSide
					  error: error ]
]

{ #category : 'private - execution' }
MCPToolUpdateClass >> executeBlockForAction: action [

	^ {
		  ('move' -> [ :plan :request | self executeMoveWithPlan: plan request: request ]).
		  ('rename' -> [ :plan :request | self executeRenameWithPlan: plan request: request ]).
		  ('reparent' -> [ :plan :request | self executeReparentWithPlan: plan request: request ]).
		  ('setComment' -> [ :plan :request | self executeSetCommentWithPlan: plan request: request ]).
		  ('replaceTraits' -> [ :plan :request | self executeReplaceTraitsWithPlan: plan request: request ]).
		  ('replaceSharedVariables' -> [ :plan :request | self executeReplaceSharedVariablesWithPlan: plan request: request ]).
		  ('replaceSharedPools' -> [ :plan :request | self executeReplaceSharedPoolsWithPlan: plan request: request ]).
		  ('replaceLayout' -> [ :plan :request | self executeReplaceLayoutWithPlan: plan request: request ]).
		  ('replaceDefinition' -> [ :plan :request | self executeReplaceDefinitionWithPlan: plan request: request ]).
		  ('addSlot' -> [ :plan :request | self executeAddSlotWithPlan: plan request: request ]).
		  ('removeSlot' -> [ :plan :request | self executeRemoveSlotWithPlan: plan request: request ]).
		  ('renameSlot' -> [ :plan :request | self executeRenameSlotWithPlan: plan request: request ]).
		  ('pullUpSlot' -> [ :plan :request | self executeMoveSlotWithPlan: plan request: request ]).
		  ('pushDownSlot' -> [ :plan :request | self executeMoveSlotWithPlan: plan request: request ]) } asDictionary
		  at: action
		  ifAbsent: [ nil ]
]

{ #category : 'private - execution' }
MCPToolUpdateClass >> executeMoveSlotWithPlan: plan request: request [
	"Pull a slot up or push it down, as the plan says."

	| className |
	className := request stringArgumentNamed: 'name'.
	^ self
		  apply: plan
		  force: (request booleanArgumentNamed: 'force')
		  work: [
				  (MCPMoveSlotCommand
					   className: className
					   slotName: plan slotName
					   direction: plan updateAction
					   classSide: plan classSide) execute ]
		  summary: [ :updatedClass | self moveSlotSummaryFor: plan ofClassNamed: className ]
		  failureSummary: [ :error |
				  self
					  failureMessageForMoveSlotNamed: plan slotName
					  onClassNamed: className
					  classSide: plan classSide
					  operation: plan updateAction
					  error: error ]
]

{ #category : 'private - execution' }
MCPToolUpdateClass >> executeMoveWithPlan: plan request: request [

	| className packageName tag |
	className := request stringArgumentNamed: 'name'.
	packageName := self movePackageNameIn: request.
	tag := request stringArgumentNamed: 'tag'.
	^ self
		  apply: plan
		  force: false
		  work: [ (MCPMoveClassCommand className: className packageName: packageName tag: tag) execute ]
		  summary: [ :movedClass | self moveSummaryForClassInfo: (MCPClassInfo fromClass: movedClass) ]
		  failureSummary: [ :error |
				  self
					  failureMessageForMoveClassNamed: className
					  packageName: packageName
					  tag: tag
					  error: error ]
]

{ #category : 'private - execution' }
MCPToolUpdateClass >> executeRemoveSlotWithPlan: plan request: request [

	| className |
	className := request stringArgumentNamed: 'name'.
	^ self
		  apply: plan
		  force: (request booleanArgumentNamed: 'force')
		  work: [ (MCPRemoveSlotCommand className: className slotName: plan slotName classSide: plan classSide) execute ]
		  summary: [ :updatedClass |
				  String streamContents: [ :stream |
						  stream << 'Removed ' << (self slotDescriptionForClassSide: plan classSide) << ' ' << plan slotName << ' from class '
						  << className << '.' ] ]
		  failureSummary: [ :error |
				  self
					  failureMessageForRemoveSlotNamed: plan slotName
					  onClassNamed: className
					  classSide: plan classSide
					  error: error ]
]

{ #category : 'private - execution' }
MCPToolUpdateClass >> executeRenameSlotWithPlan: plan request: request [

	| className |
	className := request stringArgumentNamed: 'name'.
	^ self
		  apply: plan
		  force: false
		  work: [
				  (MCPRenameSlotCommand
					   className: className
					   slotName: plan slotName
					   newSlotName: plan newSlotName
					   classSide: plan classSide) execute ]
		  summary: [ :updatedClass |
				  String streamContents: [ :stream |
					  stream << 'Renamed slot ' << plan slotName << ' to ' << plan newSlotName << ' in class ' << className << '.' ] ]
		  failureSummary: [ :error |
				  self
					  failureMessageForRenameSlotNamed: plan slotName
					  to: plan newSlotName
					  onClassNamed: className
					  classSide: plan classSide
					  error: error ]
]

{ #category : 'private - execution' }
MCPToolUpdateClass >> executeRenameWithPlan: plan request: request [

	| className newClassName |
	className := request stringArgumentNamed: 'name'.
	newClassName := request stringArgumentNamed: 'newName'.
	^ self
		  apply: plan
		  force: false
		  work: [ (MCPRenameClassCommand className: className newClassName: newClassName) execute ]
		  summary: [ :renamedClass |
		  String streamContents: [ :stream | stream << 'Renamed class ' << className << ' to ' << newClassName << '.' ] ]
		  failureSummary: [ :error | self failureMessageForRenameClassNamed: className to: newClassName error: error ]
]

{ #category : 'private - execution' }
MCPToolUpdateClass >> executeReparentWithPlan: plan request: request [

	| className superclassName |
	className := request stringArgumentNamed: 'name'.
	superclassName := request stringArgumentNamed: 'superclass'.
	^ self
		  apply: plan
		  force: false
		  work: [ (MCPReparentClassCommand className: className superclassName: superclassName) execute ]
		  summary: [ :updatedClass |
			  String streamContents: [ :stream | stream << 'Reparented class ' << className << ' to superclass ' << superclassName << '.' ] ]
		  failureSummary: [ :error | self failureMessageForReparentClassNamed: className superclassName: superclassName error: error ]
]

{ #category : 'private - execution' }
MCPToolUpdateClass >> executeReplaceDefinitionWithPlan: plan request: request [

	| className command |
	className := request stringArgumentNamed: 'name'.
	command := MCPReplaceClassDefinitionCommand
		           className: className
		           slotNames: (self slotReplacementIn: request side: false)
		           classSlotNames: (self slotReplacementIn: request side: true).
	^ self
		  apply: plan
		  force: false
		  work: [ command execute ]
		  summary: [ :updatedClass |
		  String streamContents: [ :stream | stream << 'Replaced slot definition for class ' << className << '.' ] ]
		  failureSummary: [ :error | self failureMessageForReplaceDefinitionOnClassNamed: className error: error ]
]

{ #category : 'private - execution' }
MCPToolUpdateClass >> executeReplaceLayoutWithPlan: plan request: request [

	| className |
	className := request stringArgumentNamed: 'name'.
	^ self
		  apply: plan
		  force: false
		  work: [ (MCPReplaceClassLayoutCommand className: className layout: (request stringArgumentNamed: 'layout')) execute ]
		  summary: [ :updatedClass | String streamContents: [ :stream | stream << 'Replaced layout for class ' << className << '.' ] ]
		  failureSummary: [ :error | self failureMessageForReplaceLayoutOnClassNamed: className error: error ]
]

{ #category : 'private - execution' }
MCPToolUpdateClass >> executeReplaceSharedPoolsWithPlan: plan request: request [

	| className |
	className := request stringArgumentNamed: 'name'.
	^ self
		  apply: plan
		  force: false
		  work: [
				  (MCPReplaceClassSharedPoolsCommand
					   className: className
					   sharedPoolNames: (request stringCollectionArgumentNamed: 'sharedPools')) execute ]
		  summary: [ :updatedClass |
		  String streamContents: [ :stream | stream << 'Replaced shared pools for class ' << className << '.' ] ]
		  failureSummary: [ :error | self failureMessageForReplaceSharedPoolsOnClassNamed: className error: error ]
]

{ #category : 'private - execution' }
MCPToolUpdateClass >> executeReplaceSharedVariablesWithPlan: plan request: request [

	| className |
	className := request stringArgumentNamed: 'name'.
	^ self
		  apply: plan
		  force: false
		  work: [
				  (MCPReplaceClassSharedVariablesCommand
					   className: className
					   sharedVariableNames: (request stringCollectionArgumentNamed: 'sharedVariables')) execute ]
		  summary: [ :updatedClass |
		  String streamContents: [ :stream | stream << 'Replaced shared variables for class ' << className << '.' ] ]
		  failureSummary: [ :error | self failureMessageForReplaceSharedVariablesOnClassNamed: className error: error ]
]

{ #category : 'private - execution' }
MCPToolUpdateClass >> executeReplaceTraitsWithPlan: plan request: request [

	| className |
	className := request stringArgumentNamed: 'name'.
	^ self
		  apply: plan
		  force: false
		  work: [
		  (MCPReplaceClassTraitsCommand className: className traitNames: (request stringCollectionArgumentNamed: 'traits')) execute ]
		  summary: [ :updatedClass | String streamContents: [ :stream | stream << 'Replaced traits for class ' << className << '.' ] ]
		  failureSummary: [ :error | self failureMessageForReplaceTraitsOnClassNamed: className error: error ]
]

{ #category : 'private - execution' }
MCPToolUpdateClass >> executeSetCommentWithPlan: plan request: request [

	| className |
	className := request stringArgumentNamed: 'name'.
	^ self
		  apply: plan
		  force: (request booleanArgumentNamed: 'force')
		  work: [ (MCPChangeClassCommentCommand className: className classComment: (self classCommentIn: request)) execute ]
		  summary: [ :updatedClass | String streamContents: [ :stream | stream << 'Set comment for class ' << className << '.' ] ]
		  failureSummary: [ :error | self failureMessageForSetCommentOnClassNamed: className error: error ]
]

{ #category : 'private - errors' }
MCPToolUpdateClass >> failureMessageForAddSlotNamed: slotName onClassNamed: className classSide: classSide error: anError [

	^ String streamContents: [ :stream |
			  stream << 'Failed to add ' << (self slotDescriptionForClassSide: classSide) << ' ' << slotName << ' to class ' << className
			  << ': ' << (self normalizedCauseMessageForMutationError: anError) ]
]

{ #category : 'private - errors' }
MCPToolUpdateClass >> failureMessageForMoveClassNamed: className packageName: packageName tag: tag error: anError [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Unable to move class ';
				  nextPutAll: className;
				  nextPutAll: ' to package ';
				  nextPutAll: packageName.
			  tag ifNotNil: [
					  stream
						  nextPutAll: ' tag ';
						  nextPutAll: tag ].
			  stream
				  nextPutAll: ': ';
				  nextPutAll: (self normalizedCauseMessageForMutationError: anError) ]
]

{ #category : 'private - errors' }
MCPToolUpdateClass >> failureMessageForMoveSlotNamed: slotName onClassNamed: className classSide: classSide operation: operation error: anError [

	operation = 'pullUpSlot' ifTrue: [
			^ String streamContents: [ :stream |
					  stream << 'Failed to pull up ' << (self slotDescriptionForClassSide: classSide) << ' ' << slotName << ' to class '
					  << className << ': ' << (self normalizedCauseMessageForMutationError: anError) ] ].
	^ String streamContents: [ :stream |
			  stream << 'Failed to push down ' << (self slotDescriptionForClassSide: classSide) << ' ' << slotName << ' from class '
			  << className << ': ' << (self normalizedCauseMessageForMutationError: anError) ]
]

{ #category : 'private - errors' }
MCPToolUpdateClass >> failureMessageForRemoveSlotNamed: slotName onClassNamed: className classSide: classSide error: anError [
	"Before Pharo 12, removing a slot that methods use fails rather than warns, an RBRefactoringError on the instance side and a breaking-change Warning on the class side, whatever force says, and the refactoring's text names none of them: they are named as a warning names them from Pharo 12 on."

	| uses |
	uses := ((anError isKindOf: RBRefactoringError) or: [ anError isKindOf: Warning ])
		        ifTrue: [ self usesOfSlotNamed: slotName inClassNamed: className classSide: classSide ]
		        ifFalse: [ #(  ) ].
	^ String streamContents: [ :stream |
			  stream << 'Failed to remove ' << (self slotDescriptionForClassSide: classSide) << ' ' << slotName << ' from class '
			  << className << ': '.
			  uses ifEmpty: [ stream << (self normalizedCauseMessageForMutationError: anError) ] ifNotEmpty: [
					  uses do: [ :each | stream << each ] separatedBy: [ stream << '; ' ].
					  stream << '. Change them first.' ] ]
]

{ #category : 'private - errors' }
MCPToolUpdateClass >> failureMessageForRenameClassNamed: className to: newClassName error: anError [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Unable to rename class ';
				  nextPutAll: className;
				  nextPutAll: ' to ';
				  nextPutAll: newClassName;
				  nextPutAll: ': ';
				  nextPutAll: (self normalizedCauseMessageForMutationError: anError) ]
]

{ #category : 'private - errors' }
MCPToolUpdateClass >> failureMessageForRenameSlotNamed: slotName to: newSlotName onClassNamed: className classSide: classSide error: anError [

	^ String streamContents: [ :stream |
			  stream << 'Failed to rename ' << (self slotDescriptionForClassSide: classSide) << ' ' << slotName << ' to ' << newSlotName
			  << ' in class ' << className << ': ' << (self normalizedCauseMessageForMutationError: anError) ]
]

{ #category : 'private - errors' }
MCPToolUpdateClass >> failureMessageForReparentClassNamed: className superclassName: superclassName error: anError [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Unable to reparent class ';
				  nextPutAll: className;
				  nextPutAll: ' to superclass ';
				  nextPutAll: superclassName;
				  nextPutAll: ': ';
				  nextPutAll: (self normalizedCauseMessageForMutationError: anError) ]
]

{ #category : 'private - errors' }
MCPToolUpdateClass >> failureMessageForReplaceDefinitionOnClassNamed: className error: anError [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Unable to replace slot definition for class ';
				  nextPutAll: className;
				  nextPutAll: ': ';
				  nextPutAll: (self normalizedCauseMessageForMutationError: anError) ]
]

{ #category : 'private - errors' }
MCPToolUpdateClass >> failureMessageForReplaceLayoutOnClassNamed: className error: anError [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Unable to replace layout for class ';
				  nextPutAll: className;
				  nextPutAll: ': ';
				  nextPutAll: (self normalizedCauseMessageForMutationError: anError) ]
]

{ #category : 'private - errors' }
MCPToolUpdateClass >> failureMessageForReplaceSharedPoolsOnClassNamed: className error: anError [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Unable to replace shared pools for class ';
				  nextPutAll: className;
				  nextPutAll: ': ';
				  nextPutAll: (self normalizedCauseMessageForMutationError: anError) ]
]

{ #category : 'private - errors' }
MCPToolUpdateClass >> failureMessageForReplaceSharedVariablesOnClassNamed: className error: anError [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Unable to replace shared variables for class ';
				  nextPutAll: className;
				  nextPutAll: ': ';
				  nextPutAll: (self normalizedCauseMessageForMutationError: anError) ]
]

{ #category : 'private - errors' }
MCPToolUpdateClass >> failureMessageForReplaceTraitsOnClassNamed: className error: anError [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Unable to replace traits for class ';
				  nextPutAll: className;
				  nextPutAll: ': ';
				  nextPutAll: (self normalizedCauseMessageForMutationError: anError) ]
]

{ #category : 'private - errors' }
MCPToolUpdateClass >> failureMessageForSetCommentOnClassNamed: className error: anError [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Unable to set comment for class ';
				  nextPutAll: className;
				  nextPutAll: ': ';
				  nextPutAll: (self normalizedCauseMessageForMutationError: anError) ]
]

{ #category : 'private - warnings' }
MCPToolUpdateClass >> impactMessagesForRefactoringWarning: aWarning action: action requestedContext: requestedContext [
	"A slot removal is stopped because methods still use the slot, which the warning names without their class, or not at all, depending on the Pharo version. They are read in the image instead, each with what it does to the slot."

	action = 'removeSlot' ifTrue: [ (self usesOfSlotIn: requestedContext) ifNotEmpty: [ :messages | ^ messages ] ].
	^ super impactMessagesForRefactoringWarning: aWarning action: action requestedContext: requestedContext
]

{ #category : 'private - results' }
MCPToolUpdateClass >> keysStatedInSummary [
	"Several updates each say what they did in the summary, a line each."

	^ #( updates )
]

{ #category : 'private - planning' }
MCPToolUpdateClass >> moveContextFor: request [
	"A move reports where the class goes, its package resolved when the call gave a tag alone."

	^ {
		  (#class -> (request stringArgumentNamed: 'name')).
		  (#package -> (self movePackageNameIn: request)).
		  (#tag -> (request stringArgumentNamed: 'tag' default: '')) } asDictionary
]

{ #category : 'private - arguments' }
MCPToolUpdateClass >> movePackageNameIn: request [
	"A tag alone retags the class inside its own package. The class is looked up as every class name is, so a global variable that is no class, such as Transcript, is refused rather than asked for its package."

	^ (request stringArgumentNamed: 'package') ifNil: [
		  (MCPImageLookup classNamed: (request stringArgumentNamed: 'name')) packageName asString ]
]

{ #category : 'private - results' }
MCPToolUpdateClass >> moveSlotSummaryFor: plan ofClassNamed: className [

	| slotDescription |
	slotDescription := self slotDescriptionForClassSide: plan classSide.
	plan updateAction = 'pullUpSlot' ifTrue: [
			^ String streamContents: [ :stream |
				  stream << 'Pulled up ' << slotDescription << ' ' << plan slotName << ' to class ' << className << '.' ] ].
	^ String streamContents: [ :stream |
		  stream << 'Pushed down ' << slotDescription << ' ' << plan slotName << ' from class ' << className << '.' ]
]

{ #category : 'private - results' }
MCPToolUpdateClass >> moveSummaryForClassInfo: aClassInfo [
	"Moved class ZooKeeper to tag People of package Zoo-Core. It says where the class is after the move: a class filed under a tag is named with the tag and its package, one at its package's root with the package alone."

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Moved class ';
				  nextPutAll: aClassInfo className;
				  nextPutAll: ' to '.
			  aClassInfo hasTag ifTrue: [
					  stream
						  nextPutAll: 'tag ';
						  nextPutAll: aClassInfo tag;
						  nextPutAll: ' of ' ].
			  stream
				  nextPutAll: 'package ';
				  nextPutAll: aClassInfo packageName;
				  nextPut: $. ]
]

{ #category : 'private - mutation' }
MCPToolUpdateClass >> mutateWith: request [
	"Every change is planned before the first is made, so a call asking for one that cannot be planned changes nothing."

	| plans |
	[ plans := self updatePlansFor: request ]
		on: MCPCommandError
		do: [ :error | ^ self errorResultForCommandError: error action: 'update' requestedContext: (self requestedContextFor: request) ].
	^ self applyUpdates: plans of: request
]

{ #category : 'private - errors' }
MCPToolUpdateClass >> mutationActionFor: request checked: aBoolean [

	^ 'update'
]

{ #category : 'private - planning' }
MCPToolUpdateClass >> planForAction: action in: request [

	^ MCPClassUpdatePlanInfo updateAction: action requestedContext: (action = 'move'
			   ifTrue: [ self moveContextFor: request ]
			   ifFalse: [ self requestedContextFor: request ])
]

{ #category : 'private - planning' }
MCPToolUpdateClass >> requestedClassUpdateActionsIn: request [
	"The actions the scalar and stateless-collection properties ask for. Slot operations come from the patches, planned one slot at a time."

	| actions |
	actions := OrderedCollection new.
	(request hasArgumentNamed: 'newName') ifTrue: [ actions add: 'rename' ].
	(request hasArgumentNamed: 'superclass') ifTrue: [ actions add: 'reparent' ].
	((request hasArgumentNamed: 'package') or: [ request hasArgumentNamed: 'tag' ]) ifTrue: [ actions add: 'move' ].
	(request hasArgumentNamed: 'comment') ifTrue: [ actions add: 'setComment' ].
	(request hasArgumentNamed: 'traits') ifTrue: [ actions add: 'replaceTraits' ].
	(request hasArgumentNamed: 'sharedVariables') ifTrue: [ actions add: 'replaceSharedVariables' ].
	(request hasArgumentNamed: 'sharedPools') ifTrue: [ actions add: 'replaceSharedPools' ].
	(request hasArgumentNamed: 'layout') ifTrue: [ actions add: 'replaceLayout' ].
	^ actions asArray
]

{ #category : 'private - errors' }
MCPToolUpdateClass >> requestedContextFor: request [
	"The class and every property the call supplied, as the update reads them. A property left out is not reported, so an empty list or string the caller gave is told apart from one it did not give."

	| context |
	context := Dictionary new.
	context at: #name put: (request stringArgumentNamed: 'name').
	(self suppliedPropertiesIn: request) do: [ :propertyName |
		context at: propertyName asSymbol put: (self contextValueOf: propertyName in: request) ].
	^ context
]

{ #category : 'private - planning' }
MCPToolUpdateClass >> signalNoUpdateRequestedIn: request [

	^ MCPCommandError
		  signalErrorCode: #NoClassUpdateRequested
		  message:
		  'Class update requires one update field such as newName, superclassName, packageName, tag, classComment, slots, classSlots, traits, sharedVariables, sharedPools, layout, or slotAction.'
		  details: (self requestedContextFor: request)
]

{ #category : 'private - arguments' }
MCPToolUpdateClass >> slotDeltaIn: request side: aBoolean [
	"The patch the call asks for over the class-side slots or the instance-side ones, nil when it asks for none."

	^ MCPSlotDelta fromRequest: request named: (aBoolean
			   ifTrue: [ 'classSlots' ]
			   ifFalse: [ 'slots' ])
]

{ #category : 'private - results' }
MCPToolUpdateClass >> slotDescriptionForClassSide: aBoolean [

	^ aBoolean
		  ifTrue: [ 'class-side slot' ]
		  ifFalse: [ 'slot' ]
]

{ #category : 'private - planning' }
MCPToolUpdateClass >> slotPlansIn: request side: classSide [
	"One plan per slot named in the patch, so each failure names the slot it was about. The wholesale replacement is not here: it covers both sides at once, so updatePlansFor: plans it once."

	| delta planFor plans |
	delta := self slotDeltaIn: request side: classSide.
	delta ifNil: [ ^ #(  ) ].
	delta isEmpty ifTrue: [
			MCPCommandError
				signalErrorCode: #EmptySlotDelta
				message: 'A slots patch must ask for at least one of add, remove, rename, pullUp, pushDown or replace.'
				details: (self requestedContextFor: request) ].
	planFor := [ :action :slotName :newSlotName |
		           | context |
		           context := Dictionary new
			                      at: #class put: (request stringArgumentNamed: 'name');
			                      at: #side put: (classSide
					                       ifTrue: [ 'class' ]
					                       ifFalse: [ 'instance' ]);
			                      at: #slot put: slotName;
			                      yourself.
		           newSlotName ifNotNil: [ context at: #newSlot put: newSlotName ].
		           (MCPClassUpdatePlanInfo updateAction: action requestedContext: context)
			           slotName: slotName;
			           newSlotName: newSlotName;
			           classSide: classSide;
			           yourself ].
	plans := OrderedCollection new.
	delta added do: [ :each | plans add: (planFor value: 'addSlot' value: each value: nil) ].
	delta renamed keysAndValuesDo: [ :from :to | plans add: (planFor value: 'renameSlot' value: from value: to) ].
	delta pulledUp do: [ :each | plans add: (planFor value: 'pullUpSlot' value: each value: nil) ].
	delta pushedDown do: [ :each | plans add: (planFor value: 'pushDownSlot' value: each value: nil) ].
	delta removed do: [ :each | plans add: (planFor value: 'removeSlot' value: each value: nil) ].
	^ plans
]

{ #category : 'private - arguments' }
MCPToolUpdateClass >> slotReplacementIn: request side: aBoolean [
	"The complete slot list the call gives for that side, nil when it patches the side or leaves it alone."

	^ (self slotDeltaIn: request side: aBoolean) ifNotNil: [ :delta | delta replacement ]
]

{ #category : 'private - arguments' }
MCPToolUpdateClass >> suppliedPropertiesIn: request [
	"The properties that ask for a change, which the schema requires at least one of, in the order it lists them."

	^ self atLeastOneInputProperties select: [ :each | request hasArgumentNamed: each ]
]

{ #category : 'private - updating' }
MCPToolUpdateClass >> updateActionOf: plan [

	^ plan updateAction
]

{ #category : 'private - planning' }
MCPToolUpdateClass >> updatePlansFor: request [
	"Every change the call asks for, as plans, in the order they must be applied."

	| plans |
	plans := OrderedCollection new.
	(self requestedClassUpdateActionsIn: request) do: [ :action | plans add: (self planForAction: action in: request) ].
	((self slotReplacementIn: request side: false) isNotNil or: [ (self slotReplacementIn: request side: true) isNotNil ]) ifTrue: [
		plans add: (self planForAction: 'replaceDefinition' in: request) ].
	plans addAll: (self slotPlansIn: request side: false).
	plans addAll: (self slotPlansIn: request side: true).
	plans ifEmpty: [ self signalNoUpdateRequestedIn: request ].
	^ self actionsInApplicationOrder: plans
]

{ #category : 'private - updating' }
MCPToolUpdateClass >> updateSubjectDescriptionFor: request [
	"What the summary of several updates calls the class."

	^ 'class ' , (request stringArgumentNamed: 'name')
]

{ #category : 'private - warnings' }
MCPToolUpdateClass >> useOfSlot: aSlot by: aMethod [
	"Class>>selector reads slot, writes slot, or reads and writes it."

	^ String streamContents: [ :stream |
			  stream << aMethod methodClass name << '>>' << aMethod selector << ' '.
			  (aMethod readsSlot: aSlot)
				  ifTrue: [
						  stream << 'reads'.
						  (aMethod writesSlot: aSlot) ifTrue: [ stream << ' and writes' ] ]
				  ifFalse: [ stream << 'writes' ].
			  stream << ' ' << aSlot name ]
]

{ #category : 'private - warnings' }
MCPToolUpdateClass >> usesOfSlotIn: requestedContext [
	"The methods that use the slot requestedContext names, as usesOfSlotNamed:inClassNamed:classSide: answers them."

	^ self
		  usesOfSlotNamed: (requestedContext at: #slot)
		  inClassNamed: (requestedContext at: #class)
		  classSide: (requestedContext at: #side ifAbsent: [ nil ]) = 'class'
]

{ #category : 'private - warnings' }
MCPToolUpdateClass >> usesOfSlotNamed: slotName inClassNamed: className classSide: aBoolean [
	"One line per method that reads or writes the slot slotName the class defines on that side, in the class and the subclasses that inherit it: the class first, then its subclasses by name, each one's methods by selector. Empty when the class defines no such slot itself."

	| behavior slot |
	behavior := [ MCPImageLookup behaviorNamed: className classSide: aBoolean ]
		            on: Error
		            do: [ ^ #(  ) ].
	slot := behavior slots detect: [ :each | each name = slotName asSymbol ] ifNone: [ ^ #(  ) ].
	^ { behavior } , (behavior allSubclasses sorted: [ :a :b | a name <= b name ]) flatCollect: [ :each |
			  ((each methods select: [ :method | (method readsSlot: slot) or: [ method writesSlot: slot ] ]) sorted: [ :a :b |
				   a selector <= b selector ]) collect: [ :method | self useOfSlot: slot by: method ] ]
]
