defmodule Troxy.Metrics.Elixometer do
  def decrement_counter(name, value \\ 1) do
    Elixometer.update_counter(elixometer_name(name), -value)
  end

  def decrement_spiral(name, value \\ 1) do
    Elixometer.update_spiral(elixometer_name(name), -value)
  end

  def delete(name) do
    :exometer.delete(name)
  end

  def get_value(name) do
    Elixometer.get_metric_value(elixometer_name(name))
  end

  def increment_counter(name, value \\ 1) do
    Elixometer.update_counter(elixometer_name(name), value)
  end

  def increment_spiral(name, value \\ 1) do
    Elixometer.update_spiral(elixometer_name(name), value)
  end

  def new(type, name) do
    :exometer.ensure(name, type, [])
  end

  def sample(name) do
    :exometer.sample(elixometer_name(name))
  end

  def update_gauge(name, value) do
    Elixometer.update_gauge(elixometer_name(name), value)
  end

  def update_histogram(name, value) do
    Elixometer.update_histogram(elixometer_name(name), value)
  end

  def update_meter(name, value) do
    Elixometer.update_meter(elixometer_name(name), value)
  end

  def elixometer_name(name) do
    name |> Enum.join(".")
  end
end


# TODO: Attempt to only use :exometer, not Elixometer
# This is a copy of erlang_metrics/elixometer_
defmodule Troxy.Metrics.Exometer do
  require Logger

  @spec notify(any(), any(), any()) :: :ok | {:error, term()}
  def notify(name, op, type) do
    :exometer.update_or_create(name, op, type, [])
  end

  @spec new(atom, binary) :: :ok | {:error, term()}
  def new(type, name) do
    log(:new, type, name)
    # TODO: Fix this, it seems that the tables arent initialized yet
    :exometer.ensure(name, type, [])
  end

  def delete(name) do
    :exometer.delete(name)
  end

  @spec increment_counter(any(), pos_integer()) ::  :ok | {:error, term()}
  def increment_counter(name, value \\ 1) do
    log(:count, name, value)
    notify(name, value, :counter)
  end

  @spec decrement_counter(any(), pos_integer()) ::  :ok | {:error, term()}
  def decrement_counter(name, value \\ 1) do
    log(:count, name, -value)
    notify(name, -value, :counter)
  end

  def increment_spiral(name, value \\ 1) do
    log(:spiral, name, value)
    notify(name, value, :spiral)
  end

  def decrement_spiral(name, value \\ 1) do
    log(:spiral, name, -value)
    notify(name, -value, :spiral)
  end


  def update_histogram(name, fun) when is_function(fun, 0) do
    begin = :os.timestamp()
    result = fun.()
    duration = div(:timer.now_diff(:os.timestamp(), begin), 1000)
    log(:measure, name, [:io_lib_format.fwrite_g(duration), ?m, ?s])
    case notify(name, duration, :histogram) do
      :ok -> result;
      error -> throw(error)
    end
  end

  def update_histogram(name, value) when is_number(value) do
    log(:measure, name, value)
    notify(name, value, :histogram)
  end

  @spec update_gauge(any(), number()) ::  :ok | {:error, term()}
  def update_gauge(name, value) do
    log(:sample, name, value)
    notify(name, value, :gauge)
  end

  @spec update_meter(any(), number()) ::  :ok | {:error, term()}
  def update_meter(name, value) do
    log(:sample, name, value)
    notify(name, value, :meter)
  end

   defp log(type, name, value) do
    Logger.info(fn ->
      [inspect(type), ?%, inspect(name), ?|, inspect(value)]
    end)
    :ok
   end

end
