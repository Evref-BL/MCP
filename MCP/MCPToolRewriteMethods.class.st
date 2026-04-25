"
Mass-edits methods by applying Smalltalk AST rewrite pattern rules in a method scope. The default mode previews changes; apply mode mutates the image only after explicit change-count confirmation.
"
Class {
	#name : 'MCPToolRewriteMethods',
	#superclass : 'MCPToolQuery',
	#traits : 'TMCPMethodTool',
	#classTraits : 'TMCPMethodTool classTrait',
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

	^ 'Preview or apply Smalltalk AST rewrite pattern rules to methods in a scope. By default apply=false returns a preview without mutating the image. apply=true performs the rewrite and requires expectedChangeCount; applying to the whole image also requires force=true. Scope properties are unioned and match find-methods semantics.'
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
	schema allOf: { self expectedChangeCountRequiredWhenApplyingSchema }.
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
		  required:
		  #( 'apply' 'changeCount' 'appliedCount' 'scope' 'changes' )
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
MCPToolRewriteMethods >> expectedChangeCountRequiredWhenApplyingSchema [

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
		                  required: #( 'expectedChangeCount' );
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
			   integerSchemaPropertyNamed: 'expectedChangeCount'
			   description:
			   'The expected change count supplied by apply requests.').
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
			   'Whether to apply the rewrite changes. false previews changes without mutation; true mutates matching methods after expectedChangeCount validation.'
			   default: false).
		  (self
			   integerSchemaPropertyNamed: 'expectedChangeCount'
			   description:
			   'Required when apply=true. The rewrite is applied only when the calculated change count exactly matches this value.').
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
		  description:
			  'A Smalltalk AST rewrite rule. Use RB pattern variables such as `@node in lhs and rhs patterns.';
		  properties: {
				  (self
					   schemaPropertyNamed: 'name'
					   type: 'string'
					   description: 'Optional rule name used for diagnostics.').
				  (self
					   schemaPropertyNamed: 'lhs'
					   type: 'string'
					   description: 'The left-hand Smalltalk AST pattern to find.').
				  (self
					   schemaPropertyNamed: 'rhs'
					   type: 'string'
					   description: 'The replacement Smalltalk AST pattern.').
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
			   'One or more Smalltalk AST rewrite pattern rules. Rules are applied with the NewTools rewriter backend.')
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
