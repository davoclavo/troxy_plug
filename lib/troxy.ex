defmodule Troxy do
  defmacro __using__(_) do
    quote location: :keep do
      use Troxy.Interfaces.Plug
    end
  end

  # def start do
  #   Troxy.Supervisor.start_link
  # end
end
