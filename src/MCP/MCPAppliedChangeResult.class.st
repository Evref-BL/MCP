"
Abstract result for a planned update that has been applied.

Subclasses decide how much of the applied change to expose in #asDictionary.
"
Class {
	#name : 'MCPAppliedChangeResult',
	#superclass : 'Object',
	#instVars : [
		'updatePlan',
		'changeResult'
	],
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'testing' }
MCPAppliedChangeResult class >> isAbstract [

	^ self == MCPAppliedChangeResult
]

{ #category : 'instance creation' }
MCPAppliedChangeResult class >> updatePlan: anUpdatePlan changeResult: aChangeResult [

	^ self new
		updatePlan: anUpdatePlan;
		changeResult: aChangeResult;
		yourself
]

{ #category : 'accessing' }
MCPAppliedChangeResult >> changeResult [

	^ changeResult
]

{ #category : 'accessing' }
MCPAppliedChangeResult >> changeResult: aResult [

	changeResult := aResult
]

{ #category : 'accessing' }
MCPAppliedChangeResult >> updateAction [

	^ self updatePlan updateAction
]

{ #category : 'accessing' }
MCPAppliedChangeResult >> updatePlan [

	^ updatePlan
]

{ #category : 'accessing' }
MCPAppliedChangeResult >> updatePlan: anUpdatePlan [

	updatePlan := anUpdatePlan
]
