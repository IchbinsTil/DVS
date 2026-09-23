#!/usr/bin/env python3
"""
Erzeugt realistische Beispieldaten für die beiden PostgreSQL-Quellsysteme.

Ausgabe:
    beispieldaten.sql

Die SQL-Datei wird im gleichen Verzeichnis erzeugt, in dem dieses Skript
ausgeführt wird.

Hinweis:
- Die vorhandenen Tabellen werden in der SQL-Datei zuerst geleert.
- Anschließend werden alle Beispieldaten per INSERT eingefügt.
- Die Daten werden bei jedem Lauf neu und zufällig erzeugt.
- Ein Seed kann über die Kommandozeile angegeben werden, um einen Lauf
  reproduzierbar zu machen:
      python generate_data.py 12345
"""

from __future__ import annotations

import random
import sys
from datetime import date, datetime, timedelta
from decimal import Decimal
from pathlib import Path


# ------------------------------------------------------------
# Konfiguration
# ------------------------------------------------------------

OUTPUT_FILE = Path.cwd() / "beispieldaten.sql"

START_DATE = date(2024, 1, 1)
END_DATE = date(2025, 12, 31)

# Für reproduzierbare Daten kann z. B. "python generate_data.py 12345"
# verwendet werden. Ohne Parameter wird bei jedem Lauf ein neuer Seed
# verwendet.
if len(sys.argv) > 1:
    try:
        random.seed(int(sys.argv[1]))
    except ValueError:
        raise SystemExit("Der Seed muss eine Ganzzahl sein, z. B. 12345.")


# ------------------------------------------------------------
# Hilfsfunktionen
# ------------------------------------------------------------

def sql_string(value: str) -> str:
    """Escaped einen String für PostgreSQL."""
    return "'" + value.replace("'", "''") + "'"


def sql_date(value: date) -> str:
    return f"'{value.isoformat()}'"


def sql_timestamp(value: datetime) -> str:
    return f"'{value.strftime('%Y-%m-%d %H:%M:%S')}'"


def sql_decimal(value: float | Decimal) -> str:
    return f"{Decimal(str(value)):.2f}"


def random_date(start: date, end: date) -> date:
    days = (end - start).days
    return start + timedelta(days=random.randint(0, days))


def random_datetime(start: date, end: date) -> datetime:
    day = random_date(start, end)
    hour = random.randint(7, 18)
    minute = random.randint(0, 59)
    second = random.randint(0, 59)
    return datetime(day.year, day.month, day.day, hour, minute, second)


def weighted_choice(values, weights):
    return random.choices(values, weights=weights, k=1)[0]


def chunks(values, size=500):
    for i in range(0, len(values), size):
        yield values[i:i + size]


def insert_statement(schema, table, columns, rows):
    """Erzeugt ein PostgreSQL-INSERT mit mehreren VALUES-Zeilen."""
    if not rows:
        return ""

    col_sql = ", ".join(columns)
    value_sql = ",\n".join(
        "(" + ", ".join(row) + ")" for row in rows
    )

    return (
        f'INSERT INTO {schema}.{table} ({col_sql}) VALUES\n'
        f'{value_sql};\n'
    )


# ------------------------------------------------------------
# Stammdaten
# ------------------------------------------------------------

FIRST_NAMES = [
    "Anna", "Ben", "Clara", "Daniel", "Elena", "Felix", "Hannah",
    "Jan", "Julia", "Laura", "Leon", "Lisa", "Lukas", "Marie",
    "Markus", "Max", "Nina", "Paul", "Sarah", "Sophie", "Tim",
    "Tobias", "Christian", "David"
]

LAST_NAMES = [
    "Bauer", "Becker", "Fischer", "Hoffmann", "Keller", "Koch",
    "Lang", "Lehmann", "Meier", "Müller", "Neumann", "Richter",
    "Schmidt", "Schneider", "Scholz", "Schubert", "Schulz",
    "Wagner", "Weber", "Wolf", "Zimmermann"
]

REGIONS = [
    ("Sachsen", "Deutschland"),
    ("Berlin", "Deutschland"),
    ("Brandenburg", "Deutschland"),
    ("Bayern", "Deutschland"),
    ("Hessen", "Deutschland"),
    ("Hamburg", "Deutschland"),
    ("Nordrhein-Westfalen", "Deutschland"),
    ("Baden-Württemberg", "Deutschland"),
    ("Niedersachsen", "Deutschland"),
    ("Wien", "Österreich"),
]

