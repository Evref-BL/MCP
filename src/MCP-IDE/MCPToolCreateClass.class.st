"
Tool that creates one class definition without exposing a combined class-mutation selector.
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

{ #category : 'private - arguments' }
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

{ #category : 'private - specs' }
MCPToolCreateClass >> classToolSpec [

	^ {
		  (#title -> 'Create Class').
		  (#description -> 'Create a class in the running image, or several sharing one definition.').
		  (#inputProperties -> {
			   self createClassNameSchemaProperty.
			   self createSuperclassNameSchemaProperty.
			   self createPackageNameSchemaProperty.
			   self createTagSchemaProperty.
			   self createSlotsSchemaProperty.
			   self createClassSlotsSchemaProperty.
			   self createTraitsSchemaProperty.
			   self createSharedVariablesSchemaProperty.
			   self createSharedPoolsSchemaProperty.
			   self layoutSchemaProperty.
			   self createCommentSchemaProperty }).
		  (#requiredProperties -> #( 'name' 'package' )) } asDictionary
]

{ #category : 'private - errors' }
MCPToolCreateClass >> classUpdateArgumentsFor: aClass from: request [
	"The arguments of the class_update call that gives aClass what this call asked class_create for and it lacks, its name first and the rest in the order class_create takes them: each one the call gave that aClass does not have. The slots aClass lacks are added, counted under the superclass the call names, since class_update moves a class before it adds slots: one that superclass defines is not added again, and one aClass inherits only where it is now is. A list class_update replaces whole keeps what aClass has, so nothing is removed. A trait is given no superclass, as class_update gives a trait none."

	| arguments newSuperclass |
	arguments := OrderedDictionary new.
	arguments at: 'name' put: aClass name asString.
	(request stringArgumentNamed: 'superclass') ifNotNil: [ :name |
			(aClass isTrait or: [ name = (aClass superclass ifNotNil: [ :superclass | superclass name asString ]) ]) ifFalse: [
					arguments at: 'superclass' put: name.
					newSuperclass := Smalltalk globals classNamed: name ] ].
	(request stringArgumentNamed: 'package') ifNotNil: [ :name |
		name = (aClass package ifNotNil: [ :package | package name asString ]) ifFalse: [ arguments at: 'package' put: name ] ].
	(request stringArgumentNamed: 'tag') ifNotNil: [ :name |
		((arguments includesKey: 'package') or: [ name ~= aClass mcpTagName ]) ifTrue: [ arguments at: 'tag' put: name ] ].
	{
		('slots' -> (self slotNamesOf: aClass under: newSuperclass)).
		('classSlots' -> (self slotNamesOf: aClass classSide under: (newSuperclass ifNotNil: [ :superclass | superclass classSide ]))) }
		do: [ :each |
				(self namesIn: request argumentNamed: each key lackedFrom: each value) ifNotEmpty: [ :names |
					arguments at: each key put: { ('add' -> names asArray) } asDictionary ] ].
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

{ #category : 'private - schema' }
MCPToolCreateClass >> createClassNameSchemaProperty [

	^ (self
		   schemaPropertyNamed: 'name'
		   type: #( 'string' 'array' )
		   description: 'Name of the class to create, or several names sharing the other arguments.')
		  items: (MCPStructureProperties new
				   type: 'string';
				   yourself);
		  yourself
]

{ #category : 'private - schema' }
MCPToolCreateClass >> createClassSlotsSchemaProperty [

	^ self stringArraySchemaNamed: 'classSlots' description: 'Class-side instance variable names.' itemDescription: 'Slot name.'
]

{ #category : 'private - schema' }
MCPToolCreateClass >> createCommentSchemaProperty [

	^ self schemaPropertyNamed: 'comment' type: 'string' description: 'Class comment.'
]

{ #category : 'private - schema' }
MCPToolCreateClass >> createPackageNameSchemaProperty [

	^ self schemaPropertyNamed: 'package' type: 'string' description: 'Package for the class, created if missing.'
]

{ #category : 'private - schema' }
MCPToolCreateClass >> createSharedPoolsSchemaProperty [

	^ self
		  stringArraySchemaNamed: 'sharedPools'
		  description: 'Shared pools the class reads variables from.'
		  itemDescription: 'Pool name.'
]

{ #category : 'private - schema' }
MCPToolCreateClass >> createSharedVariablesSchemaProperty [

	^ self stringArraySchemaNamed: 'sharedVariables' description: 'Class variable names.' itemDescription: 'Variable name.'
]

{ #category : 'private - schema' }
MCPToolCreateClass >> createSlotsSchemaProperty [

	^ self stringArraySchemaNamed: 'slots' description: 'Instance variable names.' itemDescription: 'Slot name.'
]

{ #category : 'private - schema' }
MCPToolCreateClass >> createSuperclassNameSchemaProperty [

	^ self
		  schemaPropertyNamed: 'superclass'
		  type: 'string'
		  description: 'Superclass name, Object when omitted. Trait creates a trait.'
]

{ #category : 'private - schema' }
MCPToolCreateClass >> createTagSchemaProperty [

	^ self schemaPropertyNamed: 'tag' type: 'string' description: 'Tag within the package.'
]

{ #category : 'private - schema' }
MCPToolCreateClass >> createTraitsSchemaProperty [

	^ self stringArraySchemaNamed: 'traits' description: 'Traits the class uses, class side included.' itemDescription: 'Trait name.'
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

{ #category : 'private - errors' }
MCPToolCreateClass >> failureMessageForCreateClassNamed: className superclassName: superclassName packageName: packageName error: anError [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Unable to create class ';
				  nextPutAll: className;
				  nextPutAll: ' < ';
				  nextPutAll: superclassName;
				  nextPutAll: ' in package ';
				  nextPutAll: packageName;
				  nextPutAll: ': ';
				  nextPutAll: (self normalizedCauseMessageForMutationError: anError) ]
]

{ #category : 'private - mutation' }
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
					  failureMessageForCreateClassNamed: className
					  superclassName: superclassName
					  packageName: packageName
					  error: error ]
]

{ #category : 'private - errors' }
MCPToolCreateClass >> mutationActionFor: request checked: aBoolean [

	^ 'create'
]

{ #category : 'private - errors' }
MCPToolCreateClass >> namesIn: request argumentNamed: anArgumentName lackedFrom: someNames [
	"The names the argument gives, each once and in order, that someNames, strings or symbols, does not hold."

	| present |
	present := someNames collect: [ :each | each asString ] as: Set.
	^ (request uniqueStringCollectionArgumentNamed: anArgumentName) reject: [ :each | present includes: each ]
]

{ #category : 'private - errors' }
MCPToolCreateClass >> refuseExisting: aClass from: request [
	"class_create's refusal of a class that exists. When the call asks for what it is, a class or a trait, the refusal writes the class_update call that gives it what the call asks for and it lacks. class_update makes no class a trait and no trait a class, so a call that asks for the other kind is told which kind exists instead."

	| asksForATrait |
	asksForATrait := (self superclassNameIn: request) = 'Trait'.
	aClass isTrait = asksForATrait ifFalse: [
		^ MCPCommandError signalClassAlreadyExistsNamed: aClass name asString askedForATrait: asksForATrait ].
	^ MCPCommandError
		  signalClassAlreadyExistsNamed: aClass name asString
		  update: (self classUpdateArgumentsFor: aClass from: request)
]

{ #category : 'private - errors' }
MCPToolCreateClass >> requestedContextFor: request [
	"The definition as the class is made from it."

	^ {
		  (#class -> (request stringArgumentNamed: 'name')).
		  (#superclass -> (self superclassNameIn: request)).
		  (#package -> (request stringArgumentNamed: 'package')).
		  (#tag -> (request stringArgumentNamed: 'tag' default: '')).
		  (#comment -> ((self classCommentIn: request) ifNil: [ '' ])).
		  (#slots -> (request stringCollectionArgumentNamed: 'slots')).
		  (#classSlots -> (request stringCollectionArgumentNamed: 'classSlots')).
		  (#traits -> (request stringCollectionArgumentNamed: 'traits')).
		  (#sharedVariables -> (request stringCollectionArgumentNamed: 'sharedVariables')).
		  (#sharedPools -> (request stringCollectionArgumentNamed: 'sharedPools')).
		  (#layout -> (request stringArgumentNamed: 'layout' default: '')) } asDictionary
]

{ #category : 'private - errors' }
MCPToolCreateClass >> slotNamesOf: aBehavior under: aSuperclassOrNil [
	"aBehavior's slot names, its own and those it inherits, as they would be under aSuperclassOrNil, or as they are when it is nil."

	aSuperclassOrNil ifNil: [ ^ aBehavior allInstVarNames ].
	^ aBehavior instVarNames , aSuperclassOrNil allInstVarNames
]

{ #category : 'private - arguments' }
MCPToolCreateClass >> superclassNameIn: request [
	"Object when the caller omits it, because that is what a new class subclasses unless it says otherwise. Defaulting here rather than in MCPCreateClassCommand keeps the error details and the failure messages naming the superclass the class actually gets."

	^ request stringArgumentNamed: 'superclass' default: 'Object'
]
