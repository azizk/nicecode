defmodule Mix.Tasks.JunitDialyzer do
  @moduledoc """
  Converts a dialyzer warnings file to a JUnit XML file.

  Examples:

  ```sh
  $ mix diaylizer --quiet > dialyzer_warnings.txt
  $ mix junit.dialyzer dialyzer_warnings.txt _build/test/lib/
  ```

  ```sh
  $ mix diaylizer --quiet | mix junit.dialyzer - _build/test/lib/
  ```
  """
  use Mix.Task

  @report_file_name "dialyzer-report_file_test.xml"

  @type warning :: {binary, binary, binary, binary}

  @impl true
  def run([warnings_file, dest_dir]) do
    is_lib_or_test_file? = fn path ->
      if path |> String.starts_with?(["lib/", "test/"]) and
           Path.extname(path) in [".ex", ".exs"],
         do: [path],
         else: []
    end

    umbrella_sources =
      Path.wildcard("apps/**/*.ex*")
      |> Enum.flat_map(fn path ->
        String.split(path, "/", parts: 3)
        |> List.last()
        |> then(&is_lib_or_test_file?/1)
      end)

    lib_and_test_sources =
      Stream.concat(Path.wildcard("lib/**/*.ex*"), Path.wildcard("test/**/*.ex*"))
      |> Enum.flat_map(&is_lib_or_test_file?/1)

    sources = Enum.concat(umbrella_sources, lib_and_test_sources)

    if sources == [], do: raise(RuntimeError, message: "no source files found in apps/")

    File.mkdir_p!(dest_dir)

    all_warnings =
      case warnings_file do
        "-" -> IO.read(:eof)
        _ -> File.read!(warnings_file)
      end
      |> parse_warnings()

    file_2_warnings_map = all_warnings |> Enum.group_by(fn {file_path, _, _, _} -> file_path end)

    sources
    |> Enum.map(fn source_path ->
      if warnings = file_2_warnings_map[source_path],
        do: Enum.map(warnings, &format_warning/1),
        else: format_testcase(source_path, Path.basename(source_path))
    end)
    |> to_xml_iodata(all_warnings)
    |> then(&File.write!(Path.join(dest_dir, @report_file_name, &1)))
  end

  def run(_),
    do: raise(ArgumentError, message: "missing source file and/or destination dir argument/s")

  @spec format_warning(warning) :: iodata
  def format_warning({file_name, line, warning_code, msg}) do
    tag = ~s'  <failure message="#{file_name}:#{line}">#{msg}</failure>'
    format_testcase(file_name, warning_code, tag)
  end

  @spec format_testcase(iodata, iodata, iodata | nil) :: iodata
  def format_testcase(classname, name, content \\ nil) do
    tag = ~s'<testcase classname="#{classname}" name="#{name}"'

    if content,
      do: [tag, ">", content, "</testcase>"],
      else: [tag, "/>"]
  end

  @tstamp DateTime.utc_now() |> DateTime.to_iso8601()

  @spec to_xml_iodata(iodata, [warning]) :: iodata
  def to_xml_iodata(testcases, failures) do
    num_failures = length(failures)
    num_tests = length(testcases)

    [
      """
      <?xml version="1.0"?>
      <testsuites>
      <testsuite failures="#{num_failures}" name="JUnitDialyzer" tests="#{num_tests}">
      <properties><property name="date" value="#{@tstamp}"/></properties>
      """,
      testcases,
      """
      </testsuite>
      </testsuites>
      """
    ]
  end

  @rx_separator ~r"_{80}\n"
  @rx_file_line ~r"^(.*?):(\d+):(.+)"

  @spec parse_warnings(binary) :: [warning]
  def parse_warnings(file) do
    Regex.split(@rx_separator, file)
    |> Enum.flat_map(fn warning ->
      Regex.run(@rx_file_line, warning, return: :index)
      |> case do
        [{0, end_idx} | indices] ->
          [file_name, line, warning_code] =
            Enum.map(indices, fn {x, y} -> warning |> String.slice(x..(x + y - 1)) end)

          msg = warning |> String.slice((end_idx + 1)..-1)
          [{file_name, line, warning_code, msg}]

        nil ->
          []
      end
    end)
  end
end
