#!/bin/bash

function show_menu () {
    echo "====================="
    echo " Self Service portal"
    echo "====================="
    echo "1. Nieuwe omgeving"
    echo "2. Omgeving aanpassen"
    echo "3. Omgeving verwijderen"
    echo "4. Omgeving overzicht"
    echo "5. Afsluiten"
    echo "====================="
    echo -n "Maak een keuze [1-5]: "
}

function create_customer_environment () {
    echo -n "Wat is uw klantnaam? "
    read klantnaam

    # Check if customer already exists
    grep -q "^$klantnaam$" klantenlijst.txt &  # Achtergrondcontrole
    check_process=$!

    # Ask customer what environment needs to be deployed
    echo -n "Welke type omgeving wilt u uitrollen? (productie, acceptatie, test): "
    read klantomgeving

    # Wait for check if customer already exists
    wait $check_process
    if [[ $? -eq 0 ]]; then
        # Customer already exist
        :
    else
        # Customer doesn't exist, add to klantenlijst.txt
        echo "$klantnaam" >> klantenlijst.txt
    fi

    # Bevestig de actie
    echo "De omgeving voor klant '$klantnaam' van het type '$klantomgeving' wordt aangemaakt."
}

# Choice Menu
while true; do
    show_menu
    read keuze

    case $keuze in
        1) 
            create_customer_environment
            ;;
        2)
            echo "Optie 2: Omgeving aanpassen is nog niet geïmplementeerd."
            ;;
        3)
            echo "Optie 3: Omgeving verwijderen is nog niet geïmplementeerd."
            ;;
        4)
            echo "Optie 4: Omgeving overzicht is nog niet geïmplementeerd."
            ;;
        5)
            echo "Afsluiten..."
            exit 0
            ;;
        *)
            echo "Ongeldige keuze. Probeer het opnieuw."
            ;;
    esac
done
