"
Structured error raised by MCP commands and queries.

It carries a stable error code and details dictionary so tools can return useful structured error output instead of only message text.
"
Class {
	#name : 'MCPCommandError',
	#superclass : 'Error',
	#instVars : [
		'errorCode',
		'details'
	],
	#category : 'MCP-Errors',
	#package : 'MCP',
	#tag : 'Errors'
}

{ #category : 'private - names' }
MCPCommandError class >> detailKeyOfRole: aRole [

	^ (self nameRoles at: aRole) third
]

{ #category : 'private - names' }
MCPCommandError class >> detailsNaming: aName role: aRole scope: aScopeKeyOrNil with: someAssociations [
	"What the caller already reports, the name under its role's key, and the key of the scope it was an entry of: only a scope entry has a scope."

	| details |
	details := someAssociations asDictionary.
	details at: (self detailKeyOfRole: aRole) put: aName.
	aScopeKeyOrNil ifNotNil: [ details at: #scope put: aScopeKeyOrNil ].
	^ details
]

{ #category : 'private - names' }
MCPCommandError class >> kindOfRole: aRole [
	"What a global variable given in aRole should have been, as in: not a class."

	^ (self nameRoles at: aRole) fourth
]

{ #category : 'texts - names' }
MCPCommandError class >> messageAbout: aSubject saying: aPredicate scope: aScopeKeyOrNil skipped: isSkipped suggestions: someNames closing: aSentenceOrNil [
	"The one way MCP says what is wrong with a name it was given. aSubject opens the text: the name, after its role's noun when the text is about what the name names. An entry of a scope names its key as the schema spells it: a scope that must be complete names it as it refuses, one that answers partial results says it skipped the entry. Suggestions, then what is left to say, close the text."

	^ String streamContents: [ :stream |
			  stream nextPutAll: aSubject.
			  (aScopeKeyOrNil isNotNil and: [ isSkipped not ]) ifTrue: [ stream << ', in ' << aScopeKeyOrNil << ',' ].
			  stream
				  space;
				  nextPutAll: aPredicate.
			  (aScopeKeyOrNil isNotNil and: [ isSkipped ]) ifTrue: [ stream << ', so ' << aScopeKeyOrNil << ' skipped it' ].
			  stream nextPut: $..
			  someNames ifNotEmpty: [ stream << ' Did you mean: ' << (', ' join: someNames) << '.' ].
			  aSentenceOrNil ifNotNil: [
					  stream
						  space;
						  nextPutAll: aSentenceOrNil ] ]
]

{ #category : 'private - suggestions' }
MCPCommandError class >> methodReferenceForClassName: className selector: selectorString classSide: classSide [

	^ String streamContents: [ :stream |
			  stream nextPutAll: className.
			  classSide ifTrue: [ stream nextPutAll: ' class' ].
			  stream
				  nextPutAll: '>>';
				  nextPutAll: selectorString ]
]

{ #category : 'private - suggestions' }
MCPCommandError class >> methodSuggestionForBehavior: aBehavior selector: aSelectorSymbol [

	| protocolName |
	protocolName := (aBehavior compiledMethodAt: aSelectorSymbol) protocolName
		                ifNil: [ '' ]
		                ifNotNil: [ :protocol | protocol asString ].
	^ {
		  (#class -> aBehavior instanceSide name asString).
		  (#side -> (aBehavior isClassSide
			    ifTrue: [ 'class' ]
			    ifFalse: [ 'instance' ])).
		  (#selector -> aSelectorSymbol asString).
		  (#protocol -> protocolName) } asDictionary
]

{ #category : 'private - suggestions' }
MCPCommandError class >> methodSuggestionsForClass: targetClass classSide: classSide selector: selectorSymbol [

	^ Array streamContents: [ :stream |
			  (self oppositeSideMethodSuggestionForClass: targetClass classSide: classSide selector: selectorSymbol) ifNotNil: [
				  :suggestion | stream nextPut: suggestion ].
			  (self superclassMethodSuggestionForClass: targetClass classSide: classSide selector: selectorSymbol) ifNotNil: [ :suggestion |
				  stream nextPut: suggestion ] ]
]

{ #category : 'private - names' }
MCPCommandError class >> nameRoles [
	"What the texts say of a name given in each role: the noun they open with, the code a missing name answers, the detail key that holds the name, and what a global variable given for it is not. A package is no class, but a missing one is said the same way."

	^ Dictionary newFrom: {
			  (#class -> #( 'Class' #ClassNotFound #class 'a class' )).
			  (#superclass -> #( 'Superclass' #SuperclassNotFound #superclass 'a class' )).
			  (#trait -> #( 'Trait' #TraitNotFound #trait 'a trait' )).
			  (#sharedPool -> #( 'Shared pool' #SharedPoolNotFound #sharedPool 'a shared pool' )).
			  (#layoutClass -> #( 'Layout class' #LayoutClassNotFound #layout 'a layout class' )).
			  (#critiqueRule -> #( 'Critique rule' #CritiqueRuleNotFound #ruleClass 'a critique rule' )).
			  (#rewriteRule -> #( 'Rewrite rule' #RewriteRuleNotFound #ruleClass 'a rewrite rule' )).
			  (#package -> #( 'Package' #PackageNotFound #package nil )) }
]

{ #category : 'private - names' }
MCPCommandError class >> notFoundCodeOfRole: aRole [

	^ (self nameRoles at: aRole) second
]

{ #category : 'private - names' }
MCPCommandError class >> nounOfRole: aRole [

	^ (self nameRoles at: aRole) first
]

{ #category : 'private - suggestions' }
MCPCommandError class >> oppositeSideMethodSuggestionForClass: targetClass classSide: classSide selector: selectorSymbol [

	| oppositeBehavior |
	oppositeBehavior := classSide
		                    ifTrue: [ targetClass ]
		                    ifFalse: [ targetClass classSide ].
	(oppositeBehavior includesSelector: selectorSymbol) ifFalse: [ ^ nil ].
	^ self methodSuggestionForBehavior: oppositeBehavior selector: selectorSymbol
]

{ #category : 'signaling' }
MCPCommandError class >> signalClassAlreadyExistsNamed: aClassName [
	"The message says which tools work on a class that exists, since a client reading text sees nothing of the details. class_update is not in every client's list, and a client that calls only what it lists reaches it through tool_call alone, so the message gives that call. A backslash keeps a brace of the call from being read as a placeholder."

	^ self
		  signalErrorCode: #ClassAlreadyExists
		  message:
			  ('Class {1} already exists. Change it with class_update, through tool_call when class_update is not in your list: tool_call \{"name": "class_update", "arguments": \{"name": "{1}", ...}}. class_get shows it.'
				   format: { aClassName })
		  details: { (#class -> aClassName) } asDictionary
]

{ #category : 'signaling' }
MCPCommandError class >> signalClassAlreadyExistsNamed: aClassName update: someArguments [
	"class_create's refusal of a class that exists, knowing what the call asked for. someArguments are what class_update needs besides the name to give the class what it lacks of that, in the order the call writes them; the message writes that call, or says the class lacks nothing when they are empty. A client reading text sees nothing of the details, and one that calls only what it lists reaches class_update through tool_call alone."

	| arguments |
	someArguments ifEmpty: [
			^ self
				  signalErrorCode: #ClassAlreadyExists
				  message:
				  ('Class {1} already exists and already has everything this call asks for. class_get shows it.' format: { aClassName })
				  details: { (#class -> aClassName) } asDictionary ].
	arguments := OrderedDictionary new.
	arguments at: 'name' put: aClassName.
	someArguments keysAndValuesDo: [ :key :value | arguments at: key put: value ].
	^ self
		  signalErrorCode: #ClassAlreadyExists
		  message: (String streamContents: [ :stream |
					   stream << 'Class ' << aClassName
					   << ' already exists. Change it with class_update, through tool_call when class_update is not in your list: tool_call '
					   << (STONJSON toString: (OrderedDictionary new
								     at: 'name' put: 'class_update';
								     at: 'arguments' put: arguments;
								     yourself)) << '. class_get shows it.' ])
		  details: { (#class -> aClassName) } asDictionary
]

{ #category : 'signaling - names' }
MCPCommandError class >> signalClassNameIsAList: aName scope: aScopeKeyOrNil details: someAssociations [

	| details |
	details := someAssociations asDictionary.
	details at: #name put: aName.
	aScopeKeyOrNil ifNotNil: [ details at: #scope put: aScopeKeyOrNil ].
	^ self
		  signalErrorCode: #ClassNameIsAList
		  message: (self textForClassNameIsAList: aName scope: aScopeKeyOrNil skipped: false)
		  details: details
]

{ #category : 'signaling' }
MCPCommandError class >> signalClassRemovalBlocked: aMessage details: aDictionary [
	"Pharo's removal check refused class_remove. aMessage says what blocks it; aDictionary carries classes, impactMessages, howToProceed and forceSupported."

	^ self signalErrorCode: #ClassRemovalBlocked message: aMessage details: aDictionary
]

{ #category : 'signaling - names' }
MCPCommandError class >> signalClassSideConflict: aName baseName: aBaseName side: aSide [
	"aName, such as Foo class, names the class side, and the call's side says the other: guessing would put a method on the wrong side."

	^ self
		  signalErrorCode: #ClassSideConflict
		  message: (String streamContents: [ :stream |
					   stream << aName << ' names the class side, but side is ' << aSide << '. Pass class ' << aBaseName
					   << ', with side class or instance.' ])
		  details: {
				  (#class -> aBaseName).
				  (#name -> aName).
				  (#side -> aSide) } asDictionary
]

{ #category : 'signaling - names' }
MCPCommandError class >> signalClassSideNamed: aName baseName: aBaseName for: aToolName [
	"aName, such as Foo class, names a class side where aToolName, class_create, class_update or class_remove, works on a whole class definition: reading it as Foo would change the call's effect."

	^ self
		  signalErrorCode: #ClassSideNamed
		  message: (String streamContents: [ :stream |
					   stream << aName << ' is the class side of ' << aBaseName.
					   aToolName = 'class_remove' ifTrue: [
							   stream << ', and goes only with its class. Name ' << aBaseName
							   << ' to remove the class, or use method_remove with side class to remove class-side methods.' ].
					   aToolName = 'class_update' ifTrue: [
						   stream << '. class_update changes the whole class: name ' << aBaseName << ', and use classSlots for class-side slots.' ].
					   aToolName = 'class_create' ifTrue: [
						   stream << ', which class_create makes with the class. Name ' << aBaseName << ', and give class-side slots in classSlots.' ] ])
		  details: {
				  (#class -> aBaseName).
				  (#name -> aName) } asDictionary
]

{ #category : 'signaling' }
MCPCommandError class >> signalErrorCode: anErrorCode message: aMessage details: aDictionary [

	^ self new
		  errorCode: anErrorCode;
		  details: aDictionary;
		  messageText: aMessage;
		  signal
]

{ #category : 'signaling - names' }
MCPCommandError class >> signalGlobalAlreadyExistsNamed: aName [
	"class_create was asked for a class under a name a global variable already holds."

	^ self
		  signalErrorCode: #GlobalAlreadyExists
		  message: (self
				   messageAbout: aName
				   saying: 'already names a global variable'
				   scope: nil
				   skipped: false
				   suggestions: #(  )
				   closing: 'Choose another class name.')
		  details: { (#class -> aName) } asDictionary
]

{ #category : 'signaling' }
MCPCommandError class >> signalMethodSourceHeader: aHeader message: aMessage className: aClassName side: aSide [
	"A method_compile source began with a method's reference, aHeader, that the call cannot simply drop. aMessage says what to write instead; nothing is compiled."

	^ self signalErrorCode: #MethodSourceHeader message: aMessage details: {
			  (#header -> aHeader).
			  (#class -> aClassName).
			  (#side -> aSide) } asDictionary
]

{ #category : 'signaling - names' }
MCPCommandError class >> signalMissing: aName role: aRole scope: aScopeKeyOrNil suggestions: someNames details: someAssociations [
	"aName, given in aRole, names nothing. Each role answers its own code; the suggestions are names of the role's kind."

	| details |
	details := self
		           detailsNaming: aName
		           role: aRole
		           scope: aScopeKeyOrNil
		           with: someAssociations.
	details at: #suggestions put: someNames asArray.
	^ self
		  signalErrorCode: (self notFoundCodeOfRole: aRole)
		  message: (self
				   textForMissing: aName
				   role: aRole
				   scope: aScopeKeyOrNil
				   skipped: false
				   suggestions: someNames)
		  details: details
]

{ #category : 'signaling - names' }
MCPCommandError class >> signalMissingCompileTarget: aName suggestions: someNames [
	"method_compile is the one tool that writes into the class it names, so a missing one says how to make it."

	^ self
		  signalErrorCode: #ClassNotFound
		  message: (self
				   messageAbout: (String streamContents: [ :stream | stream << (self nounOfRole: #class) << ' ' << aName ])
				   saying: 'does not exist'
				   scope: nil
				   skipped: false
				   suggestions: someNames
				   closing: (someNames
						    ifEmpty: [ 'Create it with class_create, then compile into it.' ]
						    ifNotEmpty: [ 'If it is a new class, create it with class_create first.' ]))
		  details: {
				  (#class -> aName).
				  (#suggestions -> someNames asArray) } asDictionary
]

{ #category : 'signaling' }
MCPCommandError class >> signalMissingMethod: aSelectorString in: aBehavior [
	"aBehavior, which the caller has resolved, has no method aSelectorString of its own."

	^ self signalMissingMethod: aSelectorString in: aBehavior closingWhenNoMatch: nil
]

{ #category : 'signaling' }
MCPCommandError class >> signalMissingMethod: aSelectorString in: aBehavior closingWhenNoMatch: aStringOrNil [
	"aBehavior, which the caller has resolved, has no method aSelectorString of its own. The methods of that selector the caller may have meant are named: on the other side, or the first one up the hierarchy. When none is, aStringOrNil, if given, ends the message with what the caller's tool offers instead; a method named is already the next step."

	| className classSide details message suggestions |
	className := aBehavior instanceSide name asString.
	classSide := aBehavior isClassSide.
	suggestions := self methodSuggestionsForClass: aBehavior instanceSide classSide: classSide selector: aSelectorString asSymbol.
	message := String streamContents: [ :stream |
			           stream << 'Method ' << (self methodReferenceForClassName: className selector: aSelectorString classSide: classSide)
			           << ' does not exist.'.
			           suggestions ifEmpty: [ aStringOrNil ifNotNil: [ :closing | stream << ' ' << closing ] ] ifNotEmpty: [
					           stream << ' Exact matches: ' << (', ' join: (suggestions collect: [ :each |
							             self
								             methodReferenceForClassName: (each at: #class)
								             selector: (each at: #selector)
								             classSide: (each at: #side) = 'class' ])) << '.' ] ].
	details := {
		           (#class -> className).
		           (#side -> (classSide
			             ifTrue: [ 'class' ]
			             ifFalse: [ 'instance' ])).
		           (#selector -> aSelectorString asString) } asDictionary.
	suggestions ifNotEmpty: [ :matches | details at: #suggestions put: matches ].
	^ self signalErrorCode: #MethodNotFound message: message details: details
]

{ #category : 'signaling' }
MCPCommandError class >> signalMissingProjectNamed: aProjectName [
	"Projects are named only by package_search's projects, which is where the scope says the name was given."

	| message |
	message := String streamContents: [ :stream | stream << 'Project ' << aProjectName << ' does not exist.' ].
	^ self signalErrorCode: #ProjectNotFound message: message details: {
			  (#project -> aProjectName).
			  (#scope -> 'projects') } asDictionary
]

{ #category : 'signaling' }
MCPCommandError class >> signalMissingTag: aTag packageName: aPackageName forClassNamed: aClassName [

	| message |
	message := String streamContents: [ :stream |
		           stream << 'Package ' << aPackageName << ' does not have a tag named ' << aTag << '.' ].
	^ self signalErrorCode: #TagNotFound message: message details: {
			  (#class -> aClassName).
			  (#package -> aPackageName).
			  (#tag -> aTag) } asDictionary
]

{ #category : 'signaling - names' }
MCPCommandError class >> signalNameIsAList: aString kind: aKind argument: anArgumentName [
	"aString, an entry of anArgumentName that takes one name per entry, such as a slot name, is several names written as one string. aKind is what the entry should have been, with its article. A class name that is a list answers ClassNameIsAList instead, which keeps the string under name too."

	^ self
		  signalErrorCode: #NameIsAList
		  message: (self
				   textForNameIsAList: aString
				   kind: aKind
				   scope: nil
				   skipped: false)
		  details: {
				  (#argument -> anArgumentName).
				  (#name -> aString) } asDictionary
]

{ #category : 'signaling - names' }
MCPCommandError class >> signalNotAClass: aName role: aRole scope: aScopeKeyOrNil details: someAssociations [
	"aName, given in aRole, is a global variable that is no class or trait."

	^ self
		  signalErrorCode: #NotAClass
		  message: (self
				   textForNotAClass: aName
				   role: aRole
				   scope: aScopeKeyOrNil
				   skipped: false)
		  details: (self
				   detailsNaming: aName
				   role: aRole
				   scope: aScopeKeyOrNil
				   with: someAssociations)
]

{ #category : 'signaling - names' }
MCPCommandError class >> signalWrongKind: aName role: aRole details: someAssociations [
	"aName names a class, but not of the kind aRole needs."

	| wrongKind |
	wrongKind := self wrongKinds at: aRole.
	^ self
		  signalErrorCode: wrongKind first
		  message: (self
				   messageAbout: aName
				   saying: wrongKind second
				   scope: nil
				   skipped: false
				   suggestions: #(  )
				   closing: wrongKind third)
		  details: (self
				   detailsNaming: aName
				   role: aRole
				   scope: nil
				   with: someAssociations)
]

{ #category : 'private - suggestions' }
MCPCommandError class >> superclassMethodSuggestionForClass: targetClass classSide: classSide selector: selectorSymbol [

	| behavior |
	behavior := classSide
		            ifTrue: [ targetClass classSide superclass ]
		            ifFalse: [ targetClass superclass ].
	[ behavior isNotNil ] whileTrue: [
			(behavior includesSelector: selectorSymbol) ifTrue: [ ^ self methodSuggestionForBehavior: behavior selector: selectorSymbol ].
			behavior := behavior superclass ].
	^ nil
]

{ #category : 'texts - names' }
MCPCommandError class >> textForClassNameIsAList: aName scope: aScopeKeyOrNil skipped: isSkipped [

	^ self
		  textForNameIsAList: aName
		  kind: 'a class name'
		  scope: aScopeKeyOrNil
		  skipped: isSkipped
]

{ #category : 'texts - names' }
MCPCommandError class >> textForMissing: aName role: aRole scope: aScopeKeyOrNil skipped: isSkipped suggestions: someNames [

	^ self
		  messageAbout: (String streamContents: [ :stream | stream << (self nounOfRole: aRole) << ' ' << aName ])
		  saying: 'does not exist'
		  scope: aScopeKeyOrNil
		  skipped: isSkipped
		  suggestions: someNames
		  closing: nil
]

{ #category : 'texts - names' }
MCPCommandError class >> textForNameIsAList: aName kind: aKind scope: aScopeKeyOrNil skipped: isSkipped [
	"Splitting the list would guess at a format the schema does not offer, and an array is one edit away. aKind is what one entry should have been, with its article: a class name, a slot name."

	^ self
		  messageAbout: aName
		  saying: 'is a list written as one string, not ' , aKind
		  scope: aScopeKeyOrNil
		  skipped: isSkipped
		  suggestions: #(  )
		  closing: 'Pass several names as an array of strings.'
]

{ #category : 'texts - names' }
MCPCommandError class >> textForNotAClass: aName role: aRole scope: aScopeKeyOrNil skipped: isSkipped [

	^ self
		  messageAbout: aName
		  saying: 'is a global variable, not ' , (self kindOfRole: aRole)
		  scope: aScopeKeyOrNil
		  skipped: isSkipped
		  suggestions: #(  )
		  closing: nil
]

{ #category : 'private - names' }
MCPCommandError class >> wrongKinds [
	"For each role that needs a class of some kind, the code and what the text says of a class that is not of that kind."

	^ Dictionary newFrom: {
			  (#trait -> #( #InvalidTrait 'is not a trait' nil )).
			  (#sharedPool -> #( #InvalidSharedPool 'is not a shared pool: a pool is a subclass of SharedPool'
			      nil )).
			  (#layoutClass -> #( #InvalidLayoutClass 'is not a layout class: name a subclass of AbstractLayout, such as VariableLayout'
			      nil )).
			  (#critiqueRule -> #( #InvalidCritiqueRule 'is not a critique rule class' nil )).
			  (#rewriteRule -> #( #RewriteRuleClassHasNoPatterns 'is not a rewrite rule' 'Name a subclass of ReNodeRewriteRule.' )) }
]

{ #category : 'accessing' }
MCPCommandError >> details [

	^ details ifNil: [ Dictionary new ]
]

{ #category : 'accessing' }
MCPCommandError >> details: aDictionary [

	details := aDictionary ifNil: [ Dictionary new ] ifNotNil: [ aDictionary copy ]
]

{ #category : 'accessing' }
MCPCommandError >> errorCode [

	^ errorCode
]

{ #category : 'accessing' }
MCPCommandError >> errorCode: anObject [

	errorCode := anObject
]

{ #category : 'dispatching' }
MCPCommandError >> mcpCommandErrorDo: commandBlock otherwise: fallbackBlock [

	^ commandBlock cull: self
]

{ #category : 'dispatching' }
MCPCommandError >> mcpErrorResultForMutationTool: aTool action: action requestedContext: requestedContext summary: summary [

	^ aTool errorResultForCommandError: self action: action requestedContext: requestedContext
]

{ #category : 'accessing' }
MCPCommandError >> structuredDetails [

	| structured |
	structured := self details copy.
	structured at: #errorClass put: self class name.
	structured at: #errorCode put: self errorCode asString.
	structured at: #message put: self messageText.
	^ structured
]
