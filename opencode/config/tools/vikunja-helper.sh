#!/usr/bin/env bash
set -euo pipefail

# Vikunja API helper for OpenCode
# This script handles all direct API communication with Vikunja.
# It is called by the OpenCode custom tool wrapper (vikunja.ts).

CREDS_FILE="${HOME}/.local/share/vikunja/credentials"

usage() {
    cat <<EOF
Usage: vikunja-helper <command> [args...]

Commands:
  status                              Check if credentials are configured and valid
  list_projects                       List all projects
  list_tasks [project_id]             List tasks (optionally filtered by project)
  get_task <id>                       Get a specific task by ID
  create_task <project_id> <json>     Create a new task in a project
  update_task <id> <json>             Update an existing task
  list_labels                         List all labels
  create_label <title> [hex_color]    Create a new label (title required; optional hex_color like ff0000)
  bulk_update_labels <task_id> <json> Replace all labels on a task via POST /tasks/{taskID}/labels/bulk
  list_views <project_id>             List all views for a project
  list_buckets <project_id> <view_id> List all buckets in a kanban view
  get_view <project_id> <view_id>     Get tasks from a view (for kanban: returns buckets with tasks)
  move_task_bucket <project_id> <view_id> <bucket_id> <task_id>
                                      Move a task into a bucket (column) within a view
  delete_task <id>                    Delete a task
EOF
    exit 1
}

load_creds() {
    if [[ ! -f "$CREDS_FILE" ]]; then
        echo '{"error": "not_configured", "message": "Vikunja credentials not configured. Run opencode-setup-vikunja first."}' >&2
        return 1
    fi

    # shellcheck source=/dev/null
    source "$CREDS_FILE"

    if [[ -z "${VIKUNJA_BASE_URL:-}" || -z "${VIKUNJA_API_TOKEN:-}" ]]; then
        echo '{"error": "invalid_config", "message": "Credentials file is missing required values."}' >&2
        return 1
    fi
}

api_call() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    local curl_opts=(
        -s -S
        -H "Authorization: Bearer ${VIKUNJA_API_TOKEN}"
        -H "Content-Type: application/json"
        -H "Accept: application/json"
    )

    local url
    url="${VIKUNJA_BASE_URL%/}/api/v1${endpoint}"

    if [[ -n "$data" ]]; then
        curl "${curl_opts[@]}" -X "$method" -d "$data" "$url"
    else
        curl "${curl_opts[@]}" -X "$method" "$url"
    fi
}

cmd_status() {
    if [[ ! -f "$CREDS_FILE" ]]; then
        echo '{"configured": false, "message": "Credentials file not found. Run opencode-setup-vikunja."}'
        return 0
    fi

    if ! load_creds >/dev/null 2>&1; then
        echo '{"configured": true, "valid": false, "message": "Credentials file exists but is invalid."}'
        return 0
    fi

    local response
    if response=$(api_call GET "/user" 2>/dev/null); then
        if echo "$response" | grep -q '"id"' 2>/dev/null; then
            local username
            username=$(echo "$response" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('username','unknown'))" 2>/dev/null || echo "unknown")
            echo "{\"configured\": true, \"valid\": true, \"user\": \"${username}\"}"
        else
            echo '{"configured": true, "valid": false, "message": "Invalid API token or base URL"}'
        fi
    else
        echo '{"configured": true, "valid": false, "message": "Failed to connect to Vikunja API"}'
    fi
}

cmd_list_projects() {
    load_creds
    api_call GET "/projects"
}

cmd_list_tasks() {
    load_creds
    local project_id="${1:-}"

    if [[ -n "$project_id" ]]; then
        api_call GET "/projects/${project_id}/tasks"
    else
        api_call GET "/tasks"
    fi
}

cmd_get_task() {
    load_creds
    local task_id="$1"
    api_call GET "/tasks/${task_id}"
}

cmd_create_task() {
    load_creds
    local project_id="$1"
    local json_data="$2"
    api_call PUT "/projects/${project_id}/tasks" "$json_data"
}

cmd_update_task() {
    load_creds
    local task_id="$1"
    local json_data="$2"
    api_call POST "/tasks/${task_id}" "$json_data"
}

cmd_delete_task() {
    load_creds
    local task_id="$1"
    api_call DELETE "/tasks/${task_id}"
}

