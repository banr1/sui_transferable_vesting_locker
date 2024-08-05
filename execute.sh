#!/bin/zsh

csv_file="input.csv"

# Function to check for errors
check_error() {
    local output=$1
    local command=$2
    if echo "$output" | grep -q "Error"; then
        tput setaf 1 # Set text color to red
        echo "Error occurred in $command:"
        echo "$output" | grep -A 5 "Error"
        tput sgr0 # Reset text color
        return 1
    fi
    return 0
}

# Deploy package
echo "Deploy package"
output_deploy=$(sui client publish \
    --gas-budget 50000000 \
    --skip-dependency-verification
)
if ! check_error "$output_deploy" "package deployment"; then
    exit 1
fi

# Extract Some IDs
package=$(echo "$output_deploy" | grep "PackageID:" | awk '{print $4}')
echo "PackageID: $package"
locker_cap=$(echo "$output_deploy" | \
    grep -A 30 "Created Objects:" | \
    grep -B 3 "LockerCap" | \
    grep "ObjectID:" | \
    head -n 1 | \
    awk '{print $4}'
)
echo "LockerCap ObjectID: $locker_cap"
category_registry=$(echo "$output_deploy" | \
    grep -A 30 "Created Objects:" | \
    grep -B 3 "CategoryRegistry" | \
    grep "ObjectID:" | \
    head -n 1 | \
    awk '{print $4}'
)
echo "CategoryRegistry ObjectID: $category_registry"

# Define variable for `register_category` function
categories=(
    "Game Owners"
    "Marketing"
    "Team & Advisors"
    "Ecosystem"
    "Exchange"
    "Backup Reserve"
)

# Execute `register_category` function for all categories
for category in "${categories[@]}"; do
    echo "Execute register_category function ($category)"
    output_register_category=$(sui client ptb \
        --move-call "${package}::locker::register_category" \
        @${locker_cap} \
        @${category_registry} \
        \'${category}\' \
        --gas-budget 10000000
    )
    check_error "$output_register_category" "register_category ($category)"
done

# Define variables for `new` function
n_digits=9
senet_token=0x734b63f6f46828dda088198f25c126991651c0b586d69cd877d964a768b00430
senet_token_object=0x1bab6b65f5dff752edae8cc256df2c4d3d1f4b586a10cc41142b318460c7de2e
interval=2592000000 # 60 * 60 * 24 * 30 * 1000 (1 month)
steps=60
clock_object=0x6
start=1720580400000 # Wed Jul 10 2024 12:00:00 (JST)

# Read CSV file and execute new and transfer functions
is_first_line=true
while IFS=',' read -r receiver amount_per_step category; do
    # Skip the first line
    if $is_first_line; then
        is_first_line=false
        continue
    fi

    echo "Processing: Receiver=$receiver, Amount=$amount_per_step, Category=$category"
    amount_per_step=$((amount_per_step * 10 ** n_digits))
    total_amount=$((amount_per_step * steps))

    # Prepare coin for `new` function
    echo "Prepare coin for new function"
    output_prepare_coin=$(sui client split-coin \
        --coin-id ${senet_token_object} \
        --amounts ${total_amount} \
        --gas-budget 10000000
    )
    check_error "$output_transfer1" "transfer function (1st)"

    # Extract Created Coin ObjectID
    coin=$(echo "$output_prepare_coin" | \
        grep -A 3 "Created Objects:" | \
        grep "ObjectID:" | \
        awk '{print $4}'
    )
    echo "Coin ObjectID: $coin"

    # Execute `new` function
    echo "Execute new function"
    output_new=$(sui client ptb \
        --move-call "${package}::locker::new" \
        "<${senet_token}::token::TOKEN>" \
        @${locker_cap} \
        @${coin} \
        @${category_registry} \
        @${receiver} \
        ${amount_per_step} \
        ${start} \
        ${interval} \
        ${steps} \
        ${category} \
        @${clock_object} \
        --gas-budget 10000000
    )
    if ! check_error "$output_new" "new function"; then
        continue
    fi

    echo "----------------------------------------"
done <"$csv_file"
