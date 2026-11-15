"
Reads every class name an MCP tool takes, through the image's own `Smalltalk globals classNamed:`, and says every miss with `MCPCommandError`'s one builder.

A name is read in one order: a list written as one string is refused; a trailing ` class` or ` classTrait` is split off as the side; the class or trait is looked up by its base name alone, and the lookup applies the side itself. A name that names no class is a global variable that is not one (`NotAClass`) or is missing, with the code of the role the name had (Class, Superclass, Trait, Shared pool, Layout class, Critique rule, Rewrite rule) and suggestions drawn from that role's kind.

The strict entry points signal. A scope entry names its key as the schema spells it (`scope.classes`); a scope that must be complete refuses it, any other skips it with a warning text.
"
Class {
	#name : 'MCPImageLookup',
	#superclass : 'Object',
	#category : 'MCP-IDE-Utilities',
	#package : 'MCP-IDE',
	#tag : 'Utilities'
}

{ #category : 'reading names' }
MCPImageLookup class >> baseNameOf: aName [
	"aName without the side it may name: a trailing class or classTrait, after any run of spaces and in any case, as Pharo prints a class side. Pharo's own classNamed: strips exactly one space and class, so Foo  class must not reach it whole."

	| text index |
	text := aName asString trimBoth.
	index := text findLast: [ :each | each isSeparator ].
	index isZero ifTrue: [ ^ text ].
	(#( 'class' 'classtrait' ) includes: (text allButFirst: index) asLowercase) ifFalse: [ ^ text ].
	^ (text first: index) trimBoth
]

{ #category : 'private - resolving' }
MCPImageLookup class >> behavior: aBehavior isOfRole: aRole [
	"Whether a class found for a name given in aRole is of the kind the role needs. A class and a superclass may be any class."

	aRole = #trait ifTrue: [ ^ aBehavior isTrait ].
	aRole = #sharedPool ifTrue: [ ^ SharedPool withAllSubclasses includes: aBehavior ].
	aRole = #layoutClass ifTrue: [ ^ AbstractLayout withAllSubclasses includes: aBehavior ].
	aRole = #critiqueRule ifTrue: [ ^ aBehavior canUnderstand: #check:forCritiquesDo: ].
	aRole = #rewriteRule ifTrue: [ ^ aBehavior inheritsFrom: ReNodeRewriteRule ].
	^ true
]

{ #category : 'resolving' }
MCPImageLookup class >> behaviorNamed: aName classSide: aBoolean [
	"The method tools' target."

	^ self sideOf: (self classNamed: aName) named: aName classSide: aBoolean
]

{ #category : 'private - resolving' }
MCPImageLookup class >> candidatesForRole: aRole [
	"The behaviours a name given in aRole could have meant, so that a misspelt trait suggests traits and a misspelt pool suggests pools. Pharo counts a trait among its classes, and a trait is no superclass."

	aRole = #superclass ifTrue: [ ^ Smalltalk globals allClasses reject: [ :each | each isTrait ] ].
	aRole = #trait ifTrue: [ ^ Smalltalk globals allTraits ].
	aRole = #sharedPool ifTrue: [ ^ SharedPool allSubclasses ].
	aRole = #layoutClass ifTrue: [ ^ AbstractLayout allSubclasses ].
	aRole = #critiqueRule ifTrue: [ ^ ReRuleManager visibleRuleClasses ].
	aRole = #rewriteRule ifTrue: [ ^ ReNodeRewriteRule allSubclasses ].
	^ Smalltalk globals allClassesAndTraits
]

{ #category : 'reading names' }
MCPImageLookup class >> className: aName side: aSideOrNil do: aBlock [
	"Read a method tool's class and side once, while parsing. Foo class, or TFoo classTrait, names the class side; a side the call sent that says the other is refused rather than guessed, since guessing would put a method on the wrong side. aSideOrNil is the side argument as sent, nil when absent. aBlock gets the name without its side, whether the class side is meant, and whether the call said which side, by side or by the suffix."

	| namesClassSide |
	aName ifNil: [ ^ aBlock value: nil value: aSideOrNil = 'class' value: aSideOrNil isNotNil ].
	namesClassSide := self namesClassSide: aName.
	(namesClassSide and: [ aSideOrNil = 'instance' ]) ifTrue: [
		MCPCommandError signalClassSideConflict: aName asString trimBoth baseName: (self baseNameOf: aName) side: aSideOrNil ].
	^ aBlock
		  value: (self baseNameOf: aName)
		  value: (namesClassSide or: [ aSideOrNil = 'class' ])
		  value: (namesClassSide or: [ aSideOrNil isNotNil ])
]

{ #category : 'resolving' }
MCPImageLookup class >> classNamed: aName [

	^ self classNamed: aName role: #class details: #(  )
]

{ #category : 'private - resolving' }
MCPImageLookup class >> classNamed: aName ifList: listBlock ifNotAClass: notAClassBlock ifAbsent: absentBlock [
	"The class or trait aName names, on its instance side, read in the one order every lookup reads a name. The blocks answer for a list written as one string, for a global variable that is no class or trait, and for a name that is missing; the last two get the name without its side."

	| baseName behavior |
	(self isListInOneName: aName) ifTrue: [ ^ listBlock value ].
	baseName := self baseNameOf: aName.
	behavior := (baseName anySatisfy: [ :each | each isSeparator ]) ifFalse: [ Smalltalk globals classNamed: baseName ].
	behavior ifNotNil: [ ^ behavior instanceSide ].
	(Smalltalk globals includesKey: baseName asSymbol) ifTrue: [ ^ notAClassBlock value: baseName ].
	^ absentBlock value: baseName
]

{ #category : 'resolving - scopes' }
MCPImageLookup class >> classNamed: aName inScope: aScopeKey [
	"An entry of a scope that must be complete, under aScopeKey as the schema spells it, such as scope.classes."

	^ self
		  classNamed: aName
		  ifList: [ MCPCommandError signalClassNameIsAList: aName scope: aScopeKey details: #(  ) ]
		  ifNotAClass: [ :baseName |
				  MCPCommandError
					  signalNotAClass: baseName
					  role: #class
					  scope: aScopeKey
					  details: #(  ) ]
		  ifAbsent: [ :baseName |
				  MCPCommandError
					  signalMissing: baseName
					  role: #class
					  scope: aScopeKey
					  suggestions: (self suggestionsFor: baseName role: #class)
					  details: #(  ) ]
]

{ #category : 'resolving - scopes' }
MCPImageLookup class >> classNamed: aName inScope: aScopeKey ifSkipped: aBlock [
	"An entry of a scope that answers partial results. An entry that names no class is skipped: aBlock gets the warning that says so, and answers for it."

	^ self
		  classNamed: aName
		  ifList: [ aBlock value: (MCPCommandError textForClassNameIsAList: aName scope: aScopeKey skipped: true) ]
		  ifNotAClass: [ :baseName |
				  aBlock value: (MCPCommandError
						   textForNotAClass: baseName
						   role: #class
						   scope: aScopeKey
						   skipped: true) ]
		  ifAbsent: [ :baseName |
				  aBlock value: (MCPCommandError
						   textForMissing: baseName
						   role: #class
						   scope: aScopeKey
						   skipped: true
						   suggestions: (self suggestionsFor: baseName role: #class)) ]
]

{ #category : 'resolving' }
MCPImageLookup class >> classNamed: aName role: aRole details: someAssociations [
	"The class aName names, on its instance side, for a name given in aRole: #class, #superclass, #trait, #sharedPool, #layoutClass, #critiqueRule or #rewriteRule. someAssociations are what the caller already reports, such as the class being made. Anything else is refused: a list, a global variable that is no class, a missing name, and a class that is not of the role's kind."

	| behavior |
	behavior := self
		            classNamed: aName
		            ifList: [ MCPCommandError signalClassNameIsAList: aName scope: nil details: someAssociations ]
		            ifNotAClass: [ :baseName |
				            MCPCommandError
					            signalNotAClass: baseName
					            role: aRole
					            scope: nil
					            details: someAssociations ]
		            ifAbsent: [ :baseName |
				            MCPCommandError
					            signalMissing: baseName
					            role: aRole
					            scope: nil
					            suggestions: (self suggestionsFor: baseName role: aRole)
					            details: someAssociations ].
	(self behavior: behavior isOfRole: aRole) ifFalse: [
		MCPCommandError signalWrongKind: (self baseNameOf: aName) role: aRole details: someAssociations ].
	^ behavior
]

{ #category : 'resolving' }
MCPImageLookup class >> compileTargetNamed: aName classSide: aBoolean [
	"method_compile's target. It is the one tool that writes into the class it names, so a missing class says how to make one."

	| class |
	class := self
		         classNamed: aName
		         ifList: [ MCPCommandError signalClassNameIsAList: aName scope: nil details: #(  ) ]
		         ifNotAClass: [ :baseName |
				         MCPCommandError
					         signalNotAClass: baseName
					         role: #class
					         scope: nil
					         details: #(  ) ]
		         ifAbsent: [ :baseName |
		         MCPCommandError signalMissingCompileTarget: baseName suggestions: (self suggestionsFor: baseName role: #class) ].
	^ self sideOf: class named: aName classSide: aBoolean
]

{ #category : 'reading names' }
MCPImageLookup class >> isClassName: aName [
	"Whether aName names a class or trait, read as every lookup reads a name: Foo class names Foo, and neither a list nor a global variable that is no class names one."

	^ (self
		   classNamed: aName
		   ifList: [ nil ]
		   ifNotAClass: [ :baseName | nil ]
		   ifAbsent: [ :baseName | nil ]) isNotNil
]

{ #category : 'reading names' }
MCPImageLookup class >> isListInOneName: aName [
	"Whether aName is several names written as one string, between brackets or braces, rather than one name."

	| text |
	text := aName asString trimBoth.
	text size < 2 ifTrue: [ ^ false ].
	^ (text first = $[ and: [ text last = $] ]) or: [ text first = ${ and: [ text last = $} ] ]
]

{ #category : 'reading names' }
MCPImageLookup class >> namesClassSide: aName [
	"Whether aName ends with a class side, as Foo class or TFoo classTrait do."

	^ (self baseNameOf: aName) size < aName asString trimBoth size
]

{ #category : 'reading names' }
MCPImageLookup class >> newClassName: aName [
	"class_create's name for the class it makes. A list, a class side and a name already taken are refused: an existing class says so, and any other global variable keeps its name."

	(self isListInOneName: aName) ifTrue: [ MCPCommandError signalClassNameIsAList: aName scope: nil details: #(  ) ].
	self wholeClassName: aName for: 'class_create'.
	(Smalltalk globals classNamed: aName) ifNotNil: [ MCPCommandError signalClassAlreadyExistsNamed: aName ].
	(Smalltalk globals includesKey: aName asSymbol) ifTrue: [ MCPCommandError signalGlobalAlreadyExistsNamed: aName ].
	^ aName
]

{ #category : 'resolving' }
MCPImageLookup class >> packageNamed: aName [

	^ self packageOrganizer packageNamed: aName asSymbol ifAbsent: [
			  MCPCommandError
				  signalMissing: aName
				  role: #package
				  scope: nil
				  suggestions: (MCPScopeNameSuggester packageSuggestionsFor: aName)
				  details: #(  ) ]
]

{ #category : 'resolving - scopes' }
MCPImageLookup class >> packageNamed: aName inScope: aScopeKey [
	"An entry of a scope that must be complete, under aScopeKey as the schema spells it, such as scope.packages."

	^ self packageOrganizer packageNamed: aName asSymbol ifAbsent: [
			  MCPCommandError
				  signalMissing: aName
				  role: #package
				  scope: aScopeKey
				  suggestions: (MCPScopeNameSuggester packageSuggestionsFor: aName)
				  details: #(  ) ]
]

{ #category : 'resolving - scopes' }
MCPImageLookup class >> packageNamed: aName inScope: aScopeKey ifSkipped: aBlock [
	"An entry of a scope that answers partial results. A missing package is skipped: aBlock gets the warning that says so, and answers for it."

	^ self packageOrganizer packageNamed: aName asSymbol ifAbsent: [
			  aBlock value: (MCPCommandError
					   textForMissing: aName
					   role: #package
					   scope: aScopeKey
					   skipped: true
					   suggestions: (MCPScopeNameSuggester packageSuggestionsFor: aName)) ]
]

{ #category : 'private - resolving' }
MCPImageLookup class >> sideOf: aClass named: aName classSide: aBoolean [
	"The class side when the call asks for it, or when the name says it as Foo class does."

	^ (aBoolean or: [ self namesClassSide: aName ])
		  ifTrue: [ aClass classSide ]
		  ifFalse: [ aClass ]
]

{ #category : 'private - resolving' }
MCPImageLookup class >> suggestionsFor: aBaseName role: aRole [

	^ MCPScopeNameSuggester suggestionsFor: aBaseName among: (self candidatesForRole: aRole)
]

{ #category : 'resolving' }
MCPImageLookup class >> traitNamed: aName details: someAssociations [
	"A trait for a class's composition. TFoo classTrait reads as TFoo, and a class is refused as not a trait."

	^ self classNamed: aName role: #trait details: someAssociations
]

{ #category : 'reading names' }
MCPImageLookup class >> wholeClassName: aName for: aToolName [
	"The name of a class that aToolName, class_create, class_update or class_remove, makes, changes or deletes as a whole. Foo class is refused: read as Foo it would change the call's effect."

	(aName isNotNil and: [ self namesClassSide: aName ]) ifTrue: [
		MCPCommandError signalClassSideNamed: aName asString trimBoth baseName: (self baseNameOf: aName) for: aToolName ].
	^ aName
]
