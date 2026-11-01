"
Shared method-domain helper behavior for MCP tools.

Kept as a trait so method tools can combine it with query or mutation behavior.
"
Trait {
	#name : 'TMCPMethodTool',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'private - methods' }
TMCPMethodTool >> behaviorNamed: aClassName classSide: aBoolean [

	| targetClass |
	targetClass := self class environment at: aClassName asSymbol.
	^ aBoolean
		  ifTrue: [ targetClass classSide ]
		  ifFalse: [ targetClass ]
]

{ #category : 'private - methods' }
TMCPMethodTool >> methodEntryLabel: anEntry [

	^ self
		  methodReferenceForClassName: (anEntry at: #class)
		  selector: (anEntry at: #selector)
		  isClassSide: (anEntry at: #side ifAbsent: [ 'instance' ]) = 'class'
]

{ #category : 'private - methods' }
TMCPMethodTool >> methodForClassNamed: className selector: selectorString classSide: classSide [

	| behavior selectorSymbol targetClass |
	selectorSymbol := selectorString asSymbol.
	targetClass := self class environment
		               at: className asSymbol
		               ifAbsent: [
		               MCPCommandError signalMissingMethodInClassName: className classSide: classSide selector: selectorString ].
	behavior := classSide
		            ifTrue: [ targetClass classSide ]
		            ifFalse: [ targetClass ].
	(behavior includesSelector: selectorSymbol) ifFalse: [
		MCPCommandError signalMissingMethodInClassName: className classSide: classSide selector: selectorString ].
	^ behavior compiledMethodAt: selectorSymbol
]

{ #category : 'private - schema' }
TMCPMethodTool >> methodQueryScopeInputProperties [

	^ { self methodSearchScopeSchemaProperty }
]

{ #category : 'private - methods' }
TMCPMethodTool >> methodReferenceForBehavior: aBehavior selector: aSelector [

	^ String streamContents: [ :stream |
			  stream nextPutAll: (self targetNameForBehavior: aBehavior).
			  stream nextPutAll: '>>'.
			  stream nextPutAll: aSelector asString ]
]

{ #category : 'private - methods' }
TMCPMethodTool >> methodReferenceForClassName: aClassName selector: aSelector isClassSide: isClassSide [

	^ String streamContents: [ :stream |
			  stream nextPutAll: aClassName.
			  isClassSide ifTrue: [ stream nextPutAll: ' class' ].
			  stream
				  nextPutAll: '>>';
				  nextPutAll: aSelector ]
]

{ #category : 'private - methods' }
TMCPMethodTool >> methodScopeQueryFromRequest: request [

	^ MCPCompiledMethodScopeQuery new
		  packageNames: (self searchScopeStringCollectionNamed: 'packages' fromRequest: request);
		  classNames: (self searchScopeStringCollectionNamed: 'classes' fromRequest: request);
		  hierarchyClassNames: (self searchScopeStringCollectionNamed: 'hierarchyOf' fromRequest: request);
		  subclassClassNames: (self searchScopeStringCollectionNamed: 'subclassesOf' fromRequest: request);
		  parentClassNames: (self searchScopeStringCollectionNamed: 'superclassesOf' fromRequest: request);
		  side: (self searchScopeSideFromRequest: request);
		  yourself
]

{ #category : 'private - request' }
TMCPMethodTool >> selectorStringFromRequest: request [

	^ request stringArgumentNamed: 'selector'
]

{ #category : 'private - traits' }
TMCPMethodTool >> signalTraitOriginBeforeCompiling: aSelector in: aBehavior unlessForced: forceRequested [
	"Compiling here installs a method of the class's own over the copy. That is how Pharo overrides a trait method, and the override does land in the source of the class, so force lets it through, and the one tool that takes force answers for it here rather than deciding on its own."

	forceRequested ifTrue: [ ^ self ].
	self signalTraitOriginFor: aSelector in: aBehavior howToProceed: [ :origin |
			String streamContents: [ :stream |
					stream << 'Compile into ' << (self targetNameForBehavior: origin)
					<< ' to change it for every user of the trait, or resend with force to override it in '
					<< (self targetNameForBehavior: aBehavior) << ' alone.' ] ]
]

{ #category : 'private - traits' }
TMCPMethodTool >> signalTraitOriginBeforeRemoving: aSelector in: aBehavior [
	"Removing a copy removes nothing: the method is there afterwards, still the trait's, and the tool would have reported a removal that never happened."

	self signalTraitOriginFor: aSelector in: aBehavior howToProceed: [ :origin |
			String streamContents: [ :stream |
					stream << 'Remove ' << (self methodReferenceForBehavior: origin selector: aSelector)
					<< ' to remove it from every user of the trait. ' << (self targetNameForBehavior: aBehavior)
					<< ' has no method of its own to remove.' ] ]
]

{ #category : 'private - traits' }
TMCPMethodTool >> signalTraitOriginBeforeUpdating: aSelector in: aBehavior [
	"Renaming a copy, or changing its protocol or its arguments, recompiles it into the class as a method of its own: a duplicate of the trait's source, shadowing it, which nobody asked for. There is nothing worth forcing there, so the update belongs in the trait."

	self signalTraitOriginFor: aSelector in: aBehavior howToProceed: [ :origin |
			String streamContents: [ :stream |
					stream << 'Update ' << (self methodReferenceForBehavior: origin selector: aSelector)
					<< ' instead. Changing the copy writes a method of its own into ' << (self targetNameForBehavior: aBehavior)
					<< ', shadowing the trait.' ] ]
]

{ #category : 'private - traits' }
TMCPMethodTool >> signalTraitOriginFor: aSelector in: aBehavior howToProceed: aBlock [
	"Stop before changing a method a class got from a trait. The copy is in no source file of that class, so what a caller means by changing it does not happen: a removal removes nothing, and an update writes a method of the class's own in its place. What to do instead goes in the message rather than only in the details, because the message is the part every caller reads."

	| origin proceedText reference |
	origin := self traitDefining: aSelector in: aBehavior.
	origin ifNil: [ ^ self ].
	reference := self methodReferenceForBehavior: origin selector: aSelector.
	proceedText := aBlock value: origin.
	MCPCommandError
		signalErrorCode: #MethodInstalledFromTrait
		message: (String streamContents: [ :stream |
					 stream << (self methodReferenceForBehavior: aBehavior selector: aSelector) << ' is installed from ' << reference << '. '
					 << proceedText ])
		details: {
				(#trait -> origin instanceSide name asString).
				(#origin -> reference).
				(#howToProceed -> proceedText) } asDictionary
]

{ #category : 'private - methods' }
TMCPMethodTool >> targetNameForBehavior: aBehavior [

	^ aBehavior isMeta
		  ifTrue: [ aBehavior instanceSide name , ' class' ]
		  ifFalse: [ aBehavior name ]
]

{ #category : 'private - traits' }
TMCPMethodTool >> traitDefining: aSelector in: aBehavior [
	"The trait a behaviour got this method from, nil when the method is its own. A class overriding a trait method owns the override."

	| method |
	method := aBehavior compiledMethodAt: aSelector asSymbol ifAbsent: [ ^ nil ].
	method isFromTrait ifFalse: [ ^ nil ].
	^ method origin
]
