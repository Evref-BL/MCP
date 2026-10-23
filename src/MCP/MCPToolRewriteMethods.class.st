"
Mass-updates methods by applying Smalltalk AST rewrite rules in a method scope.

It is a method-scoped command tool, not a search tool: it previews the ordered rewrite changes, and applies them when asked. A scope is required, so rewriting the whole image is not something a caller can ask for by leaving an argument out.
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
		  required: #( 'scope' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - execution' }
MCPToolRewriteMethods >> commandForRequest: rewriteRequest [

	^ MCPRewriteMethodsCommand tool: self request: rewriteRequest
]

{ #category : 'metadata' }
MCPToolRewriteMethods >> description [

	^ 'Preview or apply Smalltalk AST pattern rewrites within scoped methods. Write the patterns, or name rewrite rule classes whose patterns to apply. Smalltalk AST pattern syntax, not regex.'
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
		  self rewriteRuleClassesSchemaProperty.
		  (self booleanSchemaPropertyNamed: 'apply' description: 'Apply the changes instead of previewing them.' default: false) }
	  , self methodQueryScopeInputProperties
]

{ #category : 'private - schema' }
MCPToolRewriteMethods >> rewriteRuleClassesSchemaProperty [

	^ MCPStructureProperties new
		  name: 'ruleClasses';
		  type: 'array';
		  description:
			  'Rewrite rule classes whose patterns to apply, as critique_run names them. Any subclass of ReNodeRewriteRule, including Pharo''s own.';
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
				  (self schemaPropertyNamed: 'name' type: 'string' description: 'Diagnostic name.').
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
				  (self booleanSchemaPropertyNamed: 'isForMethod' description: 'Match whole methods.' default: false) };
		  required: #( 'match' 'replacement' );
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

