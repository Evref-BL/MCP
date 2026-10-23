"
Mass-updates methods by applying Smalltalk AST rewrite rules in a method scope.

It is a method-scoped command tool, not a search tool: preview mode calculates ordered rewrite changes and a changeSetHash, while apply mode mutates the image only after expectedChangeSetHash confirmation.
"
Class {
	#name : 'MCPToolRewriteMethods',
	#superclass : 'MCPTool',
	#traits : 'TMCPMethodTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
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
		  required: #( 'rules' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - execution' }
MCPToolRewriteMethods >> commandForRequest: rewriteRequest [

	^ MCPRewriteMethodsCommand tool: self request: rewriteRequest
]

{ #category : 'metadata' }
MCPToolRewriteMethods >> description [

	^ 'Preview or apply Smalltalk AST pattern rewrites within scoped methods. Smalltalk AST pattern syntax, not regex.'
]

{ #category : 'error handling' }
MCPToolRewriteMethods >> errorResultForRewriteError: anError request: rewriteRequest rawRequest: rawRequest [

	^ anError
		  mcpCommandErrorDo: [ :commandError | self errorResultText: commandError messageText details: commandError structuredDetails ]
		  otherwise: [ :toolError | self errorResultFor: toolError ]
]

{ #category : 'executing' }
MCPToolRewriteMethods >> executeWithRequest: request [

	^ self
		  executeParsedRequestFrom: request
		  do: [ :rewriteRequest | (self commandForRequest: rewriteRequest) execute ]
		  onError: [ :error :rewriteRequest | self errorResultForRewriteError: error request: rewriteRequest rawRequest: request ]
]

{ #category : 'private - results' }
MCPToolRewriteMethods >> keysStatedInSummary [
	"The summary already reads 'Previewed 3 method rewrite changes.'"

	^ #( apply appliedCount changeCount )
]

{ #category : 'private - execution' }
MCPToolRewriteMethods >> parsedRequestFromToolRequest: request [

	^ MCPMethodRewriteRequest fromRequest: request tool: self
]

{ #category : 'private - schema' }
MCPToolRewriteMethods >> rewriteInputProperties [

	^ {
		  self rewriteRulesSchemaProperty.
		  (self booleanSchemaPropertyNamed: 'apply' description: 'Apply changes instead of preview.' default: false).
		  (self integerSchemaPropertyNamed: 'expectedChangeSetHash' description: 'Required when apply=true.').
		  (self booleanSchemaPropertyNamed: 'force' description: 'Allow whole-image apply scope.' default: false).
		  (self
			   booleanSchemaPropertyNamed: 'includeSource'
			   description: 'Include source code. Use only for small result sets.'
			   default: false) } , self methodQueryScopeInputProperties
]

{ #category : 'private - schema' }
MCPToolRewriteMethods >> rewriteRuleSchema [

	^ MCPStructureProperties new
		  type: 'object';
		  description: 'Rewrite rule.';
		  properties: {
				  (self schemaPropertyNamed: 'name' type: 'string' description: 'Diagnostic name.').
				  ((self schemaPropertyNamed: 'lhs' type: 'string' description: 'Pattern to match.')
					   minLength: 1;
					   yourself).
				  ((self schemaPropertyNamed: 'rhs' type: 'string' description: 'Replacement pattern.')
					   minLength: 1;
					   yourself).
				  (self booleanSchemaPropertyNamed: 'isForMethod' description: 'Match whole methods.' default: false) };
		  required: #( 'lhs' 'rhs' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - schema' }
MCPToolRewriteMethods >> rewriteRulesSchemaProperty [

	^ (self schemaPropertyNamed: 'rules' type: 'array' description: 'Rewrite rules.')
		  minItems: 1;
		  items: self rewriteRuleSchema;
		  yourself
]

{ #category : 'metadata' }
MCPToolRewriteMethods >> title [

	^ 'Rewrite Methods'
]

{ #category : 'validating' }
MCPToolRewriteMethods >> validateRequest: request [

	((request booleanArgumentNamed: 'apply' default: false) and: [ (request hasArgumentNamed: 'expectedChangeSetHash') not ])
		ifTrue: [ MCPInvalidToolInput signalMissingRequiredArgumentNamed: 'expectedChangeSetHash' forTool: self ]
]
