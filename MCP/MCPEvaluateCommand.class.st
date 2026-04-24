"
Command that evaluates Smalltalk code for the evaluate tool and returns a result data dictionary.
"
Class {
	#name : 'MCPEvaluateCommand',
	#superclass : 'Object',
	#instVars : [
		'request',
		'resultPreviewCharacterLimit',
		'tool'
	],
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPEvaluateCommand class >> tool: aTool request: aRequest resultPreviewCharacterLimit: anInteger [

	^ self new
		  initializeTool: aTool
		  request: aRequest
		  resultPreviewCharacterLimit: anInteger
]

{ #category : 'executing' }
MCPEvaluateCommand >> execute [

	| answer compiler notice |
	compiler := SmalltalkImage current compiler.
	compiler compilationContext isScripting: true.
	notice := nil.
	compiler failBlock: [ :aNotice |
		notice := aNotice.
		nil ].
	answer := [ compiler evaluate: request code ]
		          on: Error
		          do: [ :error | ^ self runtimeFailureFor: error ].
	notice ifNotNil: [ ^ self syntaxFailureFor: notice ].
	^ {
		  (#status -> #ok).
		  (#data -> {
			   (#resultClassName -> answer class name asString).
			   (#resultPrintString
			    -> (answer printStringLimitedTo: resultPreviewCharacterLimit)) }
			   asDictionary) } asDictionary
]

{ #category : 'initialization' }
MCPEvaluateCommand >> initializeTool: aTool request: aRequest resultPreviewCharacterLimit: anInteger [

	tool := aTool.
	request := aRequest.
	resultPreviewCharacterLimit := anInteger.
	^ self
]

{ #category : 'accessing' }
MCPEvaluateCommand >> request [

	^ request
]

{ #category : 'accessing' }
MCPEvaluateCommand >> resultPreviewCharacterLimit [

	^ resultPreviewCharacterLimit
]

{ #category : 'private' }
MCPEvaluateCommand >> runtimeFailureFor: anError [

	^ {
		  (#status -> #error).
		  (#summary -> (tool runtimeFailureMessageFor: anError)).
		  (#error -> (tool errorDetailsFor: anError)) } asDictionary
]

{ #category : 'private' }
MCPEvaluateCommand >> syntaxFailureFor: aNotice [

	| details |
	details := tool errorDetailsFor: aNotice.
	details at: #description put: 'Compilation failed before evaluation.'.
	details at: #position put: aNotice position.
	^ {
		  (#status -> #error).
		  (#summary -> (tool syntaxFailureMessageFor: aNotice)).
		  (#error -> details) } asDictionary
]

{ #category : 'accessing' }
MCPEvaluateCommand >> tool [

	^ tool
]
