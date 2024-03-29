#!/bin/bash

# parses json file and fills asssociative array with keys and ther values
# parameters
# 1) associative array to be filled
# 2) json file
utils_parse_json() {
    local -n params_arr=$1
    local json_file="$2"
    keys=($(jq -r 'paths | map(. | tostring) | join(".")' "$json_file"))

    is_scalar() {
        local key="$1"
        # Check if the value is not an array and not an object
        local is_array=$(jq "if .\"$key\" | type | IN(\"object\", \"array\") then \"1\" else \"0\" end" "$json_file")
        if [ $is_array == '"0"' ]; then
            return 0
        else
            return 1
        fi

    }

    # Iterate through keys and add to key-value structure if not array or object
    for key in "${keys[@]}"; do
        if is_scalar "$key"; then
        params_arr["$key"]="$(jq ".$key" $json_file)"
        fi
    done
    echo "$json_file parsed successfully"
}


# executes substitution of values from array to given files
# parameters:
# 1) associative array with key-value pairs
# 2) directory where rendered files should be placed
# 3) list of files for substitution
utils_substitute_placeholders() {
  local -n params_arr=$1
  local output_dir=$2
  local yaml_files=("${@:3}")

  mkdir -p $output_dir

  # Function to substitute placeholders in YAML files
  substitute_file() {
    local input_file="$1"
    local output_file="$output_dir/${input_file}" 
    cp "$input_file" "$output_file" 

    for placeholder in $(grep -o '<{[^>]*}>' "$output_file"); do
      key="${placeholder:2:-2}"  # Remove <{}> from the placeholder
      value="${params_arr[$key]}"
      if [[ "${key:0:1}" == "/" ]]; then
          sed -i "s|$placeholder|${placeholder:3:-2}|g" "$output_file"
          continue
      fi
      if [ -n "$value" ]; then
        sed -i "s|$placeholder|$value|g" "$output_file"
      else
        echo "Error: Placeholder '$key' not found in parameters"
        exit 1
      fi
    done

    echo "Substitution completed for $input_file. Rendered file: $output_file"
  }

  for yaml_file in "${yaml_files[@]}"; do
    substitute_file "$yaml_file"
  done
}

# deletes files in given directory (useful if you need to delete rendered files, you just need to pass same file list)
# parameters:
# 1) directory where files are placed
# 2) list of files to be deleted
utils_delete_rendered_files() {
  local dir="$1"
  local files=("${@:2}")
  for file in "${files[@]}"; do
    if [ -e "$file" ]; then
        rm "$DIR_RENDERED/$file"
    fi
  done
  echo "Rendered files deleted"
}

