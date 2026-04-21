Class {
	#name : 'MCPToolRemoveClass',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'executing' }
MCPToolRemoveClass >> executeWithArguments: arguments [

	| className result |
	className := arguments at: #className.
	^ [
	  [
	  result := (MCPRemoveClassCommand className: className) execute.
	  self
		  successResultText: (self
				   successSummaryForClassName: className
				   reparentedSubclassNames: result reparentedSubclassNames)
		  data: result asDictionary ]
		  on: MCPCommandError
		  do: [ :error |
			  self
				  errorResultText: error messageText
				  details: error structuredDetails ] ]
		  on: Exception
		  do: [ :error |
			  self
				  errorResultText:
				  (self failureMessageForClassNamed: className error: error)
				  details: {
						  (#errorClass -> error class name).
						  (#message -> error messageText).
						  (#className -> className) } asDictionary ]
]

{ #category : 'private' }
MCPToolRemoveClass >> failureMessageForClassNamed: className error: anError [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Unable to remove class ';
			  nextPutAll: className;
			  nextPutAll: ' (';
			  nextPutAll: anError class name;
			  nextPutAll: '): ';
			  nextPutAll: anError messageText ]
]

{ #category : 'initialization' }
MCPToolRemoveClass >> initialize [

	super initialize.
	name := 'pharo-remove-class'.
	title := 'Remove Pharo Class'.
	description := 'Remove a class from the running Pharo image using ReRemoveClassRefactoring safety checks. Empty classes may be removed with subclasses by reparenting those subclasses to the removed class superclass.'.
	inputSchema := MCPStructureInputSchema new
		               type: 'object';
		               properties: { (MCPStructureProperties new
				                name: 'className';
				                type: 'string';
				                description: 'The class to remove.';
				                yourself) };
		               required: #( 'className' );
		               yourself.
	outputSchema := self
		                standardOutputSchemaForDataProperties: {
				                (self
					                 schemaPropertyNamed: 'className'
					                 type: 'string'
					                 description: 'The class that was removed.').
				                (self
					                 schemaPropertyNamed: 'superclassName'
					                 type: 'string'
					                 description:
					                 'The superclass of the removed class before removal.').
				                (self
					                 schemaPropertyNamed: 'packageName'
					                 type: 'string'
					                 description:
					                 'The package that owned the removed class before removal.').
				                (self
					                 schemaPropertyNamed: 'tag'
					                 type: 'string'
					                 description:
					                 'The package tag that was assigned to the removed class before removal.').
				                (self
					                 schemaPropertyNamed: 'wasEmpty'
					                 type: 'boolean'
					                 description:
					                 'Whether the removed class was considered empty by the safe-removal rules.').
				                (self
					                 schemaPropertyNamed:
					                 'reparentedToSuperclassName'
					                 type: 'string'
					                 description:
					                 'The superclass that direct subclasses were reparented to when applicable.').
				                ((self
					                  schemaPropertyNamed: 'instanceSlotNames'
					                  type: 'array'
					                  description:
						                  'The instance-side slots that were present on the removed class.')
					                 items: (MCPStructureProperties new
							                  type: 'string';
							                  description: 'An instance-side slot name.';
							                  yourself);
					                 yourself).
				                ((self
					                  schemaPropertyNamed: 'classSlotNames'
					                  type: 'array'
					                  description:
						                  'The class-side slots that were present on the removed class.')
					                 items: (MCPStructureProperties new
							                  type: 'string';
							                  description: 'A class-side slot name.';
							                  yourself);
					                 yourself).
				                ((self
					                  schemaPropertyNamed: 'subclassNames'
					                  type: 'array'
					                  description:
						                  'The direct subclasses that existed before removal.')
					                 items: (MCPStructureProperties new
							                  type: 'string';
							                  description: 'A direct subclass name.';
							                  yourself);
					                 yourself).
				                ((self
					                  schemaPropertyNamed: 'reparentedSubclassNames'
					                  type: 'array'
					                  description:
						                  'The direct subclasses that were reparented as part of the removal.')
					                 items: (MCPStructureProperties new
							                  type: 'string';
							                  description:
								                  'A reparented direct subclass name.';
							                  yourself);
					                 yourself) }
		                required:
			                #( 'className' 'superclassName' 'packageName'
			                   'tag' 'wasEmpty' 'reparentedToSuperclassName'
			                   'instanceSlotNames' 'classSlotNames'
			                   'subclassNames' 'reparentedSubclassNames' ).
	icons := {  }
]

{ #category : 'private' }
MCPToolRemoveClass >> successSummaryForClassName: className reparentedSubclassNames: reparentedSubclassNames [

	^ reparentedSubclassNames isEmpty
		  ifTrue: [ 'Removed class ' , className , '.' ]
		  ifFalse: [
			  'Removed class ' , className , ' and reparented subclasses: '
			  , (', ' join: reparentedSubclassNames) , '.' ]
]
