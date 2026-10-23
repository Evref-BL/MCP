"
Runs Renraku critique rules over a requested image scope and returns paginated critique hits grouped by rule class.
"
Class {
	#name : 'MCPToolRunCritiques',
	#superclass : 'MCPToolSearch',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolRunCritiques class >> groupName [

	^ self methodsGroupName
]

{ #category : 'metadata' }
MCPToolRunCritiques class >> toolName [

	^ 'critique_run'
]

{ #category : 'private - running' }
MCPToolRunCritiques >> addClassCritiqueEntriesForRuleClass: ruleClass queryRequest: queryRequest to: entries maximum: maximum [

	| rule |
	rule := ruleClass new.
	self sortedBehaviorsForQueryRequest: queryRequest do: [ :eachBehavior |
			(self hasCollectedEnoughEntries: entries maximum: maximum) ifFalse: [
					rule check: eachBehavior forCritiquesDo: [ :critique |
							self
								addEntryForCritique: critique
								rule: rule
								fallbackEntity: eachBehavior
								to: entries
								maximum: maximum ] ] ]
]

{ #category : 'private - rules' }
MCPToolRunCritiques >> addCritiqueEntriesForRuleClass: ruleClass queryRequest: queryRequest to: entries maximum: maximum [

	ruleClass checksMethod ifTrue: [
			self
				addMethodCritiqueEntriesForRuleClass: ruleClass
				queryRequest: queryRequest
				to: entries
				maximum: maximum ].
	ruleClass checksNode ifTrue: [
			self
				addNodeCritiqueEntriesForRuleClass: ruleClass
				queryRequest: queryRequest
				to: entries
				maximum: maximum ].
	ruleClass checksClass ifTrue: [
			self
				addClassCritiqueEntriesForRuleClass: ruleClass
				queryRequest: queryRequest
				to: entries
				maximum: maximum ].
	ruleClass checksPackage ifTrue: [
			self
				addPackageCritiqueEntriesForRuleClass: ruleClass
				queryRequest: queryRequest
				to: entries
				maximum: maximum ]
]

{ #category : 'private - entries' }
MCPToolRunCritiques >> addEntryForCritique: critique rule: rule fallbackEntity: fallbackEntity to: entries maximum: maximum [

	(self hasCollectedEnoughEntries: entries maximum: maximum) ifTrue: [ ^ self ].
	entries add: (self critiqueEntryFor: critique rule: rule fallbackEntity: fallbackEntity)
]

{ #category : 'private - entries' }
MCPToolRunCritiques >> addIntervalFromAnchor: sourceAnchor toHitData: data [

	| interval |
	(sourceAnchor class canUnderstand: #interval) ifFalse: [ ^ self ].
	interval := sourceAnchor interval.
	interval ifNil: [ ^ self ].
	data at: #interval put: interval first asString , '-' , interval last asString
]

{ #category : 'private - running' }
MCPToolRunCritiques >> addMethodCritiqueEntriesForRuleClass: ruleClass queryRequest: queryRequest to: entries maximum: maximum [

	| rule |
	rule := ruleClass new.
	self sortedMethodsForQueryRequest: queryRequest do: [ :eachMethod |
			(self hasCollectedEnoughEntries: entries maximum: maximum) ifFalse: [
					rule check: eachMethod forCritiquesDo: [ :critique |
							self
								addEntryForCritique: critique
								rule: rule
								fallbackEntity: eachMethod
								to: entries
								maximum: maximum ] ] ]
]

{ #category : 'private - running' }
MCPToolRunCritiques >> addNodeCritiqueEntriesForRuleClass: ruleClass queryRequest: queryRequest to: entries maximum: maximum [

	| rule |
	rule := ruleClass new.
	self sortedMethodsForQueryRequest: queryRequest do: [ :eachMethod |
			(self hasCollectedEnoughEntries: entries maximum: maximum) ifFalse: [
					eachMethod ast nodesDo: [ :eachNode |
							(self hasCollectedEnoughEntries: entries maximum: maximum) ifFalse: [
									rule check: eachNode forCritiquesDo: [ :critique |
											self
												addEntryForCritique: critique
												rule: rule
												fallbackEntity: eachMethod
												to: entries
												maximum: maximum ] ] ] ] ]
]

{ #category : 'private - running' }
MCPToolRunCritiques >> addPackageCritiqueEntriesForRuleClass: ruleClass queryRequest: queryRequest to: entries maximum: maximum [

	| rule |
	rule := ruleClass new.
	self sortedPackagesForQueryRequest: queryRequest do: [ :eachPackage |
			(self hasCollectedEnoughEntries: entries maximum: maximum) ifFalse: [
					rule check: eachPackage forCritiquesDo: [ :critique |
							self
								addEntryForCritique: critique
								rule: rule
								fallbackEntity: eachPackage
								to: entries
								maximum: maximum ] ] ]
]

{ #category : 'private - entries' }
MCPToolRunCritiques >> addTarget: target toHitData: data [

	target ifNil: [ ^ self ].
	target isCompiledMethod ifTrue: [
			data at: #method put: (self methodReferenceForCompiledMethod: target).
			^ self ].
	target isBehavior ifTrue: [
			data at: #class put: (self targetNameForBehavior: target).
			^ self ].
	target class name = #Package ifTrue: [
			data at: #package put: target name.
			^ self ].
	data at: #entity put: target printString
]

{ #category : 'metadata' }
MCPToolRunCritiques >> additionalKeywords [

	^ #( 'critique' 'critiques' 'lint' 'renraku' 'rule' 'rules' 'quality' 'review' )
]

{ #category : 'private - rules' }
MCPToolRunCritiques >> allRuleClasses [

	^ (ReRuleManager uniqueInstance allRules collect: [ :each | each class ]) asSet asArray sort: [ :left :right |
		  left name <= right name ]
]

{ #category : 'metadata' }
MCPToolRunCritiques >> buildInputSchema [

	^ self queryInputSchemaWithProperties: { self searchScopeSchemaProperty } , {
			  self methodSideSchemaProperty.
			  self ruleClassesSchemaProperty.
			  self offsetInputProperty }
]

{ #category : 'private - entries' }
MCPToolRunCritiques >> critiqueEntryFor: critique rule: rule fallbackEntity: fallbackEntity [
	"The rule class and its title say which rule this is; its rationale is documentation of the rule,
	not of the hit, and is the same on every one of them. A fixable hit is one whose rule method_rewrite
	can be given by name."

	| entry |
	entry := Dictionary new.
	entry at: #ruleClass put: rule class name asString.
	entry at: #title put: rule name asString.
	rule severity ifNotNil: [ :severity | entry at: #severity put: severity asString ].
	(rule isKindOf: MCPMethodStyleRule) ifTrue: [ entry at: #fixable put: true ].
	entry at: #hit put: (self hitDataForCritique: critique fallbackEntity: fallbackEntity).
	^ entry
]

{ #category : 'defaults' }
MCPToolRunCritiques >> defaultPageLimit [
	"A rule carries its hits, so a page holds fewer than a flat list would."

	^ 20
]

{ #category : 'metadata' }
MCPToolRunCritiques >> description [

	^ 'Run Renraku critique rules over a scoped part of the Pharo image and return paginated hits grouped by rule class. A hit marked fixable names a rule method_rewrite can apply.'
]

{ #category : 'private - template' }
MCPToolRunCritiques >> failureMessageForScope: scopeSummary error: anError [

	^ self scopeQueryFailureMessageFor: 'critiques' scope: scopeSummary error: anError
]

{ #category : 'private - results' }
MCPToolRunCritiques >> finalizedRuleGroup: group [

	| finalized |
	finalized := group copy.
	finalized at: #hits put: (group at: #hits) asArray.
	^ finalized
]

{ #category : 'private - entries' }
MCPToolRunCritiques >> hasCanonicalTargetDataFor: target [

	target ifNil: [ ^ false ].
	target isCompiledMethod ifTrue: [ ^ true ].
	target isBehavior ifTrue: [ ^ true ].
	^ target class name = #Package
]

{ #category : 'private - pagination' }
MCPToolRunCritiques >> hasCollectedEnoughEntries: entries maximum: maximum [

	^ entries size >= maximum
]

{ #category : 'private - entries' }
MCPToolRunCritiques >> hitDataForCritique: critique fallbackEntity: fallbackEntity [

	| anchor data target |
	data := Dictionary new.
	anchor := self sourceAnchorForCritique: critique.
	target := anchor
		          ifNil: [ fallbackEntity ]
		          ifNotNil: [ :sourceAnchor | self targetEntityFromAnchor: sourceAnchor fallbackEntity: fallbackEntity ].
	self addTarget: target toHitData: data.
	anchor ifNotNil: [ self addIntervalFromAnchor: anchor toHitData: data ].
	^ data
]

{ #category : 'private - rules' }
MCPToolRunCritiques >> isCritiqueRuleClass: aClass [

	^ aClass isBehavior and: [ aClass isMeta not and: [ aClass canUnderstand: #check:forCritiquesDo: ] ]
]

{ #category : 'private - pagination' }
MCPToolRunCritiques >> maximumEntriesToCollectForQueryRequest: queryRequest [

	queryRequest limit = 0 ifTrue: [ ^ 0 ].
	^ queryRequest offset + queryRequest limit + 1
]

{ #category : 'private - methods' }
MCPToolRunCritiques >> methodReferenceForBehavior: aBehavior selector: aSelector [

	^ String streamContents: [ :stream |
			  stream nextPutAll: (self targetNameForBehavior: aBehavior).
			  stream nextPutAll: '>>'.
			  stream nextPutAll: aSelector asString ]
]

{ #category : 'private - methods' }
MCPToolRunCritiques >> methodReferenceForCompiledMethod: aCompiledMethod [

	^ self methodReferenceForBehavior: aCompiledMethod methodClass selector: aCompiledMethod selector
]

{ #category : 'private - request' }
MCPToolRunCritiques >> methodScopeQueryFromRequest: request [

	^ MCPCompiledMethodScopeQuery new
		  packageNames: (self searchScopeStringCollectionNamed: 'packages' fromRequest: request);
		  classNames: (self searchScopeStringCollectionNamed: 'classes' fromRequest: request);
		  subclassClassNames: (self searchScopeStringCollectionNamed: 'subclassesOf' fromRequest: request);
		  parentClassNames: (self searchScopeStringCollectionNamed: 'superclassesOf' fromRequest: request);
		  side: (request stringArgumentNamed: 'side' default: 'both');
		  yourself
]

{ #category : 'private - schema' }
MCPToolRunCritiques >> methodSideSchemaProperty [

	^ self
		  stringEnumSchemaPropertyNamed: 'side'
		  description: 'Method side to search.'
		  values: #( 'instance' 'class' 'both' )
		  default: 'both'
]

{ #category : 'private - scope' }
MCPToolRunCritiques >> packagesForQueryRequest: queryRequest [

	queryRequest scopeQuery usesImplicitImageScope ifTrue: [ ^ PackageOrganizer default packages asArray ].
	queryRequest scopeQuery packageNames ifEmpty: [ ^ #(  ) ].
	^ queryRequest scopeQuery packageNames
		  collect: [ :eachName | queryRequest scopeQuery packageNamed: eachName inScope: 'packageNames' ]
		  thenSelect: [ :eachPackage | eachPackage notNil ]
]

{ #category : 'private - template' }
MCPToolRunCritiques >> queryEntriesForQueryRequest: queryRequest [

	| entries maximum |
	entries := OrderedCollection new.
	maximum := self maximumEntriesToCollectForQueryRequest: queryRequest.
	maximum = 0 ifTrue: [ ^ #(  ) ].
	queryRequest ruleClasses do: [ :eachRuleClass |
			self
				addCritiqueEntriesForRuleClass: eachRuleClass
				queryRequest: queryRequest
				to: entries
				maximum: maximum ].
	^ entries asArray
]

{ #category : 'private - template' }
MCPToolRunCritiques >> queryResultDataForQueryRequest: queryRequest page: page [

	| data |
	data := Dictionary new.
	data at: #rules put: (self ruleGroupsFromEntries: page entries).
	page nextOffset ifNotNil: [ :offset | data at: #nextOffset put: offset ].
	^ data
]

{ #category : 'private - template' }
MCPToolRunCritiques >> requestedContextFromRequest: request [

	^ { (#scope -> (self classAndMethodScopeSummaryFromRequest: request)) } asDictionary
]

{ #category : 'private - rules' }
MCPToolRunCritiques >> ruleClassNamed: aRuleClassName [

	| ruleClass |
	ruleClass := Smalltalk globals at: aRuleClassName asSymbol ifAbsent: [
			             MCPCommandError
				             signalErrorCode: #CritiqueRuleNotFound
				             message: 'Critique rule class not found: ' , aRuleClassName
				             details: { (#ruleClass -> aRuleClassName) } asDictionary ].
	(self isCritiqueRuleClass: ruleClass) ifFalse: [
			MCPCommandError
				signalErrorCode: #InvalidCritiqueRule
				message: aRuleClassName , ' is not a critique rule class.'
				details: { (#ruleClass -> aRuleClassName) } asDictionary ].
	^ ruleClass
]

{ #category : 'private - rules' }
MCPToolRunCritiques >> ruleClassesFromRequest: request [

	| ruleClassNames |
	ruleClassNames := request uniqueStringCollectionArgumentNamed: 'ruleClasses'.
	ruleClassNames ifEmpty: [ ^ self allRuleClasses ].
	^ (ruleClassNames collect: [ :eachName | self ruleClassNamed: eachName ]) sort: [ :left :right | left name <= right name ]
]

{ #category : 'private - schema' }
MCPToolRunCritiques >> ruleClassesSchemaProperty [

	^ self
		  stringArraySchemaNamed: 'ruleClasses'
		  description: 'Renraku rule class names to run. Omit or pass an empty array to run all available rules.'
		  itemDescription: 'Rule class name.'
]

{ #category : 'private - results' }
MCPToolRunCritiques >> ruleGroupFromEntry: entry [

	| group |
	group := Dictionary new.
	group at: #ruleClass put: (entry at: #ruleClass).
	group at: #title put: (entry at: #title).
	entry at: #severity ifPresent: [ :severity | severity isEmpty ifFalse: [ group at: #severity put: severity ] ].
	group at: #hits put: OrderedCollection new.
	^ group
]

{ #category : 'private - results' }
MCPToolRunCritiques >> ruleGroupsFromEntries: entries [

	| groups |
	groups := OrderedCollection new.
	entries do: [ :entry |
			| group |
			group := groups detect: [ :eachGroup | (eachGroup at: #ruleClass) = (entry at: #ruleClass) ] ifNone: [
					         | newGroup |
					         newGroup := self ruleGroupFromEntry: entry.
					         groups add: newGroup.
					         newGroup ].
			(group at: #hits) add: (entry at: #hit) ].
	^ groups collect: [ :each | self finalizedRuleGroup: each ] as: Array
]

{ #category : 'private - request' }
MCPToolRunCritiques >> searchRequestFromToolRequest: request [

	^ MCPCritiqueRunRequest fromRequest: request tool: self
]

{ #category : 'private - scope' }
MCPToolRunCritiques >> sortedBehaviorsForQueryRequest: queryRequest do: aBlock [

	| behaviors |
	behaviors := queryRequest scopeQuery behaviors asArray.
	behaviors sort: [ :left :right | (self targetNameForBehavior: left) <= (self targetNameForBehavior: right) ].
	behaviors do: aBlock
]

{ #category : 'private - scope' }
MCPToolRunCritiques >> sortedMethodsForQueryRequest: queryRequest do: aBlock [

	| methods |
	methods := queryRequest scopeQuery methods asArray.
	methods sort: [ :left :right | (self methodReferenceForCompiledMethod: left) <= (self methodReferenceForCompiledMethod: right) ].
	methods do: aBlock
]

{ #category : 'private - scope' }
MCPToolRunCritiques >> sortedPackagesForQueryRequest: queryRequest do: aBlock [

	| packages |
	packages := self packagesForQueryRequest: queryRequest.
	packages sort: [ :left :right | left name <= right name ].
	packages do: aBlock
]

{ #category : 'private - entries' }
MCPToolRunCritiques >> sourceAnchorForCritique: critique [

	(critique class canUnderstand: #sourceAnchor) ifFalse: [ ^ nil ].
	^ critique sourceAnchor
]

{ #category : 'private - results' }
MCPToolRunCritiques >> successSummaryForScope: scopeSummary page: page [

	^ self scopeQuerySuccessSummaryFor: 'critique hits' scope: scopeSummary page: page
]

{ #category : 'private - entries' }
MCPToolRunCritiques >> targetEntityFromAnchor: sourceAnchor fallbackEntity: fallbackEntity [

	| entity |
	(sourceAnchor class canUnderstand: #entity) ifFalse: [ ^ fallbackEntity ].
	entity := sourceAnchor entity ifNil: [ ^ fallbackEntity ].
	(self hasCanonicalTargetDataFor: entity) ifTrue: [ ^ entity ].
	^ fallbackEntity
]

{ #category : 'private - methods' }
MCPToolRunCritiques >> targetNameForBehavior: aBehavior [

	^ aBehavior isMeta
		  ifTrue: [ aBehavior instanceSide name , ' class' ]
		  ifFalse: [ aBehavior name ]
]

{ #category : 'metadata' }
MCPToolRunCritiques >> title [

	^ 'Run critiques'
]
