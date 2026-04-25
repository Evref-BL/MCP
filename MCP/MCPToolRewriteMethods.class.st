"
Mass-edits methods by applying Smalltalk AST rewrite rules in a method scope.

It is a method-scoped command tool, not a query tool: preview mode calculates ordered rewrite changes and a changeSetHash, while apply mode mutates the image only after expectedChangeSetHash confirmation.
"
Class {
	#name : 'MCPToolRewriteMethods',
	#superclass : 'MCPTool',
	#traits : 'TMCPMethodTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'private - execution' }
MCPToolRewriteMethods >> commandForRequest: rewriteRequest [

	^ MCPRewriteMethodsCommand tool: self request: rewriteRequest
]

{ #category : 'defaults' }
MCPToolRewriteMethods >> defaultDescription [

	^ 'Preview or apply Smalltalk AST rewrite rules to methods in a scope. Patterns use RB AST pattern syntax, not regex; pattern variables such as `@node` match AST nodes. By default apply=false returns a preview with changeSetHash and does not mutate the image. apply=true performs the rewrite and requires expectedChangeSetHash from a preview. Applying to the whole image also requires force=true. Scope properties are unioned and match find-methods semantics.'
]

{ #category : 'defaults' }
MCPToolRewriteMethods >> defaultIcons [

	^ { (self pngCompositeBaseIconNamed: #page badgeIconNamed: #edit) }
]

{ #category : 'defaults' }
MCPToolRewriteMethods >> defaultInputSchema [

	| schema |
	schema := MCPStructureInputSchema new
		          type: 'object';
		          properties: self rewriteInputProperties;
		          required: #( 'rules' );
		          additionalProperties: false;
		          yourself.
	schema allOf:
		{ self expectedChangeSetHashRequiredWhenApplyingSchema }.
	^ schema
]

{ #category : 'defaults' }
MCPToolRewriteMethods >> defaultName [

	^ 'rewrite-methods'
]

{ #category : 'defaults' }
MCPToolRewriteMethods >> defaultOutputSchema [

	^ self
		  standardOutputSchemaForDataProperties: self rewriteDataProperties
		  required: #( 'apply' 'changeCount' 'appliedCount' 'changeSetHash'
			     'scope' 'changes' )
]

{ #category : 'defaults' }
MCPToolRewriteMethods >> defaultTitle [

	^ 'Rewrite Methods'
]

{ #category : 'error handling' }
MCPToolRewriteMethods >> errorResultForRewriteError: anError request: rewriteRequest rawRequest: rawRequest [

	(anError isKindOf: MCPCommandError) ifTrue: [
		^ self
			  errorResultText: anError messageText
			  details: anError structuredDetails ].
	^ self errorResultFor: anError
]

{ #category : 'executing' }
MCPToolRewriteMethods >> executeWithRequest: request [

	^ self
		  executeParsedRequestFrom: request
		  do: [ :rewriteRequest |
		  (self commandForRequest: rewriteRequest) execute ]
		  onError: [ :error :rewriteRequest |
			  self
				  errorResultForRewriteError: error
				  request: rewriteRequest
				  rawRequest: request ]
]

{ #category : 'private - schema' }
MCPToolRewriteMethods >> expectedChangeSetHashRequiredWhenApplyingSchema [

	| conditionSchema expectedSchema |
	conditionSchema := MCPStructureInputSchema new
		                   type: 'object';
		                   properties: { (MCPStructureProperties new
				                    name: 'apply';
				                    type: 'boolean';
				                    const: true;
				                    yourself) };
		                   required: #( 'apply' );
		                   additionalProperties: true;
		                   yourself.
	expectedSchema := MCPStructureInputSchema new
		                  type: 'object';
		                  required: #( 'expectedChangeSetHash' );
		                  additionalProperties: true;
		                  yourself.
	^ MCPStructureInputSchema new
		  additionalProperties: true;
		  schemaKeyword: #if put: conditionSchema;
		  schemaKeyword: #then put: expectedSchema;
		  yourself
]

{ #category : 'private - execution' }
MCPToolRewriteMethods >> parsedRequestFromToolRequest: request [

	^ MCPMethodRewriteRequest fromRequest: request tool: self
]

{ #category : 'private - schema' }
MCPToolRewriteMethods >> rewriteChangeSchema [

	^ MCPStructureProperties new
		  type: 'object';
		  description: 'One method source rewrite change.';
		  properties: {
				  (self
					   schemaPropertyNamed: 'className'
					   type: 'string'
					   description: 'The base class that defines the method.').
				  (self
					   booleanSchemaPropertyNamed: 'classSide'
					   description: 'Whether the method is on the class side.').
				  (self
					   schemaPropertyNamed: 'selector'
					   type: 'string'
					   description: 'The method selector.').
				  (self
					   schemaPropertyNamed: 'packageName'
					   type: 'string'
					   description: 'The package that owns the method.').
				  (self
					   schemaPropertyNamed: 'protocol'
					   type: 'string'
					   description: 'The method protocol/category.').
				  (self
					   schemaPropertyNamed: 'oldSource'
					   type: 'string'
					   description: 'The method source before applying the rewrite.').
				  (self
					   schemaPropertyNamed: 'newSource'
					   type: 'string'
					   description: 'The method source produced by the rewrite.') };
		  required:
			  #( 'className' 'classSide' 'selector' 'packageName' 'protocol' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - schema' }
MCPToolRewriteMethods >> rewriteChangesSchemaProperty [

	^ (self
		   schemaPropertyNamed: 'changes'
		   type: 'array'
		   description:
			   'The method rewrite changes calculated for the requested scope.')
		  items: self rewriteChangeSchema;
		  yourself
]

{ #category : 'private - schema' }
MCPToolRewriteMethods >> rewriteDataProperties [

	^ {
		  (self
			   booleanSchemaPropertyNamed: 'apply'
			   description:
			   'Whether the request applied changes or only previewed them.').
		  (self
			   integerSchemaPropertyNamed: 'changeCount'
			   description: 'The number of rewrite changes calculated.').
		  (self
			   integerSchemaPropertyNamed: 'appliedCount'
			   description:
			   'The number of rewrite changes applied to the image.').
		  (self
			   integerSchemaPropertyNamed: 'changeSetHash'
			   description: 'Hash of the calculated rewrite change set.').
		  self rewriteScopeSchemaProperty.
		  self rewriteChangesSchemaProperty }
]

{ #category : 'private - schema' }
MCPToolRewriteMethods >> rewriteInputProperties [

	^ {
		  self rewriteRulesSchemaProperty.
		  (self
			   booleanSchemaPropertyNamed: 'apply'
			   description:
			   'Whether to apply the rewrite changes. false previews changes without mutation; true mutates matching methods after expectedChangeSetHash validation.'
			   default: false).
		  (self
			   integerSchemaPropertyNamed: 'expectedChangeSetHash'
			   description:
			   'Required when apply=true. Use the changeSetHash returned by a preview of the same rewrite request.').
		  (self
			   booleanSchemaPropertyNamed: 'force'
			   description:
			   'Allows apply=true with implicit whole-image scope. Prefer an explicit method scope for rewrite application.'
			   default: false).
		  (self
			   booleanSchemaPropertyNamed: 'includeSources'
			   description:
			   'Whether each change includes oldSource and newSource in the output.'
			   default: true) } , self methodQueryScopeInputProperties
]

{ #category : 'private - schema' }
MCPToolRewriteMethods >> rewriteRuleSchema [

	^ MCPStructureProperties new
		  type: 'object';
		  description: 'One method rewrite rule.';
		  properties: {
				  (self
					   schemaPropertyNamed: 'name'
					   type: 'string'
					   description: 'Optional rule name used for diagnostics.').
				  ((self
					    schemaPropertyNamed: 'lhs'
					    type: 'string'
					    description: 'The left-hand pattern to find.')
					   minLength: 1;
					   yourself).
				  ((self
					    schemaPropertyNamed: 'rhs'
					    type: 'string'
					    description: 'The replacement pattern.')
					   minLength: 1;
					   yourself).
				  (self
					   booleanSchemaPropertyNamed: 'isForMethod'
					   description:
					   'Whether lhs and rhs are whole-method patterns instead of expression patterns.'
					   default: false) };
		  required: #( 'lhs' 'rhs' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - schema' }
MCPToolRewriteMethods >> rewriteRulesSchemaProperty [

	^ (self
		   schemaPropertyNamed: 'rules'
		   type: 'array'
		   description:
			   'One or more method rewrite rules applied with the NewTools rewriter backend.')
		  minItems: 1;
		  items: self rewriteRuleSchema;
		  yourself
]

{ #category : 'private - schema' }
MCPToolRewriteMethods >> rewriteScopeSchemaProperty [

	| property |
	property := self
		            schemaPropertyNamed: 'scope'
		            type: 'object'
		            description:
		            'The normalized method scope used to calculate rewrite changes.'.
	property additionalProperties: true.
	^ property
]

{ #category : 'testing' }
MCPToolRewriteMethods >> shouldSaveImageAfterSuccessfulExecutionForResult: aResult [

	| data structuredContent |
	aResult isError ifTrue: [ ^ false ].
	structuredContent := aResult structuredContent.
	structuredContent ifNil: [ ^ false ].
	data := structuredContent at: #data ifAbsent: [ ^ false ].
	^ (data at: #apply ifAbsent: [ false ]) = true and: [
		  (data at: #appliedCount ifAbsent: [ 0 ]) > 0 ]
]
