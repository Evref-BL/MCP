"
Compact public result for a method update selected and executed by a method mutation tool.
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
MCPMethodAppliedChangeResult >> asDictionary [

	^ self changeResult asDictionary copy
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
