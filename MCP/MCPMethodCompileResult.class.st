"
Structured result DTO for a successful edit-method compile operation. It serializes the compiled method metadata and any included critiques.
"
Class {
	#name : 'MCPMethodCompileResult',
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
MCPMethodCompileResult class >> method: aCompiledMethod critiques: critiqueDictionaries [

	^ self new
		  methodInfo: (MCPCompiledMethodInfo fromMethod: aCompiledMethod);
		  critiques: critiqueDictionaries;
		  yourself
]

{ #category : 'converting' }
MCPMethodCompileResult >> asDictionary [

	| data |
	data := self methodInfo asDictionaryIncludingSource: true.
	self critiques ifNotEmpty: [ data at: #critiques put: self critiques ].
	^ data
]

{ #category : 'accessing' }
MCPMethodCompileResult >> critiques [

	^ critiques ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPMethodCompileResult >> critiques: critiqueDictionaries [

	critiques := critiqueDictionaries ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPMethodCompileResult >> methodInfo [

	^ methodInfo
]

{ #category : 'accessing' }
MCPMethodCompileResult >> methodInfo: aMethodInfo [

	methodInfo := aMethodInfo
]
