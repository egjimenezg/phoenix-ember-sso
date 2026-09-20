# Phoenix + Ember: OAuth & JWT Authentication

Implements authentication for a Phoenix + Ember application using two strategies: SSO via Google OAuth 2.0/OIDC and local authentication wit
h JWT for direct username/password login.

## Running Locally

### Prerequisites

- Docker with Docker Compose
- Elixir `~> 1.15` and a compatible Erlang/OTP version
- Node.js 20 or newer with npm
- A Google OAuth client for testing Google sign-in

Configure the Google OAuth client with this authorized redirect URI:

```text
http://localhost:4000/auth/google/callback
```

### First-time setup

Start PostgreSQL from the repository root:

```bash
docker compose up -d db
```

Install dependencies and prepare the development database:

```bash
cd api
mix setup

cd ../web
npm install
```

### Start the Phoenix API

In one terminal:

```bash
cd api
export GOOGLE_CLIENT_ID="your-google-client-id"
export GOOGLE_CLIENT_SECRET="your-google-client-secret"
mix phx.server
```

The API runs at [http://localhost:4000](http://localhost:4000). Keep the credentials in environment variables and do not commit them.

### Start the Ember app

In another terminal:

```bash
cd web
npm run start
```

Open [http://localhost:4200](http://localhost:4200). Visiting `/` shows your name, email, and a **Log out** button when signed in; otherwise it redirects to `/sign-in`. The Google button starts the OIDC flow through the Phoenix API. On return, Ember reads `/api/session` with the session cookie to display the authenticated home page. Refreshing the page restores the session; logging out clears it and returns to sign-in.

### Stop PostgreSQL

From the repository root:

```bash
docker compose stop db
```

## OAuth 2.0 Key Concepts

| Concept | Role | In this project |
|---|---|---|
| **Resource Owner** | The user granting access | The person logging in via Google |
| **Client** | The app requesting access on the user's behalf | The Ember frontend |
| **Authorization Server** | Issues tokens after authenticating the user | Google (`accounts.google.com`) |
| **Resource Server** | Hosts the protected resources | The Phoenix API |
| **Authorization Grant** | Proof that the user consented | The `code` Google sends back to `/auth/google/callback` |

The flow in this project uses the **Authorization Code** grant type: Ember redirects the user to Google, Google authenticates them and redirects back with a short-lived `code`, and the Phoenix API exchanges that `code` for tokens directly with Google — keeping secrets server-side.

## SSO Authentication Flow

```mermaid
sequenceDiagram
    autonumber

    actor User
    participant Ember as Ember SPA
    participant Phoenix as Phoenix API
    participant Google as Google OIDC
    participant DB as PostgreSQL

    User->>Ember: Select "Sign in with Google"
    Ember->>Phoenix: Navigate to GET /auth/google

    Phoenix->>Phoenix: Build OIDC authorization URL
    Phoenix->>Phoenix: Store OAuth state in signed session cookie
    Phoenix-->>User: 302 redirect to Google

    User->>Google: Authenticate and grant consent
    Google-->>Phoenix: GET /auth/google/callback<br/>?code=...&state=...

    Phoenix->>Phoenix: Validate state from session
    Phoenix->>Google: Exchange authorization code for tokens
    Google-->>Phoenix: ID and access tokens
    Phoenix->>Google: Obtain verified OIDC user information
    Google-->>Phoenix: Email, given name, and family name

    Phoenix->>DB: Find user by email

    alt Existing user
        DB-->>Phoenix: Return user
    else New user
        Phoenix->>DB: Insert user
        DB-->>Phoenix: Return created user
    end

    Phoenix->>Phoenix: Delete temporary OAuth state
    Phoenix->>Phoenix: Store local user ID in signed session cookie
    Phoenix-->>User: 302 redirect to Ember

    Ember->>Phoenix: GET /api/session with session cookie
    Phoenix-->>Ember: User profile and CSRF token
    Ember->>Ember: Display authenticated home page
    User->>Ember: Select Log out
    Ember->>Phoenix: DELETE /api/session with cookie and CSRF token
    Phoenix-->>Ember: Clear session cookie and return 204
    Ember->>Ember: Clear local session and display sign-in

    Note over Ember,Phoenix: Local username/password and JWT authentication remain unimplemented.
```
