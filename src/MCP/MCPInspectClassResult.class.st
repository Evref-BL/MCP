"
Result DTO produced by the inspect-class command.
"
Class {
	#name : 'MCPInspectClassResult',
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
MCPInspectClassResult class >> className: aClassName data: aDictionary superclasses: superclassCollection subclasses: subclassCollection [

	^ self new
		  initializeClassName: aClassName
		  data: aDictionary
		  superclasses: superclassCollection
		  subclasses: subclassCollection
]

{ #category : 'accessing' }
MCPInspectClassResult >> className [

	^ className
]

{ #category : 'accessing' }
MCPInspectClassResult >> data [

	^ data
]

{ #category : 'initialization' }
MCPInspectClassResult >> initializeClassName: aClassName data: aDictionary superclasses: superclassCollection subclasses: subclassCollection [

	className := aClassName.
	data := aDictionary.
	superclasses := superclassCollection.
	subclasses := subclassCollection.
	^ self
]

{ #category : 'accessing' }
MCPInspectClassResult >> subclasses [

	^ subclasses
]

{ #category : 'accessing' }
MCPInspectClassResult >> superclasses [

	^ superclasses
]