CITIES = [
    ("Dresden", "Sachsen", "Deutschland"),
    ("Leipzig", "Sachsen", "Deutschland"),
    ("Chemnitz", "Sachsen", "Deutschland"),
    ("Berlin", "Berlin", "Deutschland"),
    ("Potsdam", "Brandenburg", "Deutschland"),
    ("München", "Bayern", "Deutschland"),
    ("Nürnberg", "Bayern", "Deutschland"),
    ("Frankfurt", "Hessen", "Deutschland"),
    ("Wiesbaden", "Hessen", "Deutschland"),
    ("Hamburg", "Hamburg", "Deutschland"),
    ("Köln", "Nordrhein-Westfalen", "Deutschland"),
    ("Stuttgart", "Baden-Württemberg", "Deutschland"),
    ("Hannover", "Niedersachsen", "Deutschland"),
    ("Bremen", "Bremen", "Deutschland"),
    ("Wien", "Wien", "Österreich"),
]

CUSTOMER_PREFIXES = [
    "Müller", "Schneider", "Bauer", "Kronberg", "Elbe",
    "Rhein", "Hanse", "Sachsen", "Bavaria", "Capital",
    "Nord", "Central", "Alpen", "West", "Metro"
]

CUSTOMER_SUFFIXES = [
    "GmbH", "AG", "GmbH & Co. KG", "SE", "Solutions GmbH",
    "Industrie GmbH", "Systems AG", "Logistik GmbH"
]

DEVICE_TYPES = [
    ("Firewall", ["Fortinet", "Sophos", "Cisco"]),
    ("Core-Switch", ["Cisco", "Aruba"]),
    ("Access Point", ["Cisco", "Aruba", "LANCOM"]),
    ("Server", ["Dell", "HPE", "Lenovo"]),
]

MODELS = {
    "Fortinet": ["FortiGate 60F", "FortiGate 100F", "FortiGate 200F"],
    "Sophos": ["XGS 107", "XGS 136", "XGS 2100"],
    "Cisco": ["Catalyst 9200", "Catalyst 9300", "Catalyst 1000"],
    "Aruba": ["CX 6100", "CX 6200", "AP-515"],
    "LANCOM": ["LX-6400", "LX-6500", "GS-4530"],
    "Dell": ["PowerEdge R550", "PowerEdge R650", "PowerEdge R750"],
    "HPE": ["ProLiant DL360", "ProLiant DL380", "ProLiant ML350"],
    "Lenovo": ["ThinkSystem SR250", "ThinkSystem SR630", "ThinkSystem SR650"],
}

CONTRACT_TYPES = [
    ("24/7 Premium", 800, 1500),
    ("8x5 Standard", 400, 800),
    ("Next-Business-Day", 200, 500),
]

MAINTENANCE_TYPES = [
    "Firmware-Update",
    "Komponententausch",
    "Konfigurationsprüfung",
    "Inspektion",
]

TICKET_CATEGORIES = ["Hardware", "Netzwerk", "Security", "Software"]

TICKET_PRIORITIES = {
    "Kritisch": 60,
    "Hoch": 240,
    "Mittel": 480,
    "Niedrig": 1440,
}

TICKET_ACTIONS = [
    "Diagnose",
    "Konfiguration",
    "Patch",
    "Komponententausch",
    "Sicherheitsprüfung",
    "Abschlusstest",
]

TEAMS = [
    "Helpdesk",
    "Netzwerktechnik",
    "Field Service",
]

ROLES = {
    "Helpdesk": ["Supportmitarbeiter", "Senior Supportmitarbeiter"],
    "Netzwerktechnik": ["Techniker", "Senior Techniker", "Netzwerkingenieur"],
    "Field Service": ["Techniker", "Field Service Engineer"],
}


# ------------------------------------------------------------
# Daten erzeugen
# ------------------------------------------------------------

def create_name(used_names):
    while True:
        name = f"{random.choice(FIRST_NAMES)} {random.choice(LAST_NAMES)}"
        if name not in used_names:
            used_names.add(name)
            return name


def generate_locations():
    count = random.randint(10, 15)
    selected = random.sample(CITIES, count)

    locations = []
    for location_id, (city, region, country) in enumerate(selected, start=1):
        prefixes = [
            "Hauptsitz",
            "Niederlassung",
            "Campus",
            "Standort",
            "Datacenter",
            "Servicezentrum",
            "Logistikzentrum",
        ]
        locations.append({
            "StandortID": location_id,
            "Standortbezeichnung": f"{random.choice(prefixes)} {city}",
            "Region": region,
            "Land": country,
        })

    return locations


