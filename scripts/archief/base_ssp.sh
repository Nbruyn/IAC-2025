#!/bin/bash

# Functies
function show_menu() {
    echo "====================="
    echo " Self-Service Portal"
    echo "====================="
    echo "1. Nieuwe omgeving uitrollen"
    echo "2. Bestaande omgeving aanpassen"
    echo "3. Omgeving verwijderen"
    echo "4. Lijst van omgevingen bekijken"
    echo "5. Afsluiten"
    echo "====================="
    echo -n "Maak een keuze [1-5]: "
}

function create_environment() {
    echo -n "Voer de naam in van de nieuwe omgeving: "
    read env_name
    echo -n "Kies het type omgeving (productie, acceptatie, test): "
    read env_type

    # Maak een map of voer een specifieke actie uit
    mkdir -p "$env_name"
    echo "$env_type omgeving uitgerold in $env_name."
}

function modify_environment() {
    echo -n "Voer de naam van de omgeving in die je wilt aanpassen: "
    read env_name
    if [ -d "$env_name" ]; then
        echo "Huidige instellingen van $env_name:"
        echo "1. Type aanpassen"
        echo "2. Naam wijzigen"
        echo "3. Terug naar hoofdmenu"
        echo -n "Maak een keuze: "
        read mod_choice

        case $mod_choice in
            1)
                echo -n "Voer een nieuw type in (productie, acceptatie, test): "
                read new_type
                echo "$env_name is nu ingesteld als $new_type omgeving."
                ;;
            2)
                echo -n "Voer een nieuwe naam in: "
                read new_name
                mv "$env_name" "$new_name"
                echo "$env_name is hernoemd naar $new_name."
                ;;
            3)
                return
                ;;
            *)
                echo "Ongeldige keuze."
                ;;
        esac
    else
        echo "Omgeving $env_name bestaat niet."
    fi
}

function delete_environment() {
    echo -n "Voer de naam in van de omgeving die je wilt verwijderen: "
    read env_name
    if [ -d "$env_name" ]; then
        rm -rf "$env_name"
        echo "Omgeving $env_name is verwijderd."
    else
        echo "Omgeving $env_name bestaat niet."
    fi
}

function list_environments() {
    echo "Lijst van omgevingen:"
    ls -d */ 2>/dev/null || echo "Geen omgevingen gevonden."
}

# Hoofdscript
while true; do
    show_menu
    read choice
    case $choice in
        1)
            create_environment
            ;;
        2)
            modify_environment
            ;;
        3)
            delete_environment
            ;;
        4)
            list_environments
            ;;
        5)
            echo "Afsluiten..."
            exit 0
            ;;
        *)
            echo "Ongeldige keuze, probeer opnieuw."
            ;;
    esac
    echo ""
done
