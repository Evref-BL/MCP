"
Compact public result for method compilation.

It reports whether compiling the source created a new method or replaced an existing method, plus optional critiques.
"
Class {
	#name : 'MCPMethodCompileResult',
	#superclass : 'MCPResult',
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
MCPMethodCompileResult class >> method: aCompiledMethod critiques: critiqueDictionaries [

	^ self method: aCompiledMethod critiques: critiqueDictionaries changeKind: 'created'
]

{ #category : 'instance creation' }
MCPMethodCompileResult class >> method: aCompiledMethod critiques: critiqueDictionaries changeKind: changeKindString [

	^ self new
		  methodInfo: (MCPCompiledMethodInfo fromMethod: aCompiledMethod);
		  critiques: critiqueDictionaries;
		  changeKind: changeKindString;
		  yourself
]

{ #category : 'converting' }
MCPMethodCompileResult >> asDictionary [

	| data |
	data := Dictionary new.
	data at: #changeKind put: self changeKind.
	self critiques ifNotEmpty: [ data at: #critiques put: self critiques ].
	^ data
]

{ #category : 'accessing' }
MCPMethodCompileResult >> changeKind [

	^ changeKind
]

{ #category : 'accessing' }
MCPMethodCompileResult >> changeKind: aString [

	changeKind := aString
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
