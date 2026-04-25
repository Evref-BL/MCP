"
Parsed edit-method update request. It uses patch semantics: exactly one method update field, such as newSelector or protocol, selects the internal update action for an existing method.
"
Class {
	#name : 'MCPMethodUpdateRequest',
	#superclass : 'Object',
	#instVars : [
		'className',
		'classSide',
		'selector',
		'newSelector',
		'protocol',
		'permutation',
		'force',
		'suppliedProperties',
		'refactoringScopeSpec'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPMethodUpdateRequest class >> fromRequest: request tool: aTool [

	| parsedRequest |
	parsedRequest := self new initializeFromRequest: request.
	parsedRequest hasRenameUpdate
		ifTrue: [
			parsedRequest refactoringScopeSpec:
				(aTool refactoringScopeSpecFromRequest: request) ]
		ifFalse: [
			parsedRequest refactoringScopeSpec: (MCPRefactoringScopeSpec
					 packageNames: #(  )
					 classNames: #(  )
					 hierarchyClassNames: #(  )) ].
	^ parsedRequest
]

{ #category : 'accessing' }
MCPMethodUpdateRequest >> className [

	^ className
]

{ #category : 'accessing' }
MCPMethodUpdateRequest >> classSide [

	^ classSide = true
]

{ #category : 'converting' }
MCPMethodUpdateRequest >> contextValueForPropertyNamed: propertyName [

	propertyName = 'newSelector' ifTrue: [ ^ self newSelector ].
	propertyName = 'protocol' ifTrue: [ ^ self protocol ].
	propertyName = 'permutation' ifTrue: [ ^ self permutation ].
	^ nil
]

{ #category : 'accessing' }
MCPMethodUpdateRequest >> force [

	^ force = true
]

{ #category : 'testing' }
MCPMethodUpdateRequest >> hasPermutation [

	^ self hasSuppliedPropertyNamed: 'permutation'
]

{ #category : 'testing' }
MCPMethodUpdateRequest >> hasProtocolUpdate [

	^ self hasSuppliedPropertyNamed: 'protocol'
]

{ #category : 'testing' }
MCPMethodUpdateRequest >> hasRenameUpdate [

	^ self hasSuppliedPropertyNamed: 'newSelector'
]

{ #category : 'testing' }
MCPMethodUpdateRequest >> hasSuppliedPropertyNamed: aPropertyName [

	^ self suppliedProperties includes: aPropertyName asString
]

{ #category : 'private - request' }
MCPMethodUpdateRequest >> identityPermutationForSelector: aSelector [

	^ (1 to: aSelector numArgs) asArray
]

{ #category : 'initialization' }
MCPMethodUpdateRequest >> initializeFromRequest: request [

	suppliedProperties := self updatePropertyNames select: [ :each |
		                      request hasArgumentNamed: each ].
	className := request stringArgumentNamed: 'className'.
	classSide := request booleanArgumentNamed: 'classSide' default: false.
	selector := request stringArgumentNamed: 'selector'.
	newSelector := request stringArgumentNamed: 'newSelector'.
	protocol := request stringArgumentNamed: 'protocol'.
	permutation := self
		               permutationFromRequest: request
		               selector: selector asSymbol.
	force := request booleanArgumentNamed: 'force' default: false.
	^ self
]

{ #category : 'accessing' }
MCPMethodUpdateRequest >> newSelector [

	^ newSelector
]

{ #category : 'accessing' }
MCPMethodUpdateRequest >> permutation [

	^ permutation ifNil: [ #(  ) ]
]

{ #category : 'private - request' }
MCPMethodUpdateRequest >> permutationFromRequest: request selector: aSelector [

	| requestedPermutation |
	requestedPermutation := request
		                        arrayArgumentNamed: 'permutation'
		                        ifAbsent: [
		                        ^ self identityPermutationForSelector:
			                          aSelector ].
	self validatePermutation: requestedPermutation forSelector: aSelector.
	^ requestedPermutation
]

{ #category : 'accessing' }
MCPMethodUpdateRequest >> protocol [

	^ protocol
]

{ #category : 'accessing' }
MCPMethodUpdateRequest >> refactoringScopeSpec [

	^ refactoringScopeSpec
]

{ #category : 'accessing' }
MCPMethodUpdateRequest >> refactoringScopeSpec: aRefactoringScopeSpec [

	refactoringScopeSpec := aRefactoringScopeSpec
]

{ #category : 'converting' }
MCPMethodUpdateRequest >> requestedContext [

	| context |
	context := Dictionary new.
	context at: #className put: self className.
	context at: #classSide put: self classSide.
	context at: #selector put: self selector.
	self suppliedProperties do: [ :propertyName |
		context
			at: propertyName asSymbol
			put: (self contextValueForPropertyNamed: propertyName) ].
	^ context
]

{ #category : 'accessing' }
MCPMethodUpdateRequest >> requestedMethodUpdateActions [

	| actions |
	actions := OrderedCollection new.
	self hasRenameUpdate ifTrue: [ actions add: 'rename' ].
	self hasProtocolUpdate ifTrue: [ actions add: 'changeProtocol' ].
	^ actions asArray
]

{ #category : 'accessing' }
MCPMethodUpdateRequest >> selector [

	^ selector
]

{ #category : 'accessing' }
MCPMethodUpdateRequest >> suppliedProperties [

	^ suppliedProperties ifNil: [ #(  ) ]
]

{ #category : 'private - request' }
MCPMethodUpdateRequest >> updatePropertyNames [

	^ #( 'newSelector' 'protocol' 'permutation' )
]

{ #category : 'validating' }
MCPMethodUpdateRequest >> validateForUpdate [

	self hasPermutation ifTrue: [
		self hasRenameUpdate ifFalse: [
			MCPCommandError
				signalErrorCode: #PermutationRequiresMethodRename
				message:
				'permutation is only valid when update renames a method with newSelector.'
				details: self requestedContext ] ].
	^ self
]

{ #category : 'private - request' }
MCPMethodUpdateRequest >> validatePermutation: requestedPermutation forSelector: aSelector [

	| expected |
	expected := self identityPermutationForSelector: aSelector.
	requestedPermutation size = expected size ifFalse: [
		Error signal:
			'permutation must contain one index for each method argument.' ].
	requestedPermutation asSet = expected asSet ifFalse: [
		Error signal:
			'permutation must be a reordering of the integers from 1 to '
			, expected size asString , '.' ]
]
