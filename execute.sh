#!/bin/zsh

csv_file="input.csv"

# Function to check for errors
check_error() {
    local output=$1
    local command=$2
    if echo "$output" | grep -q "Error"; then
        tput setaf 1  # Set text color to red
        echo "Error occurred in $command:"
        echo "$output" | grep -A 5 "Error"
        tput sgr0  # Reset text color
        return 1
    fi
    return 0
}

# Deploy package
output_deploy=$(sui client publish --gas-budget 50000000 --skip-dependency-verification)
if ! check_error "$output_deploy" "package deployment"; then
    exit 1
fi

# Extract Some IDs
package_id=$(echo "$output_deploy" | grep "PackageID:" | awk '{print $4}')
echo "PackageID: $package_id"
locker_cap_object_id=$(echo "$output_deploy" | grep -A 30 "Created Objects:" | grep -B 3 "LockerCap" | grep "ObjectID:" | head -n 1 | awk '{print $4}')
echo "LockerCap ObjectID: $locker_cap_object_id"
category_registry_object_id=$(echo "$output_deploy" | grep -A 30 "Created Objects:" | grep -B 3 "CategoryRegistry" | grep "ObjectID:" | head -n 1 | awk '{print $4}')
echo "CategoryRegistry ObjectID: $category_registry_object_id"

# Define variable for `register_category` function
category_game_owners="Game Owners"
category_team_advisors="Team & Advisors"

# Execute `regsiter_category` function
echo "Execute register_category function (Game Owners)"
output_register_category1=$(sui client ptb --move-call "${package_id}::locker::register_category" @${locker_cap_object_id} @${category_registry_object_id} \'${category_game_owners}\' --gas-budget 10000000)
check_error "$output_register_category1" "register_category (Game Owners)"

echo "Execute register_category function (Team & Advisors)"
output_register_category2=$(sui client ptb --move-call "${package_id}::locker::register_category" @${locker_cap_object_id} @${category_registry_object_id} \'${category_team_advisors}\' --gas-budget 10000000)
check_error "$output_register_category2" "register_category (Team & Advisors)"

# Define variables for `new` function
coin_object_id=0xf766d83eff18fb2936c3e45805f387d29540c8b0811120a007ee45742409b402
start=1719565200000 # Fri Jun 28 2024 18:00:00 GMT+0900
interval=86400000 # 60 * 60 * 24 * 1000 (1 day)
step=2
# interval=2592000000 # 60 * 60 * 24 * 30 * 1000 (1 month)
# step=60

# Read CSV file and execute new and transfer functions
is_first_line=true
while IFS=',' read -r receiver amount_per_step category
do
    # Skip the first line
    if $is_first_line; then
        is_first_line=false
        continue
    fi

    echo "Processing: Receiver=$receiver, Amount=$amount_per_step, Category=$category"

    # Execute `new` function
    echo "Execute new function"
    output_new=$(sui client ptb --move-call "${package_id}::locker::new" "<0x2::sui::SUI>" @${coin_object_id} @${category_registry_object_id} @${receiver} ${amount_per_step} ${start} ${interval} ${step} ${category} --gas-budget 10000000)
    if ! check_error "$output_new" "new function"; then
        continue
    fi

    # Extract Locker ObjectID
    locker_object_id=$(echo "$output_new" | grep -A 30 "Created Objects:" | grep -B 3 "Locker" | grep "ObjectID:" | head -n 1 | awk '{print $4}')
    echo "Locker ObjectID: $locker_object_id"

    # Execute `transfer` function
    echo "Execute transfer function (1st)"
    output_transfer1=$(sui client ptb --move-call "${package_id}::locker::transfer" "<0x2::sui::SUI>" @${locker_object_id} @0x6 --gas-budget 10000000)
    check_error "$output_transfer1" "transfer function (1st)"

    echo "Execute transfer function (2nd)"
    output_transfer2=$(sui client ptb --move-call "${package_id}::locker::transfer" "<0x2::sui::SUI>" @${locker_object_id} @0x6 --gas-budget 10000000)
    check_error "$output_transfer2" "transfer function (2nd)"

    echo "Execute transfer function (3rd): This should fail"
    output_transfer3=$(sui client ptb --move-call "${package_id}::locker::transfer" "<0x2::sui::SUI>" @${locker_object_id} @0x6 --gas-budget 10000000)
    check_error "$output_transfer3" "transfer function (3rd)"

    echo "PackageID: $package_id"
    echo "Locker ObjectID: $locker_object_id"

    echo "----------------------------------------"
done < "$csv_file"
