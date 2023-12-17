#!/bin/bash
HASH_FILE="hash_used.txt"
ENV_FILE=".env"
IMPL_SALT=""
REPEAT=""
# Extract IMPL_SALT from .env file
if [[ -f $ENV_FILE ]]; then
    IMPL_SALT=$(grep 'IMPL_SALT=' $ENV_FILE | cut -d '=' -f2)
else
    echo "File $ENV_FILE not found. Continue."
fi

# Check if hash_used.txt exists and compare the SALT
if [[ -f $HASH_FILE ]] && [[ $REPEAT == 'false' ]]; then
    existing_salt=$(cat $HASH_FILE)
    if [[ $IMPL_SALT == $existing_salt ]]; then
        echo "SALT matches. Exiting."
        exit 1
    fi
fi

# Parse .env file and prepare arguments
args=()
while IFS='=' read -r key value; do
    args+=(--build-arg "$key=$value")
done < $ENV_FILE

# Function to build the Docker image
build_image() {
    echo "${args[@]}"
    docker build "${args[@]}" -t optimism-stack .
    # now check if image was created
    image=$(docker images -q $IMAGE_NAME)
    if [[ -n $image ]]; then
        echo "Image $IMAGE_NAME found. Running Docker Compose..."
        echo $image > $HASH_FILE
        docker-compose -p op-stack up op-services -d
          # Write IMPL_SALT to hash_used.txt file
          if [[ $REPEAT == 'false' ]]; then
            echo $IMPL_SALT > $HASH_FILE
            echo "Stored IMPL_SALT in $HASH_FILE."
          fi
    else
        echo "Image $IMAGE_NAME not found. Exiting."
    fi
}


# Check if an argument is provided
if [ $# -eq 0 ]; then
    echo "No arguments provided. Building image..."
    build_image

fi