def generate_employees():
    count = random.randint(10, 15)
    employees = []
    used_names = set()

    for employee_id in range(401, 401 + count):
        team = random.choice(TEAMS)
        employees.append({
            "MitarbeiterNr": employee_id,
            "Name": create_name(used_names),
            "Team": team,
            "Rolle": random.choice(ROLES[team]),
        })

    return employees


def generate_customers(locations):
    count = random.randint(8, 12)
    customers = []
    used_names = set()

    types = ["Kleinunternehmen", "Mittelstand", "Konzern"]

    for customer_id in range(201, 201 + count):
        location = random.choice(locations)

        while True:
            name = (
                f"{random.choice(CUSTOMER_PREFIXES)} "
                f"{random.choice(CUSTOMER_SUFFIXES)}"
            )
            if name not in used_names:
                used_names.add(name)
                break

        customer_type = weighted_choice(
            types,
            [25, 55, 20]
        )

        customers.append({
            "KundenNr": customer_id,
            "Kunden_Name": name,
            "Kundentyp": customer_type,
            "StandortID": location["StandortID"],
        })

    return customers


def generate_account_managers(customers):
    managers = []
    used_names = set()

    for i, customer in enumerate(customers):
        managers.append({
            "BetreuerNr": 301 + i,
            "KundenNr": customer["KundenNr"],
            "Name": create_name(used_names),
            "Team": random.choice([
                "Key Accounts",
                "Regionalbetreuung",
                "Kundenservice",
            ]),
        })

    return managers

def generate_devices(locations):
    count = random.randint(60, 100)
    devices = []

    for device_id in range(101, 101 + count):
        device_type, manufacturers = random.choice(DEVICE_TYPES)
        manufacturer = random.choice(manufacturers)

        # Anschaffung vor Beginn des Betrachtungszeitraums.
        acquisition_start = date(2019, 1, 1)
        acquisition_end = date(2023, 12, 31)

        devices.append({
            "GeräteNr": device_id,
            "Gerätetyp": device_type,
            "Hersteller": manufacturer,
            "Modell": random.choice(MODELS[manufacturer]),
            "StandortID": random.choice(locations)["StandortID"],
            "Anschaffungsdatum": random_date(
                acquisition_start,
                acquisition_end
            ),
        })

    return devices


def generate_contracts(devices):
    contracts = []
    contract_id = 5001

    for device in devices:
        # Ein Teil der Geräte besitzt keinen Vertrag.
        if random.random() < 0.10:
            continue

        contract_count = random.choices(
            [1, 2],
            weights=[80, 20],
            k=1
        )[0]

        current_start = date(2023, 1, 1)

        for _ in range(contract_count):
            contract_type, min_cost, max_cost = random.choice(CONTRACT_TYPES)

            # Vertragslaufzeiten von 1 oder 2 Jahren.
            duration_years = random.choice([1, 1, 1, 2])

            # Beginn so wählen, dass der Vertrag mindestens teilweise
            # im Betrachtungszeitraum liegt.
            if current_start < date(2024, 1, 1):
                current_start = date(2024, 1, 1)

            end = date(
                current_start.year + duration_years,
                current_start.month,
                current_start.day
            ) - timedelta(days=1)

            # Nicht über das Ende des Betrachtungszeitraums hinausgehen,
            # sofern kein Folge-Vertrag benötigt wird.
            if end > END_DATE:
                end = END_DATE

            contracts.append({
                "VertragsNr": contract_id,
                "GeräteNr": device["GeräteNr"],
                "Vertragsart": contract_type,
                "Beginn": current_start,
                "Ende": end,
                "Kosten_pro_Jahr": round(
                    random.uniform(min_cost, max_cost), 2
                ),
            })

            contract_id += 1

            if end >= END_DATE:
                break

            current_start = end + timedelta(days=1)

    return contracts


