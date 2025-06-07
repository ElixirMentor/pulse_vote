# PulseVote

A real-time polling application built with Phoenix LiveView that allows users to create polls, vote, and see live results.

## Features

- **User Authentication**: Register and login with email/password
- **Poll Creation**: Create polls with multiple options
- **Real-time Voting**: Vote on polls with instant results updates
- **Vote Changing**: Change your vote after casting it
- **Live Results**: See voting results update in real-time across all connected users
- **Results Toggle**: Non-voters can preview results before voting
- **Responsive Design**: Clean, mobile-friendly interface using Tailwind CSS

## Getting Started

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Usage

1. **Create an Account**: Register with your email and password
2. **Create a Poll**: Click "New Poll" and add your question with at least 2 options
3. **Share and Vote**: Share the poll link with others to collect votes
4. **View Results**: See real-time results with vote counts and percentages
5. **Change Votes**: Users can change their vote at any time

## Technology Stack

- **Phoenix Framework**: Web framework for Elixir
- **Phoenix LiveView**: Real-time, server-rendered UI
- **PostgreSQL**: Database for storing polls and votes
- **Tailwind CSS**: Utility-first CSS framework
- **Phoenix PubSub**: Real-time communication between users

## Database Schema

- **Users**: Email authentication with secure password hashing
- **Polls**: Title, description, embedded options with vote counts
- **Votes**: User votes linked to specific poll options

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).