cmd_list_labels() {
    load_creds
    api_call GET "/labels"
}

cmd_create_label() {
    load_creds
    local title="$1"
    local color="${2:-}"
    local payload
    if [[ -n "$color" ]]; then
        payload=$(python3 -c "import sys,json; print(json.dumps({'title':sys.argv[1],'hex_color':sys.argv[2]}))" "$title" "$color")
    else
        payload=$(python3 -c "import sys,json; print(json.dumps({'title':sys.argv[1]}))" "$title")
    fi
    api_call PUT "/labels" "$payload"
}

cmd_bulk_update_labels() {
    load_creds
    local task_id="$1"
    local json_data="$2"
    api_call POST "/tasks/${task_id}/labels/bulk" "$json_data"
}

cmd_list_views() {
    load_creds
    local project_id="$1"
    api_call GET "/projects/${project_id}/views"
}

cmd_list_buckets() {
    load_creds
    local project_id="$1"
    local view_id="$2"
    api_call GET "/projects/${project_id}/views/${view_id}/buckets"
}

cmd_get_view() {
    load_creds
    local project_id="$1"
    local view_id="$2"
    api_call GET "/projects/${project_id}/views/${view_id}/tasks"
}

cmd_move_task_bucket() {
    load_creds
    local project_id="$1"
    local view_id="$2"
    local bucket_id="$3"
    local task_id="$4"
    local payload
    payload=$(python3 -c "import sys,json; print(json.dumps({'task_id':int(sys.argv[1])}))" "$task_id")
    api_call POST "/projects/${project_id}/views/${view_id}/buckets/${bucket_id}/tasks" "$payload"
}

main() {
    if [[ $# -lt 1 ]]; then
        usage
    fi

    local cmd="$1"
    shift

    case "$cmd" in
        status)
            cmd_status
            ;;
        list_projects)
            cmd_list_projects
            ;;
        list_tasks)
            cmd_list_tasks "$@"
            ;;
        get_task)
            if [[ $# -lt 1 ]]; then
                echo "Usage: get_task <task_id>" >&2
                exit 1
            fi
            cmd_get_task "$1"
            ;;
        create_task)
            if [[ $# -lt 2 ]]; then
                echo "Usage: create_task <project_id> <json_data>" >&2
                exit 1
            fi
            cmd_create_task "$1" "$2"
            ;;
        update_task)
            if [[ $# -lt 2 ]]; then
                echo "Usage: update_task <task_id> <json_data>" >&2
                exit 1
            fi
            cmd_update_task "$1" "$2"
            ;;
        delete_task)
            if [[ $# -lt 1 ]]; then
                echo "Usage: delete_task <task_id>" >&2
                exit 1
            fi
            cmd_delete_task "$1"
            ;;
        list_labels)
            cmd_list_labels
            ;;
        create_label)
            if [[ $# -lt 1 ]]; then
                echo "Usage: create_label <title> [hex_color]" >&2
                exit 1
            fi
            cmd_create_label "$1" "${2:-}"
            ;;
        bulk_update_labels)
            if [[ $# -lt 2 ]]; then
                echo "Usage: bulk_update_labels <task_id> <json_data>" >&2
                exit 1
            fi
            cmd_bulk_update_labels "$1" "$2"
            ;;
        list_views)
            if [[ $# -lt 1 ]]; then
                echo "Usage: list_views <project_id>" >&2
                exit 1
            fi
            cmd_list_views "$1"
            ;;
        list_buckets)
            if [[ $# -lt 2 ]]; then
                echo "Usage: list_buckets <project_id> <view_id>" >&2
                exit 1
            fi
            cmd_list_buckets "$1" "$2"
            ;;
        get_view)
            if [[ $# -lt 2 ]]; then
                echo "Usage: get_view <project_id> <view_id>" >&2
                exit 1
            fi
            cmd_get_view "$1" "$2"
            ;;
        move_task_bucket)
            if [[ $# -lt 4 ]]; then
                echo "Usage: move_task_bucket <project_id> <view_id> <bucket_id> <task_id>" >&2
                exit 1
            fi
            cmd_move_task_bucket "$1" "$2" "$3" "$4"
            ;;
        -h|--help|help)
            usage
            ;;
        *)
            echo "Unknown command: $cmd" >&2
            usage
            ;;
    esac
}

main "$@"
