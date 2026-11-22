"
A probe that debug_watch installs before Pharo 12, which has no debug points: a metalink that evaluates a script after its node runs, in the frame of the method, the way a watch debug point with a script behavior does from Pharo 12 on. I answer remove, as a debug point does.
"
Class {
	#name : 'MCPWatchProbe',
	#superclass : 'Object',
	#instVars : [
		'link',
		'script'
	],
	#category : 'MCP-IDE-Compatibility-Before12',
	#package : 'MCP-IDE-Compatibility-Before12'
}

{ #category : 'instance creation' }
MCPWatchProbe class >> installOn: aNode script: aString [

	^ self new
		  script: aString;
		  installOn: aNode;
		  yourself
]

{ #category : 'evaluating' }
MCPWatchProbe >> hitWithContext: aContext [
	"Evaluated as ScriptBehavior evaluates the script of a debug point from Pharo 12 on. What fails is dropped: the probe sits in a method any process may run, a server's worker among them, where a failure reaches no handler and quits a headless image, and a process still in the method when the probe is removed runs into it afterwards, in a frame the script may not compile against."

	^ [
	  Smalltalk compiler
		  source: script;
		  context: aContext;
		  receiver: aContext receiver;
		  bindings: { (#thisContext -> aContext) };
		  evaluate ]
		  on: Error
		  do: [ :error | error return: nil ]
]

{ #category : 'installing' }
MCPWatchProbe >> installOn: aNode [
	"The link runs at the base level only: the probe's own work, which compiles the script and prints the value, may send the watched method again, which would fire it without end."

	link := MetaLink new
		        metaObject: self;
		        selector: #hitWithContext:;
		        arguments: #( #context );
		        control: #after;
		        options: #( #+ #optionCompileOnLinkInstallation );
		        level: 0;
		        yourself.
	aNode link: link
]

{ #category : 'installing' }
MCPWatchProbe >> remove [

	link ifNotNil: [ link uninstall ]
]

{ #category : 'accessing' }
MCPWatchProbe >> script: aString [

	script := aString
]
