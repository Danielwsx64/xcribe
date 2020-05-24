defmodule Xcribe.CLI.Output do
  @moduledoc false

  @blue IO.ANSI.blue()
  @dark_blue IO.ANSI.color(25)
  @gray IO.ANSI.color(240)
  @light_green IO.ANSI.color(37)
  @white IO.ANSI.white()
  @yellow IO.ANSI.yellow()
  @bg_blue IO.ANSI.blue_background()
  @reset IO.ANSI.reset()

  def print_request_errors(errors) do
    print_header_error("Xcribe found errors")

    errors
    |> print_and_remove(:parsing)

    :ok
  end

  defp print_and_remove(errors, type) do
    Enum.reduce(errors, [], &reduce_errors(&1, &2, type))
  end

  defp reduce_errors(%{type: typ} = err, errs, typ) do
    print_error(err)

    errs
  end

  defp reduce_errors(err, errs, _typ), do: [err, errs]

  defp print_error(%{type: :parsing, message: msg, __meta__: %{call: call}}) do
    line_call = get_line(call.file, call.line)

    IO.puts("""
    #{tab(@blue)}
    #{tab(@blue)} [P] → #{@yellow} #{msg}
    #{tab(@blue)} #{space(6)} #{@blue}> #{call.description}
    #{tab(@blue)} #{space(6)} #{@gray}#{format_file_path(call.file)}:#{call.line}
    #{tab(@dark_blue)}
    #{tab(@dark_blue)} #{space(6)} #{@light_green}#{line_call}
    #{tab(@dark_blue)} #{space(6)} #{@dark_blue}#{pointer_for(line_call)}
    #{tab(@dark_blue)}
    """)
  end

  defp format_file_path(path), do: String.replace(path, File.cwd!(), "")

  defp tab(color), do: "#{color}┃#{@reset}"

  defp print_header_error(message) do
    IO.puts("#{@bg_blue}#{@white}  #{message}#{space_for(message)}#{@reset}")
  end

  defp pointer_for(message) do
    message
    |> String.replace("document", "^^^^^^^^")
    |> String.replace(~r"[^\^]", " ")
  end

  defp space_for(message), do: String.duplicate(" ", 80 - String.length(message))
  defp space(count), do: String.duplicate(" ", count)

  def get_line(filename, line) do
    filename
    |> File.stream!()
    |> Stream.with_index()
    |> Stream.filter(fn {_value, index} -> index == line - 1 end)
    |> Enum.at(0)
    |> (fn {value, _line} -> String.trim(value) end).()
  end
end
