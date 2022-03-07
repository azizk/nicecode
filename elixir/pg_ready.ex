defmodule Mix.Tasks.PgReady do
  @vsn 1
  @author "Aziz Köksal"
  @license "MIT"

  @moduledoc """
  Use this Mix task to check for the configured database connection or
  to quickly set one up using Docker to run or test your Elixir app.

  **Version:** #{@vsn}
  **Author:** #{@author}
  **License:** #{@license}
  """
  @shortdoc "Ensures that a database is running."

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    [app_str, repo_str | _] = args
    app = String.to_existing_atom(app_str)
    repo = Module.concat([repo_str])
    pg_image = Enum.at(args, 2)

    case ready_database(app: app, repo: repo, pg_image: pg_image) do
      false -> "Warning: No database ready or available!"
      {:ok, config} -> "Database ready at: #{inspect(Enum.to_list(config))}"
      {:error, e} -> exit("Error: #{e}")
    end
    |> IO.puts()
  end

  @doc "Calls `pg_isready` to check for the status of the database."
  @spec pg_isready(keyword | map) :: {binary, {Collectable.t(), non_neg_integer}}
  def pg_isready(opts) do
    args =
      [
        opts[:h] && ["-h", opts[:h]],
        opts[:p] && ["-p", "#{opts[:p]}"],
        opts[:d] && ["-d", opts[:d]],
        opts[:U] && ["-U", opts[:U]],
        opts[:t] && ["-t", "#{opts[:t]}"],
        opts[:q] && ["-q"]
      ]
      |> Enum.flat_map(&((&1 && &1) || []))

    cmd = "pg_isready #{Enum.join(args, " ")}"
    opts[:print] && IO.puts(cmd)

    {cmd, System.cmd("pg_isready", args)}
  end

  def read_config(opts) do
    repo_conf = Application.get_env(opts[:app], opts[:repo])

    if repo_conf == nil,
      do: exit("application `:#{opts[:app]}` doesn't seem to be defined/configured")

    if url = repo_conf[:url] do
      parse_userinfo = fn str ->
        destructure([u, p], String.split(str, ":", parts: 2))
        [username: u] ++ ((p && [password: p]) || [])
      end

      overrides =
        URI.parse(url)
        |> Map.from_struct()
        |> Enum.reduce([], fn
          {:host, host}, acc -> put_in(acc[:hostname], host)
          {:port, port}, acc -> put_in(acc[:port], port)
          {:path, "/" <> database}, acc -> put_in(acc[:database], database)
          {:userinfo, "" <> userinfo}, acc -> Keyword.merge(acc, parse_userinfo.(userinfo))
          _, acc -> acc
        end)

      Keyword.merge(repo_conf, overrides)
    else
      repo_conf
    end
  end

  @doc "Checks whether the database is online and suggests to start one if not."
  @spec ready_database(keyword | map) :: {:ok, map} | {:error, binary} | false
  def ready_database(opts) do
    repo_conf = read_config(opts)
    repo_conf = Keyword.put_new(repo_conf, :port, 54321)

    {cmd, {ret_text, ret_code}} = pg_isready(h: repo_conf[:hostname], p: repo_conf[:port])

    if ret_code == 0 do
      {:ok, Keyword.take(repo_conf, [:hostname, :port, :database]) |> Map.new()}
    else
      IO.puts(cmd)
      IO.write("> #{ret_text}")
      start_database?(repo_conf, opts)
    end
  end

  @yes_rx ~r/^(y(es)?|\s*)$/i

  @doc "Suggests to start a database using Docker."
  @spec start_database?(keyword, keyword | map) :: {:ok, map} | {:error, binary} | false
  def start_database?(repo_conf, opts) do
    hostname = opts[:hostname] || "127.0.0.1"

    container_name =
      repo_conf[:container_name] || opts[:container_name] || "#{opts[:app]}_pg_ready"

    unless match?({_, 0}, docker(["ps"])),
      do: exit("Error: the docker daemon is not running!")

    container_state =
      with {text, 0} <- docker(["inspect", container_name]),
           [%{"State" => state}] <- Jason.decode!(text) do
        state
      else
        _ -> nil
      end

    command_return =
      cond do
        System.find_executable("docker") == nil ->
          :no_docker

        container_state["Restarting"] ->
          IO.puts("Container `#{container_name}` is restarting!")
          {"", 0}

        container_state["Running"] == false ->
          input =
            IO.gets("""
            Database `#{container_name}` container is stopped! Restart?
            (Y/n) \
            """)

          if input =~ @yes_rx do
            docker(["start", container_name])
          else
            :dont_start
          end

        container_state ->
          exit("A container named `#{container_name}` already exists!")

        :else ->
          args =
            [
              "run",
              "-d",
              ["--name", container_name],
              ["-p", "#{hostname}:#{repo_conf[:port]}:5432"],
              ["-e", "POSTGRES_PASSWORD=#{repo_conf[:password] || "postgres"}"],
              "postgres:#{opts[:pg_image] || "alpine"}"
            ]
            |> Enum.flat_map(&((is_list(&1) && &1) || [&1]))

          input =
            IO.gets("""
            Database is not running! Start one with Docker?
              $ #{["docker ", Enum.join(args, " ")]}
            (Y/n) \
            """)

          if input =~ @yes_rx do
            docker(args)
          else
            :dont_start
          end
      end

    with {_, true} <- {:exe?, command_return != :no_docker},
         {_, true} <- {:start?, command_return != :dont_start},
         {_, 0} <- command_return,
         :ok <- Process.sleep(2000),
         {_cmd, {_stdout, _status} = ret} <-
           pg_isready(h: hostname, p: repo_conf[:port], t: 10),
         {_stdout, 0} <- ret do
      {:ok, %{hostname: hostname, port: repo_conf[:port], database: repo_conf[:database]}}
    else
      {:start?, _} -> false
      {:exe?, _} -> {:error, "No docker executable found!"}
      {text, _} -> {:error, text}
    end
  end

  defp docker(args), do: System.cmd("docker", args, stderr_to_stdout: true)
end
