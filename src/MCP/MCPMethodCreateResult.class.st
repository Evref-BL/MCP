"
Structured result DTO for a successful method_create operation. It serializes the compiled method metadata and any included critiques.
"
Class {
	#name : 'MCPMethodCreateResult',
	#superclass : 'Object',
	#instVars : [
		'methodInfo',
		'critiques',
		'changeKind'
	],
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPMethodCreateResult class >> method: aCompiledMethod critiques: critiqueDictionaries [

	^ self
		  method: aCompiledMethod
		  critiques: critiqueDictionaries
		  changeKind: 'created'
]

{ #category : 'instance creation' }
MCPMethodCreateResult class >> method: aCompiledMethod critiques: critiqueDictionaries changeKind: changeKindString [

	^ self new
		  methodInfo: (MCPCompiledMethodInfo fromMethod: aCompiledMethod);
		  critiques: critiqueDictionaries;
		  changeKind: changeKindString;
		  yourself
]

{ #category : 'converting' }
MCPMethodCreateResult >> asDictionary [

	| data |
	data := self methodInfo asDictionaryIncludingSource: true.
	data at: #action put: 'create'.
	data at: #changeKind put: self changeKind.
	self critiques ifNotEmpty: [ data at: #critiques put: self critiques ].
	^ data
]

{ #category : 'accessing' }
MCPMethodCreateResult >> changeKind [

	^ changeKind
]

{ #category : 'accessing' }
MCPMethodCreateResult >> changeKind: aString [

	changeKind := aString
]

{ #category : 'accessing' }
MCPMethodCreateResult >> critiques [

	^ critiques ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPMethodCreateResult >> critiques: critiqueDictionaries [

	critiques := critiqueDictionaries ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPMethodCreateResult >> methodInfo [

	^ methodInfo
]

{ #category : 'accessing' }
MCPMethodCreateResult >> methodInfo: aMethodInfo [

	methodInfo := aMethodInfo
]
