"
Creates a class and answers it.

It owns the class-builder interaction for superclass, package, tag, slots, traits, shared variables, pools and layout.
"
Class {
	#name : 'MCPCreateClassCommand',
	#superclass : 'MCPClassCommand',
	#instVars : [
		'superclassName',
		'packageName',
		'tag',
		'slots',
		'classSlots',
		'traits',
		'sharedVariables',
		'sharedPools',
		'layout'
	],
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPCreateClassCommand class >> className: aClassName superclassName: aSuperclassName packageName: aPackageName tag: aTag slots: someSlots classSlots: someClassSlots traits: someTraits sharedVariables: someSharedVariables sharedPools: someSharedPools layout: aLayout [

	^ self new
		  className: aClassName;
		  superclassName: aSuperclassName;
		  packageName: aPackageName;
		  tag: aTag;
		  slots: someSlots;
		  classSlots: someClassSlots;
		  traits: someTraits;
		  sharedVariables: someSharedVariables;
		  sharedPools: someSharedPools;
		  layout: aLayout;
		  yourself
]

{ #category : 'accessing' }
MCPCreateClassCommand >> classSlots [

	^ classSlots ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPCreateClassCommand >> classSlots: someSlots [

	classSlots := someSlots ifNil: [ #(  ) ] ifNotNil: [ someSlots asArray ]
]

{ #category : 'executing' }
MCPCreateClassCommand >> execute [
	"The package is made first, for the class to land in, and removed again when the class does not build, so that a create that fails leaves nothing behind."

	| packageIsNew |
	MCPImageLookup newClassName: self className.
	packageIsNew := (self packageOrganizer hasPackage: self packageName) not.
	self packageOrganizer ensurePackage: self packageName.
	^ [ self buildClass ] ifCurtailed: [ packageIsNew ifTrue: [ self removePackageIfEmptyNamed: self packageName ] ]
]

{ #category : 'accessing' }
MCPCreateClassCommand >> layout [

	^ layout
]

{ #category : 'accessing' }
MCPCreateClassCommand >> layout: aLayoutName [

	layout := aLayoutName
]

{ #category : 'accessing' }
MCPCreateClassCommand >> packageName [

	^ packageName
]

{ #category : 'accessing' }
MCPCreateClassCommand >> packageName: aString [

	packageName := aString
]

{ #category : 'private' }
MCPCreateClassCommand >> resolvedTraits [

	^ self resolvedTraitsNamed: self traits
]

{ #category : 'accessing' }
MCPCreateClassCommand >> sharedPools [

	^ sharedPools ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPCreateClassCommand >> sharedPools: somePools [

	sharedPools := somePools ifNil: [ #(  ) ] ifNotNil: [ somePools asArray ]
]

{ #category : 'accessing' }
MCPCreateClassCommand >> sharedVariables [

	^ sharedVariables ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPCreateClassCommand >> sharedVariables: someVariables [

	sharedVariables := someVariables ifNil: [ #(  ) ] ifNotNil: [ someVariables asArray ]
]

{ #category : 'accessing' }
MCPCreateClassCommand >> slots [

	^ slots ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPCreateClassCommand >> slots: someSlots [

	slots := someSlots ifNil: [ #(  ) ] ifNotNil: [ someSlots asArray ]
]

{ #category : 'private' }
MCPCreateClassCommand >> superclass [

	^ self resolvedSuperclassNamed: self superclassName
]

{ #category : 'accessing' }
MCPCreateClassCommand >> superclassName [

	^ superclassName
]

{ #category : 'accessing' }
MCPCreateClassCommand >> superclassName: aString [

	superclassName := aString
]

{ #category : 'accessing' }
MCPCreateClassCommand >> tag [

	^ tag
]

{ #category : 'accessing' }
MCPCreateClassCommand >> tag: aString [

	tag := aString
]

{ #category : 'accessing' }
MCPCreateClassCommand >> traits [

	^ traits ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPCreateClassCommand >> traits: someTraits [

	traits := someTraits ifNil: [ #(  ) ] ifNotNil: [ someTraits asArray ]
]
