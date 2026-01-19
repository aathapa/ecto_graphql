defmodule EctoGraphql.GqlObject do
  @moduledoc """
  Provides macros for generating Absinthe object and input object definitions from Ecto schemas.

  This module provides:
  * `gql_object/2-4` - Generates a complete GraphQL `object` block
  * `gql_input_object/2-4` - Generates a complete GraphQL `input_object` block

  The `gql_object` macro creates a complete GraphQL `object` block with all fields
  automatically derived from an Ecto schema. This is the recommended approach for
  quickly defining GraphQL types that mirror your Ecto schemas.

  ## Basic Usage

  Generate a complete object from an Ecto schema:

      defmodule MyAppWeb.Schema.Types do
        use Absinthe.Schema.Notation
        use EctoGraphql

        gql_object(:user, MyApp.Accounts.User)
      end

  This creates an object named `:user` with all fields from the `User` schema.

  ## Field Filtering

  ### Using `:only`

  Include only specific fields:

      gql_object(:user_public, MyApp.Accounts.User, only: [:id, :name, :email])

  ### Using `:except`

  Exclude sensitive or internal fields:

      gql_object(:user, MyApp.Accounts.User, except: [:password_hash, :recovery_token])

  ## Custom Fields

  Add custom fields or override auto-generated ones using a `do` block:

      gql_object :user, MyApp.Accounts.User do
        # Adds a new custom field
        field :full_name, :string do
          resolve fn user, _, _ ->
            {:ok, "\#{user.first_name} \#{user.last_name}"}
          end
        end

        # Adds another custom field
        field :avatar_url, :string do
          resolve fn user, _, _ ->
            {:ok, "https://avatars.example.com/\#{user.id}"}
          end
        end
      end

  ## Overriding Fields

  Fields defined in the `do` block automatically override auto-generated fields:

      gql_object :user, MyApp.Accounts.User do
        # This overrides the auto-generated :name field
        field :name, :string do
          resolve fn user, _, _ ->
            {:ok, String.upcase(user.name)}
          end
        end
      end

  ## Combining Options and Custom Fields

      gql_object :user, MyApp.Accounts.User, except: [:inserted_at, :updated_at] do
        field :created, :string do
          resolve fn user, _, _ ->
            {:ok, DateTime.to_iso8601(user.inserted_at)}
          end
        end

        field :member_since, :string do
          resolve fn user, _, _ ->
            days = DateTime.diff(DateTime.utc_now(), user.inserted_at, :day)
            {:ok, "\#{days} days"}
          end
        end
      end

  ## When to Use

  Use `gql_object` when you:
  - Want a quick, complete object definition
  - Need to exclude certain fields
  - Want to add a few custom fields to an otherwise standard object

  For more fine-grained control over field ordering or mixing fields from multiple
  schemas, use `gql_fields` instead.
  """

  @type object_opts :: [only: [atom()]] | [except: [atom()]] | []

  @doc "See `gql_object/4`."
  @spec gql_object(atom(), module()) :: Macro.t()
  defmacro gql_object(name, schema_module) do
    generate_object(name, schema_module, [], nil)
  end

  @doc "See `gql_object/4`."
  @spec gql_object(atom(), module(), object_opts() | Macro.t()) :: Macro.t()
  defmacro gql_object(name, schema_module, do: block) do
    generate_object(name, schema_module, [], block)
  end

  defmacro gql_object(name, schema_module, opts) do
    generate_object(name, schema_module, opts, nil)
  end

  @doc """
  Generates a complete Absinthe object definition from an Ecto schema.

  ## Parameters

    * `name` - The GraphQL object name (atom)
    * `schema_module` - The Ecto schema module
    * `opts` - Optional keyword list:
      * `:only` - List of field names to include (atoms)
      * `:except` - List of field names to exclude (atoms)
    * `do` block - Optional block for custom field definitions

  ## Examples

      # Basic usage - all fields
      gql_object(:user, MyApp.Accounts.User)

      # With filtering
      gql_object(:user, MyApp.Accounts.User, only: [:id, :name, :email])
      gql_object(:user, MyApp.Accounts.User, except: [:password_hash])

      # With custom fields
      gql_object :user, MyApp.Accounts.User do
        field :display_name, :string do
          resolve fn user, _, _ ->
            {:ok, String.upcase(user.name)}
          end
        end
      end

      # Combining filtering and custom fields
      gql_object :user, MyApp.Accounts.User, except: [:password_hash] do
        field :is_admin, :boolean do
          resolve fn user, _, _ ->
            {:ok, user.role == :admin}
          end
        end
      end

  ## Field Override Behavior

  When you define a field in the `do` block with the same name as an auto-generated
  field, the custom definition takes precedence. The auto-generated field is
  automatically excluded.

      gql_object :user, MyApp.Accounts.User do
        # Overrides the auto-generated :email field with custom logic
        field :email, :string do
          resolve fn user, _, _ ->
            if user.email_public do
              {:ok, user.email}
            else
              {:ok, "[hidden]"}
            end
          end
        end
      end

  """
  @spec gql_object(atom(), module(), object_opts(), Macro.t()) :: Macro.t()
  defmacro gql_object(name, schema_module, opts, do: block) do
    generate_object(name, schema_module, opts, block)
  end

  @doc "See `gql_input_object/4`."
  @spec gql_input_object(atom(), module()) :: Macro.t()
  defmacro gql_input_object(name, schema_module) do
    generate_input_object(name, schema_module, [], nil)
  end

  @doc "See `gql_input_object/4`."
  @spec gql_input_object(atom(), module(), object_opts() | Macro.t()) :: Macro.t()
  defmacro gql_input_object(name, schema_module, do: block) do
    generate_input_object(name, schema_module, [], block)
  end

  defmacro gql_input_object(name, schema_module, opts) do
    generate_input_object(name, schema_module, opts, nil)
  end

  @doc """
  Generates a complete Absinthe input object definition from an Ecto schema.

  The usage is identical to `gql_object/2-4`, but generates an `input_object` instead.

  ## Examples

      # Basic usage - all fields
      gql_input_object(:user_input, MyApp.Accounts.User)

      # With filtering
      gql_input_object(:user_input, MyApp.Accounts.User, only: [:name, :email])
      gql_input_object(:user_input, MyApp.Accounts.User, except: [:id, :inserted_at])

      # With custom fields
      gql_input_object :user_input, MyApp.Accounts.User do
        field :password_confirmation, :string
      end
  """
  @spec gql_input_object(atom(), module(), object_opts(), Macro.t()) :: Macro.t()
  defmacro gql_input_object(name, schema_module, opts, do: block) do
    generate_input_object(name, schema_module, opts, block)
  end

  defp generate_input_object(name, schema_module, opts, do_block) do
    overridden_fields = if do_block, do: extract_field_names(do_block), else: []
    filtered_opts = filter_overridden_fields(overridden_fields, opts)
    # Input objects should not include associations
    filtered_opts = Keyword.put(filtered_opts, :include_associations, false)

    quote do
      input_object(unquote(name)) do
        EctoGraphql.GqlFields.gql_fields(unquote(schema_module), unquote(filtered_opts))
        unquote(do_block)
      end
    end
  end

  defp generate_object(name, schema_module, opts, do_block) do
    overridden_fields = if do_block, do: extract_field_names(do_block), else: []
    filtered_opts = filter_overridden_fields(overridden_fields, opts)

    quote do
      object(unquote(name)) do
        EctoGraphql.GqlFields.gql_fields(unquote(schema_module), unquote(filtered_opts))
        unquote(do_block)
      end
    end
  end

  defp extract_field_names({:__block__, _, expressions}) do
    Enum.flat_map(expressions, &extract_field_names/1)
  end

  defp extract_field_names({:field, _, [name | _]}) when is_atom(name) do
    [name]
  end

  defp extract_field_names(_), do: []

  defp filter_overridden_fields(overridden_fields, opts) do
    case {Keyword.get(opts, :except), overridden_fields} do
      {nil, []} -> opts
      {nil, overridden_fields} -> Keyword.put(opts, :except, overridden_fields)
      {except, _} -> Keyword.put(opts, :except, except ++ overridden_fields)
    end
  end
end
