#!/bin/bash

# Beveiligde bestandslocaties
KLANTENLIJST="klantenlijst.txt"
LOGFILE="audit.log"

# Controleer of bestanden bestaan
touch "$KLANTENLIJST" "$LOGFILE"
chmod 600 "$KLANTENLIJST" "$LOGFILE"

# Functie: Menu weergeven
function show_menu () {
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

# Functie: Nieuwe klantomgeving aanmaken
function create_customer_environment () {
    echo -n "Wat is uw klantnaam? "
    read klantnaam

    # Controleer op lege invoer
    if [[ -z "$klantnaam" ]]; then
        echo "Klantnaam mag niet leeg zijn."
        return 1
    fi

    # Vraag omgevingstype
    echo -n "Welke type omgeving wilt u uitrollen? (productie, acceptatie, test): "
    read klantomgeving

    # Controleer op lege invoer
    if [[ -z "$klantomgeving" ]]; then
        echo "Omgevingstype mag niet leeg zijn."
        return 1
    fi

    # Validatie omgevingstype
    if [[ ! "$klantomgeving" =~ ^(productie|acceptatie|test)$ ]]; then
        echo "Ongeldig omgevingstype. Kies uit: productie, acceptatie of test."
        return 1
    fi

    # Controleer of combinatie al bestaat
    if grep -q "^$klantnaam:$klantomgeving$" "$KLANTENLIJST"; then
        echo "Deze omgeving bestaat al voor klant '$klantnaam'."
        return 1
    fi

    # Voeg klant en omgeving toe aan de lijst
    echo "$klantnaam:$klantomgeving" >> "$KLANTENLIJST"

    # Log de actie
    echo "$(date +'%Y-%m-%d %H:%M:%S') - Klant '$klantnaam' heeft omgeving '$klantomgeving' aangevraagd." >> "$LOGFILE"

    # Bevestig de actie
    echo "De omgeving voor klant '$klantnaam' van het type '$klantomgeving' wordt aangemaakt."
}

# Functie: Bestaande klantomgeving aanpassen
function adjust_customer_environment () {
    echo -n "Wat is uw klantnaam? "
    read klantnaam

    # Controleer op lege invoer
    if [[ -z "$klantnaam" ]]; then
        echo "Klantnaam mag niet leeg zijn."
        return 1
    fi

    # Controleer of klant bestaat
    if ! grep -q "^$klantnaam:" "$KLANTENLIJST"; then
        echo "Klant '$klantnaam' bestaat niet. U kunt geen omgeving aanpassen."
        return 1
    fi

    # Vraag omgevingstype
    echo -n "Welke type omgeving wilt u aanpassen? (productie, acceptatie, test): "
    read klantomgeving

    # Controleer op lege invoer
    if [[ -z "$klantomgeving" ]]; then
        echo "Omgevingstype mag niet leeg zijn."
        return 1
    fi

    # Validatie omgevingstype
    if [[ ! "$klantomgeving" =~ ^(productie|acceptatie|test)$ ]]; then
        echo "Ongeldig omgevingstype. Kies uit: productie, acceptatie of test."
        return 1
    fi

    # Log action
    echo "$(date +'%Y-%m-%d %H:%M:%S') - Klantomgeving '$klantomgeving' is aangevraagd door klant '$klantnaam'." >> "$LOGFILE"

    # Bevestig de actie
    echo "De omgeving voor klant '$klantnaam' is aangepast naar '$klantomgeving'."
}

# Functie: Klantomgeving verwijderen
function delete_customer_environment () {
    echo -n "Wat is de naam van de omgeving die u wilt verwijderen? "
    read env_name

    # Controleer op lege invoer
    if [[ -z "$env_name" ]]; then
        echo "De naam mag niet leeg zijn."
        return 1
    fi

    # Controleer of omgeving in klantenlijst bestaat
    if ! grep -q "^$env_name" "$KLANTENLIJST"; then
        echo "Deze omgeving bestaat niet volgens de klantenlijst."
        return 1
    fi

    # Vraag om bevestiging
    echo -n "Weet u zeker dat u de serveromgeving '$env_name' wilt verwijderen? (ja/nee): "
    read confirm

    if [[ "$confirm" == "ja" ]]; then
        # Verwijder de omgeving en log de actie
        sed -i "/^$env_name/d" "$KLANTENLIJST"
        echo "$(date +'%Y-%m-%d %H:%M:%S') - Serveromgeving '$env_name' is verwijderd." >> "$LOGFILE"
        echo "De serveromgeving '$env_name' is succesvol verwijderd."
    else
        echo "Actie geannuleerd. Geen wijzigingen doorgevoerd."
    fi
}

# Hoofdscript: Keuzemenu
while true; do
    show_menu
    read keuze

    case $keuze in
        1)
            create_customer_environment
            ;;
        2)
            adjust_customer_environment
            ;;
        3)
            delete_customer_environment
            ;;
        4)
            echo "Afsluiten..."
            exit 0
            ;;
        *)
            echo "Ongeldige keuze. Probeer het opnieuw."
            ;;
    esac
done
