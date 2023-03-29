import gleam/bool
import gleam/io
import gleam/list
import gleam/order
import gleam/result
import gleam/string

fn sort_file(file_contents: String) -> Result(String, Nil) {
  let lines = string.split(file_contents, on: "\n")
  let #(to_sort, rest) =
    list.split_while(
      lines,
      fn(line) {
        line
        |> string.trim
        |> fn(s) {
          string.starts_with(s, "import") || !string.is_empty(s)
          |> bool.negate
        }
      },
    )
  to_sort
  |> list.filter(fn(x) {
    string.is_empty(x)
    |> bool.negate
  })
  |> sort_imports
  |> result.map(fn(x) {
    list.append(x, ["", ..rest])
    |> string.join("\n")
  })
}

fn sort_imports(imports: List(String)) -> Result(List(String), Nil) {
  // Verify the imports are not malformed
  use <- bool.guard(
    list.filter(
      imports,
      fn(x) {
        x
        |> string.split(" ")
        |> list.length == 1
      },
    )
    |> list.is_empty
    |> bool.negate,
    Error(Nil),
  )

  // First get all the gleam imports
  list.sort(
    imports,
    fn(x, y) {
      let assert Ok(x) =
        x
        |> string.split(" ")
        |> list.at(1)
        |> result.map(string.trim)

      let assert Ok(y) =
        y
        |> string.split(" ")
        |> list.at(1)
        |> result.map(string.trim)

      use <- bool.guard(
        string.starts_with(x, "gleam/") && string.starts_with(y, "gleam/"),
        string.compare(x, y),
      )
      use <- bool.guard(string.starts_with(x, "gleam/"), order.Lt)
      use <- bool.guard(string.starts_with(y, "gleam/"), order.Gt)

      string.compare(x, y)
    },
  )
  |> Ok
}

external fn sort_ffi(
  path: String,
  for_each: fn(String) -> Result(String, Nil),
) -> Nil =
  "./sorting.mjs" "sort"

external fn get_args() -> List(String) =
  "./sorting.mjs" "getArgs"

external fn directory_exists(String) -> Bool =
  "./sorting.mjs" "dirExists"

external fn exit(code: Int) -> Nil =
  "./sorting.mjs" "exit"

pub fn main() {
  let path = case get_args() {
    [arg, ..] -> arg
    _ -> "src/"
  }

  case directory_exists(path) {
    False -> {
      io.println("Directory not found: " <> path)
      exit(1)
      Nil
    }
    True -> Nil
  }

  sort_ffi(path, sort_file)
}
