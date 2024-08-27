#!/bin/bash

# Define the directory containing the PDF files
# directory="/path/to/your/pdf_directory"
directory="./data"

# Define the target URL for the upload
upload_url="http://localhost:8081/documents"

# Flag to check if any files are found
found_files=false

# Loop through each PDF file in the directory
for file in "$directory"/*.pdf; do
    if [ -f "$file" ]; then  # Check if it's a regular file (not a directory)
        found_files=true
        echo "Uploading $file..."
        response=$(curl -s -o /dev/null -w "%{http_code}" -X 'POST' \
            "$upload_url" \
            -H 'accept: application/json' \
            -H 'Content-Type: multipart/form-data' \
            -F "file=@\"$file\";type=application/pdf")

        if [ "$response" -eq 200 ]; then
            echo "Successfully uploaded $file"
        else
            echo "Failed to upload $file. HTTP Status Code: $response"
        fi
    fi
done

# If no files are found, print a message
if [ "$found_files" = false ]; then
    echo "No PDF files found in the directory."
fi

echo "All files have been processed."
