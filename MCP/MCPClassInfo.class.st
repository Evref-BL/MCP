Class {
	#name : 'MCPClassInfo',
	#superclass : 'Object',
	#instVars : [
		'className',
		'superclassName',
		'packageName',
		'tag',
		'instanceSlotNames',
		'classSlotNames',
		'subclassNames'
	],
	#category : 'MCP-Internal',
	#package : 'MCP',
	#tag : 'Internal'
}

{ #category : 'instance creation' }
MCPClassInfo class >> fromClass: aClass [

	^ self new initializeFromClass: aClass
]

{ #category : 'converting' }
MCPClassInfo >> asDictionary [

	^ {
		  (#className -> self className).
		  (#superclassName -> self superclassName).
		  (#packageName -> self packageName).
		  (#tag -> self tag).
		  (#instanceSlotNames -> self instanceSlotNames).
		  (#classSlotNames -> self classSlotNames).
		  (#subclassNames -> self subclassNames) } asDictionary
]

{ #category : 'converting' }
MCPClassInfo >> asQueryDictionary [

	^ {
		  (#className -> self className).
		  (#packageName -> self packageName).
		  (#tag -> self tag).
		  (#instanceSlotNames -> self instanceSlotNames).
		  (#classSlotNames -> self classSlotNames) } asDictionary
]

{ #category : 'accessing' }
MCPClassInfo >> className [

	^ className
]

{ #category : 'accessing' }
MCPClassInfo >> classSlotNames [

	^ classSlotNames
]

{ #category : 'initialization' }
MCPClassInfo >> initializeFromClass: aClass [

	className := aClass name asString.
	superclassName := aClass superclass
		                  ifNil: [ '' ]
		                  ifNotNil: [ :aSuperclass |
		                  aSuperclass name asString ].
	packageName := aClass package
		               ifNil: [ '' ]
		               ifNotNil: [ :aPackage | aPackage name asString ].
	tag := aClass packageTagName asString.
	instanceSlotNames := aClass slots
		                     collect: [ :each | each name asString ]
		                     as: Array.
	classSlotNames := aClass classSide slots
		                  collect: [ :each | each name asString ]
		                  as: Array.
	subclassNames := (aClass subclasses
		                  collect: [ :each | each name asString ]
		                  as: Array) asSortedCollection asArray.
	^ self
]

{ #category : 'accessing' }
MCPClassInfo >> instanceSlotNames [

	^ instanceSlotNames
]

{ #category : 'accessing' }
MCPClassInfo >> packageName [

	^ packageName
]

{ #category : 'accessing' }
MCPClassInfo >> subclassNames [

	^ subclassNames
]

{ #category : 'accessing' }
MCPClassInfo >> superclassName [

	^ superclassName
]

{ #category : 'accessing' }
MCPClassInfo >> tag [

	^ tag
]
