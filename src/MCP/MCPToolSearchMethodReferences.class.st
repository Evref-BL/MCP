"
Concrete method_reference_search tool. It answers where a name is used, working out from the name itself whether that means implementors and senders of a selector, references to a class, or references to a variable.
"
Class {
	#name : 'MCPToolSearchMethodReferences',
	#superclass : 'MCPToolMethodLookupOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolSearchMethodReferences class >> toolName [

	^ 'method_reference_search'
]

{ #category : 'metadata' }
MCPToolSearchMethodReferences >> defaultExposure [

	^ 'static'
]

{ #category : 'metadata' }
MCPToolSearchMethodReferences >> description [

	^ 'Find where a name is used. A selector answers its implementors and its senders, a class name answers the methods referring to the class, any other name answers the methods referring to the variable. Use kind to ask for one of them.'
]

{ #category : 'private - lookup' }
MCPToolSearchMethodReferences >> entriesForKinds: kinds name: aName queryRequest: queryRequest [

	| entries |
	entries := OrderedCollection new.
	kinds do: [ :kind | entries addAll: (self entriesOfKind: kind forName: aName queryRequest: queryRequest) ].
	^ entries asArray
]

{ #category : 'private - lookup' }
MCPToolSearchMethodReferences >> entriesForKinds: kinds name: aName queryRequest: queryRequest ifUnknown: aBlock [
	"A reading that does not resolve is not a failure while another reading is still to be tried, so what
	it said is kept for the message that reports both."

	^ [ self entriesForKinds: kinds name: aName queryRequest: queryRequest ]
		  on: Error
		  do: [ :error | aBlock value: error ]
]

{ #category : 'private - lookup' }
MCPToolSearchMethodReferences >> entriesOfKind: aKind forName: aName queryRequest: queryRequest [

	| entries |
	entries := aKind = 'implementors'
		           ifTrue: [ self implementorEntriesForSelector: aName queryRequest: queryRequest ]
		           ifFalse: [
			           aKind = 'senders'
				           ifTrue: [ self selectorReferenceEntriesForSelector: aName queryRequest: queryRequest ]
				           ifFalse: [
					           aKind = 'class'
						           ifTrue: [ self classReferenceEntriesForClassNamed: aName queryRequest: queryRequest ]
						           ifFalse: [ self variableReferenceEntriesForVariableNamed: aName queryRequest: queryRequest ] ] ].
	^ entries collect: [ :each |
		  | entry |
		  entry := each copy.
		  entry at: #reference put: aKind.
		  entry ]
]

{ #category : 'private - schema' }
MCPToolSearchMethodReferences >> extraInputProperties [

	^ { ((self schemaPropertyNamed: 'kind' type: 'string' description: 'What the name is, when it should not be worked out from the name.')
		   enum: self referenceKinds;
		   yourself) }
]

{ #category : 'private - lookup' }
MCPToolSearchMethodReferences >> fallbackKindsFor: kinds [
	"A lowercase name is read as a selector, but an instance variable looks exactly the same, so a
	selector that nothing implements or sends is tried as a variable instead, and the other way round."

	(kinds includes: 'implementors') ifTrue: [ ^ #( 'variable' ) ].
	(kinds includes: 'variable') ifTrue: [ ^ #( 'implementors' 'senders' ) ].
	^ #(  )
]

{ #category : 'private - lookup' }
MCPToolSearchMethodReferences >> kindsForName: aName request: request [

	(self requestedKindIn: request) ifNotNil: [ :requested | ^ { requested } ].
	(aName includes: $:) ifTrue: [ ^ #( 'implementors' 'senders' ) ].
	aName first isLetter ifFalse: [ ^ #( 'implementors' 'senders' ) ].
	aName first isUppercase ifFalse: [ ^ #( 'implementors' 'senders' ) ].
	^ (Smalltalk globals at: aName asSymbol ifAbsent: [ nil ]) isBehavior
		  ifTrue: [ #( 'class' ) ]
		  ifFalse: [ #( 'variable' ) ]
]

{ #category : 'private - schema' }
MCPToolSearchMethodReferences >> lookupArgumentDescription [

	^ 'The selector, class name or variable name whose uses should be returned.'
]

{ #category : 'private - schema' }
MCPToolSearchMethodReferences >> lookupArgumentName [

	^ 'name'
]

{ #category : 'private - template' }
MCPToolSearchMethodReferences >> queryEntriesForQueryRequest: queryRequest [

	| entries fallback kinds name failures |
	name := self requiredLookupPatternFromQueryRequest: queryRequest.
	kinds := self kindsForName: name request: queryRequest.
	(self requestedKindIn: queryRequest) ifNotNil: [ ^ self entriesForKinds: kinds name: name queryRequest: queryRequest ].
	failures := OrderedCollection new.
	entries := self
		           entriesForKinds: kinds
		           name: name
		           queryRequest: queryRequest
		           ifUnknown: [ :error |
		           failures add: error.
		           nil ].
	(entries isNotNil and: [ entries notEmpty ]) ifTrue: [ ^ entries ].
	fallback := self
		            entriesForKinds: (self fallbackKindsFor: kinds)
		            name: name
		            queryRequest: queryRequest
		            ifUnknown: [ :error |
		            failures add: error.
		            nil ].
	(fallback isNotNil and: [ fallback notEmpty ]) ifTrue: [ ^ fallback ].
	failures ifNotEmpty: [ ^ self signalUnknownName: name failures: failures ].
	^ entries ifNil: [ #(  ) ]
]

{ #category : 'metadata' }
MCPToolSearchMethodReferences >> referenceKinds [

	^ #( 'implementors' 'senders' 'class' 'variable' )
]

{ #category : 'private - lookup' }
MCPToolSearchMethodReferences >> requestedKindIn: queryRequest [

	^ (queryRequest fieldFilters ifNil: [ Dictionary new ]) at: 'kind' ifAbsent: [ nil ]
]

{ #category : 'private - lookup' }
MCPToolSearchMethodReferences >> searchRequestFromToolRequest: request [

	| searchRequest |
	searchRequest := super searchRequestFromToolRequest: request.
	searchRequest fieldFilters: (self fieldFiltersFromRequest: request fieldNames: #( 'kind' )).
	^ searchRequest
]

{ #category : 'private - lookup' }
MCPToolSearchMethodReferences >> signalUnknownName: aName failures: failures [
	"Both readings were tried; what each of them said is kept, so a real failure underneath is not lost."

	MCPCommandError
		signalErrorCode: #ReferenceSubjectNotFound
		message: 'There is no class, variable or selector named ' , aName , ' in the requested scope.'
		details: {
				(#name -> aName).
				(#attempted -> ((failures collect: [ :each | each messageText ]) asArray)) } asDictionary
]

{ #category : 'metadata' }
MCPToolSearchMethodReferences >> title [

	^ 'Search Method References'
]
