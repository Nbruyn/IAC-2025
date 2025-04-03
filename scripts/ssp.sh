#!/bin/bash

# Toon het menu aan de gebruiker
function show_menu() {
    echo "====================="
    echo " Self Service portal"
    echo "====================="
    echo "1. Nieuwe omgeving(en) uitrollen"
    echo "2. Omgeving(en) aanpassen"
    echo "3. Omgeving(en) verwijderen"
    echo "4. Afsluiten"
    echo "====================="
    echo -n "Maak een keuze [1-4]: "
}

# Functie klant-ip genereren
function f_clientnumber() {
    local file_path="/home/neville/IAC-2025/vagrant/klanten/template/clientnumber.txt"
    
    [[ ! -f "$file_path" ]] && echo 9 > "$file_path"

    clientnumber=$(($(cat "$file_path") + 1))
    echo "$clientnumber" | tee "$file_path"
}

# Functie ansible inventory file
function _ansible_inventory() {

    local klantenpad="/home/neville/IAC-2025/vagrant/klanten/${klantnaam}/${klantomgeving}"
    local inventory_file="${klantenpad}/inventory.ini"

    # Kopieer de juiste inventory template
    if [[ "$klantomgeving" == "productie" ]]; then
        cp "/home/neville/IAC-2025/ansible/inventories/inventory_p.ini" "$inventory_file"
        local host_suffix="-p"
    else
        cp "/home/neville/IAC-2025/ansible/inventories/inventory_t.ini" "$inventory_file"
        local host_suffix="-t"
    fi

    # Stel IP-prefix in afhankelijk van omgeving
    local ip_prefix=""
    if [[ "$klantomgeving" == "productie" ]]; then
        ip_prefix="10.0.${clientnumber}.2"  # bijv: 10.0.9.21, 10.0.9.22
    else
        ip_prefix="10.0.${clientnumber}.1"  # bijv: 10.0.9.11, 10.0.9.12
    fi

    # Voeg [WEB] groep toe aan inventory

    # Voeg webservers toe
    for ((i = 1; i <= SERVER; i++)); do
        echo "${klantnaam}${host_suffix}-web${i} ansible_host=${ip_prefix}${i}" >> "$inventory_file"
    done

    # Pas placeholders aan in het bestand
    sed -i "s/klantnaam/${klantnaam}/g" "$inventory_file"
    sed -i "s/\.ip\./.${clientnumber}./g" "$inventory_file"
}

# Functie key-scan
function f_keyscan() {
    local INVENTORY_FILE="/home/neville/IAC-2025/vagrant/klanten/${klantnaam}/${klantomgeving}/inventory.ini"

    if [[ ! -f "$INVENTORY_FILE" ]]; then
        echo "Inventory file not found: $INVENTORY_FILE"
        return 1
    fi

    # Gather the IP addresses from the inventory file
    local ip_addresses
    ip_addresses=$(awk -F'=' '/ansible_host/ {
        gsub(/[[:blank:]]/, "", $2)
        print $2
    }' "$INVENTORY_FILE")

    for ip in $ip_addresses; do
        echo "Running ssh-keyscan for $ip"
        ssh-keyscan -H "$ip" >> ~/.ssh/known_hosts 2>/dev/null
        if [[ $? -ne 0 ]]; then
            echo "Error running ssh-keyscan for $ip"
        fi
    done

    echo "SSH key scanning completed."
}

#Functie klantomgeving(en) verwijderen
function f_destroy() {
    read -p "Welke klant wilt u verwijderen? " _klantnaam

    local klantpad="/home/neville/IAC-2025/vagrant/klanten/${_klantnaam}"
    if [[ ! -d "$klantpad" ]]; then
        echo "Klant '${_klantnaam}' bestaat niet."
        return 1
    fi

    echo "Welke omgeving(en) wilt u verwijderen? '${_klantnaam}'?"
    echo "1. testomgeving"
    echo "2. productieomgeving"
    echo "3. testomgeving & productieomgeving"
    echo -n "Maak een keuze [1-3]: "
    read keuze

    read -p "Weet u zeker dat u wilt doorgaan met verwijderen? (y/n): " bevestiging
    if [[ "$bevestiging" != "y" && "$bevestiging" != "Y" ]]; then
        echo "Verwijderen geannuleerd."
        return
    fi

    if [[ "$keuze" == "1" || "$keuze" == "3" ]]; then
        if [[ -d "$klantpad/test" ]]; then
            echo "Testomgeving stoppen..."
            cd "$klantpad/test"
            vagrant halt
            echo "Verwijder testomgeving..."
            vagrant destroy -f
            rm -rf "$klantpad/test"
        else
            echo "Geen testomgeving gevonden."
        fi
    fi

    if [[ "$keuze" == "2" || "$keuze" == "3" ]]; then
        if [[ -d "$klantpad/productie" ]]; then
            echo "Productieomgeving stoppen..."
            cd "$klantpad/productie"
            vagrant halt
            echo "Verwijder productieomgeving..."
            vagrant destroy -f
            rm -rf "$klantpad/productie"
        else
            echo "Geen productieomgeving gevonden."
        fi
    fi

    # Verwijder klantmap als test én productie verwijderd zijn
    if [[ ! -d "$klantpad/test" && ! -d "$klantpad/productie" ]]; then
        echo "Verwijder klantdirectory..."
        rm -rf "$klantpad"
    fi


}



