defmodule Xcribe.CLI.Output do
  @moduledoc false

  @blue IO.ANSI.blue()
  @dark_blue IO.ANSI.color(25)
  @dark_green IO.ANSI.color(100)
  @gray IO.ANSI.color(240)
  @green IO.ANSI.green()
  @light_green IO.ANSI.color(37)
  @white IO.ANSI.white()
  @yellow IO.ANSI.yellow()
  @bg_blue IO.ANSI.blue_background()
  @bg_green IO.ANSI.green_background()
  @reset IO.ANSI.reset()

  @bar_size 95

  def print_request_errors(errors) do
    print_header_error("[ Xcribe ] Parsing Errors", @bg_blue)

    Enum.each(errors, &print_error/1)
  end

  def print_configuration_errors(errors) do
    print_header_error("[ Xcribe ] Configuration Errors", @bg_green)

    Enum.each(errors, &print_error/1)
  end

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

  defp print_error({config, value, msg, info}) do
    IO.puts("""
    #{tab(@green)}
    #{tab(@green)} [C] → #{@blue} #{msg}
    #{tab(@green)} #{space(6)} #{@gray}> Config key: #{config}
    #{tab(@dark_green)}
    #{tab(@dark_green)} #{space(6)} Given value: #{@light_green}#{inspect(value)}
    #{tab(@dark_green)} #{space(6)} #{@dark_green}#{info}
    #{tab(@dark_green)}
    """)
  end

  defp format_file_path(path), do: String.replace(path, File.cwd!(), "")

  defp tab(color), do: "#{color}┃#{@reset}"

  defp print_header_error(message, bg),
    do: IO.puts("#{bg}#{@white}  #{message}#{space_for(message)}#{@reset}")

  defp pointer_for(message) do
    message
    |> String.replace("document", "^^^^^^^^")
    |> String.replace(~r"[^\^]", " ")
  end

  defp space_for(message), do: String.duplicate(" ", @bar_size - String.length(message))
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
