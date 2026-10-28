# Building On MCP

MCP is a server you can embed. Loading `Core` gives you the Streamable HTTP
transport, the JSON-RPC and schema machinery and the catalog tools, and
nothing that knows about Pharo code. Everything the server then offers a
client — tools, resources, prompts — you write in a package of your own.

A project doing this changes nothing in MCP. Its tools live in a package of
its own, which it loads when it wants them served and leaves out when it does
not.

## Load the server alone

Depend on the baseline and ask for `Core`:

```smalltalk
BaselineOfMyProject >> baseline: spec

	<baseline>
	spec for: #common do: [
		spec baseline: 'MCP' with: [
			spec
				repository: 'github://Evref-BL/MCP:vX.Y.Z/src';   "a release, not a branch"
				loads: #( 'Core' ) ].
		spec package: 'MyProject-MCP' with: [ spec requires: #( 'MyProject' 'MCP' ) ].
		spec group: 'Tools' with: #( 'MyProject-MCP' ).
		spec group: 'default' with: #( 'Core' 'Tests' ) ]
```

Two things in it are worth copying. The group is named `Tools` rather than
`MCP`, because Metacello refuses a group and a baseline that share one name.
And it is left out of `default`: your project is useful without a server, and
an image that does not serve MCP has no use for tools it cannot register.

The other groups are `IDE`, MCP's own image tools for classes, methods,
packages, tests, repositories, change history and debugging; `UI`,
the world-menu server list; `Telemetry`, the OpenTelemetry backend; and
`default`, which is `Core`, `IDE`, `UI` and their tests.

## The three things a server offers

| Kind | What it is | Who reaches for it | Subclass of | Names itself with |
| --- | --- | --- | --- | --- |
| Tool | an action with arguments | the model, on its own | `MCPTool` | `toolName` |
| Resource | a document to read | the host, for the user | `MCPResource` | `resourceUri` |
| Prompt | a message template | the user, deliberately | `MCPPrompt` | `promptName` |

They are independent. A server may have one of them, two, or all three.

## A tool

Give your tools a common superclass. It is where the things they share live —
the group they belong to, the icon they are drawn with, the helpers that talk
to your project:

```smalltalk
MCPTool << #MyProjectTool
	package: 'MyProject-MCP'
```

```smalltalk
MyProjectTool class >> groupName

	^ 'widgets'
```

The base is not served, and needs to say nothing to stay out: it answers no
`toolName`, so there is no tool there to register.

Then one class per tool:

```smalltalk
MyProjectTool << #MyProjectToolListWidgets
	package: 'MyProject-MCP'
```

```smalltalk
MyProjectToolListWidgets class >> toolName

	^ 'widget_list'

MyProjectToolListWidgets >> title

	^ 'List Widgets'

MyProjectToolListWidgets >> description

	^ 'List the widgets this image holds, optionally those whose name starts with a prefix. Use widget_get to read one.'

MyProjectToolListWidgets >> additionalKeywords

	^ #( 'widget' 'inventory' )

MyProjectToolListWidgets >> annotations

	^ MCPStructureToolAnnotations readOnly

MyProjectToolListWidgets >> buildInputSchema

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: { (self
				   schemaPropertyNamed: 'prefix'
				   type: 'string'
				   description: 'Only answer widgets whose name starts with this. Defaults to all of them.') };
		  required: #(  );
		  yourself

MyProjectToolListWidgets >> executeWithRequest: request

	| prefix names |
	prefix := request stringArgumentNamed: 'prefix' default: ''.
	names := (MyProject widgetNames select: [ :each | each beginsWith: prefix ]) asArray sorted.
	^ self
		  successResultText: names size asString , ' widget(s): ' , (', ' join: names) , '.'
		  data: { (#widgets -> names) } asDictionary
```

`MyProject widgetNames` stands for your own code. What the rest is for:

- **`toolName`** is the key in one catalog shared with every other tool the
  image has loaded, so pick a first word that is yours. `widget_list` is
  safe; `class_search` is taken.
