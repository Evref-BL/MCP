"
Command that calculates and optionally applies method rewrite changes.

It resolves the method scope, delegates pattern matching to the NewTools rewrite backend, enforces apply guardrails, and returns an MCPMethodRewriteReport.
"
Class {
	#name : 'MCPRewriteMethodsCommand',
	#superclass : 'Object',
	#instVars : [
		'tool',
		'request'
	],
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPRewriteMethodsCommand class >> tool: aTool request: aRequest [

	^ self new initializeTool: aTool request: aRequest
]

{ #category : 'private - results' }
MCPRewriteMethodsCommand >> changeInfosForChanges: changes [

	^ changes
		  collect: [ :each |
			  MCPMethodRewriteChangeInfo
				  fromChange: each
				  includeSources: self request includeSources ]
		  as: Array
]

{ #category : 'private - hashing' }
MCPRewriteMethodsCommand >> changeSetHashForChanges: changes [

	| hash |
	hash := changes
		        inject: (self stableHashForString: self class name asString)
		        into: [ :currentHash :change |
			        (currentHash bitXor: (self hashForChange: change))
				        hashMultiply ].
	^ hash abs
]

{ #category : 'private - rewriting' }
MCPRewriteMethodsCommand >> classNameForChange: aChange [

	| behavior |
	behavior := aChange changeClass.
	^ behavior isMeta
		  ifTrue: [ behavior instanceSide name asString ]
		  ifFalse: [ behavior name asString ]
]

{ #category : 'executing' }
MCPRewriteMethodsCommand >> execute [

	| appliedCount changeInfos changes changeSetHash report |
	self request apply ifTrue: [ self validateExplicitApplyScope ].
	changes := self sortedChanges: self rewriteChanges.
	changeSetHash := self changeSetHashForChanges: changes.
	changeInfos := self changeInfosForChanges: changes.
	appliedCount := 0.
	self request apply ifTrue: [
		self validateExpectedChangeSetHash: changeSetHash.
		StRewriterAbstractApplier applyTransformationChanges: changes.
		appliedCount := changes size ].
	report := MCPMethodRewriteReport
		          request: self request
		          changeInfos: changeInfos
		          appliedCount: appliedCount
		          changeSetHash: changeSetHash.
	^ self tool
		  successResultText: (self successSummaryForReport: report)
		  data: report asDictionary
]

{ #category : 'private - hashing' }
MCPRewriteMethodsCommand >> hashForChange: aChange [

	| behavior className oldSource valueHashes |
	behavior := aChange changeClass.
	className := behavior isMeta
		             ifTrue: [ behavior instanceSide name asString ]
		             ifFalse: [ behavior name asString ].
	oldSource := (behavior
		              compiledMethodAt: aChange selector
		              ifAbsent: [ nil ])
		             ifNil: [ '' ]
		             ifNotNil: [ :method | method sourceCode ifNil: [ '' ] ].
	valueHashes := {
		               (self stableHashForString: className).
		               (self stableHashForValue: behavior isMeta).
		               (self stableHashForString: aChange selector asString).
		               (self stableHashForSource: oldSource).
		               (self stableHashForSource:
			                (aChange source ifNil: [ '' ])) }.
	^ valueHashes
		  inject: (self stableHashForString: self class name asString)
		  into: [ :hash :valueHash | (hash bitXor: valueHash) hashMultiply ]
]

{ #category : 'initialization' }
MCPRewriteMethodsCommand >> initializeTool: aTool request: aRequest [

	tool := aTool.
	request := aRequest.
	^ self
]

{ #category : 'accessing' }
MCPRewriteMethodsCommand >> request [

	^ request
]

{ #category : 'private - rewriting' }
MCPRewriteMethodsCommand >> rewriteChanges [

	| methods transformationRule |
	methods := self request scopeQuery methods.
	methods ifEmpty: [ ^ #(  ) ].
	transformationRule := RBTransformationRule new
		                      rewriteRule: self rewriteRule;
		                      yourself.
	methods do: [ :eachMethod |
		transformationRule checkMethod: eachMethod ].
	^ transformationRule changes asArray
]

{ #category : 'private - rewriting' }
MCPRewriteMethodsCommand >> rewriteRule [

	self validateRewriteRules.
	^ StRewriterRBApplier rewriter: self ruleHolders
]

{ #category : 'private - rewriting' }
MCPRewriteMethodsCommand >> ruleHolders [

	^ self request rules
		  collect: [ :each | each asStRewriterRuleHolder ]
		  as: Array
]

{ #category : 'private - rewriting' }
MCPRewriteMethodsCommand >> sortedChanges: changes [

	^ (changes asSortedCollection: [ :left :right |
		   self sortsChange: left before: right ]) asArray
]

{ #category : 'private - rewriting' }
MCPRewriteMethodsCommand >> sortsChange: leftChange before: rightChange [

	| leftClassName leftClassSide rightClassName rightClassSide |
	leftClassName := self classNameForChange: leftChange.
	rightClassName := self classNameForChange: rightChange.
	leftClassName = rightClassName ifFalse: [
		^ leftClassName < rightClassName ].
	leftClassSide := leftChange changeClass isMeta.
	rightClassSide := rightChange changeClass isMeta.
	leftClassSide = rightClassSide ifFalse: [
		^ leftClassSide not and: [ rightClassSide ] ].
	^ leftChange selector asString < rightChange selector asString
]

{ #category : 'private - hashing' }
MCPRewriteMethodsCommand >> stableHashForSource: aString [

	| hash |
	hash := 5381.
	aString do: [ :character |
		character isSeparator ifFalse: [
			hash := (hash bitXor: character asciiValue) hashMultiply ] ].
	^ hash abs
]

{ #category : 'private - hashing' }
MCPRewriteMethodsCommand >> stableHashForString: aString [

	| hash |
	hash := 5381.
	aString do: [ :character |
		hash := (hash bitXor: character asciiValue) hashMultiply ].
	^ hash abs
]

{ #category : 'private - hashing' }
MCPRewriteMethodsCommand >> stableHashForValue: anObject [

	anObject ifNil: [ ^ 0 ].
	anObject == true ifTrue: [ ^ 2 ].
	anObject == false ifTrue: [ ^ 1 ].
	anObject isInteger ifTrue: [ ^ anObject abs ].
	^ self stableHashForString: anObject asString
]

{ #category : 'private - results' }
MCPRewriteMethodsCommand >> successSummaryForReport: report [

	report apply ifTrue: [
		^ 'Applied ' , report appliedCount asString
		  , ' method rewrite change(s).' ].
	^ 'Previewed ' , report changeCount asString
	  , ' method rewrite change(s).'
]

{ #category : 'accessing' }
MCPRewriteMethodsCommand >> tool [

	^ tool
]

{ #category : 'private - validating' }
MCPRewriteMethodsCommand >> validateExpectedChangeSetHash: changeSetHashInteger [

	self request expectedChangeSetHash ifNil: [
		MCPCommandError
			signalErrorCode: #RewriteExpectedChangeSetHashRequired
			message:
			'Applying rewrite-methods requires expectedChangeSetHash from a preview.'
			details: self request requestedContext ].
	self request expectedChangeSetHash = changeSetHashInteger ifFalse: [
		MCPCommandError
			signalErrorCode: #RewriteChangeSetHashMismatch
			message:
			'Rewrite change set hash does not match expectedChangeSetHash.'
			details: (self request requestedContext
					 at: #actualChangeSetHash put: changeSetHashInteger;
					 yourself) ]
]

{ #category : 'private - validating' }
MCPRewriteMethodsCommand >> validateExplicitApplyScope [

	(self request scopeQuery usesImplicitImageScope and: [
		 self request force not ]) ifTrue: [
		MCPCommandError
			signalErrorCode: #RewriteApplyRequiresExplicitScope
			message:
			'Applying rewrite-methods to the whole image requires force=true. Prefer packageNames, classNames, hierarchyClassNames, subclassClassNames, or parentClassNames.'
			details: self request requestedContext ]
]

{ #category : 'private - validating' }
MCPRewriteMethodsCommand >> validateRewriteRules [

	self request rules do: [ :each | each validatePatterns ]
]
