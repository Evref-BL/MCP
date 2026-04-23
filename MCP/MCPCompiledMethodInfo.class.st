Class {
	#name : 'MCPCompiledMethodInfo',
	#superclass : 'Object',
	#instVars : [
		'className',
		'side',
		'selector',
		'protocol',
		'packageName',
		'isExtension',
		'source'
	],
	#category : 'MCP-Internal',
	#package : 'MCP',
	#tag : 'Internal'
}

{ #category : 'instance creation' }
MCPCompiledMethodInfo class >> fromMethod: aCompiledMethod [

	^ self new initializeFromMethod: aCompiledMethod
]

{ #category : 'converting' }
MCPCompiledMethodInfo >> asDictionaryIncludingSource: includeSource [

	| data |
	data := {
		        (#selector -> self selector).
		        (#className -> self className).
		        (#side -> self side).
		        (#packageName -> self packageName).
		        (#isExtension -> self isExtension).
		        (#protocol -> self protocol) } asDictionary.
	includeSource ifTrue: [ data at: #source put: self source ].
	^ data
]

{ #category : 'accessing' }
MCPCompiledMethodInfo >> className [

	^ className
]

{ #category : 'initialization' }
MCPCompiledMethodInfo >> initializeFromMethod: aCompiledMethod [

	| classPackageName methodPackageName |
	className := aCompiledMethod methodClass instanceSide name asString.
	side := aCompiledMethod methodClass isMeta
		        ifTrue: [ 'class' ]
		        ifFalse: [ 'instance' ].
	selector := aCompiledMethod selector asString.
	protocol := aCompiledMethod protocol
		            ifNil: [ '' ]
		            ifNotNil: [ :aProtocol | aProtocol name asString ].
	methodPackageName := aCompiledMethod package
		                     ifNil: [
		                     aCompiledMethod methodClass instanceSide
			                     package name asString ]
		                     ifNotNil: [ :aPackage | aPackage name asString ].
	packageName := methodPackageName.
	classPackageName := aCompiledMethod methodClass instanceSide package
		                    name asString.
	isExtension := packageName ~= classPackageName.
	source := aCompiledMethod sourceCode ifNil: [ '' ].
	^ self
]

{ #category : 'accessing' }
MCPCompiledMethodInfo >> isExtension [

	^ isExtension = true
]

{ #category : 'accessing' }
MCPCompiledMethodInfo >> packageName [

	^ packageName
]

{ #category : 'accessing' }
MCPCompiledMethodInfo >> protocol [

	^ protocol
]

{ #category : 'accessing' }
MCPCompiledMethodInfo >> selector [

	^ selector
]

{ #category : 'accessing' }
MCPCompiledMethodInfo >> side [

	^ side
]

{ #category : 'accessing' }
MCPCompiledMethodInfo >> source [

	^ source ifNil: [ '' ]
]
