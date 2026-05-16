"
DTO describing one method rewrite change.

It records the affected method identity and, when requested, the before and after source strings returned by the rewriter.
"
Class {
	#name : 'MCPMethodRewriteChangeInfo',
	#superclass : 'Object',
	#instVars : [
		'className',
		'classSide',
		'selector',
		'packageName',
		'protocol',
		'oldSource',
		'newSource',
		'includeSources'
	],
	#category : 'MCP-DTOs',
	#package : 'MCP',
	#tag : 'DTOs'
}

{ #category : 'instance creation' }
MCPMethodRewriteChangeInfo class >> fromChange: aChange includeSources: aBoolean [

	^ self new initializeFromChange: aChange includeSources: aBoolean
]

{ #category : 'converting' }
MCPMethodRewriteChangeInfo >> asDictionary [

	| data |
	data := {
		        (#className -> self className).
		        (#classSide -> self classSide).
		        (#selector -> self selector).
		        (#packageName -> self packageName).
		        (#protocol -> self protocol) } asDictionary.
	self includeSources ifTrue: [
		data at: #oldSource put: self oldSource.
		data at: #newSource put: self newSource ].
	^ data
]

{ #category : 'accessing' }
MCPMethodRewriteChangeInfo >> className [

	^ className
]

{ #category : 'accessing' }
MCPMethodRewriteChangeInfo >> classSide [

	^ classSide = true
]

{ #category : 'accessing' }
MCPMethodRewriteChangeInfo >> includeSources [

	^ includeSources ~= false
]

{ #category : 'initialization' }
MCPMethodRewriteChangeInfo >> initializeFromChange: aChange includeSources: aBoolean [

	| behavior compiledMethod methodInfo |
	behavior := aChange changeClass.
	selector := aChange selector asString.
	classSide := behavior isMeta.
	className := classSide
		             ifTrue: [ behavior instanceSide name asString ]
		             ifFalse: [ behavior name asString ].
	compiledMethod := behavior
		                  compiledMethodAt: aChange selector
		                  ifAbsent: [ nil ].
	compiledMethod
		ifNil: [
			packageName := ''.
			protocol := ''.
			oldSource := '' ]
		ifNotNil: [
			methodInfo := MCPCompiledMethodInfo fromMethod: compiledMethod.
			packageName := methodInfo packageName.
			protocol := methodInfo protocol.
			oldSource := compiledMethod sourceCode ifNil: [ '' ] ].
	newSource := aChange source ifNil: [ '' ].
	includeSources := aBoolean.
	^ self
]

{ #category : 'accessing' }
MCPMethodRewriteChangeInfo >> newSource [

	^ newSource ifNil: [ '' ]
]

{ #category : 'accessing' }
MCPMethodRewriteChangeInfo >> oldSource [

	^ oldSource ifNil: [ '' ]
]

{ #category : 'accessing' }
MCPMethodRewriteChangeInfo >> packageName [

	^ packageName ifNil: [ '' ]
]

{ #category : 'accessing' }
MCPMethodRewriteChangeInfo >> protocol [

	^ protocol ifNil: [ '' ]
]

{ #category : 'accessing' }
MCPMethodRewriteChangeInfo >> selector [

	^ selector
]