def generate_maintenance(devices, contracts, employees):
    maintenance = []
    maintenance_id = 9001

    # Nur Mitarbeiter aus Netzwerktechnik und Field Service dürfen
    # Wartungen durchführen.
    technicians = [
        employee["MitarbeiterNr"]
        for employee in employees
        if employee["Team"] in ("Netzwerktechnik", "Field Service")
    ]

    contracts_by_device = {}
    for contract in contracts:
        contracts_by_device.setdefault(
            contract["GeräteNr"], []
        ).append(contract)

    for device in devices:
        device_contracts = contracts_by_device.get(
            device["GeräteNr"], []
        )

        if not device_contracts:
            continue

        # 1 bis 3 Wartungen pro Gerät im Betrachtungszeitraum.
        number = random.randint(1, 3)

        for _ in range(number):
            contract = random.choice(device_contracts)

            # Nur Wartungen innerhalb des gültigen Vertrags.
            start = max(contract["Beginn"], START_DATE)
            end = min(contract["Ende"], END_DATE)

            if start > end:
                continue

            maintenance_type = random.choice(MAINTENANCE_TYPES)

            cost_ranges = {
                "Firmware-Update": (0, 100),
                "Komponententausch": (200, 800),
                "Konfigurationsprüfung": (50, 150),
                "Inspektion": (50, 150),
            }

            min_cost, max_cost = cost_ranges[maintenance_type]

            maintenance.append({
                "WartungsNr": maintenance_id,
                "GeräteNr": device["GeräteNr"],
                "Datum": random_date(start, end),
                "Wartungsart": maintenance_type,
                "TechnikerNr": random.choice(technicians),
                "Kosten": round(
                    random.uniform(min_cost, max_cost), 2
                ),
            })

            maintenance_id += 1

    return maintenance


def generate_tickets(customers, devices):
    count = random.randint(300, 600)
    tickets = []

    devices_by_location = {}

    for device in devices:
        devices_by_location.setdefault(
            device["StandortID"], []
        ).append(device)

    for ticket_id in range(1001, 1001 + count):
        customer = random.choice(customers)

        # Für realistische Beziehungen wird bevorzugt ein Gerät am
        # Standort des Kunden ausgewählt.
        available_devices = devices_by_location.get(
            customer["StandortID"],
            devices
        )

        device = random.choice(available_devices)

        category = weighted_choice(
            TICKET_CATEGORIES,
            [25, 40, 20, 15]
        )

        priority = weighted_choice(
            list(TICKET_PRIORITIES.keys()),
            [5, 20, 55, 20]
        )

        # Kritische und hoch priorisierte Tickets werden seltener
        # geschlossen gelassen.
        status = weighted_choice(
            ["Geschlossen", "Gelöst", "In Bearbeitung"],
            [65, 25, 10]
        )

        created = random_datetime(START_DATE, END_DATE)

        tickets.append({
            "TicketNr": ticket_id,
            "KundenNr": customer["KundenNr"],
            "GeräteNr": device["GeräteNr"],
            "Erstellungsdatum": created,
            "Kategorie": category,
            "Priorität": priority,
            "Status": status,
            "SLA_Zielzeit_Minuten": TICKET_PRIORITIES[priority],
        })

    return tickets


def generate_processings(tickets, employees):
    processings = []
    processing_id = 8001

    # Tickets können durch Mitarbeiter aus allen Teams bearbeitet werden.
    employee_ids = [
        employee["MitarbeiterNr"]
        for employee in employees
    ]

    for ticket in tickets:
        # 1 bis 4 Bearbeitungsschritte pro Ticket.
        count = random.randint(1, 4)

        current_time = ticket["Erstellungsdatum"]

        # Bewusst ein Anteil an SLA-Verletzungen.
        # Die Bearbeitungszeit wird so erzeugt, dass bei einem Teil der
        # Tickets die Summe der Bearbeitungszeiten das SLA überschreitet.
        sla = ticket["SLA_Zielzeit_Minuten"]

        violate_sla = random.random() < 0.18

        if violate_sla:
            total_target = int(
                sla * random.uniform(1.05, 1.80)
            )
        else:
            total_target = int(
                sla * random.uniform(0.20, 0.85)
            )

        # Verteilung auf die einzelnen Bearbeitungsschritte.
        weights = [
            random.uniform(0.5, 1.5)
            for _ in range(count)
        ]
        weight_sum = sum(weights)

        for step in range(count):
            if step == count - 1:
                processing_time = max(
                    10,
                    total_target - sum(
                        p["Bearbeitungszeit_Minuten"]
                        for p in processings
                        if p["TicketNr"] == ticket["TicketNr"]
                    )
                )
            else:
                processing_time = max(
                    10,
                    int(total_target * weights[step] / weight_sum)
                )

            # Bearbeitung findet zeitlich nach der Ticketerstellung statt.
            current_time += timedelta(
                minutes=random.randint(5, 180)
            )

            # Bei langen Abständen kann die Bearbeitung auch am nächsten
            # Tag stattfinden.
            if random.random() < 0.15:
                current_time += timedelta(
                    hours=random.randint(1, 24)
                )

            # Nicht künstlich über den Betrachtungszeitraum hinausgehen.
            if current_time.date() > END_DATE:
                current_time = datetime(
                    END_DATE.year,
                    END_DATE.month,
                    END_DATE.day,
                    17,
                    random.randint(0, 59)
                )

            processings.append({
                "BearbeitungsNr": processing_id,
                "TicketNr": ticket["TicketNr"],
                "MitarbeiterNr": random.choice(employee_ids),
                "Datum": current_time,
                "Bearbeitungszeit_Minuten": processing_time,
                "Aktionstyp": random.choice(TICKET_ACTIONS),
            })

            processing_id += 1

    return processings


