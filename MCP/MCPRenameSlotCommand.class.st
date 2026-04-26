"
Renames a slot on a class. Instance-side renames use the refactoring engine. Class-side renames use a metaclass-aware path that snapshots affected class objects, restores their values into the renamed slot, rewrites class-side references, and renames local accessors.
"
Class {
	#name : 'MCPRenameSlotCommand',
	#superclass : 'Object',
	#instVars : [
		'className',
		'slotName',
		'newSlotName',
		'classSide'
	],
	#category : 'MCP-Commands',
	#package : 'MCP',
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

{ #category : 'accessing' }
MCPRenameSlotCommand >> className [

	^ className
]

{ #category : 'accessing' }
MCPRenameSlotCommand >> className: aClassName [

	className := aClassName
]

{ #category : 'accessing' }
MCPRenameSlotCommand >> classSide [

	^ classSide
]

{ #category : 'accessing' }
MCPRenameSlotCommand >> classSide: aBoolean [

	classSide := aBoolean
]

{ #category : 'private' }
MCPRenameSlotCommand >> classSideAccessorMessageRewriter [

	| rewriter |
	rewriter := RBParseTreeRewriter new.
	rewriter
		replace: '``@receiver ' , self slotName , ': ``@value'
		with: '``@receiver ' , self newSlotName , ': ``@value';
		replace: '``@receiver ' , self slotName
		with: '``@receiver ' , self newSlotName.
	^ rewriter
]

{ #category : 'private' }
MCPRenameSlotCommand >> classSideReferenceSelectorsInBehavior: aBehavior [

	| selectors |
	selectors := Set new.
	selectors addAll:
		((aBehavior whichMethodsAccess: self slotName) collect: #selector).
	selectors addAll:
		(aBehavior whichSelectorsReferTo: self slotName asSymbol).
	selectors addAll:
		(aBehavior whichSelectorsReferTo: (self slotName , ':') asSymbol).
	^ selectors
]

{ #category : 'private' }
MCPRenameSlotCommand >> classSideSlotValuesForBehavior: aBehavior [

	| values |
	(self slotNamed: self slotName isDefinedIn: aBehavior) ifFalse: [
		^ #(  ) ].
	values := OrderedCollection new.
	aBehavior withAllSubclasses do: [ :eachBehavior |
		eachBehavior allInstances do: [ :eachObject |
			values add:
				eachObject -> (eachObject instVarNamed: self slotName asString) ] ].
	^ values asArray
]

{ #category : 'private' }
MCPRenameSlotCommand >> currentClass [

	^ Smalltalk globals
		  at: self className asSymbol
		  ifAbsent: [
		  MCPCommandError signalMissingClassNamed: self className ]
]

{ #category : 'executing' }
MCPRenameSlotCommand >> execute [

	| currentClass updatedClass |
	currentClass := self currentClass.
	updatedClass := self classSide
		                ifTrue: [
			                self renameClassSideSlotInBehavior:
				                currentClass classSide.
			                Smalltalk globals at: self className asSymbol ]
		                ifFalse: [
			                (self refactoringForBehavior: currentClass) execute.
			                Smalltalk globals at: self className asSymbol ].
	^ MCPRenameSlotResult
		  classInfo: (MCPClassInfo fromClass: updatedClass)
		  oldSlotName: self slotName
		  newSlotName: self newSlotName
		  classSide: self classSide
]

{ #category : 'private' }
MCPRenameSlotCommand >> getterSourceForNewSlot [

	^ self newSlotName , String cr , String cr , '^ ' , self newSlotName
]

{ #category : 'private' }
MCPRenameSlotCommand >> hierarchyDefinesSlotNamed: aSlotName inBehavior: aBehavior [

	(aBehavior hasSlotNamed: aSlotName asSymbol) ifTrue: [ ^ true ].
	^ aBehavior allSubclasses anySatisfy: [ :each |
		  self slotNamed: aSlotName isDefinedIn: each ]
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
MCPRenameSlotCommand >> normalizedBehaviorNameFor: aBehavior [

	^ (aBehavior isMeta
		   ifTrue: [ aBehavior instanceSide name ]
		   ifFalse: [ aBehavior name ]) asString
]

{ #category : 'private' }
MCPRenameSlotCommand >> refactoringForBehavior: aBehavior [

	^ RBRenameInstanceVariableRefactoring
		  rename: self slotName
		  to: self newSlotName
		  in: aBehavior
		  renameAccessors: true
]

{ #category : 'private' }
MCPRenameSlotCommand >> renameClassSideAccessor: oldSelector to: newSelector source: sourceString inBehavior: aBehavior [

	| protocol |
	(aBehavior includesLocalSelector: oldSelector) ifFalse: [ ^ self ].
	protocol := (aBehavior >> oldSelector) protocol.
	(aBehavior includesLocalSelector: newSelector) ifTrue: [
		RBRefactoringError signal:
			'Cannot rename accessor ' , oldSelector asString , ' to '
			, newSelector asString
			, ' because the target selector already exists.' ].
	aBehavior compile: sourceString classified: protocol.
	aBehavior removeSelector: oldSelector
]

{ #category : 'private' }
MCPRenameSlotCommand >> renameClassSideAccessorsInBehavior: aBehavior [

	self
		renameClassSideAccessor: self slotName asSymbol
		to: self newSlotName asSymbol
		source: self getterSourceForNewSlot
		inBehavior: aBehavior.
	self
		renameClassSideAccessor: (self slotName , ':') asSymbol
		to: (self newSlotName , ':') asSymbol
		source: self setterSourceForNewSlot
		inBehavior: aBehavior
]

{ #category : 'private' }
MCPRenameSlotCommand >> renameClassSideSlotInBehavior: aBehavior [

	| preservedValues |
	self validateClassSideSlotRenameInBehavior: aBehavior.
	preservedValues := self classSideSlotValuesForBehavior: aBehavior.
	aBehavior addInstVarNamed: self newSlotName.
	self restoreClassSideSlotValues: preservedValues.
	self rewriteClassSideReferencesInBehavior: aBehavior.
	self renameClassSideAccessorsInBehavior: aBehavior.
	aBehavior removeInstVarNamed: self slotName
]

{ #category : 'private' }
MCPRenameSlotCommand >> restoreClassSideSlotValues: someAssociations [

	someAssociations do: [ :each |
		each key instVarNamed: self newSlotName asString put: each value ]
]

{ #category : 'private' }
MCPRenameSlotCommand >> rewriteClassSideReferencesForSelector: aSelector inBehavior: aBehavior [

	| accessorRewriter changed parseTree protocol variableRewriter |
	parseTree := aBehavior parseTreeForSelector: aSelector.
	parseTree ifNil: [ ^ self ].
	changed := false.
	variableRewriter := self variableReferenceRewriterForSelector:
		                    aSelector.
	(variableRewriter executeTree: parseTree) ifTrue: [
		parseTree := variableRewriter tree.
		changed := true ].
	accessorRewriter := self classSideAccessorMessageRewriter.
	(accessorRewriter executeTree: parseTree) ifTrue: [
		parseTree := accessorRewriter tree.
		changed := true ].
	changed ifFalse: [ ^ self ].
	protocol := (aBehavior >> aSelector) protocol.
	aBehavior compile: parseTree formattedCode classified: protocol
]

{ #category : 'private' }
MCPRenameSlotCommand >> rewriteClassSideReferencesInBehavior: aBehavior [

	aBehavior withAllSubclasses do: [ :eachBehavior |
		(self classSideReferenceSelectorsInBehavior: eachBehavior) do: [
			:eachSelector |
			self
				rewriteClassSideReferencesForSelector: eachSelector
				inBehavior: eachBehavior ] ]
]

{ #category : 'private' }
MCPRenameSlotCommand >> setterSourceForNewSlot [

	^ self newSlotName , ': anObject' , String cr , String cr
	  , self newSlotName , ' := anObject'
]

{ #category : 'accessing' }
MCPRenameSlotCommand >> slotName [

	^ slotName
]

{ #category : 'accessing' }
MCPRenameSlotCommand >> slotName: aSlotName [

	slotName := aSlotName
]

{ #category : 'private' }
MCPRenameSlotCommand >> slotNamed: aSlotName isDefinedIn: aBehavior [

	^ aBehavior slots anySatisfy: [ :each |
		  each name = aSlotName asSymbol ]
]

{ #category : 'private' }
MCPRenameSlotCommand >> validateClassSideSlotRenameInBehavior: aBehavior [

	(self slotNamed: self slotName isDefinedIn: aBehavior) ifFalse: [
		RBApplicabilityChecksFailedError signal:
			'The variable ' , self slotName
			, ' is not directly defined in the class '
			, (self normalizedBehaviorNameFor: aBehavior) ].
	(self
		 hierarchyDefinesSlotNamed: self newSlotName
		 inBehavior: aBehavior) ifTrue: [
		RBApplicabilityChecksFailedError signal:
			self newSlotName , ' is already defined in the class '
			, (self normalizedBehaviorNameFor: aBehavior)
			, ' or its hierarchy.' ]
]

{ #category : 'private' }
MCPRenameSlotCommand >> variableReferenceRewriterForSelector: aSelector [

	^ RBParseTreeRewriter
		  rename: self slotName
		  to: self newSlotName
		  handler: [
			  RBRefactoringError signal: self newSlotName
				  ,
				  ' is already defined as a method or block temporary variable while rewriting '
				  , aSelector asString ]
]
