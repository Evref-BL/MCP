Class {
	#name : 'MCPToolGetPackages',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'executing' }
MCPToolGetPackages >> executeWithArguments: params [

	| packages |
	packages := (self packageOrganizer packages collect: [ :package |
		             package name asString ]) asSortedCollection asArray.
	^ self
		  successResultText: packages size asString , ' packages listed.'
		  data: {
				  (#packageNames -> packages).
				  (#count -> packages size) } asDictionary
]

{ #category : 'initialization' }
MCPToolGetPackages >> initialize [

	super initialize.
	name := 'pharo-list-packages'.
	title := 'List Pharo Packages'.
	description := 'List package names available in the running Pharo image.'.
	inputSchema := MCPStructureInputSchema new
		               type: 'object';
		               yourself.
	outputSchema := self
		                standardOutputSchemaForDataProperties: {
				                ((self
					                  schemaPropertyNamed: 'packageNames'
					                  type: 'array'
					                  description:
						                  'The package names available in the running image.')
					                 items: (MCPStructureProperties new
							                  type: 'string';
							                  description: 'A package name.';
							                  yourself);
					                 yourself).
				                (self
					                 schemaPropertyNamed: 'count'
					                 type: 'number'
					                 description: 'The number of packages returned.') }
		                required: #( 'packageNames' 'count' ).
	icons := {  }
]
