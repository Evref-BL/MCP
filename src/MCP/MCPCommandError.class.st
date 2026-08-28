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
		at: #className put: className;
		at: #scopeName put: scopeName;
		at: #suggestions put: suggestions.
	^ details
]

{ #category : 'private - suggestions' }
MCPCommandError class >> detailsWith: associations suggestionsForPackageNamed: packageName scopeName: scopeName [

	| details suggestions |
	details := associations asDictionary.
	suggestions := MCPScopeNameSuggester packageSuggestionsFor: packageName.
	details
		at: #packageName put: packageName;
		at: #scopeName put: scopeName;
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

{ #category : 'signaling' }
MCPCommandError class >> signalClassAlreadyExistsNamed: aClassName [

	| details message |
	message := 'Class ' , aClassName , ' already exists.'.
	details := {
		           (#className -> aClassName).
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
	details := self detailsWith: #(  ) suggestionsForClassNamed: aClassName scopeName: 'className'.
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

	| message |
	message := 'Method ' , (aBoolean
		            ifTrue: [ aClassName , ' class>>' , aSelectorString ]
		            ifFalse: [ aClassName , '>>' , aSelectorString ]) , ' does not exist.'.
	^ self signalErrorCode: #MethodNotFound message: message details: {
			  (#className -> aClassName).
			  (#classSide -> aBoolean).
			  (#selector -> aSelectorString) } asDictionary
]

{ #category : 'signaling' }
MCPCommandError class >> signalMissingPackageNamed: aPackageName [

	| details suggestions |
	details := self detailsWith: #(  ) suggestionsForPackageNamed: aPackageName scopeName: 'packageName'.
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
	details := self detailsWith: { (#className -> aClassName) } suggestionsForPackageNamed: aPackageName scopeName: 'packageName'.
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
	message := 'Project ' , aProjectName , ' does not exist.'.
	^ self signalErrorCode: #ProjectNotFound message: message details: { (#projectName -> aProjectName) } asDictionary
]

{ #category : 'signaling' }
MCPCommandError class >> signalMissingSuperclassNamed: aSuperclassName forClassNamed: aClassName [

	| message |
	message := 'Superclass ' , aSuperclassName , ' does not exist.'.
	^ self signalErrorCode: #SuperclassNotFound message: message details: {
			  (#className -> aClassName).
			  (#superclassName -> aSuperclassName) } asDictionary
]

{ #category : 'signaling' }
MCPCommandError class >> signalMissingTag: aTag packageName: aPackageName [

	| message |
	message := 'Package ' , aPackageName , ' does not have a tag named ' , aTag , '.'.
	^ self signalErrorCode: #TagNotFound message: message details: {
			  (#packageName -> aPackageName).
			  (#tag -> aTag) } asDictionary
]

{ #category : 'signaling' }
MCPCommandError class >> signalMissingTag: aTag packageName: aPackageName forClassNamed: aClassName [

	| message |
	message := 'Package ' , aPackageName , ' does not have a tag named ' , aTag , '.'.
	^ self signalErrorCode: #TagNotFound message: message details: {
			  (#className -> aClassName).
			  (#packageName -> aPackageName).
			  (#tag -> aTag) } asDictionary
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
