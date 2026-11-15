"
Mass-updates methods by applying Smalltalk AST rewrite rules in a method scope.

It is a method-scoped command tool, not a search tool: it previews the ordered rewrite changes, and applies them when asked. A scope is required, so rewriting the whole image is not something a caller can ask for by leaving an argument out.
"
Class {
	#name : 'MCPToolRewriteMethods',
	#superclass : 'MCPTool',
	#traits : 'TMCPMethodTool',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolRewriteMethods class >> groupName [

	^ self methodsGroupName
]

{ #category : 'metadata' }
MCPToolRewriteMethods class >> toolName [

	^ 'method_rewrite'
]

{ #category : 'metadata' }
MCPToolRewriteMethods >> buildInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: self rewriteInputProperties;
		  required: #( 'scope' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'metadata' }
MCPToolRewriteMethods >> description [

	^ 'Preview or apply Smalltalk AST pattern rewrites within scoped methods. Write the patterns, or name rewrite rule classes whose patterns to apply. Smalltalk AST pattern syntax, not regex.'
]

{ #category : 'error handling' }
MCPToolRewriteMethods >> errorResultForRewriteError: anError [

	^ anError
		  mcpCommandErrorDo: [ :commandError | self errorResultText: commandError messageText details: commandError structuredDetails ]
		  otherwise: [ :toolError | self errorResultFor: toolError ]
]

{ #category : 'executing' }
MCPToolRewriteMethods >> executeWithRequest: request [

	^ self
		  executeParsedRequestFrom: request
		  do: [ :arguments | self rewriteWith: arguments ]
		  onError: [ :error :arguments | self errorResultForRewriteError: error ]
]

{ #category : 'private - results' }
MCPToolRewriteMethods >> keysStatedInSummary [
	"The summary already reads 'Previewed 3 method rewrite changes in package Eval-Shapes.'"

	^ #( apply appliedCount changeCount scope )
]

{ #category : 'private - results' }
MCPToolRewriteMethods >> methodReferencesForChanges: changes [
	"Each method the changes would rewrite, named once, in order."

	^ (changes collect: [ :each | self methodReferenceForBehavior: each changeClass selector: each selector ] as: Set) asArray sort
]

{ #category : 'private - schema' }
MCPToolRewriteMethods >> rewriteInputProperties [
	"Unlike the searching tools, this one requires a scope: rewriting whatever the whole image happens to match is never what a caller means."

	^ {
		  self rewriteRulesSchemaProperty.
		  self rewriteRuleClassesSchemaProperty.
		  (self booleanSchemaPropertyNamed: 'confirm' description: 'False previews; true performs.' default: false).
		  (self methodSearchScopeSchemaProperty
			   description:
				   'What to rewrite. Give several entries and everything any of them selects is covered. Required: there is no rewriting the whole image.';
			   yourself) }
]

{ #category : 'private - schema' }
MCPToolRewriteMethods >> rewriteRuleClassesSchemaProperty [

	^ MCPStructureProperties new
		  name: 'ruleClasses';
		  type: 'array';
		  description:
			  'Rewrite rules to apply, as critique_run names them. Any subclass of ReNodeRewriteRule, Pharo''s own included, and one that builds its replacement instead of writing it as a pattern just as well.';
		  items: (MCPStructureProperties new
				   type: 'string';
				   description: 'One rule class name.';
				   yourself);
		  yourself
]

{ #category : 'private - schema' }
MCPToolRewriteMethods >> rewriteRuleSchema [

	^ MCPStructureProperties new
		  type: 'object';
		  description: 'Rewrite rule.';
		  properties: {
				  (self schemaPropertyNamed: 'name' type: 'string' description: 'Name for this rule in the results.').
				  ((self
					    schemaPropertyNamed: 'match'
					    type: 'string'
					    description: 'Pattern the code must match. Metavariables start with a backquote, as in `@receiver.')
					   minLength: 1;
					   yourself).
				  ((self
					    schemaPropertyNamed: 'replacement'
					    type: 'string'
					    description: 'Pattern the matched code becomes. Reuse the metavariable names from match.')
					   minLength: 1;
					   yourself).
				  (self
					   booleanSchemaPropertyNamed: 'isForMethod'
					   description: 'Match the whole method rather than an expression inside it.'
					   default: false) };
		  required: #( 'match' 'replacement' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - arguments' }
MCPToolRewriteMethods >> rewriteRulesFrom: request [
	"The patterns the call wrote, then the rule classes it named, numbered in that order."

	| ruleClassNames ruleObjects rules |
	ruleObjects := request objectCollectionArgumentNamed: 'rules'.
	ruleClassNames := request stringCollectionArgumentNamed: 'ruleClasses'.
	(ruleObjects isEmpty and: [ ruleClassNames isEmpty ]) ifTrue: [
			MCPCommandError
				signalErrorCode: #RewriteRulesRequired
				message: 'method_rewrite requires rules, ruleClasses, or both.'
				details: Dictionary new ].
	rules := OrderedCollection new.
	ruleObjects doWithIndex: [ :eachRule :index |
		rules add: (MCPMethodRewriteRuleSpec fromDictionary: eachRule request: request index: index) ].
	ruleClassNames do: [ :eachName | rules add: (MCPMethodRewriteNamedRuleSpec named: eachName index: rules size + 1) ].
	^ rules
]

{ #category : 'private - schema' }
MCPToolRewriteMethods >> rewriteRulesSchemaProperty [

	^ (self
		   schemaPropertyNamed: 'rules'
		   type: 'array'
		   description: 'The patterns to rewrite with, each a match pattern and what it becomes. They are applied in order.')
		  minItems: 1;
		  items: self rewriteRuleSchema;
		  yourself
]

{ #category : 'executing' }
MCPToolRewriteMethods >> rewriteWith: request [
	"Preview or apply the rules in the scope the call names. A trait's method is rewritten where the trait defines it, so the copies in scope are left out and named."

	| apply report rewrite rules scopeQuery |
	rules := self rewriteRulesFrom: request.
	apply := request booleanArgumentNamed: 'confirm'.
	scopeQuery := self methodScopeQueryFromRequest: request.
	scopeQuery requireCompleteScope.
	apply ifTrue: [ self validateExplicitApplyScope: scopeQuery rules: rules ].
	rewrite := MCPRewriteMethodsCommand rules: rules scopeQuery: scopeQuery apply: apply.
	report := rewrite execute.
	report skippedTraitMethods: (self methodReferencesForChanges: rewrite skippedTraitChanges).
	^ self successResultText: (self successSummaryForReport: report scopeQuery: scopeQuery) data: report asDictionary
]

{ #category : 'private - results' }
MCPToolRewriteMethods >> successSummaryForReport: report scopeQuery: aScopeQuery [
	"Previewed 2 method rewrite changes in package Eval-Shapes., naming where it looked as a search does. The scope must name only what exists, so its phrase holds every name."

	| count scopePhrase |
	count := report apply
		         ifTrue: [ report appliedCount ]
		         ifFalse: [ report changeCount ].
	scopePhrase := aScopeQuery scopePhrase.
	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: (report apply
						   ifTrue: [ 'Applied ' ]
						   ifFalse: [ 'Previewed ' ]);
				  print: count;
				  nextPutAll: ' method rewrite change'.
			  count = 1 ifFalse: [ stream nextPut: $s ].
			  scopePhrase ifNotNil: [
					  stream
						  nextPutAll: ' in ';
						  nextPutAll: scopePhrase ].
			  stream nextPut: $..
			  report skippedTraitMethods ifNotEmpty: [ :skipped |
					  skipped size = 1
						  ifTrue: [ stream nextPutAll: ' Skipped 1 method installed from a trait.' ]
						  ifFalse: [
								  stream
									  nextPutAll: ' Skipped ';
									  print: skipped size;
									  nextPutAll: ' methods installed from traits.' ] ] ]
]

{ #category : 'metadata' }
MCPToolRewriteMethods >> title [

	^ 'Rewrite Methods'
]

{ #category : 'private - validation' }
MCPToolRewriteMethods >> validateExplicitApplyScope: aScopeQuery rules: rules [
	"Rewriting every method in the image is not something a caller should be able to ask for by leaving an argument out. Naming the packages says it on purpose."

	| details |
	aScopeQuery usesImplicitImageScope ifFalse: [ ^ self ].
	details := Dictionary new.
	details at: #confirm put: true.
	details at: #scope put: aScopeQuery asDictionary.
	details at: #rules put: (rules collect: [ :each | each asDictionary ] as: Array).
	MCPCommandError
		signalErrorCode: #RewriteApplyRequiresExplicitScope
		message: 'Applying method_rewrite needs a scope. Name packages, classes, subclassesOf or superclassesOf.'
		details: details
]
