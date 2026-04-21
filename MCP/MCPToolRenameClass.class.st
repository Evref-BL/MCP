Class {
	#name : 'MCPToolRenameClass',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'executing' }
MCPToolRenameClass >> executeWithArguments: arguments [

	| className newClassName result |
	className := arguments at: #className.
	newClassName := arguments at: #newClassName.
	^ [
	  [
	  result := (MCPRenameClassCommand
		             className: className
		             newClassName: newClassName) execute.
	  self
		  successResultText:
		  (self successSummaryFrom: className to: newClassName)
		  data: result asDictionary ]
		  on: MCPCommandError
		  do: [ :error |
			  self
				  errorResultText: error messageText
				  details: error structuredDetails ] ]
		  on: Exception
		  do: [ :error |
			  self
				  errorResultText: (self
						   failureMessageForClassNamed: className
						   to: newClassName
						   error: error)
				  details: {
						  (#errorClass -> error class name).
						  (#message -> error messageText).
						  (#className -> className).
						  (#newClassName -> newClassName) } asDictionary ]
]

{ #category : 'private' }
MCPToolRenameClass >> failureMessageForClassNamed: className to: newClassName error: anError [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Unable to rename class ';
			  nextPutAll: className;
			  nextPutAll: ' to ';
			  nextPutAll: newClassName;
			  nextPutAll: ' (';
			  nextPutAll: anError class name;
			  nextPutAll: '): ';
			  nextPutAll: anError messageText ]
]

{ #category : 'initialization' }
MCPToolRenameClass >> initialize [

	super initialize.
	name := 'pharo-rename-class'.
	title := 'Rename Pharo Class'.
	description := 'Rename a class in the running Pharo image using ReRenameClassRefactoring so references and subclass definitions are updated too.'.
	inputSchema := MCPStructureInputSchema new
		               type: 'object';
		               properties: {
				               (MCPStructureProperties new
					                name: 'className';
					                type: 'string';
					                description: 'The existing class name to rename.';
					                yourself).
				               (MCPStructureProperties new
					                name: 'newClassName';
					                type: 'string';
					                description: 'The new class name to assign.';
					                yourself) };
		               required: #( 'className' 'newClassName' );
		               yourself.
	outputSchema := self
		                standardOutputSchemaForDataProperties: {
				                (self
					                 schemaPropertyNamed: 'oldClassName'
					                 type: 'string'
					                 description: 'The class name before the rename.').
				                (self
					                 schemaPropertyNamed: 'newClassName'
					                 type: 'string'
					                 description: 'The class name after the rename.').
				                (self
					                 schemaPropertyNamed: 'superclassName'
					                 type: 'string'
					                 description:
					                 'The superclass of the renamed class.').
				                (self
					                 schemaPropertyNamed: 'packageName'
					                 type: 'string'
					                 description:
					                 'The package that owns the renamed class.').
				                (self
					                 schemaPropertyNamed: 'tag'
					                 type: 'string'
					                 description:
					                 'The package tag assigned to the renamed class.').
				                ((self
					                  schemaPropertyNamed: 'instanceSlotNames'
					                  type: 'array'
					                  description:
						                  'The instance-side slots present on the renamed class.')
					                 items: (MCPStructureProperties new
							                  type: 'string';
							                  description: 'An instance-side slot name.';
							                  yourself);
					                 yourself).
				                ((self
					                  schemaPropertyNamed: 'classSlotNames'
					                  type: 'array'
					                  description:
						                  'The class-side slots present on the renamed class.')
					                 items: (MCPStructureProperties new
							                  type: 'string';
							                  description: 'A class-side slot name.';
							                  yourself);
					                 yourself).
				                ((self
					                  schemaPropertyNamed: 'subclassNames'
					                  type: 'array'
					                  description:
						                  'The direct subclasses of the renamed class after the refactoring.')
					                 items: (MCPStructureProperties new
							                  type: 'string';
							                  description: 'A direct subclass name.';
							                  yourself);
					                 yourself) }
		                required:
			                #( 'oldClassName' 'newClassName' 'superclassName'
			                   'packageName' 'tag' 'instanceSlotNames'
			                   'classSlotNames' 'subclassNames' ).
	icons := {  }
]

{ #category : 'private' }
MCPToolRenameClass >> successSummaryFrom: className to: newClassName [

	^ 'Renamed class ' , className , ' to ' , newClassName , '.'
]
