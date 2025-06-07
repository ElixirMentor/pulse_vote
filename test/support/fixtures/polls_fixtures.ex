defmodule PulseVote.PollsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `PulseVote.Polls` context.
  """

  @doc """
  Generate a poll.
  """
  def poll_fixture(attrs \\ %{}) do
    {:ok, poll} =
      attrs
      |> Enum.into(%{
        description: "some description",
        title: "some title"
      })
      |> PulseVote.Polls.create_poll()

    poll
  end
end
