# Contains all arguments passed to the script not starting with --
UNPARSED_ARGS=()

for arg in "$@"; do
    if [[ "$arg" =~ ^-- ]]; then
        # Long option
        IFS='=' read -r flag_name flag_value <<<"${arg:2}"
        # Default flag value to true if not specified
        [ -z "$flag_value" ] && flag_value=true
    elif [[ "$arg" =~ ^-[^-] ]]; then
        # Short option
        short_opt="${arg:1}"
        long_opt=$(map_short_options "$short_opt")
        # Assuming the format -o=value for short options mapped to long options
        if [[ "$long_opt" =~ = ]]; then
            IFS='=' read -r flag_name flag_value <<<"$long_opt"
        else
            flag_name="${long_opt:2}"
            flag_value=true
        fi
    else
        # Not an option, add to ARGS array
        UNPARSED_ARGS+=("$arg")
        continue
    fi

    # Replace '-' with '_' and uppercase the flag name
    flag_name="${flag_name//-/_}"
    flag_name="${flag_name^^}"

    if [ -z "$flag_name" ]; then
        continue
    fi

    # Declare the variable globally
    declare -g "FLAG_$flag_name=$flag_value"
    export "FLAG_$flag_name"
done

arg_index=0
for arg in "${ARG_NAMES[@]}"; do
    value="${UNPARSED_ARGS[$arg_index]}"

    message="Please enter a ${arg}"
    default="${ARG_SPECS[$arg, default]}"
    regex="${ARG_SPECS[$arg, regex]}"
    required="${ARG_SPECS[$arg, required]}"

    validate_fn="is_valid_${arg}"

    arg="${arg^^}"

    if [[ $NO_PROMPT != true ]] && [[ "$(eval echo "\$NO_PROMPT_$arg")" != true ]]; then
        valid_state=$(valid_fn_wrapper "$validate_fn" "$value" "$regex")
        try_index=0
        while [[ "$valid_state" != 0 ]]; do
            if [[ "$try_index" -gt 0 ]]; then
                message="$valid_state $message"
            fi

            ask_input "$message" "$regex" "$default" value
            valid_state=$(valid_fn_wrapper "$validate_fn" "$value" "$regex")
        done
    else
        if [[ -z "$value" ]]; then
            value="$default"
        fi
    fi

    declare -g "ARG_${arg}=${value}"
    export "ARG_${arg}"

    ((arg_index++))
done
