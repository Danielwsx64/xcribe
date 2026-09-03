defmodule Xcribe.CLI.Output do
  @moduledoc false

  @cyan IO.ANSI.cyan()
  @gray IO.ANSI.light_black()
  @green IO.ANSI.green()
  @red IO.ANSI.red()
  @yellow IO.ANSI.yellow()

  @invert IO.ANSI.reverse()
  @reset IO.ANSI.reset()

  @bar_size 95
  @gutter "┃"
  @marker "▸"

  alias Xcribe.{DocException, SpecificationFile}

  def print_message(message, type \\ :ok)

  def print_message(message, :error) when is_binary(message),
    do: IO.puts("#{status_prefix(@red)} #{@red}#{message}#{@reset}")

  def print_message(message, :ok) when is_binary(message),
    do: IO.puts("#{status_prefix(@cyan)} #{message}")

  def print_captured_test(%{name: name_as_atom, time: time}) do
    "test " <> name = Atom.to_string(name_as_atom)

    IO.puts("#{tab(@green)}#{space(3)}#{name} - #{format_us(normalize_us(time))}s")
  end

  def print_captured_error(%{name: name_as_atom}) do
    "test " <> name = Atom.to_string(name_as_atom)

    IO.puts("#{tab(@red)}#{space(3)}Test error: #{name}")

    print_header_error("[ Xcribe ] doc tasks was aborted", @red)
  end

  def print_request_errors(errors) do
    print_header_error("[ Xcribe ] Parsing and validation errors", @yellow)

    Enum.each(errors, &print_error/1)
  end

  def print_configuration_errors(errors) do
    print_header_error("[ Xcribe ] Configuration errors", @yellow)

    Enum.each(errors, &print_error/1)
  end

  def print_specification_error(%SpecificationFile{message: message}) do
    print_header_error("[ Xcribe ] Specification file errors", @yellow)

    IO.puts("""
    #{tab(@yellow)}
    #{tab(@yellow)} [S] → #{@yellow} #{message}
    #{tab(@yellow)}
    #{tab(@yellow)} #{@gray}The specification file must be an Elixir file evaluating to a map.
    #{tab(@yellow)} #{@gray}Run `mix xcribe.gen.spec` to generate a valid one.
    #{tab(@yellow)}
    """)
  end

  def print_file_errors({file_path, reason}) do
    print_header_error("[ Xcribe ] Output file errors", @red)

    IO.puts("""
    #{tab(@red)}
    #{tab(@red)} [E] → #{@red} Could not write to #{file_path}
    #{tab(@red)} #{space(6)} #{@red}Error: #{reason}
    #{tab(@red)}
    #{tab(@red)} #{@gray}The destination path for documentation artifact cannot be accessed.
    #{tab(@red)} #{@gray}Common reasons for this error are missing write permissions or the directory does not exist.
    #{tab(@red)}
    """)
  end

  def print_doc_exception(%DocException{
        request_error: %{__meta__: %{call: call}},
        message: msg,
        stacktrace: stack
      }) do
    line_call = get_line(call.file, call.line)

    print_header_error("[ Xcribe ] Exception", @red)

    IO.puts("""
    #{tab(@red)}
    #{tab(@red)} [E] → #{@red} #{msg}
    #{tab(@red)} #{space(6)} #{@cyan}> #{call.description}
    #{tab(@red)} #{space(6)} #{@gray}#{format_file_path(call.file)}:#{call.line}
    #{tab(@red)}
    #{tab(@red)} #{space(6)} #{@cyan}#{line_call}
    #{tab(@red)} #{space(6)} #{@red}#{pointer_for(line_call)}
    #{tab(@red)}

     - Exception stacktrace:

    #{stack}
    """)
  end

  defp print_error(%{type: typ, message: msg, __meta__: %{call: call}})
       when typ in [:parsing, :validation] do
    line_call = get_line(call.file, call.line)

    IO.puts("""
    #{tab(@yellow)}
    #{tab(@yellow)} [#{error_char(typ)}] → #{@yellow} #{msg}
    #{tab(@yellow)} #{space(6)} #{@cyan}> #{call.description}
    #{tab(@yellow)} #{space(6)} #{@gray}#{format_file_path(call.file)}:#{call.line}
    #{tab(@yellow)}
    #{tab(@yellow)} #{space(6)} #{@cyan}#{line_call}
    #{tab(@yellow)} #{space(6)} #{@yellow}#{pointer_for(line_call)}
    #{tab(@yellow)}
    """)
  end

  defp print_error({nil, nil, msg, info}) do
    IO.puts("""
    #{tab(@yellow)}
    #{tab(@yellow)} [C] → #{@yellow} #{msg}
    #{tab(@yellow)}
    #{tab(@yellow)} #{space(6)} #{@gray}#{info}
    #{tab(@yellow)}
    """)
  end

  defp print_error({config, value, msg, info}) do
    IO.puts("""
    #{tab(@yellow)}
    #{tab(@yellow)} [C] → #{@yellow} #{msg}
    #{tab(@yellow)} #{space(6)} #{@gray}> Config key: #{config}
    #{tab(@yellow)}
    #{tab(@yellow)} #{space(6)} Given value: #{@cyan}#{inspect(value)}
    #{tab(@yellow)} #{space(6)} #{@gray}#{info}
    #{tab(@yellow)}
    """)
  end

  defp format_file_path(path), do: Path.relative_to_cwd(path)

  defp tab(color), do: "#{color}#{@gutter}#{@reset}"

  defp status_prefix(color), do: "#{color}#{@gutter} #{@marker}#{@reset}"

  defp print_header_error(message, color),
    do: IO.puts("#{color}#{@invert}  #{message}#{space_for(message)}#{@reset}")

  defp pointer_for(message) do
    message
    |> String.replace("document", "^^^^^^^^")
    |> String.replace(~r"[^\^]", " ")
  end

  defp space_for(message), do: String.duplicate(" ", @bar_size - String.length(message))
  defp space(count), do: String.duplicate(" ", count)

  defp error_char(:parsing), do: "P"
  defp error_char(:validation), do: "V"

  def get_line(filename, line) do
    filename
    |> File.stream!()
    |> Stream.with_index()
    |> Stream.filter(fn {_value, index} -> index == line - 1 end)
    |> Enum.at(0)
    |> then(fn {value, _line} -> String.trim(value) end)
  end

  defp normalize_us(nil), do: 0
  defp normalize_us(us), do: div(us, 10_000)

  defp format_us(us) do
    if us < 10 do
      "0.0#{us}"
    else
      us = div(us, 10)
      "#{div(us, 10)}.#{rem(us, 10)}"
    end
  end
end
