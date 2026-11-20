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
	"The same rename on either side: a class-side slot is an instance variable of the metaclass. The methods that refer to the slot are rewritten before anything changes, since rewriting one can be refused, and compiled once the new slot is there."

	| preservedValues rewrittenReferences |
	self validateSlotRenameInBehavior: aBehavior.
	rewrittenReferences := self rewrittenReferencesInBehavior: aBehavior.
	preservedValues := self slotValuesForBehavior: aBehavior.
	aBehavior addInstVarNamed: self newSlotName.
	self restoreSlotValues: preservedValues.
	rewrittenReferences do: [ :each | each value ].
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
MCPRenameSlotCommand >> renameAccessor: oldSelector source: sourceString inBehavior: aBehavior [

	(aBehavior includesLocalSelector: oldSelector) ifFalse: [ ^ self ].
	aBehavior compile: sourceString withInternalLineEndings classified: (aBehavior >> oldSelector) protocol.
	aBehavior removeSelector: oldSelector
]

{ #category : 'private' }
MCPRenameSlotCommand >> renameAccessorsInBehavior: aBehavior [

	self renameAccessor: self slotName asSymbol source: self getterSourceForNewSlot inBehavior: aBehavior.
	self renameAccessor: (self slotName , ':') asSymbol source: self setterSourceForNewSlot inBehavior: aBehavior
]

{ #category : 'private' }
MCPRenameSlotCommand >> restoreSlotValues: someAssociations [

	someAssociations do: [ :each | each key instVarNamed: self newSlotName asString put: each value ]
]

{ #category : 'private' }
MCPRenameSlotCommand >> rewriteOfSelector: aSelector inBehavior: aBehavior [
	"A block compiling the method rewritten for the new name, or nil when nothing in it changes."

	| accessorRewriter changed parseTree source variableRewriter |
	parseTree := aBehavior parseTreeForSelector: aSelector.
	parseTree ifNil: [ ^ nil ].
	changed := false.
	variableRewriter := self variableReferenceRewriterForSelector: aSelector inBehavior: aBehavior.
	(variableRewriter executeTree: parseTree) ifTrue: [
			parseTree := variableRewriter tree.
			changed := true ].
	accessorRewriter := self accessorMessageRewriter.
	(accessorRewriter executeTree: parseTree) ifTrue: [
			parseTree := accessorRewriter tree.
			changed := true ].
	changed ifFalse: [ ^ nil ].
	source := (parseTree formattedCodeIn: aBehavior) withInternalLineEndings.
	^ [ aBehavior compile: source classified: (aBehavior >> aSelector) protocol ]
]

{ #category : 'private' }
MCPRenameSlotCommand >> rewrittenReferencesInBehavior: aBehavior [
	"A block for each method that refers to the slot or its accessors, compiling it rewritten for the new name."

	^ aBehavior withAllSubclasses flatCollect: [ :eachBehavior |
			  (self referenceSelectorsInBehavior: eachBehavior)
				  collect: [ :eachSelector | self rewriteOfSelector: eachSelector inBehavior: eachBehavior ]
				  thenReject: [ :each | each isNil ] ]
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
MCPRenameSlotCommand >> validateAccessorRenamesInBehavior: aBehavior [
	"Checked before anything changes: a refusal met while renaming the accessors would come after the new slot was added and the senders rewritten."

	{
		(self slotName -> self newSlotName).
		(self slotName , ':' -> (self newSlotName , ':')) } do: [ :each |
			((aBehavior includesLocalSelector: each key asSymbol) and: [ aBehavior includesLocalSelector: each value asSymbol ]) ifTrue: [
					RBRefactoringError signal: ('Cannot rename accessor {1} to {2} because {3} already defines {2}.' format: {
								 each key.
								 each value.
								 aBehavior name }) ] ]
]

{ #category : 'private' }
MCPRenameSlotCommand >> validateSlotRenameInBehavior: aBehavior [

	self validateSlotIsDefinedIn: aBehavior.
	(self hierarchyDefinesSlotNamed: self newSlotName inBehavior: aBehavior) ifTrue: [
			RBRefactoringError signal: (String streamContents: [ :stream |
					 stream << self newSlotName << ' is already defined in the class ' << self className << ' or its hierarchy.' ]) ].
	self validateAccessorRenamesInBehavior: aBehavior
]

{ #category : 'private' }
MCPRenameSlotCommand >> variableReferenceRewriterForSelector: aSelector inBehavior: aBehavior [

	^ RBParseTreeRewriter rename: self slotName to: self newSlotName handler: [
			  RBRefactoringError signal: ('{1}>>{2} already has a temporary or an argument named {3}.' format: {
						   aBehavior name.
						   aSelector.
						   self newSlotName }) ]
]
