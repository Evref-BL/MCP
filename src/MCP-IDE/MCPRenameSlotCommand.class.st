"
Renames a slot on either side of a class: the objects hold under the new name what the slot held, its references are rewritten, and the methods named after it are renamed as method_update renames a method, their senders across the image with them.
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
MCPRenameSlotCommand >> accessorRenames [
	"The selector of each method named after the slot, the getter and the setter, with the one it is renamed to."

	^ {
		  (self slotName asSymbol -> self newSlotName asSymbol).
		  ((self slotName , ':') asSymbol -> (self newSlotName , ':') asSymbol) }
]

{ #category : 'private' }
MCPRenameSlotCommand >> applyToBehavior: aBehavior [
	"The same rename on either side: a class-side slot is an instance variable of the metaclass. The methods that refer to the slot are rewritten once before anything changes, since rewriting one can be refused, and again after the accessors are renamed, whose senders that renaming changes, to be compiled once the new slot is there."

	| rewrittenReferences |
	self validateSlotRenameInBehavior: aBehavior.
	self rewrittenReferencesInBehavior: aBehavior.
	self renameAccessorsInBehavior: aBehavior.
	rewrittenReferences := self rewrittenReferencesInBehavior: aBehavior.
	self installing: [ aBehavior addInstVarNamed: self newSlotName ].
	rewrittenReferences do: [ :each | each value ].
	aBehavior removeInstVarNamed: self slotName
]

{ #category : 'private' }
MCPRenameSlotCommand >> hierarchyDefinesSlotNamed: aSlotName inBehavior: aBehavior [

	(aBehavior hasSlotNamed: aSlotName asSymbol) ifTrue: [ ^ true ].
	^ aBehavior allSubclasses anySatisfy: [ :each | self definesSlotNamed: aSlotName in: each ]
]

{ #category : 'private' }
MCPRenameSlotCommand >> hierarchyImplementorsOf: aSelector inBehavior: aBehavior [
	"The classes at or below aBehavior that define aSelector themselves: a method of that name in a subclass reads the slot as well."

	^ aBehavior withAllSubclasses select: [ :each | each includesLocalSelector: aSelector ]
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

	^ (aBehavior whichMethodsAccess: self slotName) collect: [ :each | each selector ] as: Set
]

{ #category : 'private' }
MCPRenameSlotCommand >> refuseOtherImplementorsOf: aSelector inBehavior: aBehavior [

	| others names |
	others := ((SystemNavigation default allImplementorsOf: aSelector) collect: [ :each | each methodClass ]) reject: [ :each |
		          aBehavior withAllSubclasses includes: each ].
	others ifEmpty: [ ^ self ].
	names := ', ' join: ((others first: (others size min: 3)) collect: [ :each | each name ]).
	others size > 3 ifTrue: [
			names := '{1} and {2} more' format: {
					         names.
					         (others size - 3) } ].
	RBRefactoringError signal:
		('Cannot rename accessor {1}: other classes define it too ({2}), and its senders cannot be told from theirs. Rename the accessors with method_update and a scope first, then the slot.'
			 format: {
					 aSelector.
					 names })
]

{ #category : 'private' }
MCPRenameSlotCommand >> renameAccessorsInBehavior: aBehavior [
	"Each method named after the slot, in its class or one below, is renamed as method_update renames a method: its source kept but for its selector line, and its senders across the image changed. One rename renames every implementor, and the validation has made sure they are all at or below aBehavior."

	self accessorRenames do: [ :each |
			(self hierarchyImplementorsOf: each key inBehavior: aBehavior) ifNotEmpty: [ :implementors |
					(MCPUpdateMethodCommand
						 changing: each key
						 of: implementors first
						 to: each value
						 argumentNames: #(  )
						 environment: RBBrowserEnvironment new) execute ] ]
]

{ #category : 'private' }
MCPRenameSlotCommand >> rewriteOfSelector: aSelector inBehavior: aBehavior [
	"A block compiling the method rewritten for the new name, or nil when nothing in it changes."

	| parseTree rewriter source |
	parseTree := aBehavior parseTreeForSelector: aSelector.
	parseTree ifNil: [ ^ nil ].
	rewriter := self variableReferenceRewriterForSelector: aSelector inBehavior: aBehavior.
	(rewriter executeTree: parseTree) ifFalse: [ ^ nil ].
	source := (aBehavior formatter format: rewriter tree) withInternalLineEndings.
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
MCPRenameSlotCommand >> slotNameAfterChange: aSlotName [

	^ aSlotName = self slotName asSymbol
		  ifTrue: [ self newSlotName asSymbol ]
		  ifFalse: [ aSlotName ]
]

{ #category : 'private' }
MCPRenameSlotCommand >> validateAccessorRenamesInBehavior: aBehavior [
	"Checked before anything changes: a refusal met while renaming the accessors would come after the new slot was added and the senders rewritten. An accessor is renamed with its senders across the image, which a class outside the slot's hierarchy implementing the same selector would share: its method and its sends would be renamed too."

	self accessorRenames do: [ :each |
			| implementors |
			implementors := self hierarchyImplementorsOf: each key inBehavior: aBehavior.
			implementors detect: [ :implementor | implementor includesLocalSelector: each value ] ifFound: [ :implementor |
					RBRefactoringError signal: ('Cannot rename accessor {1} to {2} because {3} already defines {2}.' format: {
								 each key.
								 each value.
								 implementor name }) ].
			implementors ifNotEmpty: [ self refuseOtherImplementorsOf: each key inBehavior: aBehavior ] ]
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
