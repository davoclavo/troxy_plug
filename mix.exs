defmodule Troxy.Mixfile do
  use Mix.Project

  # Project configuration
  def project do
    [app: :troxy,
     version: "0.0.1",
     elixir: "~> 1.1",
     # elixir: "~> 1.2",
     # build_embedded: Mix.env == :prod,
     # start_permanent: Mix.env == :prod,
     deps: deps,
     aliases: aliases,
     description: description,
     package: package
    ]
  end

  # An alias to run the server
  def aliases do
    # Extend the existing run task to ensure we invoke Server.start/1 afterwards
    [server: ["run", &Troxy.Server.start/1]]
  end

  # OTP Application configuration
  # Used to generate an application file
  def application do
    [applications: [:logger,
                    # :exometer_core,
                    :elixometer,
                    :exometer_influxdb,
                    :cowboy,
                    :plug,
                    :hackney
                    # :folsom
                   ]]
  end

  # Include test support modules
  # defp elixirc_paths(:test), do: ["lib", "test/support"]

  # Dependencies
  defp deps do
    [{:cowboy, "~> 1.0"},
     {:plug, "~> 1.0"},
     {:elixometer, github: "pinterest/elixometer"},
     {:exometer_influxdb, github: "travelping/exometer_influxdb"},
     {:exometer_core, "~> 1.0", override: true},
     {:lager, "3.0.2", override: true},
     {:hackney, "~> 1.4.4", override: true},
     # {:exometer, github: "Feuerlabs/exometer"},
     # {:exometer_core, "~> 1.4"},
     # {:exometer_core, git: "git://github.com/Feuerlabs/exometer_core.git", ref: "5fdd9426713a3c26cae32f644a3120711b1cdb64", override: true},
     # {:exometer, github: "PSPDFKit-labs/exometer_core"},
     # {:exometer_core, github: "Feuerlabs/exometer_core", override: true},
     # {:exometer_core, path: "../exometer_core", override: true},
     # {:meck, "0.8.2", override: true},
     # {:edown, github: "uwiger/edown", ref: "HEAD", manager: :rebar, override: true},
     # {:hackney, "~> 1.4.4", override: true},
     # {:hackney, path: "../hackney", override: true },
     # {:metrics, "~> 1.2.0", override: true },
     # {:folsom, "~> 0.8.3"},
     {:ex_doc, "~> 0.11", only: :dev}, # mix docs
     {:earmark, "~> 0.1", only: :dev},
     # {:dogma, "~> 0.1", only: :dev},
     {:credo, "~> 0.1", only: :dev},
     {:dialyxir, "~> 0.3", only: :dev}, # mix dialyzer
     {:httparrot, "~> 0.3.4", only: :test}]
  end

  defp description do
    """
    Troxy. A revolutionary proxy.
    """
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md"],
      maintainers: ["David Gomez-Urquiza"],
      # licenses: ["GPL"],
      links: %{"GitHub" => "https://github.com/davoclavo/troxy_plug",
               "Docs" => "http://hexdocs.pm/troxy_plug/"}
    ]
  end
end
