# Phoenix + Ember: OAuth & JWT Authentication

Implements authentication for a Phoenix + Ember application using two strategies: SSO via Google OAuth 2.0/OIDC and local authentication with JWT for direct username/password login.

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
    Phoenix-->>User: 200 JSON containing user profile

    Note over Ember,Phoenix: Not implemented yet:<br/>callback redirect to Ember,<br/>application session or JWT issuance,<br/>and authenticated API requests
```
