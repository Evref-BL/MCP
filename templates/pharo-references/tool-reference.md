# Tool Reference

How this server answers, and what it does when a call is not simply a success.
What a tool takes is in its own schema: read that with `tool_get`, not from
here.

## Reading An Answer

A call answers text: the summary first, then any warnings, then the payload as
lines. The fields that identify one record share a line as `key=value` pairs,
and a value carrying spaces is quoted, as in `protocol="private - results"`. A
record that names a method opens with the method, written the way Pharo writes
it: `MCPTool>>batchSummaryNoun`, or `MCPTool class>>toolName` on the class side.
A list of plain values is bracketed, as in `required: [name, slotName]`, and
text with its own lines follows under its own label.

A result does not repeat itself: what the summary states in prose, and what a
record already says another way, is left out of the lines.

The same payload is carried as `structuredContent` where the server is
configured to send it, with `data` on success and `error` on failure, the call
then also carrying the protocol's own `isError`.

## Paging

A page is the tool's own size, chosen for what one of its entries costs to
read, so a page of classes is shorter than a page of repositories. When another
page exists, `data` carries `nextOffset`; call the same tool again with that
`offset`.

A search answers what identifies each hit, not everything known about it.
`repository_search` says how many packages a repository holds rather than
naming them, which `package_search` answers.

## Several Targets At Once

Some tools take either one value or a list where they name their target, and
every other argument then applies to all of them: `method_get` and
`method_compile` by `selector` and `source`, `class_get` and `class_create` by
`name`.

Every target is attempted. The summary says how many succeeded, `data` carries
one entry per target under `results` in request order, and an entry that failed
carries its own `error`. The call is flagged `isError` only when every target
failed.

`class_update` and `method_update` are the opposite case: they take the whole
change to one target and stop at the first part that fails, rather than leaving
half a definition nobody asked for.

## Warnings Are Not Failures

Pharo signals a notification for a remark rather than a fault, and every
`Warning` is one. The tool boundary resumes them with the value the image would
have produced and the call proceeds, so a deprecated send, or an undeclared
variable during a load, does not fail it.

`RBRefactoringWarning` is the exception. It reports a change that breaks
something, so it stops the call, and the error carries `impactMessages`,
`howToProceed` and `forceSupported`. Read the impact, then send the same request
with `force=true` only when the warning is acceptable; forced warnings come back
in the normal `warnings` array.

A method can compile and still answer critiques. They are review evidence about
code that now exists, not a transport failure.

## Rewriting

`method_rewrite` takes Smalltalk AST patterns, not regex, and a scope is
required: rewriting everything is something a caller asks for by naming the
packages, not by leaving an argument out.

A metavariable starts with a backquote and stands for whatever is in its place,
however big, so one rule rewrites `anObject notNil` and `(anObject foo) notNil`
alike. The names must be the same on both sides; a name that appears only in
the replacement is bound to nothing. `confirm` is false by default, and the
preview carries the old and new source of every change.

```json
{
  "rules": [{ "match": "`@receiver notNil", "replacement": "`@receiver isNotNil" }],
  "scope": { "packages": ["MyPackage"] }
}
```

Any rewrite rule stands for its own patterns, Pharo's own included, so
`ruleClasses` can name one instead of writing its patterns out. A rule that
reports a critique is never applied by the tool that compiles: reporting is
that tool's job, changing it is this one's, and the caller asks.

## Mutation And Saving

No tool saves the image. Mutating tools change the running image only, so
closing it discards every change since its last save, and a mistake costs the
session rather than the image file. Evaluate `Smalltalk saveSession` when a
change should survive, or leave it to whoever owns the image lifecycle.

`history_entry_list` shows what changed and `history_entry_revert` undoes it in
the running image; both preview, and perform with `confirm=true`.

## The Escape Hatch

`image_evaluate` runs arbitrary Smalltalk. Prefer a dedicated tool when one
exists: it validates its input and answers structured data.

Compiling is the case that bites. Method source separates lines with CR, and
`method_compile` normalizes what it is given, while a bare `compile:` from
`image_evaluate` stores whatever it receives, so source written with LF compares
unequal to every other method in the image.

A debugger somebody opened is theirs. Read it, act on what it shows with the
ordinary class and method tools, and leave stepping, resuming and terminating
to the person at the debugger.
