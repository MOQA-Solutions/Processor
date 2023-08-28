# Processor

This Application represents a proposed solution to build the required Word Processor given
in the Technical Test.

## Installation

The package can be installed by adding `processor` to your list of dependencies in `mix.exs`
and specifying the path:

```
defp deps do
  [
    {:processor, git: "https://github.com/MOQA-Solutions/Processor.git"}
  ]
end
```
**NOTE:**<br>
Three environment variables should be configured before starting the server:<br>
- `data`: a stream of characteres(string) represents the server's data
- `lock_timeout`: maximum time that a process should take between `read` and `write`,
   the data will be locked during this time
- `request_timeout`: maximum time that a process should wait for a reply from the processor server.

## API

The Server's API is implemented in `processor.ex` module :
- `get()`: returns the server's Text data
- `insert(substring, position)`: insert the given substring at the given position in the text data
- `delete(stringlist)`: delete all occurences of all substrings or characteres given in `stringlist`
   from the text data
- `replace(substring1, substring2)`: replace all occurences of `substring1` by `substring2` in the
  text data
- `search(substring)`: search the first occurence of `substring` in the text data.<br>
<!-- end -->
For more informations, see `processor.ex`.

## Notes

- We have used a manual lock mechanism to save data and prevent data loss
- We have used just `handle_info/2` for server's callbacks and that will give us the most
  efficiency if deciding to run the server on a remote node  
- Operations on the text will be done by the caller process and not the processor server for
  more parallelism
- We have holding our data in the server's state, in real applications the data should be persistent
  and should be stored in a database.
 





