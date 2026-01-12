defmodule ExampleWeb.Graphql.Accounts.Resolvers do
  alias Example.Accounts

  @moduledoc """
  GraphQL resolvers for the Accounts context.
  """

  @doc """
  Lists all users.
  """
  def list_users(_parent, _args, _resolution) do
    {:ok, Accounts.list_users()}
  end

  @doc """
  Gets a single user.
  """
  def get_user(_parent, %{id: id}, _resolution) do
    Accounts.get_user!(id)
  end

  @doc """
  Creates a user.
  """
  def create_user(_parent, args, _resolution) do
    Accounts.create_user(args)
  end

  @doc """
  Updates a user.
  """
  def update_user(_parent, %{id: id} = args, _resolution) do
    user = Accounts.get_user!(id)
    Accounts.update_user(user, args)
  end
end
