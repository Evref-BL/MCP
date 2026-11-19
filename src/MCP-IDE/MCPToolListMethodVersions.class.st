"
Lists the versions of a method that the image's change history records, newest first: what each change did to it, the protocol and source it left, and its time when the log gives one. A method removed since is listed too, as long as its class exists. The numbers are the ones method_restore takes; MCPMethodVersionQuery says where the versions come from and how they are counted.
"
Class {
	#name : 'MCPToolListMethodVersions',
	#superclass : 'MCPTool',
	#traits : 'TMCPMethodTool',
	#classTraits : 'TMCPMethodTool classTrait',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolListMethodVersions class >> groupName [

	^ self methodsGroupName
]

{ #category : 'metadata' }
MCPToolListMethodVersions class >> toolName [

	^ 'method_version_list'
]

{ #category : 'metadata' }
MCPToolListMethodVersions >> additionalKeywords [
	"What a caller looking for a lost or broken method searches for."

	^ #( 'history' 'version' 'versions' 'previous' 'removed' 'restore' 'undo' )
]

{ #category : 'metadata' }
MCPToolListMethodVersions >> annotations [

	^ MCPStructureToolAnnotations readOnly
]

{ #category : 'metadata' }
MCPToolListMethodVersions >> batchArgumentName [

	^ 'selector'
]

{ #category : 'metadata' }
MCPToolListMethodVersions >> batchSummaryNoun [

	^ 'methods'
]

{ #category : 'metadata' }
MCPToolListMethodVersions >> batchSummaryVerb [

	^ 'Listed the versions of'
]

{ #category : 'metadata' }
MCPToolListMethodVersions >> buildInputSchema [

	^ MCPStructureInputSchema
		  properties: {
				  (self schemaPropertyNamed: 'class' type: 'string' description: 'The class the method is in, or was in.').
				  (self targetSideSchemaPropertyDescribedAs: 'Which side the method is on.').
				  (self
					   stringOrArraySchemaNamed: 'selector'
					   description: 'The method''s selector, or several of that class.'
					   itemDescription: 'Selector name.') }
		  required: #( 'class' 'selector' )
]

{ #category : 'metadata' }
MCPToolListMethodVersions >> description [

	^ 'List the versions of a method that the change history records, newest first, with their sources. A removed method is listed too. method_restore installs one.'
]

{ #category : 'executing' }
MCPToolListMethodVersions >> executeWithRequest: request [
	"Each selector's versions are listed on their own."

	^ self
		  executeBatchedRequest: request
		  do: [ :targetRequest | self executeRequest: targetRequest do: [ self listVersionsFor: targetRequest ] ]
]

{ #category : 'private - results' }
MCPToolListMethodVersions >> keyOrder [
	"A version reads as its number, what the change did, where it filed the method and when, then the source."

	^ #( version change protocol time source )
]

{ #category : 'private - execution' }
MCPToolListMethodVersions >> listVersionsFor: request [

	| behavior selector versions |
	behavior := self behaviorNamedIn: request.
	selector := (request stringArgumentNamed: 'selector') asSymbol.
	versions := MCPMethodVersionQuery inCurrentSession versionsOf: behavior selector: selector.
	^ self
		  successResultText: (self summaryForVersions: versions of: (self methodReferenceForBehavior: behavior selector: selector))
		  data: { (#versions -> (versions reversed collect: [ :each | each asDictionary ] as: Array)) } asDictionary
]

{ #category : 'private - results' }
MCPToolListMethodVersions >> summaryForVersions: versions of: aMethodReference [
	"Listed 3 versions of Foo>>bar, newest first. One version has no order to state, and none is said as such."

	^ String streamContents: [ :stream |
			  versions ifEmpty: [ stream << 'The change history records no version of ' << aMethodReference << '.' ] ifNotEmpty: [
					  stream << 'Listed ' << (self textForCount: versions size noun: 'version') << ' of ' << aMethodReference.
					  versions size > 1 ifTrue: [ stream << ', newest first' ].
					  stream << '.' ] ]
]

{ #category : 'metadata' }
MCPToolListMethodVersions >> title [

	^ 'List Method Versions'
]
