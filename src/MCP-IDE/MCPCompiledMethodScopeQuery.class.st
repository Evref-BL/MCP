"
Resolves method-scope arguments into compiled methods or behavior sets.

It handles packageNames, classNames, hierarchyClassNames, subclassClassNames, parentClassNames, and side. Scope sets are unioned. Search tools keep valid scopes and record warnings for missing names. Tools that mutate the image can require a complete scope; missing names then raise a structured error with the same suggestions. Directional subclass and parent scopes exclude their anchor classes.
"
Class {
	#name : 'MCPCompiledMethodScopeQuery',
	#superclass : 'MCPScopeQuery',
	#instVars : [
		'side',
		'collectedMethods'
	],
	#category : 'MCP-IDE-Queries',
	#package : 'MCP-IDE',
	#tag : 'Queries'
}

{ #category : 'private - scope' }
MCPCompiledMethodScopeQuery >> addBehaviorsForBaseClass: aClass to: behaviors [

	self includesInstanceSide ifTrue: [ behaviors add: aClass instanceSide ].
	self includesClassSide ifTrue: [ behaviors add: aClass instanceSide classSide ]
]

{ #category : 'private - scope' }
MCPCompiledMethodScopeQuery >> allBehaviors [

	^ Array streamContents: [ :stream |
		  Smalltalk globals allBehaviorsDo: [ :each | (self matchesSideForBehavior: each) ifTrue: [ stream nextPut: each ] ] ]
]

{ #category : 'private - scope' }
MCPCompiledMethodScopeQuery >> allMethods [

	^ Array streamContents: [ :stream | self allMethodsDo: [ :each | stream nextPut: each ] ]
]

{ #category : 'private - scope' }
MCPCompiledMethodScopeQuery >> allMethodsDo: aBlock [
	"Each method of the image sits in one method dictionary, so a sweep of its behaviors meets each once."

	self allBehaviors do: [ :each | self methodsOf: each do: aBlock ]
]

{ #category : 'converting' }
MCPCompiledMethodScopeQuery >> asDictionary [
	"The scope as the call gave it, under the keys the schema gives them, since answers repeat it."

	^ {
		  (#packages -> self packageNames).
		  (#classes -> self classNames).
		  (#hierarchyOf -> self hierarchyClassNames).
		  (#subclassesOf -> self subclassClassNames).
		  (#superclassesOf -> self parentClassNames).
		  (#side -> self side) } asDictionary
]

{ #category : 'querying' }
MCPCompiledMethodScopeQuery >> behaviors [

	self validate.
	self resetWarnings.
	self usesImplicitImageScope ifTrue: [ ^ self allBehaviors ].
	^ (self behaviorsForPackageNames
		   addAll: self namedBehaviors;
		   yourself) asArray
]

{ #category : 'private - scope' }
MCPCompiledMethodScopeQuery >> behaviorsForPackageNames [

	| behaviors |
	behaviors := IdentitySet new.
	self packageNames do: [ :eachName |
			(self packageNamed: eachName inScope: 'scope.packages') ifNotNil: [ :package |
					package definedClasses do: [ :aClass | self addBehaviorsForBaseClass: aClass to: behaviors ].
					package extensionMethods do: [ :eachMethod |
						(self matchesSideForBehavior: eachMethod methodClass) ifTrue: [ behaviors add: eachMethod methodClass ] ] ] ].
	^ behaviors
]

{ #category : 'querying' }
MCPCompiledMethodScopeQuery >> collectedMethods [
	"The methods, collected on the first call and answered again after it, so that the readings of one name that a reference search tries in turn sweep the scope's methods once."

	^ collectedMethods ifNil: [ collectedMethods := self methods ]
]

{ #category : 'private - scope' }
MCPCompiledMethodScopeQuery >> includesClassSide [

	^ side = 'class' or: [ side = 'both' ]
]

{ #category : 'private - scope' }
MCPCompiledMethodScopeQuery >> includesInstanceSide [

	^ side = 'instance' or: [ side = 'both' ]
]

{ #category : 'initialization' }
MCPCompiledMethodScopeQuery >> initialize [

	super initialize.
	side := 'both'
]

{ #category : 'querying' }
MCPCompiledMethodScopeQuery >> isInstalledFromTraitedClass: aCompiledMethod [
	"Whether Pharo installed this method from TraitedClass, as it does on the class side of every class and trait that uses traits. Nobody wrote it there, so a sweep leaves it out. TraitedClass's own methods are not from a trait, so a sweep of TraitedClass still lists them."

	^ aCompiledMethod isFromTrait and: [ aCompiledMethod origin == TraitedClass ]
]

{ #category : 'private - scope' }
MCPCompiledMethodScopeQuery >> matchesSideForBehavior: aBehavior [

	aBehavior isMeta ifTrue: [ ^ self includesClassSide ].
	^ self includesInstanceSide
]

{ #category : 'querying' }
MCPCompiledMethodScopeQuery >> methods [

	| methods |
	self validate.
	self resetWarnings.
	self usesImplicitImageScope ifTrue: [ ^ self allMethods ].
	methods := self methodsForPackageNames.
	self namedBehaviors do: [ :each | self methodsOf: each do: [ :method | methods add: method ] ].
	^ methods asArray
]

{ #category : 'querying' }
MCPCompiledMethodScopeQuery >> methodsDo: aBlock [

	self validate.
	self usesImplicitImageScope ifTrue: [ ^ self allMethodsDo: aBlock ].
	self methods do: aBlock
]

{ #category : 'private - scope' }
MCPCompiledMethodScopeQuery >> methodsForPackageNames [

	| methods |
	methods := IdentitySet new.
	self packageNames do: [ :eachName |
			(self packageNamed: eachName inScope: 'scope.packages') ifNotNil: [ :package |
					package definedClasses do: [ :aClass |
							self includesInstanceSide ifTrue: [ methods addAll: aClass localMethods ].
							self includesClassSide ifTrue: [ methods addAll: aClass classSide localMethods ] ].
					package extensionMethods do: [ :eachMethod |
						(self matchesSideForBehavior: eachMethod methodClass) ifTrue: [ methods add: eachMethod ] ] ] ].
	^ methods
]

{ #category : 'private - scope' }
MCPCompiledMethodScopeQuery >> methodsOf: aBehavior do: aBlock [
	"What a sweep lists of aBehavior: its methods, but those Pharo installed from TraitedClass."

	aBehavior methodsDo: [ :each | (self isInstalledFromTraitedClass: each) ifFalse: [ aBlock value: each ] ]
]

{ #category : 'private - scope' }
MCPCompiledMethodScopeQuery >> namedBehaviors [
	"The sides the scope reaches of the classes it names."

	| behaviors |
	behaviors := IdentitySet new.
	self namedClasses do: [ :each | self addBehaviorsForBaseClass: each to: behaviors ].
	^ behaviors
]

{ #category : 'querying' }
MCPCompiledMethodScopeQuery >> reaches: aBehavior [
	"Whether the scope holds the methods of aBehavior. A named scope is resolved again, and records the warnings the search recorded."

	self usesImplicitImageScope ifTrue: [ ^ self matchesSideForBehavior: aBehavior ].
	^ self behaviors includes: aBehavior
]

{ #category : 'phrasing' }
MCPCompiledMethodScopeQuery >> scopePhrase [
	"A sweep of one side says which."

	^ super scopePhrase ifNotNil: [ :phrase | phrase , self sidePhrase ]
]

{ #category : 'accessing' }
MCPCompiledMethodScopeQuery >> side [

	^ side
]

{ #category : 'accessing' }
MCPCompiledMethodScopeQuery >> side: aSide [

	side := aSide ifNil: [ 'both' ]
]

{ #category : 'phrasing' }
MCPCompiledMethodScopeQuery >> sidePhrase [

	side = 'instance' ifTrue: [ ^ ', instance side' ].
	side = 'class' ifTrue: [ ^ ', class side' ].
	^ ''
]

{ #category : 'validating' }
MCPCompiledMethodScopeQuery >> validate [

	(#( 'instance' 'class' 'both' ) includes: side) ifFalse: [ Error signal: 'side must be one of instance, class, or both.' ]
]
