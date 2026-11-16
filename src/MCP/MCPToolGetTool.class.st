"
Static bridge tool for reading a tool contract from its owning registry.

Agents use it after tool_search and before tool_call when a discoverable tool requires exact schema details.
"
Class {
	#name : 'MCPToolGetTool',
	#superclass : 'MCPTool',
	#instVars : [
		'toolRegistry'
	],
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolGetTool class >> groupName [

	^ self toolCatalogGroupName
]

{ #category : 'instance creation' }
MCPToolGetTool class >> newForRegistry: aToolRegistry [

	^ self new
		  toolRegistry: aToolRegistry;
		  yourself
]

{ #category : 'metadata' }
MCPToolGetTool class >> toolName [

	^ 'tool_get'
]

{ #category : 'metadata' }
MCPToolGetTool >> annotations [

	^ MCPStructureToolAnnotations readOnly
]

{ #category : 'metadata' }
MCPToolGetTool >> buildInputSchema [

	| nameProperty |
	nameProperty := self schemaPropertyNamed: 'name' type: 'string' description: 'Tool name.'.
	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: { nameProperty };
		  required: #( 'name' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - results' }
MCPToolGetTool >> callDataFrom: data [
	"The contract without what the catalog alone uses."

	| contract |
	contract := (data at: #tool) copy.
	self catalogOnlyContractKeys do: [ :each | contract removeKey: each ifAbsent: [ ] ].
	^ data copy
		  at: #tool put: contract;
		  yourself
]

{ #category : 'private - results' }
MCPToolGetTool >> catalogOnlyContractKeys [
	"How a tool is annotated, exposed, grouped and found is the catalog's business: the data keeps it, and the text leaves it out, since none of it goes into a call."

	^ #( annotations exposure group keywords )
]

{ #category : 'private - results' }
MCPToolGetTool >> contentTextForStructuredContent: structuredContent [
	"A contract is read in order to build a call, so it is written as YAML rather than as plain lines: lines cannot say whether a value is a number or the text of one, whether a list holds one item or is a string containing a comma, or where a value with spaces ends. The text carries only what a call needs."

	| data |
	data := structuredContent at: #data ifAbsent: [ ^ super contentTextForStructuredContent: structuredContent ].
	^ String streamContents: [ :stream |
			  self summaryAndWarningsOn: stream for: structuredContent.
			  stream nextPut: Character lf.
			  stream nextPutAll: (MCPYamlWriter yamlFor: (self callDataFrom: data) indent: '') ]
]

{ #category : 'metadata' }
MCPToolGetTool >> defaultExposure [

	^ 'static'
]

{ #category : 'metadata' }
MCPToolGetTool >> description [

	^ 'Get a tool''s description and input schema by name.'
]

{ #category : 'executing' }
MCPToolGetTool >> executeWithRequest: request [

	^ self
		  executeRequest: request
		  do: [
				  | contract |
				  contract := self toolRegistry contractForToolNamed: (request stringArgumentNamed: 'name').
				  self successResultText: (self summaryForContract: contract) data: { (#tool -> contract) } asDictionary ]
		  onError: [ :error | self errorResultFor: error ]
]

{ #category : 'private - results' }
MCPToolGetTool >> summaryForContract: aContract [
	"A client that calls only the tools it lists cannot call one outside that list by its name alone, so the answer says when the tool is one."

	^ String streamContents: [ :stream |
			  stream << 'Tool ' << (aContract at: #name).
			  (aContract at: #exposure ifAbsent: [ nil ]) = 'discoverable' ifTrue: [ stream << ' (not in the advertised list)' ].
			  stream nextPut: $. ]
]

{ #category : 'metadata' }
MCPToolGetTool >> title [

	^ 'Get Tool'
]

{ #category : 'accessing' }
MCPToolGetTool >> toolRegistry [

	^ toolRegistry ifNil: [ toolRegistry := MCPToolRegistry default ]
]

{ #category : 'accessing' }
MCPToolGetTool >> toolRegistry: aToolRegistry [

	toolRegistry := aToolRegistry
]
