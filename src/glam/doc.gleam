//// TODO: some generic introduction on pretty printing,
////       - why do we need this
////       - what does glam has to offer
////       - where to start? (tutorials, API doc with examples, full examples)

import gleam/list
import gleam/string
import gleam/string_builder.{StringBuilder}

/// A document that can be pretty printed with `to_string`.
/// 
pub opaque type Document {
  Line(size: Int)
  Concat(docs: List(Document))
  Text(text: String)
  Nest(doc: Document, indentation: Int)
  ForceBreak(doc: Document)
  Break(unbroken: String, broken: String)
  Group(doc: Document)
}

/// Joins a document into the end of another.
/// 
/// ## Examples
/// 
/// ```gleam
/// > from_string("pretty")
/// > |> append(from_string(" printer"))
/// > |> to_string(80)
/// "pretty printer"
/// ```
/// 
pub fn append(to first: Document, doc second: Document) -> Document {
  case first {
    Concat(docs) -> Concat(list.append(docs, [second]))
    _ -> Concat([first, second])
  }
}

/// Joins multiple documents into the end of another.
/// 
/// This is a shorthand for `append(to: first, doc: concat(docs))`.
/// 
/// ## Examples
/// 
/// ```gleam
/// > from_string("pretty")
/// > |> append_docs([
/// >   from_string("printing"),
/// >   space,
/// >   from_string("rocks!"),
/// > ])
/// > |> to_string(80) 
/// "pretty printing rocks!"
/// ```
/// 
pub fn append_docs(first: Document, docs: List(Document)) -> Document {
  append(to: first, doc: concat(docs))
}

/// A document after which the pretty printer can insert a newline.
/// A newline is added after a `break` document if the `group` it is part of
/// could not be rendered on a single line.
/// 
/// If the pretty printer decides to add a newline after `break` it will be
/// rendered as its first argument, otherwise as its first argument.
/// 
/// ## Examples
/// 
/// ```gleam
/// > let message =
/// >   [from_string("pretty"), break("•", "↩"), from_string("printed")]
/// >   |> concat
/// >   |> group
/// 
/// > message |> to_string(20)
/// "pretty•printed"
/// 
/// > message |> to_string(10)
/// "pretty↩
/// printed"
/// ```
/// 
pub fn break(unbroken: String, broken: String) {
  Break(unbroken, broken)
}

/// Joins a list of documents into a single document.
/// 
/// The resulting pretty printed document would be the same as pretty printing
/// each document separately and concatenating it together with `<>`:
/// 
/// ```gleam
/// docs |> concat |> to_string(n) ==
/// docs |> list.map(to_string(n)) |> string.concat
/// ```
/// 
/// ## Examples
/// 
/// ```gleam
/// > ["pretty", " ", "printed"]
/// > |> list.map(from_string)
/// > |> concat
/// > |> to_string(80)
/// "pretty printed"
/// ```
/// 
pub fn concat(docs: List(Document)) -> Document {
  Concat(docs)
}

/// Joins a list of documents into a single one by inserting the given
/// separators between each existing document.
/// 
/// This is a shorthand for `join(docs, concat(separators))`.
/// 
/// ## Examples
/// 
/// ```gleam
/// > ["wow", "so", "many", "commas"]
/// > |> list.map(from_string)
/// > |> concat_join([from_string(","), space])
/// > |> to_string(80)
/// "wow, so, many, commas"
/// ```
/// 
pub fn concat_join(
  docs: List(Document),
  with separators: List(Document),
) -> Document {
  join(docs, concat(separators))
}

/// An empty document that is printed as the empty string.
/// 
/// ## Examples
/// 
/// ```gleam
/// > empty |> to_string(80)
/// ""
/// ```
/// 
pub const empty: Document = Concat([])

/// Forces the pretty printer to break all the `break`s of the outermost `group`
/// into newlines as if it didn't fit on a single line.
/// 
/// ## Examples
/// 
/// ```gleam
/// >   [from_string("pretty"), break("•", "↩"), from_string("printed")]
/// >   |> concat
/// >   |> group
/// >   |> force_break
/// >   |> to_string(100)
/// "pretty↩
/// printed"
/// ```
/// 
pub fn force_break(doc: Document) -> Document {
  ForceBreak(doc)
}

/// Turns a string into a document.
/// 
/// ## Examples
/// 
/// ```gleam
/// > "doc" |> from_string |> to_string(80)
/// "doc"
/// ```
/// 
pub fn from_string(string: String) -> Document {
  Text(string)
}

