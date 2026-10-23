"
Concrete debug_watch tool. It records what named variables hold while an expression runs, without stopping it.

This is print debugging without editing the method: Pharo WatchDebugPoints go in, the expression runs, the probes come out, and the values they saw are answered. Nothing is left installed and no debug session is created.
"
Class {
	#name : 'MCPToolDebugWatch',
	#superclass : 'MCPToolDebug',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolDebugWatch class >> toolName [

	^ 'debug_watch'
]

{ #category : 'metadata' }
MCPToolDebugWatch >> additionalKeywords [

	^ #( 'watch' 'trace' 'log' 'print' 'value' 'variable' 'probe' 'observe' 'instrument' )
]

{ #category : 'private - execution' }
MCPToolDebugWatch >> commandForRequest: debugRequest [

	^ MCPDebugWatchCommand tool: self request: debugRequest
]

{ #category : 'metadata' }
MCPToolDebugWatch >> description [

	^ 'Record what variables hold while an expression runs, without stopping it. Probes are removed before the call answers, so nothing is left installed and no debug session is created.'
]

{ #category : 'metadata' }
MCPToolDebugWatch >> inputProperties [

	| methodProperty variableProperty |
	methodProperty := MCPStructureProperties new
		                  name: 'method';
		                  type: #( 'string' 'array' );
		                  description: 'A method to probe, as Class>>selector or Class class>>selector. One of them, or several.';
		                  items: (MCPStructureProperties new
				                   type: 'string';
				                   description: 'One method.';
				                   yourself);
		                  yourself.
	variableProperty := MCPStructureProperties new
		                    name: 'variable';
		                    type: #( 'string' 'array' );
		                    description:
			                    'A variable to record on every assignment to it. One of them, or several. Left out, the receiver is recorded when each method is entered.';
		                    items: (MCPStructureProperties new
				                     type: 'string';
				                     description: 'One variable.';
				                     yourself);
		                    yourself.
	^ {
		  methodProperty.
		  variableProperty.
		  (self schemaPropertyNamed: 'run' type: 'string' description: 'Smalltalk to evaluate while the probes are installed.') }
]

{ #category : 'private - request' }
MCPToolDebugWatch >> parsedRequestFromToolRequest: request [

	^ MCPDebugWatchRequest fromRequest: request tool: self
]

{ #category : 'metadata' }
MCPToolDebugWatch >> requiredInputProperties [

	^ #( 'method' 'run' )
]

{ #category : 'metadata' }
MCPToolDebugWatch >> title [

	^ 'Watch Values While Code Runs'
]
