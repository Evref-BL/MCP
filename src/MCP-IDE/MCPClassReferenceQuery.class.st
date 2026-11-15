"
Finds the methods that refer to classes already resolved, the way method_reference_search does: a method refers to a class when it accesses a global that holds the class, under the class's own name or an alias.

It answers the referring methods among methods it is given, or the test classes that refer, with how many of their methods do, most first and ties by name. Only the methods of TestCase allSubclasses are scanned for those, on both sides, abstract classes included, never the whole image. A method's literals are looked up among the bindings once, so a scan for every class of a package costs about what a scan for one class does.
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
MCPClassReferenceQuery class >> method: aCompiledMethod accessesAnyOf: someBindings [
	"Whether aCompiledMethod accesses any of someBindings, an identity set, by the test method_reference_search makes. Its literals, its blocks' included, are looked up in the set, so the cost does not grow with the number of classes asked about, and a binding found there is confirmed by isAccessedIn:."

	^ aCompiledMethod hasLiteralSuchThat: [ :each | (someBindings includes: each) and: [ each isAccessedIn: aCompiledMethod ] ]
]

{ #category : 'testing' }
MCPClassReferenceQuery class >> method: aCompiledMethod referencesAnyVariable: variables [

	^ variables anySatisfy: [ :eachVariable | eachVariable isAccessedIn: aCompiledMethod ]
]

{ #category : 'accessing' }
MCPClassReferenceQuery >> bindings [
	"The bindings a method accesses when it names one of the classes: every global that holds one, so that a method naming a class by an alias, as RBParser names OCParser in Pharo 14, refers to it too."

	| bindings wanted |
	wanted := classes asIdentitySet.
	bindings := IdentitySet new.
	Smalltalk globals associationsDo: [ :each | (wanted includes: each value) ifTrue: [ bindings add: each ] ].
	^ bindings
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
	^ (compiledMethods select: [ :each | self class method: each accessesAnyOf: bindings ]) asArray
]

{ #category : 'private' }
MCPClassReferenceQuery >> referringMethodCountIn: aBehavior bindings: bindings [

	| count |
	count := 0.
	aBehavior methodsDo: [ :method | (self class method: method accessesAnyOf: bindings) ifTrue: [ count := count + 1 ] ].
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
