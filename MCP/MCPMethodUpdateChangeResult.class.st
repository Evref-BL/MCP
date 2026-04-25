"
DTO for the narrow method edit performed by an edit-method update request, such as a rename or protocol change.
"
Class {
	#name : 'MCPMethodUpdateChangeResult',
	#superclass : 'Object',
	#instVars : [
		'methodInfo',
		'oldSelector',
		'newSelector',
		'oldProtocol',
		'newProtocol',
		'updateAction'
	],
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPMethodUpdateChangeResult class >> updateAction: anUpdateAction method: aCompiledMethod [

	^ self new
		  updateAction: anUpdateAction;
		  methodInfo: (MCPCompiledMethodInfo fromMethod: aCompiledMethod);
		  yourself
]

{ #category : 'converting' }
MCPMethodUpdateChangeResult >> asDictionary [

	| data |
	data := self methodInfo asDictionaryIncludingSource: true.
	data at: #updateAction put: self updateAction.
	self oldSelector ifNotNil: [
		data at: #oldSelector put: self oldSelector ].
	self newSelector ifNotNil: [
		data at: #newSelector put: self newSelector ].
	self oldProtocol ifNotNil: [
		data at: #oldProtocol put: self oldProtocol ].
	self newProtocol ifNotNil: [
		data at: #newProtocol put: self newProtocol ].
	^ data
]

{ #category : 'accessing' }
MCPMethodUpdateChangeResult >> methodInfo [

	^ methodInfo
]

{ #category : 'accessing' }
MCPMethodUpdateChangeResult >> methodInfo: aMethodInfo [

	methodInfo := aMethodInfo
]

{ #category : 'accessing' }
MCPMethodUpdateChangeResult >> newProtocol [

	^ newProtocol
]

{ #category : 'accessing' }
MCPMethodUpdateChangeResult >> newProtocol: aString [

	newProtocol := aString
]

{ #category : 'accessing' }
MCPMethodUpdateChangeResult >> newSelector [

	^ newSelector
]

{ #category : 'accessing' }
MCPMethodUpdateChangeResult >> newSelector: aString [

	newSelector := aString
]

{ #category : 'accessing' }
MCPMethodUpdateChangeResult >> oldProtocol [

	^ oldProtocol
]

{ #category : 'accessing' }
MCPMethodUpdateChangeResult >> oldProtocol: aString [

	oldProtocol := aString
]

{ #category : 'accessing' }
MCPMethodUpdateChangeResult >> oldSelector [

	^ oldSelector
]

{ #category : 'accessing' }
MCPMethodUpdateChangeResult >> oldSelector: aString [

	oldSelector := aString
]

{ #category : 'accessing' }
MCPMethodUpdateChangeResult >> updateAction [

	^ updateAction
]

{ #category : 'accessing' }
MCPMethodUpdateChangeResult >> updateAction: anObject [

	updateAction := anObject
]
