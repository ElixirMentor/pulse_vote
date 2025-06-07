defmodule PulseVote.Repo do
  use Ecto.Repo,
    otp_app: :pulse_vote,
    adapter: Ecto.Adapters.Postgres
end
