"
Result DTO produced by the method_remove command.
"
Class {
	#name : 'MCPRemoveMethodsResult',
	#superclass : 'MCPResult',
	#instVars : [
		'className',
		'classSide',
		'selectors',
		'removedMethods',
		'warningMessages'
	],
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPRemoveMethodsResult class >> fromRequest: aRequest removedMethods: methodCollection warningMessages: warningCollection [

	^ self new
		  initializeFromRequest: aRequest
		  removedMethods: methodCollection
		  warningMessages: warningCollection
]

{ #category : 'converting' }
MCPRemoveMethodsResult >> asDictionary [

	^ Dictionary new
]

{ #category : 'accessing' }
MCPRemoveMethodsResult >> className [

	^ className
]

{ #category : 'accessing' }
MCPRemoveMethodsResult >> classSide [

	^ classSide
]

{ #category : 'initialization' }
MCPRemoveMethodsResult >> initializeFromRequest: aRequest removedMethods: methodCollection warningMessages: warningCollection [

	className := aRequest className.
	classSide := aRequest classSide.
	selectors := aRequest selectors asArray.
	removedMethods := methodCollection asArray.
	warningMessages := warningCollection asArray.
	^ self
]

{ #category : 'accessing' }
MCPRemoveMethodsResult >> removedMethods [

	^ removedMethods
]

{ #category : 'accessing' }
MCPRemoveMethodsResult >> selectors [

	^ selectors
]

{ #category : 'accessing' }
MCPRemoveMethodsResult >> warningMessages [

	^ warningMessages
]
