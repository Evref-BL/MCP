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

{ #category : 'executing' }
MCPRewriteMethodsCommand >> execute [

	| appliedCount changeInfos changes report |
	self request apply ifTrue: [ self validateExplicitApplyScope ].
	changes := self rewriteChanges.
	changeInfos := self changeInfosForChanges: changes.
	appliedCount := 0.
	self request apply ifTrue: [
		self validateExpectedChangeCountForChanges: changes.
		StRewriterAbstractApplier applyTransformationChanges: changes.
		appliedCount := changes size ].
	report := MCPMethodRewriteReport
		          request: self request
		          changeInfos: changeInfos
		          appliedCount: appliedCount.
	^ self tool
		  successResultText: (self successSummaryForReport: report)
		  data: report asDictionary
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

	^ StRewriterRBApplier rewriter: self ruleHolders
]

{ #category : 'private - rewriting' }
MCPRewriteMethodsCommand >> ruleHolders [

	^ self request rules
		  collect: [ :each | each asStRewriterRuleHolder ]
		  as: Array
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
MCPRewriteMethodsCommand >> validateExpectedChangeCountForChanges: changes [

	self request expectedChangeCount ifNil: [
		MCPCommandError
			signalErrorCode: #RewriteExpectedChangeCountRequired
			message:
			'Applying rewrite-methods requires expectedChangeCount to confirm the previewed change count.'
			details: self request requestedContext ].
	self request expectedChangeCount = changes size ifFalse: [
		MCPCommandError
			signalErrorCode: #RewriteChangeCountMismatch
			message: 'Rewrite change count does not match expectedChangeCount.'
			details: (self request requestedContext
					 at: #actualChangeCount put: changes size;
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
