defmodule Troxy.Mixfile do
  use Mix.Project

  # Project configuration
  def project do
    [app: :troxy,
     version: "0.0.1",
     elixir: "~> 1.1",
     deps: deps,
     aliases: aliases]
  end

  # An alias to run the server
  def aliases do
    # Extend the existing run task to ensure we invoke Server.start/1 afterwards
    [serve: ["run", &Server.start/1]]
  end

  # OTP Application configuration
  # Used to generate an application file
  def application do
    [applications: [:logger,
                    :cowboy,
                    :plug,
                    :hackney]]
  end

  # Dependencies
  defp deps do
    [{:cowboy, "~> 1.0"},
     {:plug, "~> 1.0"},
     {:hackney, "~> 1.1"}]
  end
end
