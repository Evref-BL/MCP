"
Shared method-domain helper behavior for MCP tools. Kept as a trait so method tools can combine it with query or edit tool behavior.
"
Trait {
	#name : 'TMCPMethodTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
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
TMCPMethodTool >> methodBehaviorForClassNamed: className side: side [

	| baseClass |
	baseClass := self class environment
		             at: className asSymbol
		             ifAbsent: [
		             MCPCommandError signalMissingClassNamed: className ].
	^ side = 'class'
		  ifTrue: [ baseClass classSide ]
		  ifFalse: [ baseClass ]
]

{ #category : 'private - methods' }
TMCPMethodTool >> methodEntryLabel: anEntry [

	^ self
		  methodReferenceForClassName: (anEntry at: #className)
		  selector: (anEntry at: #selector)
		  isClassSide: (anEntry at: #side) = 'class'
]

{ #category : 'private - methods' }
TMCPMethodTool >> methodForClassNamed: className selector: selectorString side: side [

	| behavior selectorSymbol |
	behavior := self methodBehaviorForClassNamed: className side: side.
	selectorSymbol := selectorString asSymbol.
	(behavior includesSelector: selectorSymbol) ifFalse: [
		MCPCommandError
			signalMissingMethodInClassName: className
			classSide: side = 'class'
			selector: selectorString ].
	^ behavior compiledMethodAt: selectorSymbol
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

{ #category : 'private - request' }
TMCPMethodTool >> selectorStringFromRequest: request [

	^ request stringArgumentNamed: 'selector'
]

{ #category : 'private - methods' }
TMCPMethodTool >> targetNameForBehavior: aBehavior [

	^ aBehavior isMeta
		  ifTrue: [ aBehavior instanceSide name , ' class' ]
		  ifFalse: [ aBehavior name ]
]
