defmodule PulseVote.Polls do
  @moduledoc """
  The Polls context.
  """

  import Ecto.Query, warn: false
  alias PulseVote.Repo

  alias PulseVote.Polls.Poll
  alias PulseVote.Polls.Vote

  @doc """
  Returns the list of polls.

  ## Examples

      iex> list_polls()
      [%Poll{}, ...]

  """
  def list_polls do
    Repo.all(Poll)
  end

  @doc """
  Gets a single poll.

  Raises if the Poll does not exist.

  ## Examples

      iex> get_poll!(123)
      %Poll{}

  """
  def get_poll!(id), do: Repo.get!(Poll, id)

  @doc """
  Creates a poll.

  ## Examples

      iex> create_poll(%{field: value})
      {:ok, %Poll{}}

      iex> create_poll(%{field: bad_value})
      {:error, ...}

  """
  def create_poll(attrs \\ %{}) do
    %Poll{}
    |> Poll.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a poll.

  ## Examples

      iex> update_poll(poll, %{field: new_value})
      {:ok, %Poll{}}

      iex> update_poll(poll, %{field: bad_value})
      {:error, ...}

  """
  def update_poll(%Poll{} = poll, attrs) do
    poll
    |> Poll.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Poll.

  ## Examples

      iex> delete_poll(poll)
      {:ok, %Poll{}}

      iex> delete_poll(poll)
      {:error, ...}

  """
  def delete_poll(%Poll{} = poll) do
    Repo.delete(poll)
  end

  @doc """
  Returns a data structure for tracking poll changes.

  ## Examples

      iex> change_poll(poll)
      %Todo{...}

  """
  def change_poll(%Poll{} = poll, attrs \\ %{}) do
    Poll.changeset(poll, attrs)
  end

  @doc """
  Casts a vote for a poll option.
  """
  def cast_vote(poll_id, option_index, user_id) do
    %Vote{}
    |> Vote.changeset(%{
      poll_id: poll_id,
      option_index: option_index,
      user_id: user_id
    })
    |> Repo.insert()
    |> case do
      {:ok, vote} ->
        # Update the vote count in the poll
        poll = get_poll!(poll_id)
        updated_options = update_option_vote_count(poll.options, option_index, 1)
        update_poll(poll, %{options: updated_options})
        {:ok, vote}
      
      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Gets a user's vote for a specific poll.
  """
  def get_user_vote(poll_id, user_id) do
    Repo.get_by(Vote, poll_id: poll_id, user_id: user_id)
  end

  @doc """
  Gets the total number of votes for a poll.
  """
  def get_total_votes(poll_id) do
    from(v in Vote, where: v.poll_id == ^poll_id, select: count(v.id))
    |> Repo.one()
  end

  defp update_option_vote_count(options, option_index, increment) do
    options
    |> Enum.with_index()
    |> Enum.map(fn {option, index} ->
      if index == option_index do
        # Convert to map for the changeset
        option
        |> Map.from_struct()
        |> Map.put(:vote_count, option.vote_count + increment)
      else
        # Convert to map for the changeset
        Map.from_struct(option)
      end
    end)
  end
end
