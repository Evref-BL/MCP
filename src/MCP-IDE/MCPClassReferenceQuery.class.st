"
Finds the methods that refer to classes already resolved, the way method_reference_search does: a method refers to a class when it accesses the class's binding.

It answers the referring methods among methods it is given, or the test classes that refer, with how many of their methods do, most first and ties by name. Only the methods of TestCase allSubclasses are scanned for those, on both sides, abstract classes included, never the whole image.
"
Class {
	#name : 'MCPClassReferenceQuery',
	#superclass : 'Object',
	#instVars : [
		'classes'
	],
	#category : 'MCP-IDE-Utilities',
	#package : 'MCP-IDE',
	#tag : 'Utilities'
}

{ #category : 'bindings' }
MCPClassReferenceQuery class >> classBindingForClassName: aClassName [
	"The global binding a method accesses when it names the class, or nil when the name holds no class."

	| binding |
	binding := Smalltalk globals associationAt: aClassName asSymbol ifAbsent: [ ^ nil ].
	^ binding value isBehavior ifTrue: [ binding ]
]

{ #category : 'instance creation' }
MCPClassReferenceQuery class >> forClass: aClass [
	"The references to aClass, which the caller has already resolved."

	^ self forClasses: { aClass }
]

{ #category : 'instance creation' }
MCPClassReferenceQuery class >> forClasses: someClasses [
	"The references to any of someClasses, which the caller has already resolved."

	^ self new initializeClasses: someClasses
]

{ #category : 'testing' }
MCPClassReferenceQuery class >> method: aCompiledMethod referencesAnyVariable: variables [

	^ variables anySatisfy: [ :eachVariable | eachVariable isAccessedIn: aCompiledMethod ]
]

{ #category : 'accessing' }
MCPClassReferenceQuery >> bindings [
	"The bindings of the classes, as a method that names one accesses it."

	^ Array streamContents: [ :stream |
		  classes do: [ :each | (self class classBindingForClassName: each name) ifNotNil: [ :binding | stream nextPut: binding ] ] ]
]

{ #category : 'initialization' }
MCPClassReferenceQuery >> initializeClasses: someClasses [

	classes := someClasses collect: [ :each | each instanceSide ] as: Array
]

{ #category : 'querying' }
MCPClassReferenceQuery >> methodsReferringIn: compiledMethods [
	"Those of compiledMethods that refer to any of the classes."

	| bindings |
	bindings := self bindings.
	^ (compiledMethods select: [ :each | self class method: each referencesAnyVariable: bindings ]) asArray
]

{ #category : 'private' }
MCPClassReferenceQuery >> referringMethodCountIn: aBehavior bindings: bindings [

	| count |
	count := 0.
	aBehavior methodsDo: [ :method | (self class method: method referencesAnyVariable: bindings) ifTrue: [ count := count + 1 ] ].
	^ count
]

{ #category : 'querying' }
MCPClassReferenceQuery >> referringTestClasses [
	"Every test class with methods that refer to any of the classes, as an association to how many of its methods do, on both sides, most first and ties by name. Only test classes are scanned: they are what test_run can run."

	| bindings counts |
	bindings := self bindings.
	bindings ifEmpty: [ ^ #(  ) ].
	counts := OrderedCollection new.
	TestCase allSubclasses do: [ :testClass |
			| count |
			count := (self referringMethodCountIn: testClass bindings: bindings)
			         + (self referringMethodCountIn: testClass classSide bindings: bindings).
			count > 0 ifTrue: [ counts add: testClass -> count ] ].
	^ counts asArray sort: [ :left :right |
		  left value > right value or: [ left value = right value and: [ left key name <= right key name ] ] ]
]
