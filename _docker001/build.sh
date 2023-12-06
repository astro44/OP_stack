#!/bin/bash

# Parse .env file and prepare arguments
args=()
while IFS='=' read -r key value; do
    args+=(--build-arg "$key=$value")
done < .env

# Function to build the Docker image
build_image() {
    echo "${args[@]}"
    docker build "${args[@]}" -t optimism-env .
}

# Function to run the Docker container
run_container() {
    # Convert build args to environment variables for docker run
    env_args=()
    while IFS='=' read -r key value; do
        env_args+=(-e "$key=$value")
    done < .env

    echo "Running container with environment variables: ${env_args[@]}"
    docker run -it "${env_args[@]}" --name op_stacker optimism-env /bin/bash
}

# Check if an argument is provided
if [ $# -eq 0 ]; then
    echo "No arguments provided. Building image..."
    build_image
else
    echo "Arguments provided. Running container..."
    run_container "$@"
fi

# docker run -d --name op_stacker optimism-env
# docker exec -it op_stacker /bin/bash
# docker run -it --name op_stacker2 optimism-env /bin/bash