- **`description`** is read by a model deciding whether to call you. Say what
  the tool answers and name the tools that come next, the way the example
  points at `widget_get`.
- **`additionalKeywords`** are the words `tool_search` matches besides the
  ones already in the name and title.
- **`annotations`** tell a client what the tool does to the image.
  `MCPStructureToolAnnotations readOnly` promises it changes nothing;
  `mayModify` says otherwise. A host may require a confirmation for the
  second.
- **`buildInputSchema`** is the contract the server validates an incoming
  call against before your code runs. `additionalProperties` defaults to
  false, so a caller that misspells an argument is told so instead of having
  it ignored. Every property takes a description; it is the only place the
  caller learns what the argument means.

## Being served

A tool is served because its package was loaded, and naming itself is how a
class says it is a tool. Nothing else is needed: load `MyProject-MCP` and
every server in the image has `widget_list`.

It is the tool's **own** name that serves it, not an inherited one. A
subclass of a tool is a variation of that tool, so specialising one does not
claim the name it already holds — give the subclass its own `toolName` when
it is a tool of its own.

A class that must stay out of every catalog says so itself:

```smalltalk
MyProjectTestTool class >> shouldAutoRegister

	^ false
```

That is the right thing for a test fixture, which would otherwise be served
by every server in the image whose tests are loaded.

## Reading arguments

`executeWithRequest:` receives an `MCPToolRequest` whose arguments have
already been validated against your schema. Read them with the typed
accessors rather than by hand, so a missing or oddly typed value fails in one
place:

```smalltalk
request stringArgumentNamed: 'name'.
request stringArgumentNamed: 'name' default: 'anything'.
request stringArgumentNamed: 'side' in: #( 'instance' 'class' ) default: 'instance'.
request booleanArgumentNamed: 'force' default: false.
request nonNegativeIntegerArgumentNamed: 'offset' default: 0.
request stringCollectionArgumentNamed: 'packages' default: #(  ).
request hasArgumentNamed: 'prefix'.
```

## Answering

Two answers, both built by the tool:

```smalltalk
self successResultText: 'Three widgets.' data: { (#widgets -> names) } asDictionary.
self errorResultText: 'No widget named ' , name , '.' details: { (#known -> names) } asDictionary
```

The text is what a model reads; the data is the same answer in a shape a
program can use. Give both. A text that says only "Done." costs the caller
another round trip to find out what happened.

You do not have to catch to report a failure. An exception that escapes
`executeWithRequest:` is answered as an error result naming your tool, the
error class, the message and the frames of your own code; the server leaves
its own frames out. Build an error result yourself when you know something
the exception does not, such as what the caller should have asked for.

Which of the two reaches the client is the server's choice, not the tool's.
`toolResponseFields` defaults to `#content`, where the data is rendered into
the text. `useContentAndStructuredContentToolResponses` sends both, and
`useStructuredContentOnlyToolResponses` sends only the structured half. The
structured half carries your text as `summary` and your dictionary as `data`.

### Answering a page

A tool that answers a list answers one page of it, so a long result never
arrives as one block a model has to read through. Three parts: the shared
`offset` argument, how big a page is, and the slicing. The listing tool
again, now that the list can be long:

```smalltalk
MyProjectToolListWidgets >> buildInputSchema

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: { self offsetInputProperty };
		  required: #(  );
		  yourself

MyProjectToolListWidgets >> defaultPageLimit

	^ 25

MyProjectToolListWidgets >> executeWithRequest: request

	| page |
	page := MCPPaginationResult
		        fromEntries: MyProject widgetNames asArray sorted
		        limit: self defaultPageLimit
		        offset: (request nonNegativeIntegerArgumentNamed: 'offset' default: 0).
	^ self
		  successResultText: page returnedCount asString , ' widget(s).'
		  data: (page asDictionaryWithEntriesKey: #widgets)
```

