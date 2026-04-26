"
Structured result DTO for edit-method update. It combines the selected update plan with the narrow change result returned by the internal action.
"
Class {
	#name : 'MCPMethodAppliedChangeResult',
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
MCPMethodAppliedChangeResult class >> updatePlan: anUpdatePlan changeResult: aChangeResult [

	^ self new
		  updatePlan: anUpdatePlan;
		  changeResult: aChangeResult;
		  yourself
]

{ #category : 'converting' }
MCPMethodAppliedChangeResult >> appliedChangeDictionary [

	^ {
		  (#updateAction -> self updateAction).
		  (#resultClassName -> self changeResult class name asString).
		  (#result -> self changeResult asDictionary) } asDictionary
]

{ #category : 'converting' }
MCPMethodAppliedChangeResult >> asDictionary [

	| data |
	data := self changeResult asDictionary copy.
	data at: #operation put: 'update'.
	data at: #updateAction put: self updateAction.
	data at: #updatePlan put: self updatePlan asDictionary.
	data at: #appliedChange put: self appliedChangeDictionary.
	^ data
]

{ #category : 'accessing' }
MCPMethodAppliedChangeResult >> changeResult [

	^ changeResult
]

{ #category : 'accessing' }
MCPMethodAppliedChangeResult >> changeResult: aResult [

	changeResult := aResult
]

{ #category : 'accessing' }
MCPMethodAppliedChangeResult >> updateAction [

	^ self updatePlan updateAction
]

{ #category : 'accessing' }
MCPMethodAppliedChangeResult >> updatePlan [

	^ updatePlan
]

{ #category : 'accessing' }
MCPMethodAppliedChangeResult >> updatePlan: anUpdatePlan [

	updatePlan := anUpdatePlan
]