/// Allows the pretty printer to break the `break` documents inside the given
/// group.
/// 
/// When the pretty printer runs into a group it first tries to render it on a
/// single line, displaying all the breaks as their first argument.
/// If the group fits this is the final pretty printed result.
/// 
/// However, if the group does not fit on a single line _all_ the `break`s
/// inside that group are rendered as their second argument and immediately
/// followed by a newline.
/// 
/// Any nested group is considered on its own and may or may not be splitted,
/// depending if it fits on a single line or not. So, even if the outermost
/// group is broken, its nested groups may still end up on a single line.
/// 
/// ## Examples
/// 
/// ```gleam
/// > let food =
/// >   ["lasagna", "ravioli", "pizza"]
/// >   |> list.map(from_string) |> join(with: space) |> group
/// > let message = 
/// >   [from_string("Food I love:"), space, food] |> concat |> group
/// 
/// > message |> to_string(80)
/// "Food I love: lasagna ravioli pizza"
/// 
/// > message |> to_string(30)
/// "Food I love:
/// lasagna ravioli pizza"
/// // ^-- After splitting the aouter group, the inner one can fit
/// //     on a single line so the pretty printer does not split it
/// 
/// > message |> to_string(20)
/// "Food I love:
/// lasagna
/// ravioli
/// pizza"
/// // ^-- Even after splitting the outer group, the inner one wouldn't
/// //     fit on a single line, so the pretty printer splits that as well
/// ```
/// 
pub fn group(doc: Document) -> Document {
  Group(doc)
}

/// Joins a list of documents inserting the given separator between
/// each existing document.
/// 
/// ## Examples
/// 
/// ```gleam
/// > const message =
/// >   ["Gleam", "is", "fun!"]
/// >   |> list.map(from_string)
/// >   |> join(with: space)
/// 
/// > message |> to_string(80)
/// "Gleam is fun!"
/// ```
/// 
pub fn join(docs: List(Document), with separator: Document) -> Document {
  concat(list.intersperse(docs, separator))
}

/// A document that is always printed as a single newline.
/// 
/// ## Examples
/// 
/// ```gleam
/// > line |> to_string(80)
/// "\n"
/// ```
pub const line: Document = Line(1)

/// A document that is always printed as a series of consecutive newlines.
/// 
/// ## Examples
/// 
/// ```gleam
/// > lines(3) |> to_string(80)
/// "\n\n\n"
/// ```
/// 
pub fn lines(size: Int) -> Document {
  Line(size)
}

/// Increases the nesting level of a document by the given amount.
/// 
/// When the pretty printer breaks a group by inserting a newline, it also adds
/// a whitespace padding equal to its nesting level.
/// 
/// ## Examples
/// 
/// ```gleam
/// > let one = [space, from_string("one")] |> concat |> nest(by: 1)
/// > let two = [space, from_string("two")] |> concat |> nest(by: 2)
/// > let three = [space, from_string("three")] |> concat |> nest(by: 3)
/// > let list = [from_string("list:"), one, two, three] |> concat |> group
/// 
/// > list |> to_string(10)
/// "list:
///  one
///   two
///    three"
/// ```
///
pub fn nest(doc: Document, by indentation: Int) -> Document {
  Nest(doc, indentation)
}

/// Prefixes a document to another one.
/// 
/// ## Examples
/// 
/// ```gleam
/// > from_string("printed!")
/// > |> prepend(from_string("pretty "))
/// > |> to_string(80)
/// "pretty printed!"
/// ```
/// 
pub fn prepend(to first: Document, doc second: Document) -> Document {
  case first {
    Concat(docs) -> Concat([second, ..docs])
    _ -> Concat([second, first])
  }
}

/// Prefixes multiple documents to another one.
/// 
/// This is a shorthand for `prepend(to: first, doc: concat(docs))`.
/// 
/// ## Examples
/// 
/// ```gleam
/// > from_string("fun!")
/// > |> prepend_docs([from_string("Gleam "), from_string("is ")])
/// > |> to_string(80)
/// "Gleam is fun!"
/// ```
/// 
pub fn prepend_docs(first: Document, docs: List(Document)) -> Document {
  prepend(to: first, doc: concat(docs))
}

/// A document that is always rendered as an empty string but can act as a
/// breaking point for the pretty printer.
/// 
/// This is a shorthand for `break("", "")`.
/// 
/// ## Examples
/// 
/// ```gleam
/// > let doc = [from_string("soft"), soft_break, from_string("break")]
/// 
/// > doc |> to_string(80)
/// "softbreak"
/// 
/// > doc |> to_string(5)
/// "soft
/// break"
/// ```
/// 
pub const soft_break: Document = Break("", "")