`offsetInputProperty` is the same `offset` argument every paging tool takes,
declared once so they all describe it the same way. `MCPPaginationResult`
cuts the page and answers the shape MCP's own tools answer: your entries
under the key you name, a `pagination` summary beside them, and `nextOffset`
while entries remain — a caller asks again with that offset until it stops
coming.

Answering `defaultPageLimit` is what puts `pageSize` in your contract, so
`tool_get` can tell a caller how large a page is before asking for one. A
tool that answers a whole result rather than pages leaves it alone.

## Groups and icons

`groupName` is how the catalog and the world-menu browser group related
tools. Pick one for your project and answer it on the shared superclass.

MCP reads an icon out of a tool name whose words it recognises — `class`,
`method`, `search`, `create` — which is how its own tools stay consistent
without anyone choosing. Your words are not in that vocabulary, so declare an
icon:

```smalltalk
MyProjectTool class >> toolIconSpec

	^ MCPToolIconSpec baseIconNamed: #pharoHalfScale badgeIconNamed: #browse
```

## A resource

A resource is a document the host can put in front of the model without the
model asking. Where a tool answers a question, a resource is material:

```smalltalk
MCPResource << #MyProjectWidgetResource
	package: 'MyProject-MCP'
```

```smalltalk
MyProjectWidgetResource class >> resourceUri

	^ 'myproject://widgets'

MyProjectWidgetResource class >> resourceName

	^ 'widgets'

MyProjectWidgetResource >> title

	^ 'Widget Inventory'

MyProjectWidgetResource >> description

	^ 'Every widget this image holds, as JSON.'

MyProjectWidgetResource >> mimeType

	^ 'application/json'

MyProjectWidgetResource >> readContents

	^ self textContents: (STONJSON toStringPretty: { (#widgets -> MyProject widgetNames) } asDictionary)
```

The URI is the key in the registry, and the same rule applies: a resource
that names itself is served.

### A family of resources

When the document is one of many, named by something in the URI, subclass
`MCPResourceTemplate`. It names itself with a `resourceUriTemplate` in RFC
6570 form, resolves one URI at a time through `resourceForUri:`, and may
suggest values for its variables:

```smalltalk
MyProjectWidgetTemplate class >> resourceUriTemplate

	^ 'myproject://widget/{name}'

MyProjectWidgetTemplate >> resourceForUri: aUri

	| name |
	(aUri beginsWith: MyProjectOneWidgetResource resourceUri) ifFalse: [ ^ nil ].
	name := aUri allButFirst: MyProjectOneWidgetResource resourceUri size.
	^ name
		  ifEmpty: [ nil ]
		  ifNotEmpty: [ MyProjectOneWidgetResource named: name ]

MyProjectWidgetTemplate >> completionsFor: aVariableName value: aPrefix context: aContextDictionary

	aVariableName = 'name' ifFalse: [ ^ #(  ) ].
	^ MyProject widgetNames select: [ :each | each beginsWith: aPrefix ]
```

A template lists through `resources/templates/list` and never answers
contents of its own.

What it resolves to is an ordinary resource built per URI rather than
registered. It carries the name it was built with, answers its own `uri`, and
keeps itself out of the catalog, where one entry standing for the whole family
would be wrong:

```smalltalk
MyProjectOneWidgetResource class >> resourceUri

	^ 'myproject://widget/'

MyProjectOneWidgetResource class >> shouldAutoRegister

	^ false

MyProjectOneWidgetResource class >> named: aName

	^ self new
		  widgetName: aName;
		  yourself

MyProjectOneWidgetResource >> uri

	^ self class resourceUri , self widgetName

MyProjectOneWidgetResource >> name

	^ self widgetName

MyProjectOneWidgetResource >> readContents

	^ self textContents: (MyProject describeWidgetNamed: self widgetName)
```

## A prompt

A prompt is user-controlled where a tool is model-controlled: a client
usually shows them as slash commands, so a prompt is something a person
reaches for deliberately.

