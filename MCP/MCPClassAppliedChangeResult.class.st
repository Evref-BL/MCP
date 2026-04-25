"
Result DTO for an edit-class update after the selected narrow command has run. It carries the update plan and the narrow command result, and converts them to the flattened tool data shape plus nested updatePlan and appliedChange details.
"
Class {
	#name : 'MCPClassAppliedChangeResult',
	#superclass : 'Object',
	#instVars : [
		'updatePlan',
		'changeResult'
	],
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPClassAppliedChangeResult class >> updatePlan: anUpdatePlan changeResult: aChangeResult [

	^ self new
		  updatePlan: anUpdatePlan;
		  changeResult: aChangeResult;
		  yourself
]

{ #category : 'converting' }
MCPClassAppliedChangeResult >> appliedChangeDictionary [

	^ {
		  (#updateAction -> self updateAction).
		  (#resultClassName -> self changeResult class name asString).
		  (#result -> self changeResult asDictionary) } asDictionary
]

{ #category : 'converting' }
MCPClassAppliedChangeResult >> asDictionary [

	| data |
	data := self changeResult asDictionary copy.
	data at: #operation put: 'update'.
	data at: #updateAction put: self updateAction.
	data at: #updatePlan put: self updatePlan asDictionary.
	data at: #appliedChange put: self appliedChangeDictionary.
	^ data
]

{ #category : 'accessing' }
MCPClassAppliedChangeResult >> changeResult [

	^ changeResult
]

{ #category : 'accessing' }
MCPClassAppliedChangeResult >> changeResult: aResult [

	changeResult := aResult
]

{ #category : 'accessing' }
MCPClassAppliedChangeResult >> updateAction [

	^ self updatePlan updateAction
]

{ #category : 'accessing' }
MCPClassAppliedChangeResult >> updatePlan [

	^ updatePlan
]

{ #category : 'accessing' }
MCPClassAppliedChangeResult >> updatePlan: anUpdatePlan [

	updatePlan := anUpdatePlan
]
