defmodule PulseVoteWeb.PollLive.Index do
  use PulseVoteWeb, :live_view

  alias PulseVote.Polls
  alias PulseVote.Polls.Poll

  on_mount {PulseVoteWeb.UserAuth, :mount_current_user}

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(PulseVote.PubSub, "polls")
    end
    
    {:ok, stream(socket, :polls, Polls.list_polls())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    poll = Polls.get_poll!(id)
    current_user = socket.assigns.current_user
    
    if Polls.can_edit_poll?(poll, current_user) do
      socket
      |> assign(:page_title, "Edit Poll")
      |> assign(:poll, poll)
    else
      socket
      |> put_flash(:error, "You can only edit polls you created")
      |> push_patch(to: ~p"/polls")
    end
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Poll")
    |> assign(:poll, %Poll{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Polls")
    |> assign(:poll, nil)
  end

  @impl true
  def handle_info({PulseVoteWeb.PollLive.FormComponent, {:saved, poll}}, socket) do
    {:noreply, stream_insert(socket, :polls, poll)}
  end

  @impl true
  def handle_info({:poll_created, poll}, socket) do
    {:noreply, stream_insert(socket, :polls, poll, at: 0)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    poll = Polls.get_poll!(id)
    current_user = socket.assigns.current_user
    
    if Polls.can_delete_poll?(poll, current_user) do
      {:ok, _} = Polls.delete_poll(poll)
      {:noreply, stream_delete(socket, :polls, poll)}
    else
      {:noreply, put_flash(socket, :error, "You can only delete polls you created")}
    end
  end
end
