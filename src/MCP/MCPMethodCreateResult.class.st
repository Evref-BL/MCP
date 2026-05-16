"
Structured result DTO for a successful edit-method create operation. It serializes the compiled method metadata and any included critiques.
"
Class {
	#name : 'MCPMethodCreateResult',
	#superclass : 'Object',
	#instVars : [
		'methodInfo',
		'critiques'
	],
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPMethodCreateResult class >> method: aCompiledMethod critiques: critiqueDictionaries [

	^ self new
		  methodInfo: (MCPCompiledMethodInfo fromMethod: aCompiledMethod);
		  critiques: critiqueDictionaries;
		  yourself
]

{ #category : 'converting' }
MCPMethodCreateResult >> asDictionary [

	| data |
	data := self methodInfo asDictionaryIncludingSource: true.
	data at: #operation put: 'create'.
	self critiques ifNotEmpty: [ data at: #critiques put: self critiques ].
	^ data
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