```smalltalk
MyProjectReviewPrompt class >> promptName

	^ 'review_widget'

MyProjectReviewPrompt >> title

	^ 'Review A Widget'

MyProjectReviewPrompt >> description

	^ 'Asks for a review of one widget.'

MyProjectReviewPrompt >> arguments

	^ { (MCPStructurePromptArgument name: 'widget' description: 'The widget to review.' required: true) }

MyProjectReviewPrompt >> messagesFor: anArgumentDictionary

	^ self userMessage: 'Review the widget named ' , (anArgumentDictionary at: 'widget')
		  , ' and say what you would change.'
```

Like a template, a prompt may answer `completionsFor:value:context:` for its
own arguments.

## Shaping the server's surface

Two words govern it. A **registered** tool is in the catalog: callable by
name, and findable with `tool_search` and `tool_get`. An **advertised** tool
is also in `tools/list`, which is the list a client shows a model up front.
Advertising decides what is shown, not what may be called.

A tool from outside MCP is registered and discoverable, not advertised, so it
costs nothing in the client's context until something looks for it. Answer
`'static'` from `defaultExposure` to be in `tools/list` from the start.

Against that default, a server is configured directly:

```smalltalk
mcp := MCP new.
mcp addTool: MyProjectToolListWidgets.          "or addTools: { A. B }"
mcp removeTool: 'image_evaluate'.
mcp advertiseTool: MyProjectToolListWidgets.    "adds one to what is advertised"
mcp advertiseTools: { MyProjectToolListWidgets }. "replaces the advertised set"
mcp advertiseAllTools.
mcp advertiseToolDefaults.
mcp port: 4000.
mcp start.
```

`MCP startOnPort:` on the class side answers the server already on that port,
or builds one with the default catalog. A server you configured is started
through the instance, as above.

For a server holding only your own tools:

```smalltalk
mcp := MCP onlyTools: { MyProjectToolListWidgets. MyProjectToolGetWidget }.
mcp port: 4000.
mcp start.
```

`onlyTools:` replaces the catalog with exactly those, advertises all of them,
and discovers nothing afterwards. That includes the catalog tools: a server
built this way has no `tool_search`, `tool_get` or `tool_call` unless you add
them back. Add `MCPToolSearchTools`, `MCPToolGetTool` and `MCPToolCallTool`
when you want a surface a model can explore, or build up from `MCP new` with
`addTool:` instead.

## Testing what you serve

A server answers its JSON-RPC methods as plain messages, so a test needs no
socket and no port:

```smalltalk
MyProjectToolTest >> testListingAnswersEveryWidget

	| result |
	result := (MCP new useContentAndStructuredContentToolResponses; yourself)
		          rpcToolCall: 'widget_list' withParams: Dictionary new.
	self assert: (((result at: #structuredContent) at: #data) at: #widgets) equals: #( 'alpha' 'beta' 'gamma' ).
	self assert: (((result at: #content) first at: #text) beginsWith: '3 widget(s)')
```

Assert on the data rather than on the whole text: under the default
`#content`, the text a client receives is your summary with the data rendered
underneath it, so an equality test on it breaks whenever either half changes.

`rpcResourceRead:`, `rpcPromptGet:arguments:`, `rpcToolsList`,
`rpcResourcesList` and `rpcPromptsList` are there for the same purpose.

## Things that bite

- **A name already taken.** The catalog holds one tool per name. Prefix with
  a word that is yours.
- **A subclass of an existing tool is not served** until it names itself.
  That is deliberate: it would otherwise claim its superclass's name and the
  two would race for the key.
- **A fixture in a loaded test package is served** like anything else.
  Answer `false` from `shouldAutoRegister`.
- **`onlyTools:` drops the catalog tools.** See above.
- **Nothing is saved.** Tools change the running image and never write it to
  disk. `Smalltalk saveSession` is the caller's business, not the tool's.
