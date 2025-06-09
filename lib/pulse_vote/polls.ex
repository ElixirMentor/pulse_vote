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

  def create_poll_for_user(attrs \\ %{}, user) do
    attrs = Map.put(attrs, "user_id", user.id)
    
    case create_poll(attrs) do
      {:ok, poll} = result ->
        # Broadcast that a new poll was created
        Phoenix.PubSub.broadcast(
          PulseVote.PubSub,
          "polls",
          {:poll_created, poll}
        )
        result
        
      error ->
        error
    end
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
    # Check if user already has a vote (for changing votes)
    existing_vote = get_user_vote(poll_id, user_id)
    
    result = if existing_vote do
      # User is changing their vote
      change_vote(existing_vote, option_index)
    else
      # User is voting for the first time
      %Vote{}
      |> Vote.changeset(%{
        poll_id: poll_id,
        option_index: option_index,
        user_id: user_id
      })
      |> Repo.insert()
    end
    
    case result do
      {:ok, vote} ->
        # Recalculate vote counts from actual votes in database
        recalculate_poll_vote_counts(poll_id)
        
        # Broadcast the update to all subscribers
        broadcast_poll_update(poll_id)
        
        {:ok, vote}
      
      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp change_vote(existing_vote, new_option_index) do
    existing_vote
    |> Vote.changeset(%{option_index: new_option_index})
    |> Repo.update()
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
        # Convert to map if struct, then update the vote count
        option_map = if is_struct(option), do: Map.from_struct(option), else: option
        Map.put(option_map, :vote_count, option_map.vote_count + increment)
      else
        # Convert to map if struct for consistency
        if is_struct(option), do: Map.from_struct(option), else: option
      end
    end)
  end

  @doc """
  Checks if a user can edit a poll (only the creator can edit).
  """
  def can_edit_poll?(%Poll{user_id: user_id}, %{id: current_user_id}) do
    user_id == current_user_id
  end
  def can_edit_poll?(_, _), do: false

  @doc """
  Checks if a user can delete a poll (only the creator can delete).
  """
  def can_delete_poll?(%Poll{user_id: user_id}, %{id: current_user_id}) do
    user_id == current_user_id
  end
  def can_delete_poll?(_, _), do: false

  defp recalculate_poll_vote_counts(poll_id) do
    # Get the poll and all votes for this poll
    poll = get_poll!(poll_id)
    votes = Repo.all(from(v in Vote, where: v.poll_id == ^poll_id))
    
    # Count votes for each option
    vote_counts = votes
    |> Enum.group_by(& &1.option_index)
    |> Enum.map(fn {option_index, votes_list} -> {option_index, length(votes_list)} end)
    |> Map.new()
    
    # Update the poll options with correct vote counts
    updated_options = poll.options
    |> Enum.with_index()
    |> Enum.map(fn {option, index} ->
      vote_count = Map.get(vote_counts, index, 0)
      option_map = if is_struct(option), do: Map.from_struct(option), else: option
      Map.put(option_map, :vote_count, vote_count)
    end)
    
    update_poll(poll, %{options: updated_options})
  end

  defp broadcast_poll_update(poll_id) do
    Phoenix.PubSub.broadcast(
      PulseVote.PubSub,
      "poll:#{poll_id}",
      {:poll_updated, poll_id}
    )
  end
end
