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

	^ { (MCPStructureTextContent text: (wasExisting
			    ifTrue: [ 'Package ' , packageName , ' already exists.' ]
			    ifFalse: [ 'Package ' , packageName , ' created.' ])) }
]

{ #category : 'initialization' }
MCPToolCreatePackage >> initialize [

	super initialize.
	name := 'pharo-create-package'.
	title := 'Create Pharo Package'.
	description := 'Create a package in the Pharo environment'.
	inputSchema := MCPStructureInputSchema new
		               type: 'object';
		               properties: { (MCPStructureProperties new
				                name: 'packageName';
				                type: 'string';
				                description:
					                'The name of the package to be created') };
		               required: #( 'packageName' );
		               yourself.
	icons := {  }
]
