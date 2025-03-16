#!/bin/bash

# Toon het menu aan de gebruiker
function show_menu() {
    echo "====================="
    echo " Self Service portal"
    echo "====================="
    echo "1. Nieuwe omgeving uitrollen"
    echo "2. Omgeving aanpassen"
    echo "3. Omgeving verwijderen"
    echo "4. Afsluiten"
    echo "====================="
    echo -n "Maak een keuze [1-4]: "
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

    # (Default omgeving)
    klantomgeving="prod"

    # Aantal servers die dienen te worden uitgerold
    read -p "Hoeveel webservers wilt u? (Max 9) " _server
    read -p "Hoeveel cpu(s) per machine? (1 t/m 2) " _cpu
    read -p "Hoeveel geheugen per machine? " _mem

    # Doorvoeren keuzes
    export SERVER="$_server"
    export CPU="$_cpu"
    export MEM="$_mem"

    # Stel het pad in voor de omgeving
    local PAD="/home/neville/IAC-2025/vagrant/klanten/$klantnaam/$klantomgeving"
    # Stel het pad in voor SSH-sleutels
    local SSH_PAD="/home/neville/IAC-2025/vagrant/klanten/$klantnaam/ssh"

    # Controleer of de omgeving al bestaat
    if [[ -d "$PAD" ]]; then
        echo "De omgeving '$klantomgeving' voor klant '$klantnaam' bestaat al."
        return 1
    fi

    # Klantmappen aanmaken
    mkdir -p "$PAD" "$SSH_PAD"

    # Genereer Klant SSH-key
    ssh-keygen -t rsa -b 2048 -f "$SSH_PAD/$klantnaam" -q -N ""

    # Kopieer Vagrant template
    cp "/home/neville/IAC-2025/vagrant/klanten/template/prod/Vagrantfile" "$PAD/Vagrantfile"

    # Vervang placeholder ‘klantnaam’ in  Vagrantfile van de klant
    sed -i "s+klantnaam+$klantnaam+g" "$PAD/Vagrantfile"

    # Ga naar de klant directory (nu dat het bestaat) en start de VM
    cd "$PAD" || { echo "Kan niet naar directory $PAD wisselen."; return 1; }
    vagrant up
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
            echo "Functie nog niet geïmplementeerd."
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
