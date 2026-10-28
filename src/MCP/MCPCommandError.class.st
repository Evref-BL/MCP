"
Structured error raised by MCP commands and queries.

It carries a stable error code and details dictionary so tools can return useful structured error output instead of only message text.
"
Class {
	#name : 'MCPCommandError',
	#superclass : 'Error',
	#instVars : [
		'errorCode',
		'details'
	],
	#category : 'MCP-Errors',
	#package : 'MCP',
	#tag : 'Errors'
}

{ #category : 'private - suggestions' }
MCPCommandError class >> detailsWith: associations suggestionsForClassNamed: className scopeName: scopeName [

	| details suggestions |
	details := associations asDictionary.
	suggestions := MCPScopeNameSuggester classSuggestionsFor: className.
	details
		at: #class put: className;
		at: #scope put: scopeName;
		at: #suggestions put: suggestions.
	^ details
]

{ #category : 'private - suggestions' }
MCPCommandError class >> detailsWith: associations suggestionsForPackageNamed: packageName scopeName: scopeName [

	| details suggestions |
	details := associations asDictionary.
	suggestions := MCPScopeNameSuggester packageSuggestionsFor: packageName.
	details
		at: #package put: packageName;
		at: #scope put: scopeName;
		at: #suggestions put: suggestions.
	^ details
]

{ #category : 'private - suggestions' }
MCPCommandError class >> messageForMissingKind: kind name: missingName scopeName: scopeName suggestions: suggestions [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: kind;
				  space;
				  nextPutAll: missingName asString;
				  nextPutAll: ' does not exist'.
			  scopeName ifNotNil: [
					  stream
						  nextPutAll: ' in ';
						  nextPutAll: scopeName asString;
						  nextPutAll: ' scope' ].
			  stream nextPut: $..
			  suggestions ifNotEmpty: [
					  stream nextPutAll: ' Did you mean: '.
					  suggestions do: [ :each | stream nextPutAll: each ] separatedBy: [ stream nextPutAll: ', ' ].
					  stream nextPut: $. ] ]
]

{ #category : 'private - suggestions' }
MCPCommandError class >> methodReferenceForClassName: className selector: selectorString classSide: classSide [

	^ String streamContents: [ :stream |
			  stream nextPutAll: className.
			  classSide ifTrue: [ stream nextPutAll: ' class' ].
			  stream
				  nextPutAll: '>>';
				  nextPutAll: selectorString ]
]

{ #category : 'private - suggestions' }
MCPCommandError class >> methodSuggestionForBehavior: aBehavior selector: aSelectorSymbol [

	| protocolName |
	protocolName := (aBehavior compiledMethodAt: aSelectorSymbol) protocol
		                ifNil: [ '' ]
		                ifNotNil: [ :protocol | protocol name asString ].
	^ {
		  (#class -> aBehavior instanceSide name asString).
		  (#side -> (aBehavior isClassSide ifTrue: [ 'class' ] ifFalse: [ 'instance' ])).
		  (#selector -> aSelectorSymbol asString).
		  (#protocol -> protocolName) } asDictionary
]

{ #category : 'private - suggestions' }
MCPCommandError class >> methodSuggestionsForClass: targetClass classSide: classSide selector: selectorSymbol [

	^ Array streamContents: [ :stream |
			  (self oppositeSideMethodSuggestionForClass: targetClass classSide: classSide selector: selectorSymbol) ifNotNil: [
				  :suggestion | stream nextPut: suggestion ].
			  (self superclassMethodSuggestionForClass: targetClass classSide: classSide selector: selectorSymbol) ifNotNil: [ :suggestion |
				  stream nextPut: suggestion ] ]
]

{ #category : 'private - suggestions' }
MCPCommandError class >> oppositeSideMethodSuggestionForClass: targetClass classSide: classSide selector: selectorSymbol [

	| oppositeBehavior |
	oppositeBehavior := classSide
		                    ifTrue: [ targetClass ]
		                    ifFalse: [ targetClass classSide ].
	(oppositeBehavior includesSelector: selectorSymbol) ifFalse: [ ^ nil ].
	^ self methodSuggestionForBehavior: oppositeBehavior selector: selectorSymbol
]

{ #category : 'signaling' }
MCPCommandError class >> signalClassAlreadyExistsNamed: aClassName [

	| details message |
	message := String streamContents: [ :stream | stream << 'Class ' << aClassName << ' already exists.' ].
	details := {
		           (#class -> aClassName).
		           (#guidance
		            ->
		            'Use class_get to inspect the existing class, or use the class update tools to modify it. Do not use class_create for existing classes.') }
		           asDictionary.
	^ self signalErrorCode: #ClassAlreadyExists message: message details: details
]

{ #category : 'signaling' }
MCPCommandError class >> signalErrorCode: anErrorCode message: aMessage details: aDictionary [

	^ self new
		  errorCode: anErrorCode;
		  details: aDictionary;
		  messageText: aMessage;
		  signal
]

{ #category : 'signaling' }
MCPCommandError class >> signalMissingClassNamed: aClassName [

	| details suggestions |
	details := self detailsWith: #(  ) suggestionsForClassNamed: aClassName scopeName: 'class'.
	suggestions := details at: #suggestions.
	^ self
		  signalErrorCode: #ClassNotFound
		  message: (self
				   messageForMissingKind: 'Class'
				   name: aClassName
				   scopeName: nil
				   suggestions: suggestions)
		  details: details
]

{ #category : 'signaling' }
MCPCommandError class >> signalMissingClassNamed: aClassName scopeName: scopeName [

	| details suggestions |
	details := self detailsWith: #(  ) suggestionsForClassNamed: aClassName scopeName: scopeName.
	suggestions := details at: #suggestions.
	^ self
		  signalErrorCode: #ClassNotFound
		  message: (self
				   messageForMissingKind: 'Class'
				   name: aClassName
				   scopeName: scopeName
				   suggestions: suggestions)
		  details: details
]

{ #category : 'signaling' }
MCPCommandError class >> signalMissingMethodInClassName: aClassName classSide: aBoolean selector: aSelectorString [

	| details message selectorSymbol suggestions targetClass |
	selectorSymbol := aSelectorString asSymbol.
	targetClass := Smalltalk globals at: aClassName asSymbol ifAbsent: [
			               message := String streamContents: [ :stream |
					                          stream << 'Class ' << aClassName << ' does not exist; cannot look up method '
					                          << (self methodReferenceForClassName: aClassName selector: aSelectorString classSide: aBoolean)
					                          << '.' ].
			               ^ self signalErrorCode: #ClassNotFound message: message details: {
					                 (#class -> aClassName).
					                 (#side -> (aBoolean
						                   ifTrue: [ 'class' ]
						                   ifFalse: [ 'instance' ])).
					                 (#selector -> aSelectorString) } asDictionary ].
	suggestions := self methodSuggestionsForClass: targetClass classSide: aBoolean selector: selectorSymbol.
	message := String streamContents: [ :stream |
			           stream << 'Method ' << (self methodReferenceForClassName: aClassName selector: aSelectorString classSide: aBoolean)
			           << ' does not exist.' ].
	suggestions ifNotEmpty: [
			message := String streamContents: [ :stream |
					           stream << message << ' Exact matches: ' << (', ' join: (suggestions collect: [ :each |
								             self
									             methodReferenceForClassName: (each at: #class)
									             selector: (each at: #selector)
									             classSide: (each at: #side ifAbsent: [ 'instance' ]) = 'class' ])) << '.' ] ].
	details := {
		           (#class -> aClassName).
		           (#side -> (aBoolean
			             ifTrue: [ 'class' ]
			             ifFalse: [ 'instance' ])).
		           (#selector -> aSelectorString) } asDictionary.
	suggestions ifNotEmpty: [ :matches | details at: #suggestions put: matches ].
	^ self signalErrorCode: #MethodNotFound message: message details: details
]

{ #category : 'signaling' }
MCPCommandError class >> signalMissingPackageNamed: aPackageName [

	| details suggestions |
	details := self detailsWith: #(  ) suggestionsForPackageNamed: aPackageName scopeName: 'package'.
	suggestions := details at: #suggestions.
	^ self
		  signalErrorCode: #PackageNotFound
		  message: (self
				   messageForMissingKind: 'Package'
				   name: aPackageName
				   scopeName: nil
				   suggestions: suggestions)
		  details: details
]

{ #category : 'signaling' }
MCPCommandError class >> signalMissingPackageNamed: aPackageName forClassNamed: aClassName [

	| details suggestions |
	details := self detailsWith: { (#class -> aClassName) } suggestionsForPackageNamed: aPackageName scopeName: 'package'.
	suggestions := details at: #suggestions.
	^ self
		  signalErrorCode: #PackageNotFound
		  message: (self
				   messageForMissingKind: 'Package'
				   name: aPackageName
				   scopeName: nil
				   suggestions: suggestions)
		  details: details
]

{ #category : 'signaling' }
MCPCommandError class >> signalMissingPackageNamed: aPackageName scopeName: scopeName [

	| details suggestions |
	details := self detailsWith: #(  ) suggestionsForPackageNamed: aPackageName scopeName: scopeName.
	suggestions := details at: #suggestions.
	^ self
		  signalErrorCode: #PackageNotFound
		  message: (self
				   messageForMissingKind: 'Package'
				   name: aPackageName
				   scopeName: scopeName
				   suggestions: suggestions)
		  details: details
]

{ #category : 'signaling' }
MCPCommandError class >> signalMissingProjectNamed: aProjectName [

	| message |
	message := String streamContents: [ :stream | stream << 'Project ' << aProjectName << ' does not exist.' ].
	^ self signalErrorCode: #ProjectNotFound message: message details: { (#project -> aProjectName) } asDictionary
]

{ #category : 'signaling' }
MCPCommandError class >> signalMissingSuperclassNamed: aSuperclassName forClassNamed: aClassName [

	| message |
	message := String streamContents: [ :stream | stream << 'Superclass ' << aSuperclassName << ' does not exist.' ].
	^ self signalErrorCode: #SuperclassNotFound message: message details: {
			  (#class -> aClassName).
			  (#superclass -> aSuperclassName) } asDictionary
]

{ #category : 'signaling' }
MCPCommandError class >> signalMissingTag: aTag packageName: aPackageName [

	| message |
	message := String streamContents: [ :stream |
		           stream << 'Package ' << aPackageName << ' does not have a tag named ' << aTag << '.' ].
	^ self signalErrorCode: #TagNotFound message: message details: {
			  (#package -> aPackageName).
			  (#tag -> aTag) } asDictionary
]

{ #category : 'signaling' }
MCPCommandError class >> signalMissingTag: aTag packageName: aPackageName forClassNamed: aClassName [

	| message |
	message := String streamContents: [ :stream |
		           stream << 'Package ' << aPackageName << ' does not have a tag named ' << aTag << '.' ].
	^ self signalErrorCode: #TagNotFound message: message details: {
			  (#class -> aClassName).
			  (#package -> aPackageName).
			  (#tag -> aTag) } asDictionary
]

{ #category : 'private - suggestions' }
MCPCommandError class >> superclassMethodSuggestionForClass: targetClass classSide: classSide selector: selectorSymbol [

	| behavior |
	behavior := classSide
		            ifTrue: [ targetClass classSide superclass ]
		            ifFalse: [ targetClass superclass ].
	[ behavior isNotNil ] whileTrue: [
			(behavior includesSelector: selectorSymbol) ifTrue: [ ^ self methodSuggestionForBehavior: behavior selector: selectorSymbol ].
			behavior := behavior superclass ].
	^ nil
]

{ #category : 'accessing' }
MCPCommandError >> details [

	^ details ifNil: [ Dictionary new ]
]

{ #category : 'accessing' }
MCPCommandError >> details: aDictionary [

	details := aDictionary ifNil: [ Dictionary new ] ifNotNil: [ aDictionary copy ]
]

{ #category : 'accessing' }
MCPCommandError >> errorCode [

	^ errorCode
]

{ #category : 'accessing' }
MCPCommandError >> errorCode: anObject [

	errorCode := anObject
]

{ #category : 'dispatching' }
MCPCommandError >> mcpCommandErrorDo: commandBlock otherwise: fallbackBlock [

	^ commandBlock cull: self
]

{ #category : 'dispatching' }
MCPCommandError >> mcpErrorResultForMutationTool: aTool action: action requestedContext: requestedContext summary: summary [

	^ aTool errorResultForCommandError: self action: action requestedContext: requestedContext
]

{ #category : 'accessing' }
MCPCommandError >> structuredDetails [

	| structured |
	structured := self details copy.
	structured at: #errorClass put: self class name.
	structured at: #errorCode put: self errorCode asString.
	structured at: #message put: self messageText.
	^ structured
]