# Functie om een nieuwe klantomgeving aan te maken
function create_customer_environment() {
    # Vraag klantnaam
    read -p "Klantnaam: " klantnaam

    # Controleer of invoer bij klantnaam leeg is
    if [[ -z "$klantnaam" ]]; then
        echo "Klantnaam mag niet leeg zijn."
        return 1
    fi

    # Vraagt klant welke omgeving hij wil uitrollen ( productie of test )
    read -p "Omgevingstype (productie, test): " klantomgeving
    if [[ ! "$klantomgeving" =~ ^(productie|test)$ ]]; then
        echo "Ongeldig type."
        return 1
    fi

    # Aantal servers die dienen te worden uitgerold
    read -p "Hoeveel webservers wilt u? (Max 9) " _server
    read -p "Hoeveel cpu(s) per machine? (1 t/m 2) " _cpu
    read -p "Hoeveel geheugen per machine? " _mem

#keuze doorvoeren
export SERVER="$_server"
export CPU="$_cpu"
export MEM="$_mem"

    # Stel het pad in voor de omgeving
    local PAD="/home/neville/IAC-2025/vagrant/klanten/${klantnaam}/${klantomgeving}"
    local SSH_PAD="/home/neville/IAC-2025/vagrant/klanten/${klantnaam}/ssh"

    # Controleer of de omgeving al bestaat
    if [[ -d "$PAD" ]]; then
        echo "De omgeving '${klantomgeving}' voor klant '${klantnaam}' bestaat al."
        return 1
    fi

    # Maak klantmappen aan
    mkdir -p "$PAD" "$SSH_PAD"

 # Genereer Klant SSH-key (alleen als deze nog niet bestaat)
if [[ ! -f "$SSH_PAD/$klantnaam" ]]; then
    echo "Genereer SSH key voor ${klantnaam}..."
    ssh-keygen -t rsa -b 2048 -f "$SSH_PAD/$klantnaam" -q -N ""
else
    echo "SSH key voor ${klantnaam} bestaat al, hergebruiken..."
fi
   
    

    # Kopieer Vagrant template
    if [[ "$klantomgeving" == "productie" ]]; then
        cp "/home/neville/IAC-2025/vagrant/klanten/template/prod/Vagrantfile" "$PAD/Vagrantfile"
    else
        cp "/home/neville/IAC-2025/vagrant/klanten/template/test/Vagrantfile" "$PAD/Vagrantfile"
    fi

    clientnumber=$(f_clientnumber)
    
    echo "DEBUG: clientnumber=${clientnumber}"

    # Vervang placeholder ‘klantnaam’ in Vagrantfile
    sed -i "s+klantnaam+${klantnaam}+g" "$PAD/Vagrantfile"
    sed -i "s+_ip+$clientnumber+g" "$PAD/Vagrantfile"

    # Ga naar de klant directory en start de VM
    cd "$PAD" || { echo "Kan niet naar directory $PAD wisselen."; return 1; }
    vagrant halt
    vagrant up --provision

    # Clear known hosts
    > /home/neville/.ssh/known_hosts

    # Roep ansible Ansible inventory functie aan 
    _ansible_inventory

    # Key-scan
    f_keyscan

    # Toon IPs en voer eventueel playbooks uit
    if [[ "$klantomgeving" == "test" ]]; then
        for ((i=1; i <= SERVER; i++)); do
            echo "Uw webserver IP(s) zijn: 10.0.${clientnumber}.${i}"
        done
        cd "/home/neville/IAC-2025/ansible/"
        ansible-playbook -i "/home/neville/IAC-2025/vagrant/klanten/${klantnaam}/test/inventory.ini" playbook_deploy_t
    else
        # production
        for ((i=1; i <= SERVER; i++)); do
            echo "Uw webserver IP is: 10.0.${clientnumber}.2${i}"
        done
        echo "Uw lbserver IP is: 10.0.${clientnumber}.31"
        echo "Uw dbserver IP is: 10.0.${clientnumber}.41"

        cd "/home/neville/IAC-2025/ansible/"
        ansible-playbook -i "/home/neville/IAC-2025/vagrant/klanten/${klantnaam}/productie/inventory.ini" playbook_deploy_p
    fi

    # Optional: use `return` if you want to come back to the main menu
    return 0
}

# Hoofdmenu
while true; do
    show_menu
    read -r keuze
    case "$keuze" in
        1)
            create_customer_environment
            ;;
        2)
            echo "Functie nog niet geïmplementeerd."
            ;;
        3)
            f_destroy
            ;;
        4)
            echo "Afsluiten..."
            exit 0
            ;;
        *)
            echo "Ongeldige keuze."
            ;;
    esac
done
