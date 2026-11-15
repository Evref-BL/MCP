"
Concrete method_equivalent_search tool. It searches for methods with ASTs equivalent to a referenced method through MCPToolMethodSearch.
"
Class {
	#name : 'MCPToolSearchEquivalentMethods',
	#superclass : 'MCPToolMethodSearch',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolSearchEquivalentMethods class >> toolName [

	^ 'method_equivalent_search'
]

{ #category : 'metadata' }
MCPToolSearchEquivalentMethods >> buildInputSchema [

	| properties |
	properties := self methodQueryScopeInputProperties , {
		              (self schemaPropertyNamed: 'class' type: 'string' description: 'The class that defines the reference method.').
		              (self schemaPropertyNamed: 'selector' type: 'string' description: 'The reference method selector.').
		              (self targetSideSchemaPropertyDescribedAs: 'Which side the reference method is on.').
		              self offsetInputProperty }.
	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: properties;
		  required: #( 'class' 'selector' );
		  yourself
]

{ #category : 'private - results' }
MCPToolSearchEquivalentMethods >> countTextForRequest: request page: page [
	"2 methods equivalent to EvalRect>>area."

	| referenceMethod |
	referenceMethod := self referenceMethodFromRequest: request.
	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: (super countTextForRequest: request page: page);
				  nextPutAll: ' equivalent to ';
				  nextPutAll: (self methodReferenceForBehavior: referenceMethod methodClass selector: referenceMethod selector) ]
]

{ #category : 'metadata' }
MCPToolSearchEquivalentMethods >> description [

	^ 'Search methods whose AST is equivalent to a referenced method.'
]

{ #category : 'private - request' }
MCPToolSearchEquivalentMethods >> methodReferenceSpecFromToolRequest: request [

	| className selector |
	className := request stringArgumentNamed: 'class'.
	className ifNil: [ ^ MCPInvalidToolInput signalMissingRequiredArgumentNamed: 'class' forTool: self ].
	selector := request stringArgumentNamed: 'selector'.
	selector ifNil: [ ^ MCPInvalidToolInput signalMissingRequiredArgumentNamed: 'selector' forTool: self ].
	^ MCPImageLookup
		  className: className
		  side: (request stringArgumentNamed: 'side')
		  do: [ :baseName :isClassSide :isSideGiven |
		  MCPMethodReferenceSpec className: baseName selector: selector classSide: isClassSide ]
]

{ #category : 'private - template' }
MCPToolSearchEquivalentMethods >> queryEntriesForRequest: request scopeQuery: scopeQuery [

	| referenceMethod |
	referenceMethod := self referenceMethodFromRequest: request.
	^ self methodEntriesFromMethods: (scopeQuery methods select: [ :eachMethod | eachMethod equivalentTo: referenceMethod ]) asArray
]

{ #category : 'private - request' }
MCPToolSearchEquivalentMethods >> referenceMethodFromRequest: request [
	"The method the others are compared with."

	^ (self methodReferenceSpecFromToolRequest: request) compiledMethod
]

{ #category : 'metadata' }
MCPToolSearchEquivalentMethods >> title [

	^ 'Search Equivalent Methods'
]
