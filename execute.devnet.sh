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
category_game_owners="Game Owners"
category_team_advisors="Team & Advisors"

# Execute `regsiter_category` function
echo "Execute register_category function (Game Owners)"
output_register_category1=$(sui client ptb \
    --move-call "${package}::locker::register_category" \
    @${locker_cap} \
    @${category_registry} \
    \'${category_game_owners}\' \
    --gas-budget 10000000
)
check_error "$output_register_category1" "register_category (Game Owners)"

echo "Execute register_category function (Team & Advisors)"
output_register_category2=$(sui client ptb \
    --move-call "${package}::locker::register_category" \
    @${locker_cap} \
    @${category_registry} \
    \'${category_team_advisors}\' \
    --gas-budget 10000000
)
check_error "$output_register_category2" "register_category (Team & Advisors)"

# Define variables for `new` function
gas_coin=0xc762c3c4ca18dfcb0c047f4685c68157075c58ce926f4b7cdacbb01e3deb29fe
interval=86400000 # 1 * 60 * 60 * 24 * 1000
steps=3
clock_object=0x6

# Read CSV file and execute new and transfer functions
is_first_line=true
while IFS=',' read -r receiver amount_per_step category; do
    # Skip the first line
    if $is_first_line; then
        is_first_line=false
        continue
    fi

    echo "Processing: Receiver=$receiver, Amount=$amount_per_step, Category=$category"
    total_amount=$((amount_per_step * steps))

    # Prepare coin for `new` function
    echo "Prepare coin for new function"
    output_prepare_coin=$(sui client split-coin \
        --coin-id ${gas_coin} \
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

    # Execute `new` function
    echo "Execute new function"
    start=$(date -v+5S '+%s000')
    output_new=$(sui client ptb \
        --move-call "${package}::locker::new" \
        "<0x2::sui::SUI>" \
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

    # Extract Locker ObjectID
    locker=$(echo "$output_new" | \
        grep -A 30 "Created Objects:" | \
        grep -B 3 "Locker" | \
        grep "ObjectID:" | \
        head -n 1 | \
        awk '{print $4}'
    )
    echo "Locker ObjectID: $locker"

    sleep 20
    # Execute `transfer` function
    echo "Execute transfer function (1st)"
    output_transfer1=$(sui client ptb \
        --move-call "${package}::locker::transfer" \
        "<0x2::sui::SUI>" \
        @${locker} \
        @${clock_object} \
        --gas-budget 10000000
    )
    check_error "$output_transfer1" "transfer function (1st)"

    sleep 20
    echo "Execute transfer function (2nd)"
    output_transfer2=$(sui client ptb \
        --move-call "${package}::locker::transfer" \
        "<0x2::sui::SUI>" \
        @${locker} \
        @${clock_object} \
        --gas-budget 10000000
    )
    check_error "$output_transfer2" "transfer function (2nd)"

    echo "Execute transfer function (3rd): This should fail because the timing is invalid"
    output_transfer3=$(sui client ptb \
        --move-call "${package}::locker::transfer" \
        "<0x2::sui::SUI>" \
        @${locker} \
        @${clock_object} \
        --gas-budget 10000000
    )
    check_error "$output_transfer3" "transfer function (3rd)"

    sleep 20
    echo "Execute transfer function (4th)"
    output_transfer4=$(sui client ptb \
        --move-call "${package}::locker::transfer" \
        "<0x2::sui::SUI>" \
        @${locker} \
        @${clock_object} \
        --gas-budget 10000000
    )
    check_error "$output_transfer4" "transfer function (4th)"

    sleep 20
    echo "Execute transfer function (5th): This should fail because the steps are over"
    output_transfer5=$(sui client ptb \
        --move-call "${package}::locker::transfer" \
        "<0x2::sui::SUI>" \
        @${locker} \
        @${clock_object} \
        --gas-budget 10000000
    )
    check_error "$output_transfer5" "transfer function (5th)"

    echo "PackageID: $package"
    echo "Locker ObjectID: $locker"

    echo "----------------------------------------"
done <"$csv_file"
