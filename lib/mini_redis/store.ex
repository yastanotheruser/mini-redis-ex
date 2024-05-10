defmodule MiniRedis.Store do
  @callback set(key :: term, value :: term) :: :ok | {:error, any}
  @callback get(key :: term) :: {:ok, value :: term} | {:error, any}
  @callback delete(keys :: [term]) :: {:ok, count :: non_neg_integer} | {:error, any}
  @callback child_spec(arg :: any) :: Supervisor.child_spec()
  @optional_callbacks child_spec: 1

  @spec set(key :: term, value :: term) :: :ok | {:error, any}
  def set(key, value), do: impl_module().set(key, value)

  @spec get(key :: term) :: {:ok, value :: term} | {:error, any}
  def get(key), do: impl_module().get(key)

  @spec delete(keys :: [term]) :: {:ok, count :: non_neg_integer} | {:error, any}
  def delete(keys) when is_list(keys), do: impl_module().delete(keys)

  @spec impl :: {module, arg :: any} | module
  def impl, do: Application.fetch_env!(:mini_redis, :store)

  @spec impl_module() :: module
  def impl_module do
    case impl() do
      mod when is_atom(mod) -> mod
      {mod, _arg} when is_atom(mod) -> mod
    end
  end

  @spec has_child_spec?() :: boolean
  def has_child_spec? do
    impl_module()
    |> Code.ensure_loaded!()
    |> function_exported?(:child_spec, 1)
  end
end
