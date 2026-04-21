Class {
	#name : 'MCPToolCreatePackage',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'executing' }
MCPToolCreatePackage >> executeWithArguments: arguments [

	| packageName wasExisting |
	packageName := arguments at: #packageName.
	wasExisting := self packageOrganizer hasPackage: packageName.
	self packageOrganizer ensurePackage: packageName.
	^ self
		  successResultText: (wasExisting
				   ifTrue: [ 'Package ' , packageName , ' already existed.' ]
				   ifFalse: [ 'Package ' , packageName , ' created.' ])
		  data: {
				  (#packageName -> packageName).
				  (#existed -> wasExisting) } asDictionary
]

{ #category : 'initialization' }
MCPToolCreatePackage >> initialize [

	super initialize.
	name := 'pharo-create-package'.
	title := 'Create Pharo Package'.
	description := 'Create a package in the running Pharo image, or report that it already exists.'.
	inputSchema := MCPStructureInputSchema new
		               type: 'object';
		               properties: { (MCPStructureProperties new
				                name: 'packageName';
				                type: 'string';
				                description: 'The name of the package to create.';
				                yourself) };
		               required: #( 'packageName' );
		               yourself.
	outputSchema := self
		                standardOutputSchemaForDataProperties: {
				                (self
					                 schemaPropertyNamed: 'packageName'
					                 type: 'string'
					                 description:
					                 'The package name that was requested.').
				                (self
					                 schemaPropertyNamed: 'existed'
					                 type: 'boolean'
					                 description:
					                 'Whether the package already existed before the call.') }
		                required: #( 'packageName' 'existed' ).
	icons := {  }
]
