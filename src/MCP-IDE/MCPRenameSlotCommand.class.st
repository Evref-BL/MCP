"
Renames a slot on either side of a class: it snapshots the values of the affected objects, restores them into the renamed slot, rewrites the references and renames local accessors.
"
Class {
	#name : 'MCPRenameSlotCommand',
	#superclass : 'MCPClassSlotCommand',
	#instVars : [
		'newSlotName'
	],
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPRenameSlotCommand class >> className: aClassName slotName: aSlotName newSlotName: aNewSlotName classSide: aBoolean [

	^ self new
		  className: aClassName;
		  slotName: aSlotName;
		  newSlotName: aNewSlotName;
		  classSide: aBoolean;
		  yourself
]

{ #category : 'private' }
MCPRenameSlotCommand >> accessorMessageRewriter [

	| rewriter |
	rewriter := RBParseTreeRewriter new.
	rewriter
		replace: (String streamContents: [ :stream | stream << '`@receiver ' << self slotName << ': `@value' ])
		with: (String streamContents: [ :stream | stream << '`@receiver ' << self newSlotName << ': `@value' ]);
		replace: '`@receiver ' , self slotName with: '`@receiver ' , self newSlotName.
	^ rewriter
]

{ #category : 'private' }
MCPRenameSlotCommand >> applyToBehavior: aBehavior [
	"The same rename on either side: a class-side slot is an instance variable of the metaclass."

	| preservedValues |
	self validateSlotRenameInBehavior: aBehavior.
	preservedValues := self slotValuesForBehavior: aBehavior.
	aBehavior addInstVarNamed: self newSlotName.
	self restoreSlotValues: preservedValues.
	self rewriteReferencesInBehavior: aBehavior.
	self renameAccessorsInBehavior: aBehavior.
	aBehavior removeInstVarNamed: self slotName
]

{ #category : 'private' }
MCPRenameSlotCommand >> getterSourceForNewSlot [

	^ String streamContents: [ :stream | stream << self newSlotName << String cr << String cr << '^ ' << self newSlotName ]
]

{ #category : 'private' }
MCPRenameSlotCommand >> hierarchyDefinesSlotNamed: aSlotName inBehavior: aBehavior [

	(aBehavior hasSlotNamed: aSlotName asSymbol) ifTrue: [ ^ true ].
	^ aBehavior allSubclasses anySatisfy: [ :each | self definesSlotNamed: aSlotName in: each ]
]

{ #category : 'accessing' }
MCPRenameSlotCommand >> newSlotName [

	^ newSlotName
]

{ #category : 'accessing' }
MCPRenameSlotCommand >> newSlotName: aNewSlotName [

	newSlotName := aNewSlotName
]

{ #category : 'private' }
MCPRenameSlotCommand >> referenceSelectorsInBehavior: aBehavior [

	| selectors |
	selectors := Set new.
	selectors addAll: ((aBehavior whichMethodsAccess: self slotName) collect: #selector).
	selectors addAll: (aBehavior whichSelectorsReferTo: self slotName asSymbol).
	selectors addAll: (aBehavior whichSelectorsReferTo: (self slotName , ':') asSymbol).
	^ selectors
]

{ #category : 'private' }
MCPRenameSlotCommand >> renameAccessor: oldSelector to: newSelector source: sourceString inBehavior: aBehavior [

	| protocol |
	(aBehavior includesLocalSelector: oldSelector) ifFalse: [ ^ self ].
	protocol := (aBehavior >> oldSelector) protocol.
	(aBehavior includesLocalSelector: newSelector) ifTrue: [
			RBRefactoringError signal: (String streamContents: [ :stream |
						 stream << 'Cannot rename accessor ' << oldSelector asString << ' to ' << newSelector asString
						 << ' because the target selector already exists.' ]) ].
	aBehavior compile: sourceString withInternalLineEndings classified: protocol.
	aBehavior removeSelector: oldSelector
]

{ #category : 'private' }
MCPRenameSlotCommand >> renameAccessorsInBehavior: aBehavior [

	self
		renameAccessor: self slotName asSymbol
		to: self newSlotName asSymbol
		source: self getterSourceForNewSlot
		inBehavior: aBehavior.
	self
		renameAccessor: (self slotName , ':') asSymbol
		to: (self newSlotName , ':') asSymbol
		source: self setterSourceForNewSlot
		inBehavior: aBehavior
]

{ #category : 'private' }
MCPRenameSlotCommand >> restoreSlotValues: someAssociations [

	someAssociations do: [ :each | each key instVarNamed: self newSlotName asString put: each value ]
]

{ #category : 'private' }
MCPRenameSlotCommand >> rewriteReferencesForSelector: aSelector inBehavior: aBehavior [

	| accessorRewriter changed parseTree protocol source variableRewriter |
	parseTree := aBehavior parseTreeForSelector: aSelector.
	parseTree ifNil: [ ^ self ].
	changed := false.
	variableRewriter := self variableReferenceRewriterForSelector: aSelector.
	(variableRewriter executeTree: parseTree) ifTrue: [
			parseTree := variableRewriter tree.
			changed := true ].
	accessorRewriter := self accessorMessageRewriter.
	(accessorRewriter executeTree: parseTree) ifTrue: [
			parseTree := accessorRewriter tree.
			changed := true ].
	changed ifFalse: [ ^ self ].
	protocol := (aBehavior >> aSelector) protocol.
	source := (parseTree formattedCodeIn: aBehavior) withInternalLineEndings.
	aBehavior compile: source classified: protocol
]

{ #category : 'private' }
MCPRenameSlotCommand >> rewriteReferencesInBehavior: aBehavior [

	aBehavior withAllSubclasses do: [ :eachBehavior |
			(self referenceSelectorsInBehavior: eachBehavior) do: [ :eachSelector |
				self rewriteReferencesForSelector: eachSelector inBehavior: eachBehavior ] ]
]

{ #category : 'private' }
MCPRenameSlotCommand >> setterSourceForNewSlot [

	^ String streamContents: [ :stream |
		  stream << self newSlotName << ': anObject' << String cr << String cr << self newSlotName << ' := anObject' ]
]

{ #category : 'private' }
MCPRenameSlotCommand >> slotValuesForBehavior: aBehavior [

	| values |
	(self definesSlotNamed: self slotName in: aBehavior) ifFalse: [ ^ #(  ) ].
	values := OrderedCollection new.
	aBehavior withAllSubclasses do: [ :eachBehavior |
		eachBehavior allInstances do: [ :eachObject | values add: eachObject -> (eachObject instVarNamed: self slotName asString) ] ].
	^ values asArray
]

{ #category : 'private' }
MCPRenameSlotCommand >> validateSlotRenameInBehavior: aBehavior [

	self validateSlotIsDefinedIn: aBehavior.
	(self hierarchyDefinesSlotNamed: self newSlotName inBehavior: aBehavior) ifTrue: [
			RBRefactoringError signal: (String streamContents: [ :stream |
					 stream << self newSlotName << ' is already defined in the class ' << self className << ' or its hierarchy.' ]) ]
]

{ #category : 'private' }
MCPRenameSlotCommand >> variableReferenceRewriterForSelector: aSelector [

	^ RBParseTreeRewriter rename: self slotName to: self newSlotName handler: [
			  RBRefactoringError signal: (String streamContents: [ :stream |
					   stream << self newSlotName << ' is already defined as a method or block temporary variable while rewriting '
					   << aSelector asString ]) ]
]
