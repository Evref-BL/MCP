"
Replaces the layout of an existing class using the Shift class installer and returns a DTO describing the old and new layout class names plus the resulting class state.
"
Class {
	#name : 'MCPReplaceClassLayoutCommand',
	#superclass : 'Object',
	#instVars : [
		'className',
		'layout'
	],
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPReplaceClassLayoutCommand class >> className: aClassName layout: aLayoutName [

	^ self new
		  className: aClassName;
		  layout: aLayoutName;
		  yourself
]

{ #category : 'accessing' }
MCPReplaceClassLayoutCommand >> className [

	^ className
]

{ #category : 'accessing' }
MCPReplaceClassLayoutCommand >> className: aString [

	className := aString
]

{ #category : 'executing' }
MCPReplaceClassLayoutCommand >> execute [

	| oldLayoutClassName targetClass updatedClass |
	targetClass := self targetClass.
	oldLayoutClassName := self layoutClassNameFromClass: targetClass.
	updatedClass := self replaceLayoutOn: targetClass.
	^ MCPReplaceClassLayoutResult
		  classInfo: (MCPClassInfo fromClass: updatedClass)
		  oldLayoutClassName: oldLayoutClassName
		  newLayoutClassName: self layout
]

{ #category : 'accessing' }
MCPReplaceClassLayoutCommand >> layout [

	^ layout
]

{ #category : 'accessing' }
MCPReplaceClassLayoutCommand >> layout: aLayoutName [

	layout := aLayoutName
]

{ #category : 'private' }
MCPReplaceClassLayoutCommand >> layoutClassNameFromClass: aClass [

	^ aClass classLayout class name asString
]

{ #category : 'private' }
MCPReplaceClassLayoutCommand >> replaceLayoutOn: aClass [

	^ ShiftClassInstaller
		  update: aClass
		  to: [ :builder | builder layout: self resolvedLayoutClass ]
]

{ #category : 'private' }
MCPReplaceClassLayoutCommand >> resolvedLayoutClass [

	| behavior |
	self layout ifNil: [ ^ nil ].
	behavior := Smalltalk globals at: self layout asSymbol ifAbsent: [
		            MCPCommandError
			            signalErrorCode: #LayoutClassNotFound
			            message:
			            'Layout class ' , self layout , ' does not exist.'
			            details: {
					            (#className -> self className).
					            (#layout -> self layout) } asDictionary ].
	((behavior isBehavior and: [ behavior inheritsFrom: AbstractLayout ])
		 or: [ behavior = AbstractLayout ]) ifFalse: [
		MCPCommandError
			signalErrorCode: #InvalidLayoutClass
			message: self layout , ' is not a layout class.'
			details: {
					(#className -> self className).
					(#layout -> self layout) } asDictionary ].
	^ behavior
]

{ #category : 'private' }
MCPReplaceClassLayoutCommand >> targetClass [

	^ Smalltalk globals
		  at: self className asSymbol
		  ifAbsent: [
		  MCPCommandError signalMissingClassNamed: self className ]
]
