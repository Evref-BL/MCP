Class {
	#name : 'MCPToolGetClasses',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'executing' }
MCPToolGetClasses >> executeWithArguments: arguments [

	| packageName classes |
	packageName := arguments at: #packageName.
	^ [
	  classes := packageName asPackage classes
		             collect: [ :class | packageName , '/' , class name ]
		             as: Array.
	  { (MCPStructureTextContent text: (classes joinUsing: ', ')) } ]
		  on: Error
		  do: [ :error |
			  { (MCPStructureTextContent text:
				   (self failureMessageForPackageNamed: packageName error: error)) } ]
]

{ #category : 'private' }
MCPToolGetClasses >> failureMessageForPackageNamed: aPackageName error: anError [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Unable to list classes for package ';
			  nextPutAll: aPackageName;
			  nextPutAll: ' (';
			  nextPutAll: anError class name;
			  nextPutAll: '): ';
			  nextPutAll: anError messageText ]
]

{ #category : 'initialization' }
MCPToolGetClasses >> initialize [

	super initialize.
	name := 'get-package-class'.
	title := 'List the classes of a package'.
	description := 'Get the list of classes inside a package'.
	inputSchema := MCPStructureInputSchema new
		               type: 'object';
		               properties: { (MCPStructureProperties new
				                name: 'packageName';
				                type: 'string';
				                description:
					                'The name of the package we will look class into') };
		               yourself.
	icons := {  }
]
