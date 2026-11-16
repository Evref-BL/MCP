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
	"Nothing is refused before the image is asked: the schema has checked every argument, and MCPCreateClassCommand refuses a name no new class can take."

	
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
MCPToolCreateClass >> createdSummaryFor: aClass [
	"A trait is named as one, so asking for a trait is not answered with the word class."

	^ String streamContents: [ :stream |
			  stream << 'Created ' << (aClass isTrait
				   ifTrue: [ 'trait ' ]
				   ifFalse: [ 'class ' ]) << aClass name << '.' ]
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
	"The class is made, then given its comment. A failure in either is reported as a failure to create the class."

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
			  self successResultText: (self createdSummaryFor: createdClass) data: Dictionary new warnings: warningMessages ]
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

{ #category : 'private - arguments' }
MCPToolCreateClass >> superclassNameIn: request [
	"Object when the caller omits it, because that is what a new class subclasses unless it says otherwise. Defaulting here rather than in MCPCreateClassCommand keeps the error details and the failure messages naming the superclass the class actually gets."

	^ request stringArgumentNamed: 'superclass' default: 'Object'
]
