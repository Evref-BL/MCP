"
Result DTO produced by the class_get command.
"
Class {
	#name : 'MCPGetClassResult',
	#superclass : 'Object',
	#instVars : [
		'className',
		'data',
		'superclasses',
		'subclasses'
	],
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPGetClassResult class >> className: aClassName data: aDictionary superclasses: superclassCollection subclasses: subclassCollection [

	^ self new
		  initializeClassName: aClassName
		  data: aDictionary
		  superclasses: superclassCollection
		  subclasses: subclassCollection
]

{ #category : 'accessing' }
MCPGetClassResult >> className [

	^ className
]

{ #category : 'accessing' }
MCPGetClassResult >> data [

	^ data
]

{ #category : 'initialization' }
MCPGetClassResult >> initializeClassName: aClassName data: aDictionary superclasses: superclassCollection subclasses: subclassCollection [

	className := aClassName.
	data := aDictionary.
	superclasses := superclassCollection.
	subclasses := subclassCollection.
	^ self
]

{ #category : 'accessing' }
MCPGetClassResult >> subclasses [

	^ subclasses
]

{ #category : 'accessing' }
MCPGetClassResult >> superclasses [

	^ superclasses
]