/// A document that is rendered as a single whitespace `" "` but can be broken
/// by the pretty printer into newlines instead.
/// 
/// This is a shorthand for `break(" ", "")`.
/// 
/// ## Examples
/// 
/// ```gleam
/// > let doc =
/// >   ["pretty", "printed"]
/// >   |> list.map(from_string)
/// >   |> join(with: space)
/// 
/// > doc |> to_string(80)
/// "pretty printed"
/// 
/// > doc |> to_string(10)
/// "pretty
/// printed"
/// ```
/// 
pub const space: Document = Break(" ", "")

/// Turns a document into a pretty printed string.
/// The pretty printed process can be thought as follows:
/// - the pretty printer first tries to print every group on a single line
/// - all the `break` documents are rendered as their first argument
/// - if the string fits on the specified width this is the result
/// - if the string does not fit on a single line the outermost group is split:
///   - all of its `break` documents are rendered as their second argument
///   - a newline is inserted after every `break`
///   - a padding of the given nesting level is added after every inserted
///     newline
///   - all inner groups are then considered on their own: the splitting of the
///     outermost group does not imply that the inner gruops will be split as
///     well
/// 
/// ## Examples
/// 
/// For some examples on how pretty printing works for each kind of document you
/// can have a look at the package documentation.
/// 
/// There's also full fledged tutorial, you can start from the
/// [introductory one](TODO)
/// and work your way up to implementing a
/// [JSON pretty printer](TODO).
/// 
pub fn to_string(doc: Document, width: Int) -> String {
  to_string_builder(doc, width)
  |> string_builder.to_string()
}

/// This function works like `to_string` but returns a `StringBuilder` instead
/// of a `String`.
/// 
pub fn to_string_builder(doc: Document, width: Int) -> StringBuilder {
  do_format(string_builder.new(), width, 0, [#(0, Unbroken, doc)])
}

type Mode {
  Broken
  ForceBroken
  Unbroken
}

fn fits(
  docs: List(#(Int, Mode, Document)),
  max_width: Int,
  current_width: Int,
) -> Bool {
  case docs {
    _ if current_width > max_width -> False

    [] -> True

    [#(indent, mode, doc), ..rest] ->
      case doc {
        Line(..) -> True

        ForceBreak(..) -> False

        Text(text) -> fits(rest, max_width, current_width + string.length(text))

        Nest(doc, i) ->
          [#(indent + i, mode, doc), ..rest]
          |> fits(max_width, current_width)

        Break(unbroken: unbroken, ..) ->
          case mode {
            Broken | ForceBroken -> True
            Unbroken ->
              fits(rest, max_width, current_width + string.length(unbroken))
          }

        Group(doc) ->
          fits([#(indent, mode, doc), ..rest], max_width, current_width)

        Concat(docs) ->
          list.map(docs, fn(doc) { #(indent, mode, doc) })
          |> list.append(rest)
          |> fits(max_width, current_width)
      }
  }
}

fn indentation(size: Int) -> String {
  string.repeat(" ", size)
}

fn do_format(
  acc: StringBuilder,
  max_width: Int,
  current_width: Int,
  docs: List(#(Int, Mode, Document)),
) -> StringBuilder {
  case docs {
    [] -> acc

    [#(indent, mode, doc), ..rest] ->
      case doc {
        Line(size) ->
          string_builder.append(acc, string.repeat("\n", size))
          |> string_builder.append(indentation(indent))
          |> do_format(max_width, indent, rest)

        Break(unbroken: unbroken, broken: broken) ->
          case mode {
            Unbroken -> {
              let new_width = current_width + string.length(unbroken)
              string_builder.append(acc, unbroken)
              |> do_format(max_width, new_width, rest)
            }

            Broken | ForceBroken ->
              string_builder.append(acc, broken)
              |> string_builder.append("\n")
              |> string_builder.append(indentation(indent))
              |> do_format(max_width, indent, rest)
          }

        ForceBreak(doc) ->
          [#(indent, ForceBroken, doc), ..rest]
          |> do_format(acc, max_width, current_width, _)

        Concat(docs) ->
          list.map(docs, fn(doc) { #(indent, mode, doc) })
          |> list.append(rest)
          |> do_format(acc, max_width, current_width, _)

        Group(doc) ->
          case fits([#(indent, Unbroken, doc)], max_width, current_width) {
            True -> #(indent, Unbroken, doc)
            False -> #(indent, Broken, doc)
          }
          |> list.prepend(to: rest)
          |> do_format(acc, max_width, current_width, _)

        Nest(doc, i) ->
          [#(indent + i, mode, doc), ..rest]
          |> do_format(acc, max_width, current_width, _)

        Text(text) ->
          string_builder.append(acc, text)
          |> do_format(max_width, current_width + string.length(text), rest)
      }
  }
}
