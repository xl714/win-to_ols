#!/bin/bash

# Check if a directory argument is provided
if [ -z "$1" ]; then
  echo "Usage: $0 /path/to/directory"
  exit 1
fi

# Assign the provided directory to a variable
TARGET_DIR="$1"

# Check if the provided argument is a valid directory
if [ ! -d "$TARGET_DIR" ]; then
  echo "Error: $TARGET_DIR is not a valid directory."
  exit 1
fi

# Navigate to the target directory
cd "$TARGET_DIR" || exit

echo "##############################################################################"
echo "Ensure ImageMagick is installed and policy.xml is modified if needed."
echo "##############################################################################"

# Check if 'magick' (ImageMagick) is installed
if ! command -v magick &> /dev/null; then
  echo "ImageMagick is not installed. Please install it first."
  exit 1
fi

# Find and sort images (jpg, jpeg, png) alphabetically
mapfile -t images < <(find . -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) | sort)

# Display each found file
echo "Found files:"
for file in "${images[@]}"; do
    echo "$file"
done

# Check if no images were found
if [ ${#images[@]} -eq 0 ]; then
  echo "No images found in the specified directory."
  exit 1
fi

# Define the output PDF name based on the first image's name
output_file="${images[0]}"
output_file="${output_file%.*}.pdf"

# Combine images into a single PDF (each image as a page)
magick "${images[@]}" "$output_file"
echo "PDF created as $output_file"
