"
Replaces the layout of an existing class using the Shift class installer and answers the updated class.
"
Class {
	#name : 'MCPReplaceClassLayoutCommand',
	#superclass : 'MCPClassCommand',
	#instVars : [
		'layout'
	],
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
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

	^ self installing: [ self replaceLayoutOn: self currentClass ]
]

{ #category : 'accessing' }
MCPReplaceClassLayoutCommand >> layout [

	^ layout
]

{ #category : 'accessing' }
MCPReplaceClassLayoutCommand >> layout: aLayoutName [

	layout := aLayoutName
]
