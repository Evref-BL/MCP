"
Replaces the layout of an existing class using the Shift class installer and returns a DTO describing the old and new layout class names plus the resulting class state.
"
Class {
	#name : 'MCPReplaceClassLayoutCommand',
	#superclass : 'MCPClassCommand',
	#instVars : [
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
MCPReplaceClassLayoutCommand >> targetClass [

	^ MCPImageLookup classNamed: self className
]
