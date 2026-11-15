"
Runs Renraku critique rules over a requested image scope and returns paginated critique hits grouped by rule class.
"
Class {
	#name : 'MCPToolRunCritiques',
	#superclass : 'MCPToolSearch',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
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
MCPToolRunCritiques >> addClassCritiqueEntriesForRuleClass: ruleClass in: scopeQuery runsOn: runsOnBlock to: entries maximum: maximum [

	| rule |
	rule := ruleClass new.
	self sortedBehaviorsIn: scopeQuery do: [ :eachBehavior |
			((self hasCollectedEnoughEntries: entries maximum: maximum) not and: [ runsOnBlock value: rule value: eachBehavior ]) ifTrue: [
					rule check: eachBehavior forCritiquesDo: [ :critique |
							self
								addEntryForCritique: critique
								rule: rule
								fallbackEntity: eachBehavior
								to: entries
								maximum: maximum ] ] ]
]

{ #category : 'private - rules' }
MCPToolRunCritiques >> addCritiqueEntriesForRuleClass: ruleClass in: scopeQuery runsOn: runsOnBlock to: entries maximum: maximum [

	ruleClass checksMethod ifTrue: [
			self
				addMethodCritiqueEntriesForRuleClass: ruleClass
				in: scopeQuery
				runsOn: runsOnBlock
				to: entries
				maximum: maximum ].
	ruleClass checksNode ifTrue: [
			self
				addNodeCritiqueEntriesForRuleClass: ruleClass
				in: scopeQuery
				runsOn: runsOnBlock
				to: entries
				maximum: maximum ].
	ruleClass checksClass ifTrue: [
			self
				addClassCritiqueEntriesForRuleClass: ruleClass
				in: scopeQuery
				runsOn: runsOnBlock
				to: entries
				maximum: maximum ].
	ruleClass checksPackage ifTrue: [
			self
				addPackageCritiqueEntriesForRuleClass: ruleClass
				in: scopeQuery
				runsOn: runsOnBlock
				to: entries
				maximum: maximum ]
]

{ #category : 'private - entries' }
MCPToolRunCritiques >> addEntryForCritique: critique rule: rule fallbackEntity: fallbackEntity to: entries maximum: maximum [

	(self hasCollectedEnoughEntries: entries maximum: maximum) ifTrue: [ ^ self ].
	entries add: (self critiqueEntryFor: critique rule: rule fallbackEntity: fallbackEntity)
]

{ #category : 'private - entries' }
MCPToolRunCritiques >> addIntervalFromAnchor: sourceAnchor of: target toHitData: data [
	"A hit in a method also says the line of the method as stored where it starts, and the code there, as a compile's critiques do; the interval stays for a tool that reads offsets."

	| interval |
	(sourceAnchor class canUnderstand: #interval) ifFalse: [ ^ self ].
	interval := sourceAnchor interval.
	interval ifNil: [ ^ self ].
	data at: #interval put: (String streamContents: [ :stream | stream << interval first asString << '-' << interval last asString ]).
	(target isNotNil and: [ target isCompiledMethod ]) ifFalse: [ ^ self ].
	data at: #line put: (self lineNumberAt: interval first in: target sourceCode).
	(self codeQuoteFor: interval in: target sourceCode) ifNotEmpty: [ :code | data at: #code put: code ]
]

{ #category : 'private - running' }
MCPToolRunCritiques >> addMethodCritiqueEntriesForRuleClass: ruleClass in: scopeQuery runsOn: runsOnBlock to: entries maximum: maximum [

	| rule |
	rule := ruleClass new.
	self sortedMethodsIn: scopeQuery do: [ :eachMethod |
			((self hasCollectedEnoughEntries: entries maximum: maximum) not and: [ runsOnBlock value: rule value: eachMethod ]) ifTrue: [
					rule check: eachMethod forCritiquesDo: [ :critique |
							self
								addEntryForCritique: critique
								rule: rule
								fallbackEntity: eachMethod
								to: entries
								maximum: maximum ] ] ]
]

{ #category : 'private - running' }
MCPToolRunCritiques >> addNodeCritiqueEntriesForRule: rule method: aMethod to: entries maximum: maximum [

	aMethod ast nodesDo: [ :eachNode |
			(self hasCollectedEnoughEntries: entries maximum: maximum) ifFalse: [
					rule check: eachNode forCritiquesDo: [ :critique |
							self
								addEntryForCritique: critique
								rule: rule
								fallbackEntity: aMethod
								to: entries
								maximum: maximum ] ] ]
]

{ #category : 'private - running' }
MCPToolRunCritiques >> addNodeCritiqueEntriesForRuleClass: ruleClass in: scopeQuery runsOn: runsOnBlock to: entries maximum: maximum [
	"A node rule is asked whether it wants the method before its nodes are walked, which is what Renraku's own sweeps do. A rule that excludes a method, as ReDoNotSendSuperInitializeInClassSideRule excludes every instance-side initialize, would otherwise be reported here and by no other tool."

	| rule |
	rule := ruleClass new.
	self sortedMethodsIn: scopeQuery do: [ :eachMethod |
			((self hasCollectedEnoughEntries: entries maximum: maximum) not and: [
				 (runsOnBlock value: rule value: eachMethod) and: [ rule shouldCheckMethod: eachMethod ] ]) ifTrue: [
					self
						addNodeCritiqueEntriesForRule: rule
						method: eachMethod
						to: entries
						maximum: maximum ] ]
]

{ #category : 'private - running' }
MCPToolRunCritiques >> addPackageCritiqueEntriesForRuleClass: ruleClass in: scopeQuery runsOn: runsOnBlock to: entries maximum: maximum [

	| rule |
	rule := ruleClass new.
	self sortedPackagesIn: scopeQuery do: [ :eachPackage |
			((self hasCollectedEnoughEntries: entries maximum: maximum) not and: [ runsOnBlock value: rule value: eachPackage ]) ifTrue: [
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
	"Every rule Renraku knows. Which of them run on an entity is decided there, since a manifest may force one the image has off."

	^ ReRuleManager visibleRuleClasses asArray sort: [ :left :right | left name <= right name ]
]

{ #category : 'metadata' }
MCPToolRunCritiques >> buildInputSchema [

	^ self queryInputSchemaWithProperties: { self methodSearchScopeSchemaProperty } , {
			  self ruleClassesSchemaProperty.
			  self offsetInputProperty }
]

{ #category : 'private - results' }
MCPToolRunCritiques >> contentTextForStructuredContent: structuredContent [
	"Each rule reads as one line naming it, then its hits two spaces in, one line each."

	| data rest |
	data := structuredContent at: #data ifAbsent: [ ^ super contentTextForStructuredContent: structuredContent ].
	^ String streamContents: [ :stream |
			  self summaryAndWarningsOn: stream for: structuredContent.
			  rest := data copy.
			  rest removeKey: #rules ifAbsent: [ nil ].
			  self dataTextOn: stream for: rest.
			  (data at: #rules ifAbsent: [ #(  ) ]) do: [ :group |
					  self ruleTextOn: stream for: group.
					  (group at: #hits) do: [ :hit | self hitTextOn: stream for: hit ] ] ]
]

{ #category : 'private - results' }
MCPToolRunCritiques >> countTextForRequest: request page: page [
	"7 critique hits, First 20 critique hits, Critique hits 21 to 40, No critique hits from offset 40. Collection stops one hit past the page, so no total is ever counted, and none is stated: a page says which hits it holds."

	| offset returned |
	offset := request integerArgumentNamed: 'offset'.
	returned := page returnedCount.
	^ String streamContents: [ :stream |
			  returned = 0
				  ifTrue: [
						  stream nextPutAll: 'No critique hits'.
						  offset > 0 ifTrue: [
								  stream
									  nextPutAll: ' from offset ';
									  print: offset ] ]
				  ifFalse: [
						  offset = 0
							  ifTrue: [
									  page nextOffset ifNotNil: [ stream nextPutAll: 'First ' ].
									  stream nextPutAll: (self textForCount: returned noun: self searchedNoun) ]
							  ifFalse: [
									  returned = 1
										  ifTrue: [
												  stream
													  nextPutAll: 'Critique hit ';
													  print: offset + 1 ]
										  ifFalse: [
												  stream
													  nextPutAll: 'Critique hits ';
													  print: offset + 1;
													  nextPutAll: ' to ';
													  print: offset + returned ] ] ] ]
]

{ #category : 'private - entries' }
MCPToolRunCritiques >> critiqueEntryFor: critique rule: rule fallbackEntity: fallbackEntity [
	"The rule class and its title say which rule this is; its rationale is documentation of the rule,
	not of the hit, and is the same on every one of them. A fixable hit is one whose rule method_rewrite
	can apply."

	| entry |
	entry := Dictionary new.
	entry at: #ruleClass put: rule class name asString.
	entry at: #title put: rule name asString.
	rule severity ifNotNil: [ :severity | entry at: #severity put: severity asString ].
	(MCPMethodRewriteNamedRuleSpec canApplyRuleClass: rule class) ifTrue: [ entry at: #fixable put: true ].
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

	^ 'Run Renraku critique rules over a scoped part of the Pharo image and return paginated hits grouped by rule. A rule method_rewrite can apply says so.'
]

{ #category : 'private - template' }
MCPToolRunCritiques >> filtersRequest: request [
	"Rules choose what is run, not which hits are kept."

	^ false
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
	anchor ifNotNil: [ self addIntervalFromAnchor: anchor of: target toHitData: data ].
	^ data
]

{ #category : 'private - results' }
MCPToolRunCritiques >> hitTextOn: stream for: hit [
	"A method, with the line of its stored source where the hit starts and the code there; a class by its name; a package as package Eval-Shapes; anything else as it prints."

	stream
		nextPut: Character lf;
		nextPutAll: '  '.
	hit at: #method ifPresent: [ :method |
			stream nextPutAll: method.
			hit at: #line ifPresent: [ :line |
					stream
						nextPutAll: ' line ';
						print: line ].
			hit at: #code ifPresent: [ :code |
					stream
						nextPutAll: ': ';
						nextPutAll: code ].
			^ self ].
	hit at: #class ifPresent: [ :className | ^ stream nextPutAll: className ].
	hit at: #package ifPresent: [ :packageName |
			^ stream
				  nextPutAll: 'package ';
				  nextPutAll: packageName ].
	stream nextPutAll: (hit at: #entity ifAbsent: [ '' ])
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

{ #category : 'private - scope' }
MCPToolRunCritiques >> methodScopeQueryFromRequest: request [

	^ MCPCompiledMethodScopeQuery new
		  packageNames: (self searchScopeStringCollectionNamed: 'packages' fromRequest: request);
		  classNames: (self searchScopeStringCollectionNamed: 'classes' fromRequest: request);
		  hierarchyClassNames: (self searchScopeStringCollectionNamed: 'hierarchyOf' fromRequest: request);
		  subclassClassNames: (self searchScopeStringCollectionNamed: 'subclassesOf' fromRequest: request);
		  parentClassNames: (self searchScopeStringCollectionNamed: 'superclassesOf' fromRequest: request);
		  side: (self searchScopeSideFromRequest: request);
		  yourself
]

{ #category : 'private - results' }
MCPToolRunCritiques >> nextPageTextForOffset: anOffset [
	"Where the next page starts; critique_run takes no filter to narrow its hits with."

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Next page: offset ';
				  print: anOffset;
				  nextPut: $. ]
]

{ #category : 'private - scope' }
MCPToolRunCritiques >> packagesIn: scopeQuery [

	scopeQuery usesImplicitImageScope ifTrue: [ ^ self packageOrganizer packages asArray ].
	scopeQuery packageNames ifEmpty: [ ^ #(  ) ].
	^ scopeQuery packageNames
		  collect: [ :eachName | scopeQuery packageNamed: eachName inScope: 'scope.packages' ]
		  thenSelect: [ :eachPackage | eachPackage isNotNil ]
]

{ #category : 'private - template' }
MCPToolRunCritiques >> queryEntriesForRequest: request scopeQuery: scopeQuery [
	"MCP's own rules answer only an agent, which this is. Collection stops one hit past the page, so whether another page follows is known without running every rule. Rules the caller names run though the image has them off."

	| entries manifestRules maximum namedByCaller ruleClasses runsOn |
	ruleClasses := self ruleClassesFromRequest: request.
	namedByCaller := (request uniqueStringCollectionArgumentNamed: 'ruleClasses') isNotEmpty.
	manifestRules := IdentityDictionary new.
	runsOn := [ :rule :entity |
		          self
			          rule: rule
			          runsOn: entity
			          namedByCaller: namedByCaller
			          manifestRules: manifestRules ].
	maximum := (request integerArgumentNamed: 'offset') + self defaultPageLimit + 1.
	entries := OrderedCollection new.
	MCPAgentCritiquing value: true during: [
			ruleClasses do: [ :eachRuleClass |
					self
						addCritiqueEntriesForRuleClass: eachRuleClass
						in: scopeQuery
						runsOn: runsOn
						to: entries
						maximum: maximum ] ].
	^ entries asArray
]

{ #category : 'private - template' }
MCPToolRunCritiques >> queryResultDataForPage: page [

	| data |
	data := Dictionary new.
	data at: #rules put: (self ruleGroupsFromEntries: page entries).
	page nextOffset ifNotNil: [ :offset | data at: #nextOffset put: offset ].
	^ data
]

{ #category : 'private - results' }
MCPToolRunCritiques >> readingNoteForPage: page [
	"A hit in a method names a line of the method as stored, which is not the source a caller compiled."

	^ (page entries anySatisfy: [ :entry | (entry at: #hit) includesKey: #line ]) ifTrue: [
		  'Line numbers count each method as stored; method_get shows it.' ]
]

{ #category : 'private - rules' }
MCPToolRunCritiques >> rule: aRule runsOn: anEntity namedByCaller: aBoolean manifestRules: manifestRulesByPackage [
	"Whether a person's configuration lets aRule run on anEntity: the caller named it, the image has it on or the package's manifest forces it, and the manifest neither marks it a false positive there nor rejects it. Looking a package's manifest up walks its classes, so each package's is looked up once per call, in manifestRulesByPackage."

	| manifestRules |
	manifestRules := manifestRulesByPackage at: anEntity package ifAbsentPut: [ MCPManifestRules for: anEntity ].
	(manifestRules excludes: aRule on: anEntity) ifTrue: [ ^ false ].
	^ aBoolean or: [ aRule class enabled or: [ manifestRules forces: aRule class ] ]
]

{ #category : 'private - rules' }
MCPToolRunCritiques >> ruleClassNamed: aRuleClassName [
	"A rule named in ruleClasses: a misspelt one suggests the rules critique_run runs, and a class that runs no critique is refused as not a rule."

	^ MCPImageLookup classNamed: aRuleClassName role: #critiqueRule details: #(  )
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
		  description: 'Renraku rule class names to run, even if the image has them off. Omitted or empty, the rules Renraku would run.'
		  itemDescription: 'Rule class name.'
]

{ #category : 'private - results' }
MCPToolRunCritiques >> ruleGroupFromEntry: entry [

	| group |
	group := Dictionary new.
	group at: #ruleClass put: (entry at: #ruleClass).
	group at: #title put: (entry at: #title).
	entry at: #severity ifPresent: [ :severity | severity isEmpty ifFalse: [ group at: #severity put: severity ] ].
	entry at: #fixable ifPresent: [ :fixable | group at: #fixable put: fixable ].
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

{ #category : 'private - results' }
MCPToolRunCritiques >> ruleTextOn: stream for: group [
	"MCPStringConcatenationRule: Build strings with a stream. method_rewrite can apply it. Every rule is named by its class, since ruleClasses is how a caller picks rules, and an error says so."

	| title |
	title := group at: #title.
	stream
		nextPut: Character lf;
		nextPutAll: (group at: #ruleClass).
	(group at: #severity ifAbsent: [ nil ]) = 'error' ifTrue: [ stream nextPutAll: ' (error)' ].
	stream nextPutAll: ': '.
	(group at: #fixable ifAbsent: [ false ]) ifFalse: [ ^ stream nextPutAll: title ].
	stream
		nextPutAll: ((title endsWith: '.')
				 ifTrue: [ title allButLast ]
				 ifFalse: [ title ]);
		nextPutAll: '. method_rewrite can apply it.'
]

{ #category : 'private - template' }
MCPToolRunCritiques >> scopeQueryFromRequest: request [

	^ self methodScopeQueryFromRequest: request
]

{ #category : 'private - template' }
MCPToolRunCritiques >> searchActivityText [

	^ 'run critiques'
]

{ #category : 'private - template' }
MCPToolRunCritiques >> searchedNoun [

	^ 'critique hit'
]

{ #category : 'private - scope' }
MCPToolRunCritiques >> sortedBehaviorsIn: scopeQuery do: aBlock [

	| behaviors |
	behaviors := scopeQuery behaviors asArray.
	behaviors sort: [ :left :right | (self targetNameForBehavior: left) <= (self targetNameForBehavior: right) ].
	behaviors do: aBlock
]

{ #category : 'private - scope' }
MCPToolRunCritiques >> sortedMethodsIn: scopeQuery do: aBlock [

	| methods |
	methods := scopeQuery methods asArray.
	methods sort: [ :left :right | (self methodReferenceForCompiledMethod: left) <= (self methodReferenceForCompiledMethod: right) ].
	methods do: aBlock
]

{ #category : 'private - scope' }
MCPToolRunCritiques >> sortedPackagesIn: scopeQuery do: aBlock [

	| packages |
	packages := self packagesIn: scopeQuery.
	packages sort: [ :left :right | left name <= right name ].
	packages do: aBlock
]

{ #category : 'private - entries' }
MCPToolRunCritiques >> sourceAnchorForCritique: critique [

	(critique class canUnderstand: #sourceAnchor) ifFalse: [ ^ nil ].
	^ critique sourceAnchor
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
