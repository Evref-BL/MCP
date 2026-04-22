Class {
	#name : 'MCPCommandError',
	#superclass : 'Error',
	#instVars : [
		'errorCode',
		'details'
	],
	#category : 'MCP-Internal',
	#package : 'MCP',
	#tag : 'Internal'
}

{ #category : 'signaling' }
MCPCommandError class >> signalClassAlreadyExistsNamed: aClassName [

	| message |
	message := 'Class ' , aClassName , ' already exists.'.
	^ self
		  signalErrorCode: #ClassAlreadyExists
		  message: message
		  details: { (#className -> aClassName) } asDictionary
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

	| message |
	message := 'Class ' , aClassName , ' does not exist.'.
	^ self
		  signalErrorCode: #ClassNotFound
		  message: message
		  details: { (#className -> aClassName) } asDictionary
]

{ #category : 'signaling' }
MCPCommandError class >> signalMissingMethodInClassName: aClassName classSide: aBoolean selector: aSelectorString [

	| message |
	message := 'Method ' , (aBoolean
		            ifTrue: [ aClassName , ' class>>' , aSelectorString ]
		            ifFalse: [ aClassName , '>>' , aSelectorString ])
	           , ' does not exist.'.
	^ self signalErrorCode: #MethodNotFound message: message details: {
			  (#className -> aClassName).
			  (#classSide -> aBoolean).
			  (#selector -> aSelectorString) } asDictionary
]

{ #category : 'signaling' }
MCPCommandError class >> signalMissingPackageNamed: aPackageName [

	| message |
	message := 'Package ' , aPackageName , ' does not exist.'.
	^ self
		  signalErrorCode: #PackageNotFound
		  message: message
		  details: { (#packageName -> aPackageName) } asDictionary
]

{ #category : 'signaling' }
MCPCommandError class >> signalMissingPackageNamed: aPackageName forClassNamed: aClassName [

	| message |
	message := 'Package ' , aPackageName , ' does not exist.'.
	^ self signalErrorCode: #PackageNotFound message: message details: {
			  (#className -> aClassName).
			  (#packageName -> aPackageName) } asDictionary
]

{ #category : 'signaling' }
MCPCommandError class >> signalMissingProjectNamed: aProjectName [

	| message |
	message := 'Project ' , aProjectName , ' does not exist.'.
	^ self
		  signalErrorCode: #ProjectNotFound
		  message: message
		  details: { (#projectName -> aProjectName) } asDictionary
]

{ #category : 'signaling' }
MCPCommandError class >> signalMissingSuperclassNamed: aSuperclassName forClassNamed: aClassName [

	| message |
	message := 'Superclass ' , aSuperclassName , ' does not exist.'.
	^ self
		  signalErrorCode: #SuperclassNotFound
		  message: message
		  details: {
				  (#className -> aClassName).
				  (#superclassName -> aSuperclassName) } asDictionary
]

{ #category : 'signaling' }
MCPCommandError class >> signalMissingTag: aTag packageName: aPackageName [

	| message |
	message := 'Package ' , aPackageName , ' does not have a tag named '
	           , aTag , '.'.
	^ self signalErrorCode: #TagNotFound message: message details: {
			  (#packageName -> aPackageName).
			  (#tag -> aTag) } asDictionary
]

{ #category : 'signaling' }
MCPCommandError class >> signalMissingTag: aTag packageName: aPackageName forClassNamed: aClassName [

	| message |
	message := 'Package ' , aPackageName , ' does not have a tag named '
	           , aTag , '.'.
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

	details := aDictionary
		           ifNil: [ Dictionary new ]
		           ifNotNil: [ aDictionary copy ]
]

{ #category : 'accessing' }
MCPCommandError >> errorCode [

	^ errorCode
]

{ #category : 'accessing' }
MCPCommandError >> errorCode: anObject [

	errorCode := anObject
]

{ #category : 'accessing' }
MCPCommandError >> structuredDetails [

	| structured |
	structured := self details copy.
	structured at: #errorClass put: self errorCode asString.
	structured at: #message put: self messageText.
	^ structured
]
