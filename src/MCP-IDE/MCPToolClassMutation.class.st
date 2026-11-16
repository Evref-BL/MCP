"
Shared schema and call flow of class_create and class_update.

Each target's arguments are checked, then the class is changed through the MCPClassCommand operations. An error raised before the arguments are checked echoes them as the caller wrote them; one raised after reports them as the tool reads them.
"
Class {
	#name : 'MCPToolClassMutation',
	#superclass : 'MCPToolMutation',
	#traits : 'TMCPClassTool',
	#classTraits : 'TMCPClassTool classTrait',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolClassMutation class >> groupName [

	^ self classesGroupName
]

{ #category : 'testing' }
MCPToolClassMutation class >> isAbstract [

	^ self = MCPToolClassMutation
]

{ #category : 'metadata' }
MCPToolClassMutation >> additionalKeywords [

	^ #( 'class' 'refactor' 'refactoring' )
]

{ #category : 'private - schema' }
MCPToolClassMutation >> atLeastOneInputProperties [

	^ self classToolSpec at: #atLeastOneProperties ifAbsent: [ #(  ) ]
]

{ #category : 'private - arguments' }
MCPToolClassMutation >> checkArguments: request [
	"Refuse, before anything is changed, the arguments the schema cannot refuse."

	self subclassResponsibility
]

{ #category : 'private - arguments' }
MCPToolClassMutation >> classCommentIn: request [
	"The comment as the caller wrote it, nil when it gave none. It is text, so it is not trimmed, and null clears it."

	| value |
	value := request argumentNamed: 'comment' ifAbsent: [ ^ nil ].
	^ value ifNil: [ '' ] ifNotNil: [ value asString ]
]

{ #category : 'private - schema' }
MCPToolClassMutation >> classNameSchemaProperty [

	^ self schemaPropertyNamed: 'name' type: 'string' description: 'Name of the class to change.'
]

{ #category : 'private - specs' }
MCPToolClassMutation >> classToolSpec [

	self subclassResponsibility
]

{ #category : 'private - schema' }
MCPToolClassMutation >> commentSchemaProperty [

	^ self schemaPropertyNamed: 'comment' type: 'string' description: 'Class comment; empty clears.'
]

{ #category : 'metadata' }
MCPToolClassMutation >> description [

	^ self classToolSpec at: #description
]

{ #category : 'executing' }
MCPToolClassMutation >> executeWithRequest: request [
	"Each target is checked, then changed. An error raised before its arguments are checked echoes them as the caller wrote them."

	^ self executeBatchedRequest: request do: [ :targetRequest |
			  | checked |
			  checked := false.
			  self
				  executeParsedRequestFrom: targetRequest
				  do: [ :arguments |
						  self checkArguments: arguments.
						  checked := true.
						  self mutateWith: arguments ]
				  onError: [ :error :arguments |
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
										  summary: (actionError messageText ifNil: [ actionError asString ] ifNotNil: [ :text | text ]) ] ] ]
]

{ #category : 'private - schema' }
MCPToolClassMutation >> inputProperties [

	^ self classToolSpec at: #inputProperties
]

{ #category : 'private - schema' }
MCPToolClassMutation >> layoutSchemaProperty [

	^ self
		  schemaPropertyNamed: 'layout'
		  type: 'string'
		  description: 'Layout class, a subclass of AbstractLayout such as VariableLayout.'
]

{ #category : 'private - mutation' }
MCPToolClassMutation >> mutateWith: request [
	"Make the change the checked arguments ask for, and answer the tool result."

	self subclassResponsibility
]

{ #category : 'private - errors' }
MCPToolClassMutation >> mutationActionFor: request checked: aBoolean [
	"The action an error reports."

	self subclassResponsibility
]

{ #category : 'private - schema' }
MCPToolClassMutation >> packageNameSchemaProperty [

	^ self
		  schemaPropertyNamed: 'package'
		  type: 'string'
		  description: 'Move the class to this package. Give tag alone to retag it inside the package it is already in.'
]

{ #category : 'private - request' }
MCPToolClassMutation >> parsedRequestFromToolRequest: request [

	^ request
]

{ #category : 'private - specs' }
MCPToolClassMutation >> renameNewClassNameSchemaProperty [

	^ self
		  schemaPropertyNamed: 'newName'
		  type: 'string'
		  description: 'Rename the class to this name, updating every reference to it.'
]

{ #category : 'private - errors' }
MCPToolClassMutation >> requestedContextFor: request checked: aBoolean [
	"The arguments an error reports, as the caller wrote them when the error came before they were checked."

	self subclassResponsibility
]

{ #category : 'private - schema' }
MCPToolClassMutation >> requiredInputProperties [

	^ self classToolSpec at: #requiredProperties ifAbsent: [ #( 'class' ) ]
]

{ #category : 'private - schema' }
MCPToolClassMutation >> sharedPoolsSchemaProperty [

	^ self
		  stringArraySchemaNamed: 'sharedPools'
		  description: 'Shared pools the class reads variables from; empty array clears.'
		  itemDescription: 'Pool name.'
]

{ #category : 'private - schema' }
MCPToolClassMutation >> sharedVariablesSchemaProperty [

	^ self
		  stringArraySchemaNamed: 'sharedVariables'
		  description: 'Class variables; empty array clears.'
		  itemDescription: 'Variable name.'
]

{ #category : 'private - schema' }
MCPToolClassMutation >> slotDeltaSchemaPropertyNamed: aName describedAs: aDescription [
	"Slots are patched, not replaced: naming one slot to add needs nothing else, where a replacement list has to be complete and a stale one silently drops a slot the caller did not know about."

	^ (MCPStructureProperties new
		   name: aName;
		   type: 'object';
		   description: aDescription;
		   yourself)
		  properties: {
				  (self stringArraySchemaNamed: 'add' description: 'Slots to add.' itemDescription: 'Slot name.').
				  (self stringArraySchemaNamed: 'remove' description: 'Slots to remove.' itemDescription: 'Slot name.').
				  (MCPStructureProperties new
					   name: 'rename';
					   type: 'object';
					   description: 'Slots to rename, as current name to new name. Values are migrated and references updated.';
					   yourself).
				  (self
					   stringArraySchemaNamed: 'pullUp'
					   description: 'Slots to move up into this class from the subclasses that define them.'
					   itemDescription: 'Slot name.').
				  (self
					   stringArraySchemaNamed: 'pushDown'
					   description: 'Slots to move down to every direct subclass.'
					   itemDescription: 'Slot name.').
				  (self
					   stringArraySchemaNamed: 'replace'
					   description: 'The complete slot list, replacing what the class has. Prefer add and remove.'
					   itemDescription: 'Slot name.') };
		  yourself
]

{ #category : 'private - schema' }
MCPToolClassMutation >> superclassNameSchemaProperty [

	^ self schemaPropertyNamed: 'superclass' type: 'string' description: 'Reparent the class under this superclass.'
]

{ #category : 'private - schema' }
MCPToolClassMutation >> tagSchemaProperty [

	^ self schemaPropertyNamed: 'tag' type: 'string' description: 'Move the class to this tag inside its package.'
]

{ #category : 'metadata' }
MCPToolClassMutation >> title [

	^ self classToolSpec at: #title
]

{ #category : 'private - schema' }
MCPToolClassMutation >> traitsSchemaProperty [

	^ self
		  stringArraySchemaNamed: 'traits'
		  description: 'Traits the class uses, class side included; empty array clears.'
		  itemDescription: 'Trait name.'
]
