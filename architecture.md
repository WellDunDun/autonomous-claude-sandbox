# Cloudflare Sandbox Architecture

Technical architecture diagram showing how Claude Code runs in Cloudflare Sandbox containers.

## System Architecture

```mermaid
flowchart TB
    subgraph Client["Client"]
        REQ[/"HTTP Request<br/>POST /execute"/]
    end

    subgraph Cloudflare["Cloudflare Edge"]
        subgraph Worker["Cloudflare Worker"]
            AUTH["Auth Validation"]
            ROUTER["Request Router"]
        end

        subgraph DO["Durable Object"]
            LIFECYCLE["Sandbox Lifecycle<br/>Manager"]
        end

        subgraph Container["Sandbox Container"]
            CLI["Claude Code CLI<br/>claude -p 'task'<br/>--permission-mode acceptEdits"]
        end

        subgraph Storage["R2 Storage"]
            BUCKET[("R2 Bucket<br/>Task Results")]
        end
    end

    subgraph External["External Services"]
        ANTHROPIC[("Anthropic API<br/>Claude Authentication")]
    end

    %% Request Flow
    REQ -->|"1. POST /execute<br/>+ auth token"| AUTH
    AUTH -->|"2. Validate"| ROUTER
    ROUTER -->|"3. Get/Create<br/>Sandbox"| LIFECYCLE
    LIFECYCLE -->|"4. Start Container"| CLI
    CLI <-->|"5. Authenticate &<br/>Execute Tasks"| ANTHROPIC
    CLI -->|"6. Store Result"| BUCKET
    BUCKET -->|"7. Return Response"| REQ

    %% Styling
    classDef client fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#0d47a1
    classDef worker fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#e65100
    classDef durable fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#4a148c
    classDef container fill:#e8f5e9,stroke:#388e3c,stroke-width:2px,color:#1b5e20
    classDef storage fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#880e4f
    classDef external fill:#e0f2f1,stroke:#00796b,stroke-width:2px,color:#004d40

    class REQ client
    class AUTH,ROUTER worker
    class LIFECYCLE durable
    class CLI container
    class BUCKET storage
    class ANTHROPIC external
```

## Request Flow Sequence

```mermaid
sequenceDiagram
    autonumber
    participant C as Client
    participant W as Cloudflare Worker
    participant DO as Durable Object
    participant S as Sandbox Container
    participant CC as Claude Code CLI
    participant A as Anthropic API
    participant R2 as R2 Bucket

    C->>W: POST /execute {task, auth_token}
    W->>W: Validate auth token
    W->>DO: Get or create sandbox
    DO->>S: Start isolated container
    S->>CC: Run claude -p "task" --permission-mode acceptEdits
    CC->>A: Authenticate with OAuth token
    A-->>CC: Authentication confirmed
    CC->>CC: Execute AI task
    CC-->>S: Task result
    S->>R2: Store result
    R2-->>W: Confirm storage
    W-->>C: Return response with result
```

## Key Architecture Principles

### Isolation
Each task runs in its own isolated sandbox container, ensuring:
- Complete process isolation between tasks
- Clean environment for each execution
- No cross-contamination of state

### Security
Multiple layers of authentication and authorization:
- **API Auth Token**: Validates incoming requests at the Worker level
- **OAuth Token**: Claude Code authenticates with Anthropic API
- **Container Isolation**: Sandboxed execution environment

### Persistence
Results are durably stored for reliability:
- **R2 Bucket**: Task results stored for later retrieval
- **Durable Objects**: Manage sandbox lifecycle and state
- **Idempotent Operations**: Safe retry behavior

## Component Responsibilities

| Component | Responsibility |
|-----------|----------------|
| **Client** | Initiates requests with task definition and authentication |
| **Worker** | Entry point, auth validation, request routing |
| **Durable Object** | Manages sandbox lifecycle, ensures single instance per task |
| **Sandbox Container** | Isolated execution environment for Claude Code |
| **Claude Code CLI** | Executes AI tasks with controlled permissions |
| **R2 Bucket** | Persistent storage for task results |
| **Anthropic API** | Provides Claude AI capabilities via authenticated access |

## Data Flow Summary

```
Client Request
    |
    v
[Worker: Auth + Routing]
    |
    v
[Durable Object: Lifecycle]
    |
    v
[Sandbox: Isolated Container]
    |
    +---> [Claude Code] <---> [Anthropic API]
    |
    v
[R2: Store Results]
    |
    v
Response to Client
```
