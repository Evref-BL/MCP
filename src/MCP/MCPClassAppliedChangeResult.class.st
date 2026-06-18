"
Compact public result for a class update selected and executed by a class mutation tool.
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
MCPClassAppliedChangeResult >> asDictionary [

	^ Dictionary new
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
