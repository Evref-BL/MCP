Class {
	#name : 'MCPToolGetClasses',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'executing' }
MCPToolGetClasses >> executeWithArguments: arguments [

	| classNames packageName |
	packageName := arguments at: #packageName.
	^ [
	  classNames := (packageName asPackage classes collect: [ :class |
		                 class name asString ]) asSortedCollection asArray.
	  self
		  successResultText:
		  classNames size asString , ' classes listed for ' , packageName
		  , '.'
		  data: {
				  (#packageName -> packageName).
				  (#classNames -> classNames).
				  (#count -> classNames size) } asDictionary ]
		  on: Error
		  do: [ :error |
			  self
				  errorResultText:
				  (self failureMessageForPackageNamed: packageName error: error)
				  details: {
						  (#errorClass -> error class name).
						  (#message -> error messageText).
						  (#packageName -> packageName) } asDictionary ]
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
	name := 'pharo-list-package-classes'.
	title := 'List Classes in Pharo Package'.
	description := 'List classes defined in a package of the running Pharo image.'.
	inputSchema := MCPStructureInputSchema new
		               type: 'object';
		               properties: { (MCPStructureProperties new
				                name: 'packageName';
				                type: 'string';
				                description:
					                'The name of the package whose classes should be listed.';
				                yourself) };
		               required: #( 'packageName' );
		               yourself.
	outputSchema := self
		                standardOutputSchemaForDataProperties: {
				                (self
					                 schemaPropertyNamed: 'packageName'
					                 type: 'string'
					                 description:
					                 'The package whose classes were listed.').
				                ((self
					                  schemaPropertyNamed: 'classNames'
					                  type: 'array'
					                  description:
						                  'The class names defined in the package.')
					                 items: (MCPStructureProperties new
							                  type: 'string';
							                  description: 'A class name.';
							                  yourself);
					                 yourself).
				                (self
					                 schemaPropertyNamed: 'count'
					                 type: 'number'
					                 description: 'The number of classes returned.') }
		                required: #( 'packageName' 'classNames' 'count' ).
	icons := {  }
]