# ------------------------------------------------------------
# SQL-Erzeugung
# ------------------------------------------------------------

def generate_sql():
    locations = generate_locations()
    employees = generate_employees()
    customers = generate_customers(locations)
    account_managers = generate_account_managers(customers)
    devices = generate_devices(locations)
    contracts = generate_contracts(devices)
    maintenance = generate_maintenance(
        devices,
        contracts,
        employees
    )
    tickets = generate_tickets(customers, devices)
    processings = generate_processings(tickets, employees)

    lines = []

    lines.append("-- =========================================================")
    lines.append("-- Automatisch erzeugte Beispieldaten")
    lines.append("-- PostgreSQL")
    lines.append("-- =========================================================")
    lines.append("")
    lines.append("BEGIN;")
    lines.append("")

    # Tabellen leeren. CASCADE berücksichtigt auch vorhandene
    # Fremdschlüsselabhängigkeiten.
    lines.append("-- Vorhandene Daten entfernen")
    lines.append(
        "TRUNCATE TABLE "
        "src_ticketsystem.Bearbeitung, "
        "src_ticketsystem.Ticket, "
        "src_ticketsystem.Kundenbetreuer, "
        "src_ticketsystem.Mitarbeiter, "
        "src_ticketsystem.Kunde, "
        "src_inventarsystem.Wartung, "
        "src_inventarsystem.Wartungsvertrag, "
        "src_inventarsystem.Gerät, "
        "src_inventarsystem.Standort "
        "RESTART IDENTITY CASCADE;"
    )
    lines.append("")

    # Standort
    rows = [
        [
            str(row["StandortID"]),
            sql_string(row["Standortbezeichnung"]),
            sql_string(row["Region"]),
            sql_string(row["Land"]),
        ]
        for row in locations
    ]

    lines.append("-- Standorte")
    lines.append(
        insert_statement(
            "src_inventarsystem",
            "Standort",
            [
                "StandortID",
                "Standortbezeichnung",
                "Region",
                "Land",
            ],
            rows,
        )
    )

    # Geräte
    rows = [
        [
            str(row["GeräteNr"]),
            sql_string(row["Gerätetyp"]),
            sql_string(row["Hersteller"]),
            sql_string(row["Modell"]),
            str(row["StandortID"]),
            sql_date(row["Anschaffungsdatum"]),
        ]
        for row in devices
    ]

    lines.append("-- Geräte")
    lines.append(
        insert_statement(
            "src_inventarsystem",
            "Gerät",
            [
                "GeräteNr",
                "Gerätetyp",
                "Hersteller",
                "Modell",
                "StandortID",
                "Anschaffungsdatum",
            ],
            rows,
        )
    )

    # Wartungsverträge
    rows = [
        [
            str(row["VertragsNr"]),
            str(row["GeräteNr"]),
            sql_string(row["Vertragsart"]),
            sql_date(row["Beginn"]),
            sql_date(row["Ende"]),
            sql_decimal(row["Kosten_pro_Jahr"]),
        ]
        for row in contracts
    ]

    lines.append("-- Wartungsverträge")
    lines.append(
        insert_statement(
            "src_inventarsystem",
            "Wartungsvertrag",
            [
                "VertragsNr",
                "GeräteNr",
                "Vertragsart",
                "Beginn",
                "Ende",
                "Kosten_pro_Jahr",
            ],
            rows,
        )
    )

    # Wartungen
    rows = [
        [
            str(row["WartungsNr"]),
            str(row["GeräteNr"]),
            sql_date(row["Datum"]),
            sql_string(row["Wartungsart"]),
            str(row["TechnikerNr"]),
            sql_decimal(row["Kosten"]),
        ]
        for row in maintenance
    ]

    lines.append("-- Wartungen")
    lines.append(
        insert_statement(
            "src_inventarsystem",
            "Wartung",
            [
                "WartungsNr",
                "GeräteNr",
                "Datum",
                "Wartungsart",
                "TechnikerNr",
                "Kosten",
            ],
            rows,
        )
    )

    # Kunden
    rows = [
        [
            str(row["KundenNr"]),
            sql_string(row["Kunden_Name"]),
            sql_string(row["Kundentyp"]),
            str(row["StandortID"]),
        ]
        for row in customers
    ]

    lines.append("-- Kunden")
    lines.append(
        insert_statement(
            "src_ticketsystem",
            "Kunde",
            [
                "KundenNr",
                "Kunden_Name",
                "Kundentyp",
                "StandortID",
            ],
            rows,
        )
    )

    # Kundenbetreuer
    rows = [
        [
            str(row["BetreuerNr"]),
            str(row["KundenNr"]),
            sql_string(row["Name"]),
            sql_string(row["Team"]),
        ]
        for row in account_managers
    ]

    lines.append("-- Kundenbetreuer")
    lines.append(
        insert_statement(
            "src_ticketsystem",
            "Kundenbetreuer",
            [
                "BetreuerNr",
                "KundenNr",
                "Name",
                "Team",
            ],
            rows,
        )
    )

    # Mitarbeiter
    rows = [
        [
            str(row["MitarbeiterNr"]),
            sql_string(row["Name"]),
            sql_string(row["Team"]),
            sql_string(row["Rolle"]),
        ]
        for row in employees
    ]

    lines.append("-- Mitarbeiter")
    lines.append(
        insert_statement(
            "src_ticketsystem",
            "Mitarbeiter",
            [
                "MitarbeiterNr",
                "Name",
                "Team",
                "Rolle",
            ],
            rows,
        )
    )

    # Tickets
    rows = [
        [
            str(row["TicketNr"]),
            str(row["KundenNr"]),
            str(row["GeräteNr"]),
            sql_timestamp(row["Erstellungsdatum"]),
            sql_string(row["Kategorie"]),
            sql_string(row["Priorität"]),
            sql_string(row["Status"]),
            str(row["SLA_Zielzeit_Minuten"]),
        ]
        for row in tickets
    ]

    lines.append("-- Tickets")
    lines.append(
        insert_statement(
            "src_ticketsystem",
            "Ticket",
            [
                "TicketNr",
                "KundenNr",
                "GeräteNr",
                "Erstellungsdatum",
                "Kategorie",
                "Priorität",
                "Status",
                "SLA_Zielzeit_Minuten",
            ],
            rows,
        )
    )

    # Bearbeitungen
    rows = [
        [
            str(row["BearbeitungsNr"]),
            str(row["TicketNr"]),
            str(row["MitarbeiterNr"]),
            sql_timestamp(row["Datum"]),
            str(row["Bearbeitungszeit_Minuten"]),
            sql_string(row["Aktionstyp"]),
        ]
        for row in processings
    ]

    lines.append("-- Bearbeitungen")
    lines.append(
        insert_statement(
            "src_ticketsystem",
            "Bearbeitung",
            [
                "BearbeitungsNr",
                "TicketNr",
                "MitarbeiterNr",
                "Datum",
                "Bearbeitungszeit_Minuten",
                "Aktionstyp",
            ],
            rows,
        )
    )

    lines.append("COMMIT;")
    lines.append("")
    lines.append("-- =========================================================")
    lines.append("-- Ende der Beispieldaten")
    lines.append("-- =========================================================")

    OUTPUT_FILE.write_text("\n".join(lines), encoding="utf-8")

    return {
        "Standorte": len(locations),
        "Geräte": len(devices),
        "Wartungsverträge": len(contracts),
        "Wartungen": len(maintenance),
        "Kunden": len(customers),
        "Kundenbetreuer": len(account_managers),
        "Mitarbeiter": len(employees),
        "Tickets": len(tickets),
        "Bearbeitungen": len(processings),
    }


if __name__ == "__main__":
    counts = generate_sql()

    print()
    print("Beispieldaten wurden erfolgreich erzeugt.")
    print(f"SQL-Datei: {OUTPUT_FILE}")
    print()
    print("Erzeugte Datensätze:")
    for table, count in counts.items():
        print(f"  {table:20} {count:4}")
    print()
    print("Für einen reproduzierbaren Lauf:")
    print("  python generate_data.py 12345")
