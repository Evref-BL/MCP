"
Creates the classes a call names, all from the one definition it gives.
"
Class {
	#name : 'MCPToolCreateClass',
	#superclass : 'MCPToolClassMutation',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolCreateClass class >> toolName [

	^ 'class_create'
]

{ #category : 'metadata' }
MCPToolCreateClass >> batchArgumentName [

	^ 'name'
]

{ #category : 'metadata' }
MCPToolCreateClass >> batchSummaryNoun [

	^ 'classes'
]

{ #category : 'metadata' }
MCPToolCreateClass >> batchSummaryVerb [

	^ 'Created'
]

{ #category : 'private - execution' }
MCPToolCreateClass >> checkArguments: request [
	"An entry that is a list written as one string is refused before anything changes, in the arguments whose names the class builder takes as they are: the schema checks only that each entry is a string, and the builder would call the list an invalid slot name, or make a class variable of it. Traits and pools are class names, which MCPImageLookup refuses the same way, and MCPCreateClassCommand refuses a name no new class can take."

	{
		('slots' -> 'a slot name').
		('classSlots' -> 'a slot name').
		('sharedVariables' -> 'a class variable name') } do: [ :argument |
			(request stringCollectionArgumentNamed: argument key)
				detect: [ :each | MCPImageLookup isListInOneName: each ]
				ifFound: [ :list | MCPCommandError signalNameIsAList: list kind: argument value argument: argument key ] ]
]

{ #category : 'private - errors' }
MCPToolCreateClass >> classUpdateArgumentsFor: aClass from: request [
	"The arguments of the class_update call that gives aClass what this call asked class_create for and it lacks, its name first and the rest in the order class_create takes them: each one the call gave that aClass does not have. The slots aClass lacks are counted under the superclass the call names, since class_update moves a class before it changes its slots: one that superclass defines is not given again, and one aClass inherits only where it is now is. A list class_update replaces whole keeps what aClass has, so nothing is removed. A trait is given no superclass, as class_update gives a trait none."

	| arguments newSuperclass |
	arguments := OrderedDictionary new.
	arguments at: 'name' put: aClass name asString.
	(self newSuperclassNameOf: aClass in: request) ifNotNil: [ :name |
			arguments at: 'superclass' put: name.
			newSuperclass := self class environment classNamed: name ].
	(request stringArgumentNamed: 'package') ifNotNil: [ :name |
		name = (aClass package ifNotNil: [ :package | package name asString ]) ifFalse: [ arguments at: 'package' put: name ] ].
	(request stringArgumentNamed: 'tag') ifNotNil: [ :name |
		((arguments includesKey: 'package') or: [ name ~= aClass mcpTagName ]) ifTrue: [ arguments at: 'tag' put: name ] ].
	(self
		 slotPatchIn: request
		 named: 'slots'
		 giving: aClass
		 under: newSuperclass) ifNotEmpty: [ :patch | arguments at: 'slots' put: patch ].
	(self
		 slotPatchIn: request
		 named: 'classSlots'
		 giving: aClass classSide
		 under: (newSuperclass ifNotNil: [ :superclass | superclass classSide ])) ifNotEmpty: [ :patch |
		arguments at: 'classSlots' put: patch ].
	{
		('traits' -> (aClass traits collect: [ :each | each name ])).
		('sharedVariables' -> aClass classVarNames).
		('sharedPools' -> (aClass sharedPools collect: [ :each | each name ])) } do: [ :each |
			(self namesIn: request argumentNamed: each key lackedFrom: each value) ifNotEmpty: [ :names |
				arguments at: each key put: (each value collect: [ :name | name asString ] as: Array) , names asArray ] ].
	(request stringArgumentNamed: 'layout') ifNotNil: [ :name |
		name = aClass classLayout class name asString ifFalse: [ arguments at: 'layout' put: name ] ].
	(self classCommentIn: request) ifNotNil: [ :comment |
		comment lines = (aClass mcpComment ifNil: [ '' ]) asString lines ifFalse: [ arguments at: 'comment' put: comment ] ].
	^ arguments
]

{ #category : 'private - results' }
MCPToolCreateClass >> createdSummaryFor: aClass from: request [
	"A trait is named as one, so asking for a trait is not answered with the word class. A class made with no superclass given is said to subclass Object: a caller that meant another, as for a test class, would not see it otherwise."

	^ String streamContents: [ :stream |
			  stream << 'Created ' << (aClass isTrait
				   ifTrue: [ 'trait ' ]
				   ifFalse: [ 'class ' ]) << aClass name.
			  (request stringArgumentNamed: 'superclass') ifNil: [ stream << ', a subclass of ' << aClass superclass name ].
			  stream nextPut: $. ]
]

{ #category : 'metadata' }
MCPToolCreateClass >> defaultExposure [

	^ 'static'
]

{ #category : 'private - execution' }
MCPToolCreateClass >> mutateWith: request [
	"The class is made, then given its comment. A failure in either is reported as a failure to create the class. A class that exists is refused with the class_update call that gives it what this call asks for."

	| className classComment createdClass packageName superclassName |
	className := request stringArgumentNamed: 'name'.
	superclassName := self superclassNameIn: request.
	packageName := request stringArgumentNamed: 'package'.
	classComment := self classCommentIn: request.
	^ self
		  executeMutationAction: 'create'
		  force: false
		  requestedContext: (self requestedContextFor: request)
		  work: [
				  MCPImageLookup newClassName: className ifClassExists: [ :existingClass | self refuseExisting: existingClass from: request ].
				  createdClass := (MCPCreateClassCommand
					                   className: className
					                   superclassName: superclassName
					                   packageName: packageName
					                   tag: (request stringArgumentNamed: 'tag')
					                   slots: (request symbolCollectionArgumentNamed: 'slots')
					                   classSlots: (request symbolCollectionArgumentNamed: 'classSlots')
					                   traits: (request stringCollectionArgumentNamed: 'traits')
					                   sharedVariables: (request stringCollectionArgumentNamed: 'sharedVariables')
					                   sharedPools: (request stringCollectionArgumentNamed: 'sharedPools')
					                   layout: (request stringArgumentNamed: 'layout')) execute.
				  classComment ifNotNil: [ (MCPChangeClassCommentCommand className: className classComment: classComment) execute ] ]
		  successResult: [ :warningMessages |
			  self successResultText: (self createdSummaryFor: createdClass from: request) data: Dictionary new warnings: warningMessages ]
		  failureSummary: [ :error |
				  self
					  failureMessage: ('Unable to create class {1} < {2} in package {3}' format: {
								   className.
								   superclassName.
								   packageName })
					  error: error ]
]

{ #category : 'private - errors' }
MCPToolCreateClass >> namesIn: request argumentNamed: anArgumentName lackedFrom: someNames [
	"The names the argument gives, each once and in order, that someNames, strings or symbols, does not hold."

	| present |
	present := someNames collect: [ :each | each asString ] as: Set.
	^ (request uniqueStringCollectionArgumentNamed: anArgumentName) reject: [ :each | present includes: each ]
]

{ #category : 'private - errors' }
MCPToolCreateClass >> newSuperclassNameOf: aClass in: request [
	"The superclass the call names when class_update would move aClass under it: nil when the call names none or the one aClass has, and for a trait, which class_update gives no superclass."

	| name |
	aClass isTrait ifTrue: [ ^ nil ].
	name := request stringArgumentNamed: 'superclass'.
	name = (aClass superclass ifNotNil: [ :superclass | superclass name asString ]) ifTrue: [ ^ nil ].
	^ name
]

{ #category : 'private - errors' }
MCPToolCreateClass >> refuseExisting: aClass from: request [
	"class_create's refusal of a class that exists. A class of another project than the package the call names, as one of Pharo's own, is not the caller's to change, so the call is asked for another name and given no class_update call. class_update makes no class a trait and no trait a class, so a call that names a superclass asking for the other kind, Trait where a class exists or a class where a trait does, is told which kind exists; one that names none asks for neither. A call that names a superclass with a slot the class or one of its subclasses defines is told so, since class_update would refuse that move. Otherwise the refusal writes the class_update call that gives the class what the call asks for and it lacks, and names what the class has that a list the call gives leaves out, which that call keeps."

	| packageName superclassName |
	packageName := aClass package ifNotNil: [ :package | package name asString ].
	(self isPackageNamed: packageName inTheProjectOf: (request stringArgumentNamed: 'package')) ifFalse: [
			^ MCPCommandError
				  signalClassAlreadyExistsNamed: aClass name asString
				  package: packageName
				  otherProjectThan: (request stringArgumentNamed: 'package') ].
	superclassName := request stringArgumentNamed: 'superclass'.
	(superclassName isNotNil and: [ aClass isTrait ~= (superclassName = 'Trait') ]) ifTrue: [
		^ MCPCommandError signalClassAlreadyExistsNamed: aClass name asString askedForATrait: superclassName = 'Trait' ].
	(self newSuperclassNameOf: aClass in: request) ifNotNil: [ :name |
			(self class environment classNamed: name) ifNotNil: [ :superclass |
					(self slotsDefinedBy: aClass alsoIn: superclass) ifNotEmpty: [ :defined |
						^ MCPCommandError signalClassAlreadyExistsNamed: aClass name asString superclass: name definedSlots: defined ] ] ].
	^ MCPCommandError
		  signalClassAlreadyExistsNamed: aClass name asString
		  update: (self classUpdateArgumentsFor: aClass from: request)
		  unlisted: (self unlistedNamesOf: aClass in: request)
]

{ #category : 'private - errors' }
MCPToolCreateClass >> requestedContextFor: request [
	"The definition as the class is made from it."

	^ {
		  (#class -> (request stringArgumentNamed: 'name')).
		  (#superclass -> (self superclassNameIn: request)).
		  (#package -> (request stringArgumentNamed: 'package')).
		  (#tag -> (request stringArgumentOrDefaultNamed: 'tag')).
		  (#comment -> ((self classCommentIn: request) ifNil: [ '' ])).
		  (#slots -> (request stringCollectionArgumentNamed: 'slots')).
		  (#classSlots -> (request stringCollectionArgumentNamed: 'classSlots')).
		  (#traits -> (request stringCollectionArgumentNamed: 'traits')).
		  (#sharedVariables -> (request stringCollectionArgumentNamed: 'sharedVariables')).
		  (#sharedPools -> (request stringCollectionArgumentNamed: 'sharedPools')).
		  (#layout -> (request stringArgumentNamed: 'layout' default: '')) } asDictionary
]

{ #category : 'private - errors' }
MCPToolCreateClass >> slotNamesOf: aBehavior alsoIn: aSuperclass [
	"The slots aBehavior defines itself that aSuperclass also has, its own or inherited: those it could not define under aSuperclass."

	| inherited |
	inherited := aSuperclass allInstVarNames collect: [ :each | each asString ] as: Set.
	^ aBehavior instVarNames collect: [ :each | each asString ] thenSelect: [ :each | inherited includes: each ]
]

{ #category : 'private - errors' }
MCPToolCreateClass >> slotNamesOf: aBehavior under: aSuperclassOrNil [
	"aBehavior's slot names, its own and those it inherits, as they would be under aSuperclassOrNil, or as they are when it is nil."

	aSuperclassOrNil ifNil: [ ^ aBehavior allInstVarNames ].
	^ aBehavior instVarNames , aSuperclassOrNil allInstVarNames
]

{ #category : 'private - errors' }
MCPToolCreateClass >> slotPatchIn: request named: anArgumentName giving: aBehavior under: aSuperclassOrNil [
	"The class_update patch of the slots the argument names that aBehavior lacks, counted under aSuperclassOrNil as slotNamesOf:under: counts them, or an empty one when it lacks none. class_update refuses to add a slot that a subclass of aBehavior defines, and pulls it up from there instead, so such a slot is pulled up and any other added."

	| definedBelow lacked patch |
	patch := OrderedDictionary new.
	lacked := self namesIn: request argumentNamed: anArgumentName lackedFrom: (self slotNamesOf: aBehavior under: aSuperclassOrNil).
	lacked ifEmpty: [ ^ patch ].
	definedBelow := Set new.
	aBehavior allSubclassesDo: [ :each | each instVarNames do: [ :name | definedBelow add: name asString ] ].
	(lacked reject: [ :each | definedBelow includes: each ]) ifNotEmpty: [ :names | patch at: 'add' put: names asArray ].
	(lacked select: [ :each | definedBelow includes: each ]) ifNotEmpty: [ :names | patch at: 'pullUp' put: names asArray ].
	^ patch
]

{ #category : 'private - errors' }
MCPToolCreateClass >> slotsDefinedBy: aClass alsoIn: aSuperclass [
	"The instance-side slots aClass and its subclasses define that aSuperclass already has, as each class that defines some, aClass first, with their names. A class cannot define a slot one of its superclasses has, so class_update refuses to move aClass under aSuperclass while any is left. The class side is left out, since class_update's move refuses nothing there. A superclass that is aClass or one of its subclasses gives none, as class_update refuses that move for a reason of its own."

	(aSuperclass includesBehavior: aClass) ifTrue: [ ^ #(  ) ].
	^ ({ aClass } , aClass allSubclasses asArray collect: [ :each |
		   each name asString -> (self slotNamesOf: each alsoIn: aSuperclass) ]) reject: [ :each | each value isEmpty ]
]

{ #category : 'private - arguments' }
MCPToolCreateClass >> superclassNameIn: request [
	"The superclass the class gets, its schema default when the caller omits it. Reading it here rather than in MCPCreateClassCommand keeps the error details and the failure messages naming that superclass."

	^ request stringArgumentOrDefaultNamed: 'superclass'
]

{ #category : 'private - specs' }
MCPToolCreateClass >> toolSpec [

	^ {
		  (#title -> 'Create Class').
		  (#description -> 'Create a class in the running image, or several sharing one definition.').
		  (#action -> 'create').
		  (#inputProperties -> {
			   (self
				    stringOrArraySchemaNamed: 'name'
				    description: 'Name of the class to create, or several names sharing the other arguments.'
				    itemDescription: 'Class name.').
			   ((self schemaPropertyNamed: 'superclass' type: 'string' description: 'Superclass name. Trait creates a trait.')
				    default: 'Object';
				    yourself).
			   (self schemaPropertyNamed: 'package' type: 'string' description: 'Package for the class, created if missing.').
			   ((self schemaPropertyNamed: 'tag' type: 'string' description: 'Tag within the package.')
				    default: '';
				    yourself).
			   (self stringArraySchemaNamed: 'slots' description: 'Instance variable names.' itemDescription: 'Slot name.').
			   (self stringArraySchemaNamed: 'classSlots' description: 'Class-side instance variable names.' itemDescription: 'Slot name.').
			   (self
				    stringArraySchemaNamed: 'traits'
				    description: 'Traits the class uses, class side included.'
				    itemDescription: 'Trait name.').
			   (self stringArraySchemaNamed: 'sharedVariables' description: 'Class variable names.' itemDescription: 'Variable name.').
			   (self
				    stringArraySchemaNamed: 'sharedPools'
				    description: 'Shared pools the class reads variables from.'
				    itemDescription: 'Pool name.').
			   self layoutSchemaProperty.
			   (self schemaPropertyNamed: 'comment' type: 'string' description: 'Class comment.') }).
		  (#requiredProperties -> #( 'name' 'package' )) } asDictionary
]

{ #category : 'private - errors' }
MCPToolCreateClass >> unlistedNamesOf: aClass in: request [
	"What aClass has that a list the call gives leaves out: for each such list, in the order class_create takes them, its argument name and those names. A list the call does not give leaves nothing out. class_create gives a class whole, so the caller may mean those to go, while class_update keeps them unless told otherwise."

	| unlisted |
	unlisted := OrderedCollection new.
	{
		('slots' -> aClass instVarNames).
		('classSlots' -> aClass classSide instVarNames).
		('traits' -> (aClass traits collect: [ :each | each name ])).
		('sharedVariables' -> aClass classVarNames).
		('sharedPools' -> (aClass sharedPools collect: [ :each | each name ])) } do: [ :each |
			(request hasArgumentNamed: each key) ifTrue: [
					| listed |
					listed := (request uniqueStringCollectionArgumentNamed: each key) asSet.
					((each value collect: [ :name | name asString ] as: Array) reject: [ :name | listed includes: name ]) ifNotEmpty: [ :names |
						unlisted add: each key -> names ] ] ].
	^ unlisted asArray
]
